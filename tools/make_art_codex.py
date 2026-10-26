"""CHEAP native pixel UI artwork, micro-sprites and export of ImageGen props.

The purchased assets directory is never written. All output is staged by default.
Usage: python tools/make_art_codex.py --out PATH --generated SOURCES.json
ImageGen objects are mechanically exported to their original sprite canvases.
Texts, icons, diagrams and tiny animation frames remain editable native drawings.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageColor, ImageFont
import argparse, hashlib, json, math, random, unicodedata

ROOT = Path(__file__).resolve().parents[1]
EDGE = '#18141e'
INK = '#263244'
CREAM = '#fff1cf'
GOLD = '#efbd55'
GOLD_L = '#ffe5a0'
GOLD_D = '#a36b3f'
TEAL = '#387d83'
PINK = '#e54d86'
RED = '#bf3e55'
WOOD = '#aa7151'
WOOD_L = '#dca26a'
WOOD_D = '#654452'
METAL = '#8c9bab'
LIGHT = '#d3e0df'

FONT = {
'A':['010','101','111','101','101'], 'B':['110','101','110','101','110'],
'C':['011','100','100','100','011'], 'D':['110','101','101','101','110'],
'E':['111','100','110','100','111'], 'F':['111','100','110','100','100'],
'G':['011','100','101','101','011'], 'H':['101','101','111','101','101'],
'I':['1','1','1','1','1'], 'J':['001','001','001','101','010'],
'K':['101','101','110','101','101'], 'L':['100','100','100','100','111'],
'M':['10001','11011','10101','10001','10001'], 'N':['1001','1101','1011','1001','1001'],
'O':['010','101','101','101','010'], 'P':['110','101','110','100','100'],
'Q':['010','101','101','111','011'], 'R':['110','101','110','101','101'],
'S':['011','100','010','001','110'], 'T':['111','010','010','010','010'],
'U':['101','101','101','101','111'], 'V':['101','101','101','101','010'],
'W':['10101','10101','10101','10101','01010'], 'X':['101','101','010','101','101'],
'Y':['101','101','010','010','010'], 'Z':['111','001','010','100','111'],
'0':['111','101','101','101','111'], '1':['010','110','010','010','111'],
'2':['110','001','010','100','111'], '3':['110','001','010','001','110'],
'4':['101','101','111','001','001'], '5':['111','100','110','001','110'],
'6':['011','100','111','101','111'], '7':['111','001','010','010','010'],
'8':['111','101','111','101','111'], '9':['111','101','111','001','110'],
' ':['00']*5, '.':['0','0','0','0','1'], ',':['0','0','0','1','1'],
':':['0','1','0','1','0'], '-':['000','000','111','000','000'],
'!':['1','1','1','0','1'], '?':['110','001','010','000','010'],
"'":['1','1','0','0','0'], '/':['001','001','010','100','100'],
'%':['101','001','010','100','101'], '*':['000','101','010','101','000'],
'+':['000','010','111','010','000'], '€':['011','110','100','110','011'],
}

def norm(s):
    return ''.join(c for c in unicodedata.normalize('NFD', s.upper()) if not unicodedata.combining(c))

def measure(s, scale=1, gap=1):
    return sum(len(FONT.get(c,FONT['?'])[0])*scale+gap for c in norm(s))-gap

def text(d, pos, s, color=CREAM, scale=1, gap=1):
    x,y=map(int,pos)
    for c in norm(s):
        glyph=FONT.get(c,FONT['?'])
        for gy,line in enumerate(glyph):
            for gx,v in enumerate(line):
                if v=='1':
                    d.rectangle((x+gx*scale,y+gy*scale,x+(gx+1)*scale-1,y+(gy+1)*scale-1),fill=color)
        x+=len(glyph[0])*scale+gap

def centered(d, box, lines, color=CREAM, scale=1, leading=2, gap=1):
    if isinstance(lines,str): lines=lines.split('\n')
    x0,y0,x1,y1=map(int,box)
    while scale>1 and (max(map(lambda s:measure(s,scale,gap),lines))>x1-x0 or len(lines)*(5*scale+leading)-leading>y1-y0):
        scale-=1
    if any(measure(s,scale,gap)>x1-x0 for s in lines): gap=0
    total=len(lines)*(5*scale+leading)-leading
    y=y0+(y1-y0-total)//2
    for s in lines:
        width=measure(s,scale,gap)
        if width>x1-x0:
            raise ValueError(f'Text does not fit: {s!r} in {box}')
        text(d,(x0+(x1-x0-width)//2,y),s,color,scale,gap)
        y+=5*scale+leading

def tiny_type(d,box,lines,color=CREAM,max_size=6,leading=1):
    """Use the game's original pixel typeface for very dense small sign copy."""
    if isinstance(lines,str):lines=[lines]
    x0,y0,x1,y1=box
    oldmode=d.fontmode;d.fontmode='1'
    chosen=None
    for point in range(max_size,3,-1):
        f=ImageFont.truetype(str(ROOT/'fonts/PixelifySans.ttf'),point)
        boxes=[d.textbbox((0,0),s,font=f) for s in lines]
        total=sum(b[3]-b[1] for b in boxes)+leading*(len(lines)-1)
        if max(b[2]-b[0] for b in boxes)<=x1-x0 and total<=y1-y0:
            chosen=(f,boxes,total);break
    if chosen is None:raise ValueError('Small text cannot fit: '+str(lines))
    f,boxes,total=chosen;y=y0+(y1-y0-total)//2
    for s,b in zip(lines,boxes):
        d.text((x0+(x1-x0-(b[2]-b[0]))//2-b[0],y-b[1]),s,font=f,fill=color)
        y+=b[3]-b[1]+leading
    d.fontmode=oldmode

def canvas(size):
    im=Image.new('RGBA',size,(0,0,0,0)); return im,ImageDraw.Draw(im)

def panel(d,size,base='#293c50',edge=EDGE,trim=GOLD,bolts=True):
    w,h=size
    d.rectangle((0,1,w-1,h-2),fill=edge)
    d.rectangle((1,0,w-2,h-1),fill=edge)
    d.rectangle((1,2,w-2,h-3),fill=base)
    d.line((2,1,w-3,1),fill=trim)
    d.line((1,2,1,h-3),fill=trim)
    d.line((2,h-2,w-3,h-2),fill='#101821')
    d.line((w-2,2,w-2,h-3),fill='#172231')
    if bolts and w>=24 and h>=12:
        for x in (3,w-4):
            for y in (3,h-4):
                d.point((x,y),fill=LIGHT)

def envelope(size,pink=False):
    im,d=canvas(size);w,h=size
    d.rectangle((0,1,w-1,h-1),fill=EDGE)
    d.rectangle((1,1,w-2,h-2),fill='#e98eab' if pink else CREAM)
    d.line((1,1,w//2,h//2,w-2,1),fill=PINK if pink else '#b9ac93',width=1)
    d.line((1,h-2,w//2,h//2,w-2,h-2),fill='#b9ac93')
    d.point((w-3,2),fill=RED)
    return im

def folder(size,pink=False,label=None):
    im,d=canvas(size);w,h=size
    d.rectangle((1,0,w//2,2),fill=EDGE)
    d.rectangle((2,1,w//2-1,2),fill=PINK if pink else '#78b4c4')
    d.rectangle((0,2,w-1,h-1),fill=EDGE)
    d.rectangle((1,3,w-2,h-2),fill='#d9779f' if pink else '#9cc8d0')
    d.line((1,3,w-2,3),fill='#f4bdd1' if pink else '#d9f2ed')
    if label:
        centered(d,(1,2,w-1,h),label,INK,gap=0)
    else:
        d.line((3,4,w-4,4),fill=CREAM)
    return im

def tiny_speaker(size):
    im,d=canvas(size);w,h=size
    d.polygon([(1,2),(7,1),(w-2,2),(w-2,h-2),(7,h-1),(1,h-2)],fill=EDGE)
    d.rectangle((2,3,7,h-3),fill=METAL)
    d.polygon([(8,2),(w-3,3),(w-3,h-3),(8,h-2)],fill='#5c6b7f')
    for y in range(3,h-2,2): d.line((3,y,6,y),fill=EDGE)
    d.line((2,2,7,2),fill=LIGHT)
    return im

def signs(name,size):
    im,d=canvas(size);w,h=size
    styles={
        'billboard_ad.png':('#e7bd4c',INK,['CHEAP','SORRIDI!']),
        'board_jobs.png':('#3e5757',CREAM,['LISTA DEI LAVORI','PEGGIORI DEL MONDO']),
        'cheap_sign.png':('#252937',GOLD_L,['CHEAP S.P.A.']),
        'plate_badge.png':('#315c53','#bcdfaf',['BADGE']),
        'plate_piano5.png':('#353340','#e77d70',['PIANO -5']),
        'poster_attesa.png':('#c64f7c',CREAM,['RESTI','IN LINEA!']),
        'poster_modulo.png':('#85b9c6',INK,['UN MODULO','AL GIORNO','TOGLIE','IL PENSIERO']),
        'poster_rest.png':('#b43650',CREAM,['IL RIPOSO',"E' UN FURTO"]),
        'poster_smile.png':('#ebc55b',INK,['SORRIDI!','TI OSSERVIAMO']),
        'poster_sorridi.png':('#e8c552',RED,['SORRIDI',"E' GRATIS"]),
        'sign_asta.png':('#92374d',GOLD_L,['ASTA']),
        'sign_banca.png':('#252937',GOLD,['BANCA FIDUCIA']),
        'sign_collocamento.png':('#2c4355',CREAM,['COLLOCAMENTO']),
        'sign_leda.png':('#e2d2a2','#416c53',['DA LEDA']),
        'sign_occupata.png':('#a8394d',CREAM,['BANCA OCCUPATA']),
        'sign_razioni.png':('#55586b',CREAM,['RAZIONI']),
        'sign_saldi.png':('#be3458',GOLD_L,['OGGI TUTTO AL 50%*']),
        'sign_scambi.png':('#3c7259',CREAM,['SI SCAMBIA','NON SI VENDE']),
        'sign_vietato.png':('#eadbb7',RED,['VIETATO']),
        'c4/insegna_banca.png':('#793348',GOLD_L,['BANCA CHEAP',"IL TUO FUTURO E'",'IL NOSTRO PRESENTE.']),
        'c5/insegna_esterno.png':('#2b4051',CREAM,["BENVENUTO ALL'ESTERNO.",'SERVIZIO SOGGETTO A','DISPONIBILITA.']),
        'c5/insegna_casa_comune.png':('#527766',CREAM,['CASA COMUNE']),
        'c5/insegna_comunicazioni.png':('#67bdc8',INK,['CENTRO COMUNICAZIONI']),
        'c5/panca_premium.png':('#be4f84',GOLD_L,['PANCA PREMIUM','ABBONAMENTO IN ARRIVO']),
        'c6/insegna_ascensore.png':('#ae8048',CREAM,['NON DEVI PIU SALIRE.','SEI ARRIVATO.']),
        'c6/timbro_annullato.png':('#aa334c',CREAM,['DEBITO ANNULLATO'])
    }
    if name not in styles: return None
    bg,fg,lines=styles[name]
    panel(d,size,bg,trim=GOLD_L if 'c6/' in name or 'banca' in name else '#d9d5b9',bolts=not name.startswith('poster'))
    inset=4 if w>=50 else 2
    box=(inset,3,w-inset,h-3)
    leading=2
    if h<=12:
        box=(1,1,w-1,h-1)
        leading=0
    if name=='c5/insegna_esterno.png':
        box=(3,1,w-3,h-1)
        leading=1
    if name=='poster_sorridi.png':
        d.ellipse((w//2-5,3,w//2+5,12),fill=GOLD_L)
        d.point((w//2-2,6),fill=RED);d.point((w//2+2,6),fill=RED)
        d.line((w//2-2,9,w//2,10,w//2+2,9),fill=RED)
        box=(3,14,w-3,h-2)
    if name=='billboard_ad.png':
        # A tiny cheerful corporate sun, balanced with the headline.
        d.ellipse((4,6,18,20),fill=GOLD_L,outline=GOLD_D)
        d.point((8,11),fill=INK);d.point((13,11),fill=INK)
        d.line((8,15,10,16,13,15),fill=RED)
        box=(22,3,w-3,h-3)
    if h<=12:
        tiny_type(d,(2,1,w-2,h-1),lines,fg,max_size=6)
    elif name=='c4/insegna_banca.png':
        centered(d,(4,3,w-4,13),lines[0],fg,scale=2)
        centered(d,(4,15,w-4,h-2),lines[1:],fg,leading=1)
    elif name=='c6/timbro_annullato.png':
        d.rectangle((3,3,w-4,h-4),outline=CREAM)
        tiny_type(d,(5,4,w-5,h-4),lines,fg,max_size=12)
        for x,y in [(6,5),(w-9,6),(10,h-5),(w-16,h-6)]: d.point((x,y),fill=bg)
    else:
        tiny_type(d,box,lines,fg,max_size=12,leading=leading)
    return im

def price_board(size,which):
    im,d=canvas(size);w,h=size
    panel(d,(w,h-2),'#253548',trim=PINK)
    d.rectangle((4,3,w-5,10),fill='#7c3556')
    centered(d,(4,4,w-4,10),'PREZZI CHEAP',CREAM)
    prices=json.loads((ROOT/'data/market.json').read_text(encoding='utf-8'))['prezzi']
    for i,key in enumerate(('pane','latte','acqua')):
        x=5+i*35
        if i: d.line((x-3,13,x-3,28),fill='#4b6072')
        centered(d,(x,12,x+31,17),key,CREAM)
        value=str(prices[key]['prezzo'][which])
        centered(d,(x,20,x+31,30),value,'#fb9a85' if which else GOLD_L,scale=2)
    d.rectangle((9,h-2,11,h-1),fill=EDGE);d.rectangle((w-12,h-2,w-10,h-1),fill=EDGE)
    return im

def queue_display(size):
    im,d=canvas(size);w,h=size
    panel(d,size,'#2b394a',trim=METAL)
    d.rectangle((4,4,w-5,h-5),fill='#171d2c')
    centered(d,(5,4,w-19,10),'ORA SERVIAMO','#a3b7bf',gap=0)
    centered(d,(5,11,w-19,17),'IL NUMERO',CREAM)
    text(d,(w-15,5),'4','#f18a79',2)
    return im

def poster_premium(size):
    im,d=canvas(size);w,h=size
    panel(d,size,'#cf548a',trim='#ffc780')
    # Stylized false sky and a glossy corporate sun behind deliberately crisp type.
    d.rectangle((3,3,w-4,12),fill='#79cfdb')
    d.ellipse((w-19,3,w-7,15),fill=GOLD_L)
    d.rectangle((4,10,24,12),fill='#d6f4e9')
    centered(d,(4,12,w-4,h-3),['ANCHE IL CIELO','HA UN LIMITE.','SUPERALO CON','PREMIUM.'],CREAM,leading=1)
    for x in range(3,w-3,6): d.point((x,h-2),fill=GOLD_L)
    return im

def closure(size):
    im,d=canvas(size);w,h=size
    d.polygon([(1,0),(w-4,0),(w-1,3),(w-1,h-1),(0,h-1),(0,1)],fill=EDGE)
    d.polygon([(2,1),(w-5,1),(w-2,4),(w-2,h-2),(1,h-2),(1,2)],fill=CREAM)
    d.rectangle((w-5,1,w-3,3),fill='#c4b99e')
    tiny_type(d,(1,2,w-1,7),'CHIUSURA',RED,max_size=4)
    d.line((3,8,w-4,8),fill='#d9c9b1')
    tiny_type(d,(1,9,w-1,h-2),'FRA 3 GG',INK,max_size=6)
    return im

def leaflets(size):
    im,d=canvas(size)
    for x,y,bg in [(1,3,'#e3ccb1'),(5,1,CREAM),(3,6,'#b3d3cc')]:
        d.rectangle((x,y,x+9,y+8),fill=EDGE)
        d.rectangle((x+1,y+1,x+8,y+7),fill=bg)
        d.line((x+2,y+2,x+6,y+2),fill=RED)
        for yy in (4,6): d.line((x+2,y+yy,x+7,y+yy),fill='#6b7579')
    return im

def protest_sign(size):
    im,d=canvas(size);w,h=size
    d.rectangle((0,0,w-1,h-2),fill=EDGE)
    d.rectangle((1,1,w-2,h-3),fill=CREAM)
    d.line((2,2,w-3,2),fill='#ead9b7')
    d.rectangle((w//2-1,h-2,w//2,h-1),fill=WOOD)
    # Keep the centre blank: the scene draws the actual slogans on top.
    return im

def cardboard(size):
    im,d=canvas(size);w,h=size
    d.polygon([(0,2),(w-3,0),(w-1,h-3),(2,h-1)],fill=EDGE)
    d.polygon([(1,3),(w-4,1),(w-2,h-4),(3,h-2)],fill='#bd9364')
    for y in range(4,h-3,4): d.line((3,y,w-4,y),fill='#a37b55')
    d.rectangle((2,1,6,5),fill='#e6c797'); d.rectangle((w-7,h-6,w-3,h-2),fill='#e6c797')
    centered(d,(3,5,w-3,h-4),['APERTO','LO STESSO'],INK,leading=2)
    return im

def door(size,glass=False):
    im,d=canvas(size);w,h=size
    d.rectangle((1,0,w-2,h-1),fill=EDGE)
    d.rectangle((2,1,w-3,h-2),fill=METAL if glass else WOOD_D)
    if glass:
        d.rectangle((4,3,w-5,h-3),fill=(118,183,204,150))
        d.line((5,5,w-9,h-8),fill=(210,239,237,190),width=2)
        d.line((10,4,w-5,h-14),fill=(210,239,237,100))
        d.rectangle((w//2-1,2,w//2,h-2),fill=METAL)
        d.line((w//2-3,h//2,w//2-3,h//2+5),fill=LIGHT)
        d.line((w//2+3,h//2,w//2+3,h//2+5),fill=LIGHT)
    else:
        d.rectangle((3,3,w-4,h-3),fill=WOOD)
        d.rectangle((4,4,w-5,h//2-1),fill=WOOD_D)
        d.rectangle((4,h//2+2,w-5,h-5),outline=WOOD_D)
        d.rectangle((5,5,w-6,h//2-2),fill='#978766')
        d.rectangle((w-5,h//2+2,w-4,h//2+3),fill=GOLD_L)
        d.point((2,7),fill=LIGHT);d.point((2,h-8),fill=LIGHT)
    d.line((1,h-1,w-2,h-1),fill='#505667')
    return im

def cone(size):
    im,d=canvas(size)
    d.polygon([(1,12),(7,9),(14,12),(14,14),(1,14)],fill=EDGE)
    d.polygon([(3,12),(7,1),(9,1),(12,12)],fill=EDGE)
    d.polygon([(4,11),(7,2),(8,2),(11,11)],fill='#ed9655')
    d.polygon([(6,5),(9,5),(10,7),(5,7)],fill=CREAM)
    d.line((4,12,12,12),fill='#ba5b46')
    d.point((7,3),fill='#ffd0a0')
    return im

def crate(size):
    im,d=canvas(size);w,h=size
    d.polygon([(0,3),(3,0),(w-1,0),(w-1,h-2),(w-4,h-1),(0,h-1)],fill=EDGE)
    d.polygon([(2,3),(4,1),(w-3,1),(w-5,3)],fill=WOOD_L)
    d.rectangle((1,4,w-5,h-2),fill=WOOD)
    d.polygon([(w-4,4),(w-2,2),(w-2,h-3),(w-4,h-2)],fill=WOOD_D)
    for y in (5,8): d.line((2,y,w-6,y),fill=WOOD_D)
    d.rectangle((3,2,8,2),fill=EDGE)
    for x in (2,w-6):
        for y in (4,h-3): d.point((x,y),fill=GOLD_L)
    return im

def bulbs(size):
    im,d=canvas(size)
    for frame in range(3):
        x=frame*10
        d.ellipse((x+2,0,x+7,5),fill=EDGE)
        d.ellipse((x+3,1,x+6,4),fill='#617080' if frame==1 else GOLD_L)
        d.rectangle((x+4,5,x+5,7),fill=METAL)
        d.point((x+4,8),fill=EDGE)
        if frame!=1: d.point((x+3,2),fill=CREAM)
        else: d.line((x+3,2,x+6,4),fill=EDGE)
    return im

def antenna(size):
    im,d=canvas(size)
    d.rectangle((2,7,5,9),fill=EDGE)
    d.line((4,3,4,7),fill=METAL)
    d.ellipse((2,0,6,4),fill=EDGE)
    d.rectangle((3,1,5,3),fill=RED)
    d.point((3,1),fill='#ffb599')
    return im

def rubber_stamp(size):
    im,d=canvas(size)
    d.rectangle((2,0,5,4),fill=EDGE)
    d.rectangle((3,1,4,3),fill='#cb6a72')
    d.rectangle((1,5,6,7),fill=METAL)
    d.rectangle((0,8,7,9),fill=EDGE)
    d.line((1,8,6,8),fill=RED)
    return im

def glasses(size):
    im,d=canvas(size)
    d.rectangle((0,1,3,4),outline=EDGE);d.rectangle((6,1,9,4),outline=EDGE)
    d.point((1,2),fill='#b9e5e8');d.point((7,2),fill='#b9e5e8')
    d.line((3,2,6,2),fill=METAL)
    return im

def telephone(size):
    im,d=canvas(size);w,h=size
    d.rectangle((2,2,w-3,h-1),fill=EDGE)
    d.rectangle((3,3,w-4,h-2),fill=RED)
    d.rectangle((0,0,w-1,3),fill=EDGE)
    d.rectangle((1,1,3,3),fill='#e28786');d.rectangle((w-4,1,w-2,3),fill='#e28786')
    d.line((3,1,w-4,1),fill=RED)
    for x in (4,6,8):
        if x<w-3:d.point((x,5),fill=CREAM)
    return im

def star_sheet(size):
    im,d=canvas(size)
    shape=[(6,0),(8,4),(12,5),(9,8),(10,12),(6,10),(2,12),(3,8),(0,5),(4,4)]
    for frame in range(2):
        dx=frame*13
        d.polygon([(x+dx,y) for x,y in shape],fill='#a47545')
        inner=[(6,1),(7,5),(11,5),(8,8),(9,10),(6,9),(3,10),(4,7),(1,5),(5,5)]
        d.polygon([(x+dx,y) for x,y in inner],fill=GOLD if frame else GOLD_L)
        d.line((dx+6,3,dx+6,7),fill=CREAM)
        d.line((dx+4,5,dx+8,5),fill=CREAM)
        d.point((dx+(11 if frame else 1),1),fill=CREAM)
    return im

def emote_sheet(size):
    im,d=canvas(size)
    for i in range(4):
        x=i*11
        d.polygon([(x,0),(x+9,0),(x+9,6),(x+5,6),(x+3,9),(x+3,6),(x,6)],fill=EDGE)
        d.rectangle((x+1,1,x+8,5),fill=CREAM)
    for x in (2,4,6):d.point((x,3),fill=INK)
    d.line((15,1,15,3),fill=RED);d.point((15,5),fill=RED)
    d.line((27,1,27,4),fill=TEAL);d.point((26,5),fill=TEAL)
    d.point((28,1),fill=TEAL)
    d.polygon([(35,2),(36,1),(38,2),(39,1),(40,2),(40,3),(37,5),(35,3)],fill=RED)
    return im

def pigeon_sheet(size):
    im,d=canvas(size)
    for i in range(2):
        x=i*10; head_y=2 if i else 0
        d.polygon([(x,4),(x+3,2),(x+6,3),(x+7,5),(x+6,6),(x+2,6)],fill=EDGE)
        d.polygon([(x+1,4),(x+3,3),(x+6,4),(x+5,5),(x+2,5)],fill='#aab8c8')
        d.rectangle((x+6,head_y,x+8,head_y+3),fill='#7f8da6')
        d.point((x+8,head_y),fill=EDGE);d.point((x+9,head_y+2),fill=GOLD)
        d.point((x+6,head_y+3),fill='#70aaa3')
        d.point((x+3,7),fill='#c77b65');d.point((x+6,7),fill='#c77b65')
    return im

def sugar(size):
    im,d=canvas(size);w,h=size
    d.rectangle((0,0,w-1,h-1),fill='#c3bcad')
    d.rectangle((1,1,w-2,h-2),fill=CREAM)
    d.point((2,1),fill=PINK)
    return im

def bulb(size):
    im,d=canvas(size)
    d.ellipse((1,0,6,6),fill=EDGE)
    d.ellipse((2,1,5,5),fill=GOLD_L)
    d.point((2,2),fill=CREAM)
    d.rectangle((3,6,4,8),fill=METAL)
    d.line((2,7,5,7),fill=EDGE)
    d.line((3,9,4,9),fill=EDGE)
    return im

def notebook(size):
    im,d=canvas(size);w,h=size
    d.rectangle((0,0,w-2,h-2),fill=EDGE)
    d.rectangle((1,1,w-3,h-3),fill=GOLD)
    d.rectangle((2,2,w-4,h-4),fill=CREAM)
    d.line((1,h-1,w-1,h-1),fill='#c4b99d')
    d.line((0,0,0,h-2),fill=RED)
    d.point((3,3),fill=TEAL);d.point((6,3),fill=RED)
    return im

def turnstile(size):
    im,d=canvas(size)
    d.polygon([(2,28),(12,28),(14,30),(12,31),(2,31),(1,30)],fill=EDGE)
    d.line((3,29,11,29),fill='#647085')
    d.rectangle((4,9,11,28),fill=EDGE)
    d.rectangle((5,10,10,27),fill='#8c9bac')
    d.line((5,10,5,27),fill='#d1dfde')
    d.line((10,10,10,27),fill='#546176')
    d.polygon([(3,6),(11,6),(13,8),(11,10),(3,10)],fill=EDGE)
    d.line((4,7,10,7),fill=LIGHT)
    d.rectangle((4,8,11,9),fill=METAL)
    d.rectangle((6,12,10,16),fill=EDGE)
    d.line((7,13,9,13),fill='#ed6d6d')
    d.point((9,15),fill='#bbd4cb')
    d.line((0,19,15,19),fill=EDGE,width=3)
    d.line((0,18,15,18),fill=LIGHT)
    d.line((7,20,12,24),fill=EDGE,width=3)
    d.line((7,20,12,24),fill=METAL)
    d.point((8,19),fill=CREAM)
    return im

def bulb_crate(size):
    im,d=canvas(size)
    d.polygon([(0,11),(5,7),(26,7),(31,11),(31,22),(28,23),(2,23),(0,21)],fill=EDGE)
    d.polygon([(2,11),(6,8),(25,8),(29,11),(26,14),(4,14)],fill='#876044')
    for x,y,broken in [(7,4,False),(17,0,False),(25,5,False),(13,8,True)]:
        d.ellipse((x-3,y,x+3,y+6),fill=EDGE)
        d.ellipse((x-2,y+1,x+2,y+5),fill='#657080' if broken else GOLD_L)
        if not broken:d.point((x-1,y+2),fill=CREAM)
        else:d.line((x-1,y+2,x+1,y+4),fill=EDGE)
        d.rectangle((x-1,y+6,x+1,y+8),fill=METAL)
    d.polygon([(1,12),(4,15),(28,15),(30,12),(30,21),(28,22),(2,22),(1,20)],fill='#b48053')
    d.line((2,14,29,14),fill='#edbd7c')
    d.line((28,15,28,21),fill='#7a4f42')
    d.rectangle((16,15,19,22),fill='#dfc18d')
    d.line((3,20,11,20),fill='#875a43')
    d.point((4,17),fill=WOOD_L)
    return im

def park_sign(size):
    im,d=canvas(size);w,h=size
    d.rectangle((w//2-2,h//2,w//2+1,h-1),fill=EDGE)
    d.line((w//2-1,h//2,w//2-1,h-1),fill=WOOD_L)
    panel(d,(w,16),'#426e57',trim='#a4c390')
    centered(d,(3,3,w-3,13),'PARCO',CREAM,scale=2)
    return im

def sector_icon(size,which):
    im,d=canvas(size);w,h=size
    colors=[GOLD,'#8eb5d0','#86bc99','#d2a35d']
    d.rounded_rectangle((1,1,w-2,h-2),radius=4,fill=EDGE)
    d.rounded_rectangle((2,2,w-3,h-4),radius=3,fill=colors[which])
    d.line((5,3,w-6,3),fill=CREAM)
    if which==0:
        d.polygon([(13,5),(7,13),(11,13),(9,19),(17,10),(13,10),(16,5)],fill=INK)
    elif which==1:
        d.rectangle((7,5,16,17),fill=INK)
        d.rectangle((8,6,15,16),fill=CREAM)
        for y in (8,11,14):d.line((10,y,14,y),fill=TEAL)
    elif which==2:
        d.rectangle((6,10,17,17),fill=INK)
        for x in (6,10,14):d.rectangle((x,7,x+2,10),fill=RED)
        d.rectangle((6,6,17,7),fill=CREAM)
        d.rectangle((8,12,10,15),fill=CREAM);d.rectangle((13,12,15,17),fill=WOOD)
    else:
        d.polygon([(5,9),(12,5),(19,9)],fill=INK)
        for x in (7,11,15):d.rectangle((x,10,x+1,16),fill=INK)
        d.rectangle((5,17,18,18),fill=INK)
    return im

def sky(size):
    im,d=canvas(size);w,h=size
    a,b=(89,155,203),(203,225,224)
    for y in range(h):
        t=(y//3*3)/max(1,h-1)
        col=tuple(round(a[i]+(b[i]-a[i])*t) for i in range(3))+(255,)
        d.line((0,y,w,y),fill=col)
    for x,y,s in [(24,18,1),(155,31,1),(298,10,2),(471,28,1),(560,8,1)]:
        pts=[(0,10),(8,10),(8,5),(16,5),(16,1),(29,1),(29,5),(39,5),(39,9),(49,9),(49,14),(0,14)]
        d.polygon([(x+xx*s,y+yy*s) for xx,yy in pts],fill='#eef4de')
        d.line((x+3*s,y+14*s,x+47*s,y+14*s),fill='#b6d7d9',width=s)
    for x,y in [(100,18),(445,14),(455,18)]:
        d.line((x-2,y-1,x,y,x+2,y-1),fill='#527e9a')
    return im

def city_map(size):
    im,d=canvas(size);w,h=size
    d.rectangle((0,0,w-1,h-1),fill='#203644')
    d.rectangle((3,3,w-4,h-4),outline='#769d9d')
    # Streets and compact districts drawn natively; game adds four symbols.
    for y in (34,75,115):
        d.rectangle((8,y,w-9,y+7),fill='#556972')
        for x in range(12,w-10,14):d.line((x,y+3,x+5,y+3),fill='#a5b6b6')
    for x in (74,156,238):d.rectangle((x,10,x+6,h-10),fill='#556972')
    rng=random.Random(505)
    for row,y in enumerate((15,49,89,129)):
        for x in range(15,w-20,23):
            if any(abs(x-road)<15 for road in (74,156,238)):continue
            c=rng.choice(['#ad9f87','#618d96','#ae7776','#b9b6a1'])
            d.rectangle((x+1,y+2,x+15,min(h-10,y+13)),fill=EDGE)
            d.rectangle((x,y,x+14,min(h-12,y+10)),fill=c)
            d.line((x,y,x+14,y),fill='#d6d5b8')
            for xx in (x+3,x+9):d.rectangle((xx,y+3,xx+2,y+5),fill='#284455')
    d.rectangle((176,87,225,111),fill='#4f8b71')
    for x,y in [(183,94),(194,103),(214,96)]:d.ellipse((x-3,y-3,x+3,y+3),fill='#83b682')
    centered(d,(7,h-13,w-7,h-6),'RETE URBANA CHEAP',CREAM)
    return im

def app_icon(size):
    im,d=canvas((48,48));d.rectangle((0,0,47,47),fill='#242634')
    pts=[(19,4),(29,4),(29,7),(36,7),(36,11),(40,11),(40,18),(43,18),(43,30),(40,30),(40,37),(35,37),(35,41),(13,41),(13,38),(8,38),(8,32),(5,32),(5,19),(8,19),(8,11),(13,11),(13,7),(19,7)]
    d.polygon(pts,fill=GOLD_D)
    d.ellipse((7,6,41,40),fill=GOLD)
    d.arc((8,7,39,38),185,310,fill=GOLD_L,width=2)
    d.arc((10,9,37,36),0,145,fill='#bb8545',width=2)
    heart=[(17,17),(21,17),(24,20),(27,17),(31,17),(33,20),(33,24),(24,33),(15,24),(15,20)]
    d.polygon([(x,y+1) for x,y in heart],fill='#a93b50')
    d.polygon(heart,fill='#e94c61')
    d.line((17,18,20,18),fill='#ff9b85')
    d.point((11,12),fill=CREAM);d.point((12,11),fill=CREAM)
    return im.resize(size,Image.Resampling.NEAREST)

def native(name,size):
    result=signs(name,size)
    if result is not None:return result
    funcs={
        'price_board.png':lambda:price_board(size,0), 'price_board_nuovo.png':lambda:price_board(size,1),
        'c4/display_numeri.png':lambda:queue_display(size),
        'c4/antenna_robot.png':lambda:antenna(size),
        'c4/timbro.png':lambda:rubber_stamp(size),
        'c4/lettera.png':lambda:envelope(size),
        'c4/quaderno.png':lambda:notebook(size),
        'c5/altoparlante.png':lambda:tiny_speaker(size),
        'c5/cartellone_premium.png':lambda:poster_premium(size),
        'c5/avviso_chiusura.png':lambda:closure(size),
        'c5/volantini.png':lambda:leaflets(size),
        'c5/cartello_protesta.png':lambda:protest_sign(size),
        'c5/cartone.png':lambda:cardboard(size),
        'c5/lettera_cheap.png':lambda:envelope(size,True),
        'c5/cartella_b4.png':lambda:folder(size,label='B-4'),
        'c5/porta_vetro.png':lambda:door(size,True),
        'c5/porta_archivio.png':lambda:door(size),
        'c5/cielo.png':lambda:sky(size),
        'c5/mappa_citta.png':lambda:city_map(size),
        'c6/cartellina_obbligo.png':lambda:folder(size,True),
        'c6/zucchero.png':lambda:sugar(size),
        'c6/lampadina.png':lambda:bulb(size),
        'c6/telefono.png':lambda:telephone(size),
        'cone.png':lambda:cone(size),
        'crate.png':lambda:crate(size),
        'bulbs.png':lambda:bulbs(size),
        'glasses.png':lambda:glasses(size),
        'save_star.png':lambda:star_sheet(size),
        'emotes.png':lambda:emote_sheet(size),
        'pigeon.png':lambda:pigeon_sheet(size),
        'park_sign.png':lambda:park_sign(size),
        'icon.png':lambda:app_icon(size),
        'turnstile.png':lambda:turnstile(size),
        'bulb_box.png':lambda:bulb_crate(size),
    }
    if name.startswith('c5/simbolo_'):
        names=['energia','amministrazione','commercio','finanza']
        return sector_icon(size,names.index(Path(name).stem.replace('simbolo_','')))
    return funcs[name]() if name in funcs else None

def export_generated(source,size,keep_translucent=False):
    """Mechanical export: crop alpha and fit the specified native artboard; no dithering."""
    im=Image.open(source).convert('RGBA')
    bbox=im.getchannel('A').point(lambda a:255 if a>=24 else 0).getbbox()
    if bbox:im=im.crop(bbox)
    w,h=size
    margin=0 if min(size)<20 else 1
    dims=(w-2*margin,h-2*margin)
    im=im.resize(dims,Image.Resampling.BOX)
    alpha=im.getchannel('A') if keep_translucent else im.getchannel('A').point(lambda a:255 if a>=128 else 0)
    rgb=im.convert('RGB').quantize(colors=32,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE).convert('RGBA')
    rgb.putalpha(alpha)
    out=Image.new('RGBA',size,(0,0,0,0))
    out.alpha_composite(rgb,((w-dims[0])//2,h-margin-dims[1]))
    return out

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--out',required=True,type=Path)
    parser.add_argument('--generated',type=Path)
    parser.add_argument('--inventory',required=True,type=Path)
    args=parser.parse_args()
    sources={r['file']:r for r in json.loads(args.generated.read_text(encoding='utf-8'))} if args.generated else {}
    inventory=json.loads(args.inventory.read_text(encoding='utf-8'))
    rows=[];missing=[]
    for entry in inventory:
        name=entry['file'];size=tuple(entry['size'])
        im=native(name,size)
        mode='native UI / micro-sprite'
        if im is None and name in sources:
            im=export_generated(sources[name]['source'],size,keep_translucent='vetrina' in name)
            mode='ImageGen + native export'
            if name=='c5/tabellone_bus.png':
                d=ImageDraw.Draw(im)
                d.rectangle((12,4,28,9),fill='#172030')
                tiny_type(d,(12,4,29,9),'6 MIN',GOLD_L,max_size=6)
            elif name=='c4/terminale_rapporto.png':
                tiny_type(ImageDraw.Draw(im),(3,3,14,10),'404',INK,max_size=5)
        if im is None:
            missing.append(name);continue
        assert im.size==size and im.mode=='RGBA',name
        path=args.out/name;path.parent.mkdir(parents=True,exist_ok=True)
        im.save(path,optimize=True)
        rows.append({'file':name,'size':list(size),'mode':mode,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
    args.out.mkdir(parents=True,exist_ok=True)
    (args.out.parent/'asset_manifest.json').write_text(json.dumps(rows,indent=2,ensure_ascii=False),encoding='utf-8')
    print(json.dumps({'written':len(rows),'missing':missing},ensure_ascii=False))

if __name__=='__main__':main()
