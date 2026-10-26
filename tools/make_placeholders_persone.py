"""SEGNAPOSTO dei dettagli a colori delle persone vere (art/people/): l'unica cosa che il grigio non toglie.
Ogni file è 16x32, trasparente, allineato alla cornice dei personaggi LimeZu (la testa va da y 10 a y 24,
il collo è a y 24-25, i piedi in basso). Si disegna sopra il personaggio, in tutte le direzioni.
La grafica vera si disegna a parte (meglio: una versione per direzione): elenco in docs/ASSET_LIST.md.

Esegui dalla cartella del progetto:  python tools/make_placeholders_persone.py
"""
from PIL import Image, ImageDraw
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "art", "people")
EDGE = (24, 20, 30, 255)


def new():
    im = Image.new("RGBA", (16, 32), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def save(im, name):
    os.makedirs(OUT, exist_ok=True)
    im.save(os.path.join(OUT, name + ".png"))
    print("art/people/" + name + ".png", im.size)


def dome(d, col, top=6, bottom=11, x0=3, x1=12, brim=None):
    """Un cappello a cupola, con la tesa facoltativa."""
    d.rectangle((x0 + 1, top, x1 - 1, bottom), fill=col, outline=EDGE)
    d.rectangle((x0, top + 2, x1, bottom), fill=col, outline=EDGE)
    if brim:
        d.rectangle((brim[0], bottom, brim[1], bottom + 1), fill=col, outline=EDGE)


if __name__ == "__main__":
    # Fermo: berretto di lana rosso scuro, con il risvolto
    im, d = new()
    dome(d, (150, 40, 50, 255), 7, 12, 3, 12)
    d.line((3, 11, 12, 11), fill=(110, 25, 35, 255))
    save(im, "berretto")

    # Nonno Mina (id "bulbo"): casco giallo da elettricista
    im, d = new()
    dome(d, (250, 205, 40, 255), 5, 10, 3, 12, brim=(1, 14))
    d.point((7, 6), fill=(255, 245, 170, 255))
    save(im, "casco")

    # Bulbo (id "mina"): un fiocco arancione, di lato
    im, d = new()
    d.polygon([(10, 8), (13, 6), (13, 11)], fill=(255, 140, 40, 255), outline=EDGE)
    d.polygon([(10, 8), (7, 6), (7, 11)], fill=(255, 140, 40, 255), outline=EDGE)
    d.rectangle((9, 8, 11, 9), fill=(255, 190, 90, 255), outline=EDGE)
    save(im, "fiocco")

    # Tilde: una matita gialla infilata nello chignon
    im, d = new()
    d.line((5, 10, 11, 4), fill=EDGE, width=3)
    d.line((5, 10, 11, 4), fill=(250, 200, 40, 255), width=1)
    d.point((11, 4), fill=(240, 120, 140, 255))
    d.point((5, 10), fill=(60, 60, 60, 255))
    save(im, "matita")

    # Ercole: la cuffia del call center, blu
    im, d = new()
    d.arc((1, 7, 14, 22), 200, 340, fill=(40, 90, 220, 255), width=2)
    d.rectangle((0, 14, 2, 18), fill=(40, 90, 220, 255), outline=EDGE)
    d.rectangle((13, 14, 15, 18), fill=(40, 90, 220, 255), outline=EDGE)
    d.line((2, 18, 5, 21), fill=(40, 90, 220, 255))
    save(im, "cuffia")

    # Leda: bandana verde, con il nodo
    im, d = new()
    d.rectangle((2, 10, 13, 13), fill=(60, 170, 90, 255), outline=EDGE)
    d.point((5, 11), fill=(240, 240, 240, 255))
    d.point((9, 12), fill=(240, 240, 240, 255))
    d.polygon([(13, 11), (15, 9), (15, 14)], fill=(60, 170, 90, 255), outline=EDGE)
    save(im, "bandana")

    # Amir: cappellino arancione delle consegne, con la visiera
    im, d = new()
    dome(d, (255, 120, 30, 255), 7, 11, 3, 12, brim=(2, 15))
    d.point((7, 8), fill=(255, 230, 200, 255))
    save(im, "cappellino")

    # Olga: basco viola, storto
    im, d = new()
    d.ellipse((2, 6, 14, 11), fill=(140, 70, 190, 255), outline=EDGE)
    d.point((9, 5), fill=EDGE)
    save(im, "basco")

    # Teo: cappello di carta piegato da un modulo della Banca (bianco, con la riga blu)
    im, d = new()
    d.polygon([(2, 11), (8, 3), (14, 11)], fill=(245, 245, 240, 255), outline=EDGE)
    d.line((4, 10, 12, 10), fill=(60, 110, 230, 255))
    d.line((6, 8, 10, 8), fill=(60, 110, 230, 255))
    save(im, "cappello_carta")

    # Ada: cerchietto rosso
    im, d = new()
    d.arc((2, 9, 13, 18), 190, 350, fill=EDGE, width=3)
    d.arc((2, 9, 13, 18), 190, 350, fill=(220, 40, 50, 255), width=1)
    save(im, "cerchietto")

    # Nadir: sciarpa verde acqua (guarda gli uccelli: ha freddo alla fermata)
    im, d = new()
    d.rectangle((2, 23, 13, 25), fill=(40, 180, 170, 255), outline=EDGE)
    d.rectangle((10, 25, 12, 29), fill=(40, 180, 170, 255), outline=EDGE)
    save(im, "sciarpa")

    # Rina: fiore rosa fra i capelli
    im, d = new()
    for dx, dy in [(0, -2), (2, 0), (0, 2), (-2, 0)]:
        d.ellipse((11 + dx - 1, 11 + dy - 1, 11 + dx + 1, 11 + dy + 1), fill=(255, 110, 170, 255), outline=EDGE)
    d.point((11, 11), fill=(255, 230, 80, 255))
    save(im, "fiore")

    # La Presidente: una spilla d'oro sulla giacca
    im, d = new()
    d.rectangle((9, 25, 11, 27), fill=(230, 180, 40, 255), outline=EDGE)
    d.point((10, 26), fill=(255, 240, 160, 255))
    save(im, "spilla")
