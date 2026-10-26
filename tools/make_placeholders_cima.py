"""SEGNAPOSTO del Capitolo 6 (la Cima): forme piene con un'etichetta, solo per avere le misure giuste.
La grafica vera si disegna a parte: elenco completo (misure, prospettiva, animazioni, dove si usa)
in docs/ASSET_LIST.md. Sostituendo un PNG con uno della stessa misura, il gioco non cambia.

Esegui dalla cartella del progetto:  python tools/make_placeholders_cima.py
"""
from PIL import Image, ImageDraw
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_placeholders_banca as base  # noqa: E402

ROOT = base.ROOT
OUT = os.path.join(ROOT, "art", "c6")


def placeholder(name, w, h, fill, text="", text_fill=(255, 255, 255, 255), size=8, inner=None):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, w - 1, h - 1), fill=fill, outline=base.EDGE)
    if inner:
        d.rectangle(inner, fill=(16, 14, 22, 255))
    if text:
        base.label(d, (1, 1, w - 1, h - 1), text, size, text_fill)
    os.makedirs(OUT, exist_ok=True)
    if not base.save_asset(im, os.path.join(OUT, name)):
        return
    print("art/c6/" + name, im.size)


def tower(name, w, h):
    """La Torre in sezione: sei piani, dal Fondo alla Cima. Per il panorama e per gli epiloghi."""
    floors = [("CIMA", (214, 170, 60)), ("LA CITTÀ", (120, 190, 230)), ("LA BANCA", (200, 60, 60)),
              ("IL MERCATO", (120, 200, 120)), ("IL SOTTOUFFICIO", (120, 140, 200)), ("IL FONDO", (90, 80, 100))]
    im = Image.new("RGBA", (w, h), (16, 14, 22, 255))
    d = ImageDraw.Draw(im)
    fh = h // len(floors)
    for i, (label, col) in enumerate(floors):
        y = i * fh
        d.rectangle((8, y + 4, w - 9, y + fh - 4), fill=col + (255,), outline=base.EDGE)
        base.label(d, (8, y + 4, w - 9, y + fh - 4), label, 9, (16, 14, 22, 255))
    os.makedirs(OUT, exist_ok=True)
    if not base.save_asset(im, os.path.join(OUT, name)):
        return
    print("art/c6/" + name, im.size)


if __name__ == "__main__":
    GOLD = (214, 170, 60, 255)
    PINK = (255, 60, 170, 255)
    YELLOW = (255, 225, 77, 255)
    WHITE = (255, 255, 255, 255)
    DARK = (16, 14, 22, 255)
    MIRROR = (190, 220, 240, 255)
    placeholder("insegna_ascensore.png", 64, 12, GOLD, "NON DEVI PIÙ SALIRE.\nSEI ARRIVATO.", DARK, 5)
    placeholder("specchio_ascensore.png", 32, 32, MIRROR, "", inner=None)
    placeholder("specchio.png", 16, 24, MIRROR, "", inner=None)
    placeholder("scrivania_presidenza.png", 64, 32, (120, 60, 140, 255), "PRESIDENZA", YELLOW, 8)
    placeholder("terminale_direzione.png", 16, 32, (60, 60, 80, 255), "TURNO", (120, 255, 160, 255), 5, inner=(2, 3, 13, 14))
    placeholder("finestra_panorama.png", 80, 32, (142, 197, 255, 255), "", inner=None)
    placeholder("archivio_debito.png", 32, 40, (90, 70, 110, 255), "DEBITO\n7.000.000.000", YELLOW, 5)
    placeholder("tavolo_decisione.png", 48, 32, (170, 120, 70, 255), "", inner=None)
    placeholder("tavoli_condivisi.png", 96, 32, (150, 110, 70, 255), "TAVOLI CONDIVISI", WHITE, 7)
    placeholder("cartellina_obbligo.png", 12, 8, PINK)
    placeholder("timbro_annullato.png", 96, 24, (200, 30, 40, 255), "DEBITO ANNULLATO", WHITE, 10)
    placeholder("zucchero.png", 6, 4, WHITE)
    placeholder("lampadina.png", 8, 10, (255, 236, 150, 255))
    placeholder("macchina_caffe.png", 16, 32, (80, 70, 60, 255), "CAFFÈ", WHITE, 5, inner=(3, 4, 12, 12))
    placeholder("telefono.png", 12, 8, (214, 40, 60, 255))
    tower("torre_sezione.png", 200, 600)
