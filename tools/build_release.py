# Baut die Pakete zum Verteilen:
#   dist/Wegweiser-<Version>.zip          – nur das Addon (ohne Entwicklungsdateien)
#   dist/WegweiserRecorder-<Version>.zip  – der Recorder
# Aufruf (im Projektordner): python3 tools/build_release.py
import os, re, zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def version(toc):
    m = re.search(r"^## Version:\s*(\S+)", open(toc, encoding="utf-8").read(), re.M)
    return m.group(1) if m else "0"

def files_from_toc(toc_dir, toc_name):
    """Alle Dateien, die die .toc lädt, plus die .toc selbst."""
    out = [toc_name]
    for line in open(os.path.join(toc_dir, toc_name), encoding="utf-8"):
        line = line.strip()
        if line and not line.startswith("#"):
            out.append(line.replace("\\", "/"))
    return out

def build(src_dir, folder, toc_name, extra=()):
    ver = version(os.path.join(src_dir, toc_name))
    out = os.path.join(ROOT, "dist", f"{folder}-{ver}.zip")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    names = files_from_toc(src_dir, toc_name) + list(extra)
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for rel in names:
            path = os.path.join(src_dir, rel)
            if not os.path.isfile(path):
                raise SystemExit(f"FEHLT: {path}")
            z.write(path, f"{folder}/{rel}")
    print(f"{out}  ({len(names)} Dateien)")

build(ROOT, "Wegweiser", "Wegweiser.toc", extra=["README.md", "LICENSE"] if os.path.exists(os.path.join(ROOT, "LICENSE")) else ["README.md"])
build(os.path.join(ROOT, "WegweiserRecorder"), "WegweiserRecorder", "WegweiserRecorder.toc", extra=["LIESMICH.txt"])
