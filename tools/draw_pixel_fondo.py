"""Pixel art disegnata a mano (pixel per pixel) per le cose del Fondo che LimeZu non ha:
la lampadina (va nella cassetta LimeZu della scatola di Bulbo), la stellina del salvataggio
e gli occhiali smarriti. Colori presi dai fogli LimeZu (contorno blu-grigio scuro, luce dall'alto
a sinistra, ombre più fredde), così stanno insieme agli altri oggetti.

Uso:  python tools/draw_pixel_fondo.py   (scrive in art/)
"""
from pathlib import Path
from PIL import Image

ART = Path(__file__).resolve().parent.parent / "art"

# palette LimeZu (generic.png / grocery)
PAL = {
    ".": (0, 0, 0, 0),
    "O": (58, 58, 80, 255),      # contorno LimeZu
    "o": (86, 89, 114, 255),     # contorno chiaro / ombra fredda
    "W": (255, 252, 240, 255),   # riflesso
    "H": (255, 241, 207, 255),   # vetro chiaro
    "Y": (255, 229, 160, 255),   # vetro
    "S": (239, 189, 85, 255),    # vetro in ombra
    "A": (199, 140, 89, 255),    # ombra calda
    "G": (216, 221, 225, 255),   # metallo chiaro
    "M": (167, 151, 150, 255),   # metallo medio
    "B": (164, 205, 230, 255),   # lente
    "b": (120, 160, 200, 255),   # lente in ombra
}


def draw(rows: list[str]) -> Image.Image:
    w = max(len(r) for r in rows)
    im = Image.new("RGBA", (w, len(rows)))
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            im.putpixel((x, y), PAL[ch])
    return im


# La lampadina (6x9): bulbo di vetro con riflesso, collo, attacco a vite a righe.
BULB = [
    ".OOOO.",
    "OWHYYO",
    "OHYYSO",
    "OYYYSO",
    ".OYSO.",
    ".OGMO.",
    ".OMoO.",
    ".OGMO.",
    "..OO..",
]

# La stellina del salvataggio (13x13, 2 fotogrammi): la seconda brilla (riflesso e scintille).
STAR_A = [
    "......O......",
    ".....OYO.....",
    ".....OYO.....",
    "....OHYSO....",
    "OOOOOHYSOOOOO",
    ".OHHHYYYSSSO.",
    "..OHYYYYYSO..",
    "...OYYYYSO...",
    "...OYYSYSO...",
    "..OYYSOOSSO..",
    "..OYSO..OSO..",
    ".OSO.....OSO.",
    ".OO.......OO.",
]
STAR_B = [
    "W.....O.....W",
    ".....OWO.....",
    ".....OHO.....",
    "....OWHYO....",
    "OOOOOWHYOOOOO",
    ".OWWHHYYYSSO.",
    "..OWHYYYYSO..",
    "...OHYYYSO...",
    "...OYYSYSO...",
    "..OYYSOOSSO..",
    "..OYSO..OSO..",
    ".OSO.....OSO.",
    "WOO.......OOW",
]

# Gli occhiali smarriti (10x4), visti dall'alto: due lenti tonde e il ponte.
GLASSES = [
    ".OO....OO.",
    "OWBOOOOWBO",
    "OBbO..OBbO",
    ".OO....OO.",
]


def main() -> None:
    draw(BULB).save(ART / "lampadina_cassetta.png")
    star = Image.new("RGBA", (26, 13))
    star.paste(draw(STAR_A), (0, 0))
    star.paste(draw(STAR_B), (13, 0))
    star.save(ART / "save_star.png")
    draw(GLASSES).save(ART / "glasses.png")
    print("ok: lampadina_cassetta.png, save_star.png, glasses.png")


if __name__ == "__main__":
    main()
