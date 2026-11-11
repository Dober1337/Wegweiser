# Baut dist/WegweiserRecorder.zip zum Weitergeben an Mitspieler.
# Aufruf (im Projektordner): python3 tools/build_recorder_zip.py
import os, zipfile
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src = os.path.join(root, "WegweiserRecorder")
out = os.path.join(root, "dist", "WegweiserRecorder.zip")
os.makedirs(os.path.dirname(out), exist_ok=True)
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for name in sorted(os.listdir(src)):
        z.write(os.path.join(src, name), "WegweiserRecorder/" + name)
print("geschrieben:", out)
