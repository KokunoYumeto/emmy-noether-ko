from __future__ import annotations

import csv
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

from pypdf import PdfReader


ROOT = Path(__file__).resolve().parent
TEX = ROOT / "publication.tex"
BASE_TEX = ROOT / "reader.tex"
PROV = ROOT / "prov12.csv"
BUILD = ROOT / "b"
RAW = ROOT / "raw.pdf"
FINAL = ROOT / "reader.pdf"
LOG = ROOT / "reader.log"
OUT = ROOT / "build.json"
POPPLER = ROOT / "extract.txt"
PYPDF = ROOT / "pypdf.txt"
TEX_SHA = "180961C7AE325207304CF1CB93F05E0D9C5A95FE6673101BFE8FE8C4F2B93270"
BASE_TEX_SHA = "A647BCE5692E17EEE54EE1A7D3A3DCC48CC9C8E972F801B8E0699D036484DFDB"
PROV_SHA = "A8497C7EEE730A6D46FAB9759B34F4509169D134FE29D60B6D200B48F675BB31"
SOURCE_DATE_EPOCH = "1786579200"
PAGE_COUNT = 519
ALLOWED_C0 = {9, 10, 12, 13}


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def ident(path: Path) -> dict[str, object]:
    return {"path": path.relative_to(ROOT).as_posix(), "bytes": path.stat().st_size, "sha256": sha(path)}


def command(name: str) -> str:
    found = shutil.which(name)
    if found:
        return found
    fallback = Path.home() / f"AppData/Local/Programs/MiKTeX/miktex/bin/x64/{name}.exe"
    if fallback.is_file():
        return str(fallback)
    raise SystemExit(f"required executable not found: {name}")


def verify_inputs() -> list[dict[str, object]]:
    if TEX.stat().st_size != 8499 or sha(TEX) != TEX_SHA:
        raise SystemExit("publication.tex identity mismatch")
    if BASE_TEX.stat().st_size != 6262 or sha(BASE_TEX) != BASE_TEX_SHA:
        raise SystemExit("canonical reader.tex identity mismatch")
    if sha(PROV) != PROV_SHA:
        raise SystemExit("prov11.csv identity mismatch")
    records = []
    with PROV.open(encoding="utf-8", newline="") as handle:
        for row in csv.DictReader(handle):
            path = ROOT / row["file"]
            if not path.is_file() or path.stat().st_size != int(row["new_bytes"]) or sha(path) != row["new_sha256"]:
                raise SystemExit(f"input identity mismatch: {row['file']}")
            records.append({"path": row["file"], "bytes": path.stat().st_size, "sha256": sha(path)})
    source = TEX.read_text(encoding="utf-8")
    reader_inputs = re.findall(r"\\NoetherEntry\{[^}]*\}\{([^}]+)\}", source)
    expected = sorted(row["path"] for row in records if row["path"] != "p09_tail.tex")
    if len(reader_inputs) != 46 or len(set(reader_inputs)) != 46 or sorted(reader_inputs) != expected:
        raise SystemExit("reader input topology mismatch")
    return records


def scan_text(path: Path) -> dict[str, object]:
    text = path.read_text(encoding="utf-8")
    bad = sum(ord(char) < 32 and ord(char) not in ALLOWED_C0 for char in text)
    record = {**ident(path), "bad_c0": bad, "replacement": text.count("\ufffd"), "nul": text.count("\x00")}
    if bad or record["replacement"] or record["nul"]:
        raise SystemExit(f"extraction gate failed: {path.name} {record}")
    return record


def main() -> None:
    inputs = verify_inputs()
    xelatex = command("xelatex")
    pdftotext = command("pdftotext")
    BUILD.mkdir(exist_ok=True)
    resolved = BUILD.resolve()
    if resolved.parent != ROOT.resolve() or resolved.name != "b":
        raise SystemExit("unsafe build directory")
    for path in BUILD.iterdir():
        if not path.is_file():
            raise SystemExit(f"unexpected build subdirectory: {path}")
        path.unlink()
    env = dict(os.environ)
    env["SOURCE_DATE_EPOCH"] = SOURCE_DATE_EPOCH
    env["FORCE_SOURCE_DATE"] = "1"
    env["TZ"] = "UTC"
    run = [
        xelatex,
        "-interaction=nonstopmode",
        "-halt-on-error",
        "-file-line-error",
        "-no-shell-escape",
        "-jobname=ko-pub",
        f"-output-directory={BUILD}",
        str(TEX),
    ]
    passes = []
    for number in (1, 2, 3, 4):
        completed = subprocess.run(run, cwd=ROOT, env=env, capture_output=True, text=False)
        stdout = BUILD / f"p{number}.txt"
        stdout.write_bytes(completed.stdout + completed.stderr)
        live_pdf = BUILD / "ko-pub.pdf"
        live_log = BUILD / "ko-pub.log"
        pass_pdf = BUILD / f"p{number}.pdf"
        pass_log = BUILD / f"p{number}.log"
        if live_pdf.exists():
            shutil.copyfile(live_pdf, pass_pdf)
        if live_log.exists():
            shutil.copyfile(live_log, pass_log)
        log_text = pass_log.read_text(encoding="utf-8", errors="replace") if pass_log.exists() else ""
        passes.append(
            {
                "pass": number,
                "exit_code": completed.returncode,
                "stdout": ident(stdout),
                "log": ident(pass_log) if pass_log.exists() else None,
                "pdf": ident(pass_pdf) if pass_pdf.exists() else None,
                "signals": {
                    "fatal": log_text.count("Fatal error") + log_text.count("Emergency stop"),
                    "undefined": log_text.count("Undefined control sequence"),
                    "rerun": log_text.count("Rerun to get"),
                    "missing_character": log_text.count("Missing character:"),
                    "overfull": log_text.count("Overfull \\hbox") + log_text.count("Overfull \\vbox"),
                    "underfull": log_text.count("Underfull \\hbox") + log_text.count("Underfull \\vbox"),
                },
            }
        )
        if completed.returncode != 0 or not pass_pdf.is_file():
            raise SystemExit(f"XeLaTeX pass {number} failed")
    if (BUILD / "p3.pdf").read_bytes() != (BUILD / "p4.pdf").read_bytes():
        raise SystemExit("XeLaTeX passes 3 and 4 did not stabilize")
    if any(passes[-1]["signals"][key] for key in ("fatal", "undefined", "rerun", "missing_character")):
        raise SystemExit("fatal final-log signal")
    shutil.copyfile(BUILD / "p4.pdf", RAW)
    shutil.copyfile(BUILD / "p4.log", LOG)
    fix_run = subprocess.run([sys.executable, str(ROOT / "fix.py")], cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if fix_run.returncode != 0 or not FINAL.is_file():
        raise SystemExit(f"fix.py failed: {fix_run.stdout}{fix_run.stderr}")
    poppler_run = subprocess.run([pdftotext, "-layout", "-enc", "UTF-8", str(FINAL), str(POPPLER)], cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if poppler_run.returncode != 0:
        raise SystemExit(f"pdftotext failed: {poppler_run.stdout}{poppler_run.stderr}")
    reader = PdfReader(str(FINAL), strict=True)
    PYPDF.write_text("\f".join((page.extract_text() or "") for page in reader.pages), encoding="utf-8", newline="\n")
    if len(reader.pages) != PAGE_COUNT:
        raise SystemExit("final page-count drift")
    result = {
        "record_id": "KO-NOETHER-PUB-1.0.0-BUILD-001",
        "state": "PASS_RELEASE_BUILD_PENDING_FULL_RENDER_QA",
        "source_date_epoch": int(SOURCE_DATE_EPOCH),
        "timezone": "UTC",
        "serial": True,
        "command": run,
        "reader_tex": ident(TEX),
        "canonical_reader_tex": ident(BASE_TEX),
        "provenance": ident(PROV),
        "inputs": inputs,
        "passes": passes,
        "pass3_pass4_pdf_byte_identical": True,
        "raw_pdf": {**ident(RAW), "pages": PAGE_COUNT},
        "fix_receipt": ident(ROOT / "fix.json"),
        "final_pdf": {**ident(FINAL), "pages": PAGE_COUNT},
        "final_log": ident(LOG),
        "extraction": {"poppler": scan_text(POPPLER), "pypdf": scan_text(PYPDF)},
        "sga": "held and untouched",
    }
    tmp = OUT.with_suffix(".tmp.json")
    tmp.write_text(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8", newline="\n")
    tmp.replace(OUT)
    print(json.dumps({"raw": ident(RAW), "final": ident(FINAL), "pages": PAGE_COUNT, "extractors": "clean"}))


if __name__ == "__main__":
    main()
