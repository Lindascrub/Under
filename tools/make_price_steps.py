"""Il tabellone del Mercato alla fine del capitolo 3, quando i prezzi scappano: una striscia di
fotogrammi 112x34, uno per clic. Si parte dai prezzi nuovi e ogni scatto li moltiplica, finché le
cifre non entrano più nelle colonne. Lo usa chapters/c3/mercato_c3.gd (_price_run).
Disegnato come art/price_board_nuovo.png (tools/make_art_codex.py, price_board).
Esegui:  python tools/make_price_steps.py   (scrive art/price_board_fuga.png)
"""
import json
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import make_art_codex as codex  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
SIZE = (112, 34)
KEYS = ("pane", "latte", "acqua")


def board(values, overflow=False):
    im, d = codex.canvas(SIZE)
    w, h = SIZE
    codex.panel(d, (w, h - 2), '#253548', trim=codex.PINK)
    d.rectangle((4, 3, w - 5, 10), fill='#7c3556')
    codex.centered(d, (4, 4, w - 4, 10), 'PREZZI CHEAP', codex.CREAM)
    for i, key in enumerate(KEYS):
        x = 5 + i * 35
        if i:
            d.line((x - 3, 13, x - 3, 28), fill='#4b6072')
        codex.centered(d, (x, 12, x + 31, 17), key, codex.CREAM)
        if overflow:
            # a grandezza piena, anche se non ci sta: le cifre escono dalla colonna e dal tabellone
            value = str(values[i])
            width = codex.measure(value, 2, 1)
            codex.text(d, (x + 16 - width // 2, 20), value, '#fb9a85', 2)
        else:
            codex.centered(d, (x, 20, x + 31, 30), str(values[i]), '#fb9a85', scale=2)
    d.rectangle((9, h - 2, 11, h - 1), fill=codex.EDGE)
    d.rectangle((w - 12, h - 2, w - 10, h - 1), fill=codex.EDGE)
    return im


def save_sheet(frames, name):
    sheet = Image.new('RGBA', (SIZE[0] * len(frames), SIZE[1]), (0, 0, 0, 0))
    for n, f in enumerate(frames):
        sheet.paste(f, (n * SIZE[0], 0))
    out = ROOT / 'art' / name
    sheet.save(out)
    print(out.relative_to(ROOT), sheet.size, len(frames), 'fotogrammi')


def main():
    prices = json.loads((ROOT / 'data/market.json').read_text(encoding='utf-8'))['prezzi']
    end = [prices[k]['prezzo'][1] for k in KEYS]
    # La fine del capitolo, sulle scale: i prezzi nuovi scappano. Ogni scatto li moltiplica,
    # finché le cifre non entrano più nelle colonne e si mangiano il tabellone.
    values = list(end)
    frames = []
    while values[0] < 10 ** 8:
        frames.append(board(values, overflow=True))
        values = [int(v * 1.6) + 1 for v in values]
    save_sheet(frames, 'price_board_fuga.png')


if __name__ == '__main__':
    main()
