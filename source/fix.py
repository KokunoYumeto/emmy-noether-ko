from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
from collections import defaultdict
from pathlib import Path
from typing import Any

import pypdf
from pypdf import PdfReader, PdfWriter
from pypdf.generic import ArrayObject, DecodedStreamObject, NameObject


ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw.pdf"
FINAL = ROOT / "reader.pdf"
TMP1 = ROOT / "_fix1.pdf"
TMP2 = ROOT / "_fix2.pdf"
OUT = ROOT / "fix.json"
FONTS = ROOT / "fonts.txt"
MAP_DIR = ROOT / "map"
MAP_PINS = {
    "oms.cmap": (2370, "B0EA8E71B5D2E1DC86991867AF6B9547BE1BCC20EC7561D7C3BEDFA84204A999"),
    "omx.cmap": (3001, "C07DF4892D287A36825A0611A1E2BE0C9F120260F632E00E17D4E8C5973331F8"),
    "umsb.cmap": (2450, "22266C6FAA697A7266CF244EFF2A64037FF762F90B5AD123D8744054D2B02F82"),
}
FONT_MAP = {
    "CMSY9": "oms.cmap",
    "CMSY10": "oms.cmap",
    "MSBM10": "umsb.cmap",
    "CMEX10": "omx.cmap",
    "CMEX9": "omx.cmap",
    "CMEX7": "omx.cmap",
    "CMEX8": "omx.cmap",
}


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def ident(path: Path) -> dict[str, object]:
    data = path.read_bytes()
    return {"path": path.relative_to(ROOT).as_posix(), "bytes": len(data), "sha256": digest(data)}


def deref(value: Any) -> Any:
    return value.get_object() if hasattr(value, "get_object") else value


def ref_id(value: Any) -> tuple[int | None, int | None]:
    ref = value if hasattr(value, "idnum") else getattr(value, "indirect_reference", None)
    return getattr(ref, "idnum", None), getattr(ref, "generation", None)


def base_name(font: Any) -> str:
    return str(font.get("/BaseFont", "")).lstrip("/").rsplit("+", 1)[-1]


def stream_data(value: Any) -> tuple[bytes, bytes]:
    obj = deref(value)
    return bytes(getattr(obj, "_data", b"")), obj.get_data()


def page_streams(page: Any) -> list[tuple[bytes, bytes]]:
    value = page.get("/Contents")
    if value is None:
        return []
    values = list(deref(value)) if isinstance(deref(value), ArrayObject) else [value]
    return [stream_data(item) for item in values]


def font_inventory(reader: PdfReader) -> dict[tuple[int | None, int | None], dict[str, object]]:
    found: dict[tuple[int | None, int | None], dict[str, object]] = {}
    pages: dict[tuple[int | None, int | None], list[int]] = defaultdict(list)
    for page_number, page in enumerate(reader.pages, 1):
        resources = deref(page.get("/Resources"))
        fonts = deref(resources.get("/Font")) if resources else None
        for value in (fonts or {}).values():
            font = deref(value)
            key = ref_id(value)
            pages[key].append(page_number)
            descriptor = deref(font.get("/FontDescriptor"))
            programs = {}
            if descriptor:
                for label in ("/FontFile", "/FontFile2", "/FontFile3"):
                    if label in descriptor:
                        encoded, decoded = stream_data(descriptor[label])
                        programs[label] = [len(encoded), digest(encoded), len(decoded), digest(decoded)]
            cmap = None
            if font.get("/ToUnicode") is not None:
                encoded, decoded = stream_data(font["/ToUnicode"])
                cmap = [len(encoded), digest(encoded), len(decoded), digest(decoded)]
            found[key] = {
                "name": base_name(font),
                "subtype": str(font.get("/Subtype", "")),
                "encoding": str(font.get("/Encoding", "")),
                "programs": programs,
                "to_unicode": cmap,
                "pages": pages[key],
            }
    return found


def build(destination: Path, maps: dict[str, bytes]) -> list[dict[str, object]]:
    reader = PdfReader(str(RAW), strict=True)
    raw_missing = {str(row["name"]) for row in font_inventory(reader).values() if row["to_unicode"] is None}
    if raw_missing != set(FONT_MAP):
        raise RuntimeError(f"missing-font allowlist mismatch in raw PDF: {sorted(raw_missing)}")
    writer = PdfWriter(clone_from=reader)
    writer.pdf_header = reader.pdf_header
    writer._ID = reader.trailer["/ID"]
    map_refs = {}
    for name in sorted(maps):
        stream = DecodedStreamObject()
        stream.set_data(maps[name])
        map_refs[name] = writer._add_object(stream)
    injected: dict[tuple[int | None, int | None], dict[str, object]] = {}
    for page_number, page in enumerate(writer.pages, 1):
        resources = deref(page.get("/Resources"))
        fonts = deref(resources.get("/Font")) if resources else None
        for value in (fonts or {}).values():
            font = deref(value)
            key = ref_id(value)
            name = base_name(font)
            if name not in FONT_MAP:
                continue
            if key in injected:
                injected[key]["pages"].append(page_number)
                continue
            if font.get("/ToUnicode") is not None:
                raise RuntimeError(f"target already has ToUnicode: {name}")
            cmap_name = FONT_MAP[name]
            font[NameObject("/ToUnicode")] = map_refs[cmap_name]
            injected[key] = {"font": name, "font_ref": list(key), "cmap": cmap_name, "pages": [page_number]}
    names = {row["font"] for row in injected.values()}
    if names != set(FONT_MAP) or len(injected) != 7:
        raise RuntimeError(f"patched-font allowlist mismatch: {sorted(names)}")
    with destination.open("wb") as handle:
        writer.write(handle)
    return sorted(injected.values(), key=lambda row: row["font"])


def validate(raw: PdfReader, fixed: PdfReader, maps: dict[str, bytes]) -> None:
    if len(raw.pages) != len(fixed.pages) or len(raw.pages) != 519:
        raise RuntimeError("page-count drift")
    if raw.pdf_header != fixed.pdf_header or raw.metadata != fixed.metadata or raw.trailer.get("/ID") != fixed.trailer.get("/ID"):
        raise RuntimeError("document identity metadata drift")
    for number, (left, right) in enumerate(zip(raw.pages, fixed.pages), 1):
        if page_streams(left) != page_streams(right):
            raise RuntimeError(f"page-content drift: {number}")
        left_boxes = [str(left.mediabox), str(left.cropbox), str(left.bleedbox), str(left.trimbox), str(left.artbox), int(left.rotation)]
        right_boxes = [str(right.mediabox), str(right.cropbox), str(right.bleedbox), str(right.trimbox), str(right.artbox), int(right.rotation)]
        if left_boxes != right_boxes:
            raise RuntimeError(f"page-geometry drift: {number}")
    raw_fonts = font_inventory(raw)
    fixed_fonts = font_inventory(fixed)
    raw_by_name = {str(row["name"]): row for row in raw_fonts.values()}
    fixed_by_name = {str(row["name"]): row for row in fixed_fonts.values()}
    if set(raw_by_name) != set(fixed_by_name):
        raise RuntimeError("font-set drift")
    for name in sorted(raw_by_name):
        before = dict(raw_by_name[name])
        after = dict(fixed_by_name[name])
        before_map = before.pop("to_unicode")
        after_map = after.pop("to_unicode")
        before.pop("pages")
        after.pop("pages")
        if before != after:
            raise RuntimeError(f"font-program drift: {name}")
        if name in FONT_MAP:
            if before_map is not None or after_map is None or after_map[3] != digest(maps[FONT_MAP[name]]):
                raise RuntimeError(f"new ToUnicode mismatch: {name}")
        elif before_map != after_map:
            raise RuntimeError(f"existing ToUnicode drift: {name}")


def pdffonts_gate(path: Path) -> dict[str, object]:
    executable = shutil.which("pdffonts") or str(Path.home() / "AppData/Local/Programs/MiKTeX/miktex/bin/x64/pdffonts.exe")
    completed = subprocess.run([executable, str(path)], capture_output=True, text=True, encoding="utf-8", errors="replace")
    FONTS.write_text(completed.stdout + completed.stderr, encoding="utf-8", newline="\n")
    if completed.returncode != 0:
        raise RuntimeError("pdffonts failed")
    rows = [line.split() for line in completed.stdout.splitlines()[2:] if line.strip()]
    missing = [row[0] for row in rows if len(row) >= 8 and row[-3] != "yes"]
    if len(rows) != 38 or missing:
        raise RuntimeError(f"pdffonts ToUnicode gate failed: rows={len(rows)} missing={missing}")
    return {"fonts": len(rows), "all_embedded_subset_tounicode": True, "evidence": ident(FONTS)}


def main() -> None:
    if pypdf.__version__ != "6.12.2":
        raise SystemExit(f"unexpected pypdf version: {pypdf.__version__}")
    if not RAW.is_file():
        raise SystemExit("raw.pdf is missing")
    maps = {}
    map_records = {}
    for name, (expected_bytes, expected_sha) in MAP_PINS.items():
        path = MAP_DIR / name
        data = path.read_bytes()
        if len(data) != expected_bytes or digest(data) != expected_sha:
            raise SystemExit(f"CMap identity mismatch: {name}")
        maps[name] = data
        map_records[name] = ident(path)
    for path in (TMP1, TMP2):
        if path.exists():
            path.unlink()
    injected1 = build(TMP1, maps)
    injected2 = build(TMP2, maps)
    if injected1 != injected2 or TMP1.read_bytes() != TMP2.read_bytes():
        raise SystemExit("fixed PDF is not byte-deterministic")
    raw_reader = PdfReader(str(RAW), strict=True)
    fixed_reader = PdfReader(str(TMP1), strict=True)
    validate(raw_reader, fixed_reader, maps)
    first_identity = ident(TMP1)
    second_identity = ident(TMP2)
    TMP1.replace(FINAL)
    TMP2.unlink()
    fonts = pdffonts_gate(FINAL)
    result = {
        "record_id": "KO-NOETHER-PUB-1.0.0-CMAP-FIX-001",
        "state": "PASS_PENDING_DUAL_EXTRACTION_AND_FULL_RENDER_QA",
        "method": "pypdf 6.12.2 missing-only deterministic ToUnicode CMap injection",
        "raw_pdf": {**ident(RAW), "pages": len(raw_reader.pages)},
        "fixed_pdf": {**ident(FINAL), "pages": len(fixed_reader.pages)},
        "determinism": {"first": first_identity, "second": second_identity, "byte_identical": True},
        "cmaps": map_records,
        "injected_fonts": injected1,
        "invariants": {"page_count": 519, "page_content_streams": "exact", "page_geometry": "exact", "font_programs": "exact", "metadata_and_trailer_id": "exact", "all_pass": True},
        "pdffonts": fonts,
        "target_text_mutated_by_fix": False,
        "sga": "held and untouched",
    }
    tmp_json = OUT.with_suffix(".tmp.json")
    tmp_json.write_text(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8", newline="\n")
    tmp_json.replace(OUT)
    print(json.dumps({"fixed": ident(FINAL), "fonts": 37, "injected": 7, "invariants": True}))


if __name__ == "__main__":
    main()
