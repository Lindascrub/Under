"""Segnaposto: l'orologio senza lancette del Sottoufficio (art/c2/orologio_senza_lancette.png, 16x16).
Stile LimeZu: contorno #18141e, niente antialiasing. Da sostituire con il disegno vero, stesso nome e misura."""
from pathlib import Path
from PIL import Image

OUT = Path(__file__).resolve().parents[1] / "art/c2/orologio_senza_lancette.png"
CONT, BORDO, LUCE, QUADR, TACCHE = (24, 20, 30, 255), (120, 112, 128, 255), (168, 160, 176, 255), (236, 232, 220, 255), (80, 72, 88, 255)
img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
px = img.load()
for y in range(16):
    for x in range(16):
        d = ((x - 7.5) ** 2 + (y - 7.5) ** 2) ** 0.5
        if d <= 7.5:
            px[x, y] = CONT if d > 6.6 else BORDO if d > 5.6 else QUADR
# un riflesso sul bordo, in alto a sinistra
for x, y in [(4, 3), (3, 4), (5, 2)]:
    px[x, y] = LUCE
# le tacche delle ore (12, 3, 6, 9): le lancette non ci sono
for x, y in [(7, 3), (8, 3), (12, 7), (12, 8), (7, 12), (8, 12), (3, 7), (3, 8)]:
    px[x, y] = TACCHE
# il perno al centro, senza niente attaccato
for x, y in [(7, 7), (8, 7), (7, 8), (8, 8)]:
    px[x, y] = CONT
OUT.parent.mkdir(parents=True, exist_ok=True)
img.save(OUT)
print(OUT)
