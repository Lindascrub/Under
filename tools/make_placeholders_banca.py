"""SEGNAPOSTO del Capitolo 4 (la Banca): forme piene con un'etichetta, solo per avere le misure giuste.
La grafica vera si disegna a parte: elenco completo (misure, prospettiva, animazioni, dove si usa)
in docs/ASSET_LIST.md. Sostituendo un PNG con uno della stessa misura, il gioco non cambia.

Esegui dalla cartella del progetto:  python tools/make_placeholders_banca.py
"""
from PIL import Image, ImageDraw, ImageFont
from asset_guard import save_asset
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "art", "c4")
EDGE = (24, 20, 30, 255)


def font(size):
    return ImageFont.truetype(os.path.join(ROOT, "fonts", "PixelifySans.ttf"), size)


def label(d, box, text, size, fill):
    d.fontmode = "1"
    f = font(size)
    lines = text.split("\n")
    hs = [d.textbbox((0, 0), l, font=f) for l in lines]
    total = sum(b[3] - b[1] for b in hs) + (len(lines) - 1)
    y = box[1] + (box[3] - box[1] - total) // 2
    for l, b in zip(lines, hs):
        w = b[2] - b[0]
        d.text((box[0] + (box[2] - box[0] - w) // 2 - b[0], y - b[1]), l, font=f, fill=fill)
        y += b[3] - b[1] + 1


def placeholder(name, w, h, fill, text="", text_fill=(255, 255, 255, 255), size=8, inner=None):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, w - 1, h - 1), fill=fill, outline=EDGE)
    if inner:
        d.rectangle(inner, fill=(16, 14, 22, 255))
    if text:
        label(d, (1, 1, w - 1, h - 1), text, size, text_fill)
    os.makedirs(OUT, exist_ok=True)
    if not save_asset(im, os.path.join(OUT, name)):
        return
    print("art/c4/" + name, im.size)


if __name__ == "__main__":
    GOLD = (214, 170, 60, 255)
    RED = (150, 30, 40, 255)
    placeholder("insegna_banca.png", 128, 28, RED, "BANCA CHEAP\nIL TUO FUTURO È IL NOSTRO PRESENTE.", GOLD, 8)
    placeholder("display_numeri.png", 64, 20, (16, 14, 22, 255), "ORA SERVIAMO\nIL NUMERO 4", (255, 90, 80, 255), 7)
    placeholder("distributore_numeri.png", 16, 32, (200, 60, 70, 255), "N.", GOLD, 8)
    placeholder("bancone_sportello.png", 48, 24, (120, 70, 40, 255), "SPORTELLO", GOLD, 7)
    placeholder("colonna_oro.png", 16, 40, GOLD, "", size=7)
    placeholder("terminale_conto.png", 16, 32, (60, 120, 200, 255), "€", (255, 255, 255, 255), 10, inner=(3, 4, 12, 14))
    placeholder("terminale_rapporto.png", 16, 24, (80, 80, 96, 255), "404", (120, 255, 160, 255), 6, inner=(2, 3, 13, 12))
    placeholder("archivio.png", 32, 40, (110, 96, 80, 255), "ARCHIVIO", (240, 230, 210, 255), 7)
    placeholder("quaderno.png", 10, 8, (240, 230, 120, 255))
    placeholder("lettera.png", 8, 6, (245, 245, 235, 255))
    placeholder("timbro.png", 8, 10, (190, 40, 40, 255))
    placeholder("antenna_robot.png", 8, 10, (150, 200, 230, 255))
