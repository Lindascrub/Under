"""Converte i personaggi RPG Maker (XP e VX Ace) di LimeZu nel formato dei fogli del gioco.
Foglio del gioco: celle 16x32; riga 1 fermo, riga 2 camminata (6 fotogrammi per direzione,
direzioni destra, su, sinistra, giù); riga 4 seduto, 6 telefono, 7 lettura.
I personaggi RPG Maker non hanno seduto/telefono/lettura: si usa la posa ferma."""
import glob, os
from PIL import Image

SRC = 'C:/Users/linda/Documents/app/play/asset/Modern_Interiors_RPG_Maker_Version/Modern_Interiors_RPG_Maker_Version/'
OUT = 'C:/Users/linda/Documents/app/play/cheap/assets/limezu/characters/'
# righe RPG Maker: giù, sinistra, destra, su -> nell'ordine del gioco (destra, su, sinistra, giù)
GAME_DIRS = [2, 3, 1, 0]


def cell(frame):
    small = frame.resize((16, 24), Image.NEAREST)
    c = Image.new('RGBA', (16, 32))
    c.paste(small, (0, 8))
    return c


def build(frames, walk_order, name):
    """frames[riga_rpg][i] = immagine 32x48."""
    sheet = Image.new('RGBA', (896, 656))
    stand = walk_order[0]
    for d, r in enumerate(GAME_DIRS):
        for i in range(6):
            sheet.paste(cell(frames[r][stand]), ((d * 6 + i) * 16, 1 * 32))
            sheet.paste(cell(frames[r][walk_order[i]]), ((d * 6 + i) * 16, 2 * 32))
    for i in range(6):
        sheet.paste(cell(frames[2][stand]), (i * 16, 4 * 32))        # sit_right
        sheet.paste(cell(frames[1][stand]), ((6 + i) * 16, 4 * 32))  # sit_left
        sheet.paste(cell(frames[2][stand]), (i * 16, 5 * 32))
        sheet.paste(cell(frames[1][stand]), ((6 + i) * 16, 5 * 32))
        sheet.paste(cell(frames[0][stand]), ((3 + i) * 16, 6 * 32))  # phone
        sheet.paste(cell(frames[0][stand]), (i * 16, 7 * 32))        # read
    sheet.save(OUT + name + '.png')
    return name


made = []
for f in sorted(glob.glob(SRC + 'RPG_MAKER_XP/Characters/*.png')):
    base = os.path.splitext(os.path.basename(f))[0]
    if base.startswith('0_'):
        continue
    im = Image.open(f).convert('RGBA')
    frames = [[im.crop((c * 32, r * 48, c * 32 + 32, r * 48 + 48)) for c in range(4)] for r in range(4)]
    made.append(build(frames, [0, 1, 1, 2, 3, 3], 'rpg_' + base.lower()))

for k, f in enumerate(sorted(glob.glob(SRC + 'RPG_MAKER_VX_ACE (WIP)/Characters_0*.png')), 1):
    im = Image.open(f).convert('RGBA')
    for n in range(8):
        ox, oy = (n % 4) * 96, (n // 4) * 192
        frames = [[im.crop((ox + c * 32, oy + r * 48, ox + c * 32 + 32, oy + r * 48 + 48)) for c in range(3)] for r in range(4)]
        made.append(build(frames, [1, 0, 0, 1, 2, 2], 'rpg_vx%d_%d' % (k, n + 1)))

print(len(made), "fogli in", OUT)
