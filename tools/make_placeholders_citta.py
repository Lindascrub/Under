"""SEGNAPOSTO del Capitolo 5 (la Città): forme piene con un'etichetta, solo per avere le misure giuste.
La grafica vera si disegna a parte: elenco completo (misure, prospettiva, animazioni, dove si usa)
in docs/ASSET_LIST.md. Sostituendo un PNG con uno della stessa misura, il gioco non cambia.

Esegui dalla cartella del progetto:  python tools/make_placeholders_citta.py
"""
from PIL import Image, ImageDraw
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_placeholders_banca as base  # noqa: E402

ROOT = base.ROOT
base.OUT = os.path.join(ROOT, "art", "c5")


def placeholder(name, w, h, fill, text="", text_fill=(255, 255, 255, 255), size=8, inner=None):
    base.OUT = os.path.join(ROOT, "art", "c5")
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, w - 1, h - 1), fill=fill, outline=base.EDGE)
    if inner:
        d.rectangle(inner, fill=(16, 14, 22, 255))
    if text:
        base.label(d, (1, 1, w - 1, h - 1), text, size, text_fill)
    os.makedirs(base.OUT, exist_ok=True)
    if not base.save_asset(im, os.path.join(base.OUT, name)):
        return
    print("art/c5/" + name, im.size)


def sky(name, w, h):
    """Il cielo: una sfumatura vera (è l'unica cosa del capitolo che non ha un prezzo)."""
    im = Image.new("RGBA", (w, h))
    top, bottom = (92, 150, 220), (190, 222, 245)
    for y in range(h):
        t = y / max(1, h - 1)
        c = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)) + (255,)
        for x in range(w):
            im.putpixel((x, y), c)
    os.makedirs(base.OUT, exist_ok=True)
    if not base.save_asset(im, os.path.join(base.OUT, name)):
        return
    print("art/c5/" + name, im.size)


if __name__ == "__main__":
    PINK = (255, 60, 170, 255)
    CYAN = (40, 220, 230, 255)
    YELLOW = (255, 225, 77, 255)
    WHITE = (255, 255, 255, 255)
    GREY = (120, 116, 128, 255)
    DARK = (16, 14, 22, 255)
    sky("cielo.png", 640, 96)
    placeholder("insegna_esterno.png", 128, 20, (30, 30, 40, 255), "BENVENUTO ALL'ESTERNO.\nServizio soggetto a disponibilità.", WHITE, 6)
    placeholder("porta_vetro.png", 32, 32, (150, 200, 230, 255), "", inner=(4, 4, 27, 31))
    placeholder("cartellone_premium.png", 72, 40, PINK, "ANCHE IL CIELO\nHA UN LIMITE.\nSUPERALO CON PREMIUM.", YELLOW, 7)
    placeholder("altoparlante.png", 12, 10, (210, 210, 220, 255), "", inner=(3, 3, 8, 6))
    placeholder("insegna_casa_comune.png", 80, 12, (90, 140, 80, 255), "CASA COMUNE", WHITE, 8)
    placeholder("avviso_chiusura.png", 24, 16, WHITE, "CHIUSURA\nFRA 3 GG", (200, 40, 40, 255), 6)
    placeholder("volantini.png", 16, 16, (240, 230, 190, 255), "", inner=(3, 3, 7, 7))
    placeholder("insegna_comunicazioni.png", 80, 12, CYAN, "CENTRO COMUNICAZIONI", DARK, 7)
    placeholder("terminale_presentazioni.png", 16, 24, (80, 80, 96, 255), "PRO", (120, 255, 160, 255), 6, inner=(2, 3, 13, 12))
    placeholder("tabellone_bus.png", 32, 32, (40, 60, 90, 255), "BUS\n6 MIN", YELLOW, 8, inner=None)
    placeholder("vetrina_rotta.png", 32, 24, (170, 210, 230, 160), "CRACK", (60, 60, 70, 255), 7)
    placeholder("cartone.png", 32, 24, (180, 140, 90, 255), "APERTO\nLO STESSO", DARK, 6)
    placeholder("cartello_protesta.png", 20, 14, WHITE, "", inner=(2, 2, 17, 6))
    placeholder("panca_premium.png", 64, 12, PINK, "PANCA PREMIUM\nABBONAMENTO IN ARRIVO", YELLOW, 5)
    # dentro la Casa Comune
    placeholder("libreria.png", 32, 48, (140, 100, 60, 255), "LIBRI", (250, 240, 220, 255), 8)
    placeholder("tavolo_lungo.png", 48, 24, (160, 120, 80, 255), "", inner=None)
    placeholder("sedie_spaiate.png", 32, 16, (120, 160, 190, 255), "", inner=None)
    placeholder("bacheca.png", 32, 24, (180, 140, 90, 255), "BACHECA", DARK, 7)
    placeholder("lettera_cheap.png", 10, 8, PINK)
    placeholder("cartella_b4.png", 12, 8, (120, 170, 230, 255), "B-4", DARK, 5)
    placeholder("porta_archivio.png", 16, 32, (110, 80, 60, 255), "ARCH", (240, 230, 210, 255), 6)
    placeholder("terminale_bilanci.png", 16, 32, (60, 120, 200, 255), "€", WHITE, 10, inner=(3, 4, 12, 14))
    placeholder("armadio_documenti.png", 32, 40, (110, 96, 80, 255), "DOCUMENTI", (240, 230, 210, 255), 6)
    placeholder("contatore.png", 16, 24, (200, 200, 60, 255), "kWh", DARK, 6, inner=None)
    # la rivelazione del primo gradino
    placeholder("mappa_citta.png", 320, 150, (36, 40, 52, 255), "", inner=None)
    placeholder("simbolo_energia.png", 24, 24, YELLOW, "-5", DARK, 8)
    placeholder("simbolo_amministrazione.png", 24, 24, (120, 170, 230, 255), "-4", DARK, 8)
    placeholder("simbolo_commercio.png", 24, 24, (120, 210, 120, 255), "-3", DARK, 8)
    placeholder("simbolo_finanza.png", 24, 24, (214, 170, 60, 255), "-2", DARK, 8)
