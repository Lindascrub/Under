"""Disegna la grafica del piano -3 (il Mercato): il distributore d'acqua, la cassa, il tabellone,
gli scaffali di Leda, la sua insegna e la lavagnetta, il terminale delle consegne, l'insegna dei saldi
e lo scontrino della rivelazione.
Esegui:  python tools/make_art_mercato.py   (scrive in art/)
"""
from PIL import Image, ImageDraw, ImageFont
import json
import os

ROOT = os.path.join(os.path.dirname(__file__), "..")
ART = os.path.join(ROOT, "art")
OUT = (34, 28, 40, 255)        # contorno scuro, come gli asset LimeZu
CHEAP_Y = (255, 214, 64, 255)  # il giallo CHEAP
CHEAP_R = (232, 52, 72, 255)
CHEAP_B = (60, 170, 255, 255)
WOOD = (176, 120, 72, 255)
WOOD_D = (122, 80, 48, 255)
WOOD_L = (210, 160, 104, 255)


def save(img, name):
    img.save(os.path.join(ART, name))
    print("art/" + name, img.size)


def font(size):
    return ImageFont.truetype(os.path.join(ROOT, "fonts", "PixelifySans.ttf"), size)


def text_center(d, box, text, size, fill):
    f = font(size)
    b = d.textbbox((0, 0), text, font=f)
    w, h = b[2] - b[0], b[3] - b[1]
    x = box[0] + (box[2] - box[0] - w) // 2 - b[0]
    y = box[1] + (box[3] - box[1] - h) // 2 - b[1]
    d.text((x, y), text, font=f, fill=fill)


def water_machine():
    """Il distributore dell'ACQUA ECONOMICA: azzurro, lucido, con le bottiglie in vetrina."""
    im = Image.new("RGBA", (16, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((0, 2, 15, 31), fill=OUT)
    d.rectangle((1, 3, 14, 30), fill=CHEAP_B)
    d.rectangle((1, 3, 14, 7), fill=(255, 255, 255, 255))
    d.line((3, 5, 12, 5), fill=CHEAP_B)
    # la vetrina con le bottiglie
    d.rectangle((2, 9, 13, 21), fill=OUT)
    d.rectangle((3, 10, 12, 20), fill=(190, 230, 255, 255))
    for x in (4, 7, 10):
        for y in (11, 16):
            d.rectangle((x, y, x + 1, y + 3), fill=(110, 190, 250, 255))
            d.point((x, y - 1), fill=(255, 255, 255, 255))
    # la fessura e il pulsante
    d.rectangle((3, 24, 9, 26), fill=OUT)
    d.rectangle((11, 23, 13, 25), fill=CHEAP_R)
    d.line((1, 29, 14, 29), fill=(40, 120, 200, 255))
    save(im, "water_machine.png")


def cassa():
    """La cassa: il nastro nero, il registratore giallo CHEAP con lo schermo verde."""
    im = Image.new("RGBA", (32, 24), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # il bancone
    d.rectangle((0, 8, 31, 23), fill=OUT)
    d.rectangle((1, 9, 30, 22), fill=(220, 224, 232, 255))
    d.rectangle((1, 18, 30, 22), fill=(180, 186, 200, 255))
    # il nastro
    d.rectangle((2, 10, 19, 14), fill=(40, 40, 48, 255))
    for x in range(3, 19, 3):
        d.point((x, 12), fill=(90, 90, 100, 255))
    # il registratore
    d.rectangle((20, 1, 30, 14), fill=OUT)
    d.rectangle((21, 2, 29, 13), fill=CHEAP_Y)
    d.rectangle((22, 3, 28, 6), fill=(40, 200, 120, 255))
    for x in (22, 25, 28):
        for y in (8, 11):
            d.point((x, y), fill=OUT)
    save(im, "cassa.png")


def price_board(which, name):
    """Il tabellone dei prezzi: nero, con la cornice al neon. Due versioni, prima e dopo
    l'aggiornamento: i prezzi vengono da data/market.json (which = 0 prima, 1 dopo)."""
    prices = json.load(open(os.path.join(ROOT, "data", "market.json"), encoding="utf-8"))["prezzi"]
    w, h = 112, 34
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, w - 1, h - 3), fill=OUT)
    d.rectangle((1, 1, w - 2, h - 4), fill=CHEAP_R)
    d.rectangle((3, 3, w - 4, h - 6), fill=(16, 14, 22, 255))
    for x in range(4, w - 4, 4):
        d.point((x, 2), fill=CHEAP_Y)
        d.point((x, h - 5), fill=CHEAP_Y)
    rows = ["PANE %d  LATTE %d" % (prices["pane"]["prezzo"][which], prices["latte"]["prezzo"][which]),
            "ACQUA %d EURO" % prices["acqua"]["prezzo"][which]]
    col = CHEAP_Y if which == 0 else (255, 120, 110, 255)
    text_center(d, (3, 4, w - 3, 15), rows[0], 10, col)
    text_center(d, (3, 15, w - 3, 26), rows[1], 10, col)
    # i due pali
    d.rectangle((10, h - 3, 11, h - 1), fill=OUT)
    d.rectangle((w - 12, h - 3, w - 11, h - 1), fill=OUT)
    save(im, name)


def shelf():
    """Lo scaffale di Leda: legno, con la merce un po' in disordine."""
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 31, 31), fill=OUT)
    d.rectangle((1, 1, 30, 30), fill=WOOD)
    goods = [(240, 200, 120, 255), (200, 80, 70, 255), (120, 180, 90, 255), (250, 250, 240, 255), (150, 110, 200, 255)]
    for row, y in enumerate((2, 12, 22)):
        d.rectangle((2, y, 29, y + 7), fill=WOOD_D)
        d.line((1, y + 8, 30, y + 8), fill=WOOD_L)
        x = 3
        k = row
        while x < 28:
            w = 3 + (k % 3)
            h = 4 + (k % 2) * 2
            d.rectangle((x, y + 7 - h, x + w - 1, y + 6), fill=goods[k % len(goods)])
            x += w + 1
            k += 2
    save(im, "shelf.png")


def sign_leda():
    """L'insegna scritta a mano: DA LEDA."""
    im = Image.new("RGBA", (52, 14), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 51, 13), fill=OUT)
    d.rectangle((1, 1, 50, 12), fill=(244, 232, 200, 255))
    text_center(d, (1, 1, 51, 13), "DA LEDA", 10, (70, 110, 70, 255))
    save(im, "sign_leda.png")


def chalkboard():
    """La lavagnetta dei conti di Leda."""
    im = Image.new("RGBA", (16, 20), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 15, 15), fill=WOOD_D)
    d.rectangle((1, 1, 14, 14), fill=(46, 64, 54, 255))
    for y in (3, 6, 9):
        d.line((3, y, 11 - (y % 2) * 2, y), fill=(220, 220, 210, 255))
    d.line((3, 12, 7, 12), fill=(250, 210, 120, 255))
    d.line((3, 15, 1, 19), fill=WOOD_D)
    d.line((12, 15, 14, 19), fill=WOOD_D)
    save(im, "chalkboard.png")


def terminal_consegne():
    """Il terminale delle consegne di Amir: arancione CHEAP, schermo con il contatore."""
    im = Image.new("RGBA", (16, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((2, 4, 13, 31), fill=OUT)
    d.rectangle((3, 5, 12, 30), fill=(250, 140, 50, 255))
    d.rectangle((4, 7, 11, 14), fill=OUT)
    d.rectangle((5, 8, 10, 13), fill=(40, 200, 120, 255))
    d.line((6, 10, 9, 10), fill=OUT)
    d.line((6, 12, 8, 12), fill=OUT)
    d.rectangle((5, 18, 10, 20), fill=(255, 230, 150, 255))
    d.rectangle((4, 27, 11, 30), fill=(200, 100, 30, 255))
    save(im, "terminal_consegne.png")


def sign_saldi():
    """L'insegna dei saldi, coll'asterisco."""
    text = "OGGI TUTTO AL 50%*"
    b = ImageDraw.Draw(Image.new("RGBA", (1, 1))).textbbox((0, 0), text, font=font(10))
    w = b[2] - b[0] + 10
    im = Image.new("RGBA", (w, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, w - 1, 15), fill=OUT)
    d.rectangle((1, 1, w - 2, 14), fill=CHEAP_R)
    text_center(d, (1, 1, w - 1, 15), text, 10, CHEAP_Y)
    save(im, "sign_saldi.png")


def crates():
    """Le cassette di legno su cui si siedono Leda e Amir (la scena segreta)."""
    im = Image.new("RGBA", (16, 12), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 15, 11), fill=OUT)
    d.rectangle((1, 1, 14, 10), fill=WOOD)
    d.line((1, 4, 14, 4), fill=WOOD_D)
    d.line((1, 7, 14, 7), fill=WOOD_D)
    d.line((1, 1, 14, 1), fill=WOOD_L)
    save(im, "crate.png")


if __name__ == "__main__":
    water_machine()
    cassa()
    price_board(0, "price_board.png")
    price_board(1, "price_board_nuovo.png")
    shelf()
    sign_leda()
    chalkboard()
    terminal_consegne()
    sign_saldi()
    crates()
