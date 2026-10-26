"""Estrae le canzoni usate dal gioco dai pacchetti in ../music/ (cartella accanto al progetto)
e le copia in assets/music/ con nomi semplici. La cartella è esclusa da git: i pacchetti non si ridistribuiscono.
Quali canzoni suonano dove: autoload/sound.gd, PLAYLISTS.

Esegui dalla cartella del progetto:  python tools/import_music.py
"""
import os
import re
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(os.path.dirname(ROOT), "music")
OUT = os.path.join(ROOT, "assets", "music")
PACKS = {
    "28 High Quality 16-bit RPG Music.zip": "ogg/",
    "FREE LOOPABLE MUSIC_BISHOP.zip": "FREE LOOPABLE MUSIC_BISHOP/OGG/",
}


def simple(name):
    n = re.sub(r"^\d+\.\s*", "", os.path.splitext(os.path.basename(name))[0])
    n = re.sub(r"\(.*?\)", "", n)
    return re.sub(r"[^A-Za-z0-9]+", "_", n).strip("_").lower()


def wanted():
    text = open(os.path.join(ROOT, "autoload", "sound.gd"), encoding="utf-8").read()
    block = text[text.index("const PLAYLISTS"):text.index("}", text.index("const PLAYLISTS"))]
    names = set()
    for lst in re.findall(r"\[(.*?)\]", block):
        names |= set(re.findall(r'"([a-z0-9_]+)"', lst))
    return names


if __name__ == "__main__":
    need = wanted()
    os.makedirs(OUT, exist_ok=True)
    for pack, prefix in PACKS.items():
        path = os.path.join(SRC, pack)
        if not os.path.exists(path):
            print("manca", path)
            continue
        with zipfile.ZipFile(path) as z:
            for info in z.infolist():
                if not info.filename.startswith(prefix) or not info.filename.endswith(".ogg"):
                    continue
                if "(intro)" in info.filename or "(full)" in info.filename:
                    continue
                n = simple(info.filename)
                if n in need:
                    with open(os.path.join(OUT, n + ".ogg"), "wb") as f:
                        f.write(z.read(info))
                    need.discard(n)
                    print("assets/music/" + n + ".ogg")
    if need:
        print("non trovate:", sorted(need))
