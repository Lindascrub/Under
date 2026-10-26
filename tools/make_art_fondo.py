"""Disegna la grafica del piano -5 (il Fondo): la cyclette-generatore, il tornello, le scale e la targa.
Esegui:  python tools/make_art_fondo.py   (scrive in art/)
"""
from PIL import Image, ImageDraw, ImageFont
import os
from asset_guard import save_asset

ROOT = os.path.join(os.path.dirname(__file__), "..")
ART = os.path.join(ROOT, "art")
OUT = (34, 28, 40, 255)        # contorno scuro, come gli asset LimeZu
METAL = (150, 156, 172, 255)
METAL_D = (98, 102, 120, 255)
METAL_L = (196, 202, 214, 255)


def save(img, name):
    if not save_asset(img, os.path.join(ART, name)):
        return
    print("art/" + name, img.size)


def generator():
    """Una cyclette arrugginita collegata con un cavo a una dinamo: pedalando si accendono le luci di sopra."""
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # ombra
    d.ellipse((3, 27, 29, 31), fill=(0, 0, 0, 70))
    # dinamo (a destra): una scatola gialla con il fulmine
    d.rectangle((21, 15, 30, 28), fill=OUT)
    d.rectangle((22, 16, 29, 27), fill=(206, 168, 58, 255))
    d.rectangle((22, 16, 29, 17), fill=(236, 204, 96, 255))
    d.line((26, 18, 24, 22), fill=OUT)
    d.line((24, 22, 27, 22), fill=OUT)
    d.line((27, 22, 25, 26), fill=OUT)
    # lucina rossa sulla dinamo
    d.point((28, 25), fill=(220, 60, 50, 255))
    # ruota grande davanti
    d.ellipse((2, 15, 14, 27), fill=OUT)
    d.ellipse((3, 16, 13, 26), fill=METAL_D)
    d.ellipse((5, 18, 11, 24), fill=OUT)
    d.ellipse((6, 19, 10, 23), fill=METAL)
    d.point((8, 21), fill=OUT)
    # telaio
    d.line((8, 21, 15, 12), fill=OUT, width=3)
    d.line((8, 21, 15, 12), fill=METAL, width=1)
    d.line((15, 12, 18, 25), fill=OUT, width=3)
    d.line((15, 12, 18, 25), fill=METAL, width=1)
    d.line((12, 26, 21, 26), fill=OUT, width=3)
    d.line((12, 26, 21, 26), fill=METAL_D, width=1)
    # manubrio
    d.line((6, 10, 10, 8), fill=OUT, width=3)
    d.line((8, 9, 8, 18), fill=OUT, width=2)
    d.line((6, 10, 10, 8), fill=METAL_L, width=1)
    # sellino
    d.rectangle((13, 9, 19, 11), fill=OUT)
    d.rectangle((14, 9, 18, 10), fill=(70, 58, 66, 255))
    # pedale
    d.line((17, 21, 20, 23), fill=OUT, width=2)
    # cavo verso la dinamo
    d.line((18, 24, 21, 20), fill=(60, 50, 50, 255))
    # ruggine
    for p in [(12, 17), (16, 16), (17, 21), (10, 25)]:
        d.point(p, fill=(156, 92, 52, 255))
    save(im, "generator.png")


def turnstile():
    """Il tornello: si apre solo con il badge del piano di sopra."""
    im = Image.new("RGBA", (16, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse((2, 28, 14, 31), fill=(0, 0, 0, 70))
    # colonnina
    d.rectangle((4, 8, 11, 29), fill=OUT)
    d.rectangle((5, 9, 10, 28), fill=METAL)
    d.rectangle((5, 9, 6, 28), fill=METAL_L)
    d.rectangle((9, 9, 10, 28), fill=METAL_D)
    # lettore di badge con la luce rossa
    d.rectangle((5, 11, 10, 15), fill=OUT)
    d.rectangle((6, 12, 9, 14), fill=(60, 60, 76, 255))
    d.rectangle((7, 12, 8, 12), fill=(232, 64, 56, 255))
    # braccio del tornello
    d.line((0, 19, 15, 19), fill=OUT, width=3)
    d.line((0, 19, 15, 19), fill=METAL_L, width=1)
    # testa
    d.rectangle((3, 6, 12, 9), fill=OUT)
    d.rectangle((4, 7, 11, 8), fill=METAL_D)
    save(im, "turnstile.png")


def stairs_up():
    """Scale che salgono dentro al muro, verso il piano di sopra (e un po' più di luce)."""
    im = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 31, 47), fill=OUT)
    steps = 8
    for i in range(steps):
        # in alto i gradini sono più chiari: lassù c'è luce
        t = i / (steps - 1)
        top = int(2 + i * 5.6)
        c = tuple(int(a + (b - a) * t) for a, b in zip((176, 170, 160), (70, 64, 72))) + (255,)
        d.rectangle((3, top, 28, top + 4), fill=c)
        d.line((3, top, 28, top), fill=tuple(min(255, v + 24) for v in c[:3]) + (255,))
    # luce che arriva da sopra
    d.rectangle((3, 0, 28, 2), fill=(236, 224, 176, 255))
    # corrimano
    d.line((1, 47, 1, 2), fill=METAL_D, width=2)
    d.line((30, 47, 30, 2), fill=METAL_D, width=2)
    save(im, "stairs_up.png")


def stairs_down():
    """Una botola con le scale che scendono nel buio."""
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 31, 31), fill=OUT)
    steps = 6
    for i in range(steps):
        t = i / (steps - 1)
        top = 2 + i * 5
        c = tuple(int(a + (b - a) * t) for a, b in zip((150, 144, 140), (24, 20, 28))) + (255,)
        d.rectangle((3, top, 28, top + 3), fill=c)
    d.rectangle((0, 0, 31, 1), fill=METAL)
    d.line((1, 2, 1, 31), fill=METAL_D, width=2)
    d.line((30, 2, 30, 31), fill=METAL_D, width=2)
    save(im, "stairs_down.png")


def plate(text, name, bg, fg):
    font = ImageFont.truetype(os.path.join(ROOT, "fonts", "PixelifySans.ttf"), 10)
    probe = Image.new("RGBA", (200, 40))
    box = ImageDraw.Draw(probe).textbbox((0, 0), text, font=font)
    w, h = box[2] - box[0], box[3] - box[1]
    im = Image.new("RGBA", (w + 10, h + 8), OUT)
    d = ImageDraw.Draw(im)
    d.rectangle((1, 1, w + 8, h + 6), fill=bg)
    d.text((5 - box[0], 4 - box[1]), text, font=font, fill=fg)
    save(im, name)


if __name__ == "__main__":
    generator()
    turnstile()
    stairs_up()
    stairs_down()
    plate("PIANO -5", "plate_piano5.png", (52, 48, 60, 255), (210, 72, 60, 255))
    plate("BADGE", "plate_badge.png", (40, 60, 52, 255), (120, 220, 150, 255))
