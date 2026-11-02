"""Il foglio dei tasti della pagina "Comandi" (assets/ui/tasti.png), ritagliato da gdb-keyboard-2.png
(pacchetto "gdb-gamepad-2", cartella ui accanto al progetto). Non è nel repository, come gli altri asset.

    python tools/make_tasti.py "C:/percorso/gdb-gamepad-2(all)/gdb-keyboard-2.png"

Le regioni nei nodi Tasto di scenes/comandi.tscn seguono quest'ordine (tutti alti 16 pixel).
"""
import os
import sys

from PIL import Image

# nome, rettangolo nel foglio della tastiera (x, y, larghezza, altezza)
KEYS = [
    ("esc", (32, 16, 16, 16)), ("f11", (224, 16, 16, 16)),
    ("z", (64, 80, 16, 16)), ("x", (80, 80, 16, 16)), ("c", (96, 80, 16, 16)),
    ("w", (80, 48, 16, 16)), ("a", (64, 64, 16, 16)), ("s", (80, 64, 16, 16)), ("d", (96, 64, 16, 16)),
    ("enter", (244, 64, 24, 16)), ("shift", (36, 80, 24, 16)),
    ("space", (100, 96, 104, 16)),  # accorciata a 40: i suoi due bordi da 20
    ("up", (320, 80, 16, 16)), ("left", (304, 96, 16, 16)), ("down", (320, 96, 16, 16)), ("right", (336, 96, 16, 16)),
]


def main(src: str) -> None:
    sheet = Image.open(src).convert("RGBA")
    pieces = []
    for name, (x, y, w, h) in KEYS:
        key = sheet.crop((x, y, x + w, y + h))
        if name == "space":
            short = Image.new("RGBA", (40, 16))
            short.paste(key.crop((0, 0, 20, 16)), (0, 0))
            short.paste(key.crop((w - 20, 0, w, 16)), (20, 0))
            key = short
        px = key.load()
        # i puntini bianchi fra un tasto e l'altro, negli angoli
        for cx in (0, 1, key.width - 2, key.width - 1):
            for cy in (0, 1, 14, 15):
                r, g, b, a = px[cx, cy]
                if a and r > 200 and g > 200 and b > 200:
                    px[cx, cy] = (0, 0, 0, 0)
        pieces.append((name, key))
    out = Image.new("RGBA", (sum(k.width for _, k in pieces), 16))
    x = 0
    for name, key in pieces:
        out.paste(key, (x, 0))
        print(f"{name}: Rect2({x}, 0, {key.width}, 16)")
        x += key.width
    dst = os.path.join(os.path.dirname(__file__), "..", "assets", "ui", "tasti.png")
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    out.save(dst)


if __name__ == "__main__":
    main(sys.argv[1])
