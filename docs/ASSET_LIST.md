# Elenco degli asset personalizzati

> **Grafica aggiornata da Codex:** sono stati sostituiti tutti i **100 PNG personalizzati**,
> conservando nomi, misure, trasparenze e tagli dei fogli animati. Gli asset acquistati
> in `assets/limezu/` sono rimasti invariati. Stato e rigenerazione: [ASSET_REFRESH_CODEX.md](ASSET_REFRESH_CODEX.md).
> Le tabelle sotto conservano il contratto tecnico originario; i riferimenti ai
> segnaposto descrivono la provenienza dei file, ora sostituiti. I vecchi generatori
> conservano automaticamente i PNG definitivi tramite `tools/asset_guard.py`.

La grafica fatta apposta per CHEAP verrà disegnata a parte. Nel gioco, al suo posto, ci sono **segnaposto**:
forme piene con un'etichetta, già della misura giusta. Per sostituirne uno basta salvare il PNG nuovo
**con lo stesso nome e la stessa misura**: il gioco non cambia.

Gli asset acquistati (LimeZu, in `assets/limezu/`) restano dove sono e non vanno ridistribuiti
(la cartella è esclusa da git).

**Prospettiva di tutto il gioco:** la stessa di LimeZu Modern Interiors. Vista dall'alto, di tre quarti
frontale. Pixel art a 16 px per casella, senza antialiasing, contorno scuro (`#18141e`).
**"Piedi"** = il punto in basso a sinistra dello sprite, appoggiato sulla casella indicata.

## Capitolo 6 — La Cima (`art/c6/`, generati da `tools/make_placeholders_cima.py`)

| File | Misura (px) | Funzione | Prospettiva | Animazione | Dove si usa |
|---|---|---|---|---|---|
| `insegna_ascensore.png` | 64x12 | Insegna dell'ascensore dorato "NON DEVI PIÙ SALIRE. SEI ARRIVATO." | frontale, sul muro | consigliata: luccichio dell'oro (2 frame) | `chapters/c6/cima.tscn`, `Decori/InsegnaAscensore` (1,3) |
| `specchio_ascensore.png` | 32x32 | Lo specchio dell'ascensore ("HAI TROVATO QUELLO CHE CERCAVI?") | frontale, sul muro | nessuna (la scritta la fa il codice) | `cima.tscn`, `Decori/SpecchioAscensore` (1,4); esame `_specchio_ascensore` |
| `specchio.png` | 16x24 | Gli specchi del corridoio (riflettono chi hai incontrato) | frontale, sul muro | consigliata: riflesso che passa (2-3 frame) | `cima.tscn`, `Decori/Specchio0-2` (7,5), (9,5), (11,5) |
| `scrivania_presidenza.png` | 64x32 | La scrivania della Presidente e del TURNO di Direzione | 3/4 frontale, piedi solidi 14 px | nessuna | `cima.tscn`, `Mondo/Scrivania` (19,5); esame `_scrivania` (20,6) |
| `cartellina_obbligo.png` | 12x8 | La cartellina rosa OBBLIGO DI ESISTENZA, sulla scrivania | dall'alto, appoggiata | nessuna | `cima.tscn`, `Mondo/Cartellina` (20,5, spostata di 4,-26) |
| `terminale_direzione.png` | 16x32 | Il terminale dei bilanci (le consultazioni) | 3/4 frontale, piedi solidi 8 px | consigliata: schermo acceso (2 frame) | `cima.tscn`, `Mondo/TerminaleBilanci` (16,4); esame `_terminale` |
| `finestra_panorama.png` | 80x32 | La finestra panoramica sulla città | frontale, sul muro | consigliata: nuvole lente (loop) | `cima.tscn`, `Decori/Finestra` (23,2); esame `_finestra` (25,3) |
| `archivio_debito.png` | 32x40 | L'archivio del debito "7.000.000.000" | 3/4 frontale, piedi solidi 12 px | nessuna | `cima.tscn`, `Mondo/ArchivioDebito` (29,4); esame `_archivio` |
| `tavolo_decisione.png` | 48x32 | Il tavolo della scelta finale | 3/4 frontale, piedi solidi 14 px | nessuna | `cima.tscn`, `Mondo/Tavolo` (21,10); esame `_tavolo` (22,9) |
| `macchina_caffe.png` | 16x32 | La macchina del caffè (al secondo colpo, lo zucchero) | 3/4 frontale, piedi solidi 8 px | consigliata: vapore (2 frame) | `cima.tscn`, `Mondo/Caffe` (15,11); esame `_caffe` |
| `timbro_annullato.png` | 96x24 | Il timbro rosso ANNULLATO (mostrato nell'offerta, usato nel finale A) | frontale, sopra lo schermo | il codice lo fa scendere e "battere"; l'arte può aggiungere l'inchiostro che si allarga | `chapters/c6/cima_c6.gd` (offerta, 6.04); `chapters/c6/finale_c6.gd`, `family_scene` (A) |
| `tavoli_condivisi.png` | 96x32 | I tavoli uniti del finale C | 3/4 frontale | nessuna | `finale_c6.gd`, `family_scene` (C) |
| `torre_sezione.png` | 200x600 | La Torre in sezione, sei piani dal Fondo alla Cima | frontale, piatta | il codice la fa scorrere dall'alto in basso | `cima_c6.gd`, `_finestra` (panorama); `finale_c6.gd`, epiloghi |
| `lampadina.png` | 8x10 | La lampadina sulla scrivania: si accende quando pedali sulla dinamo | frontale, appoggiata | spenta = scurita dal codice, accesa = più luminosa; consigliati 2 frame (spenta/accesa) con alone | `cima.tscn`, `Mondo/Lampadina` (34,7); `cima_c6.gd`, `_dinamo` |
| `zucchero.png` | 6x4 | Bustina di zucchero (quella che la Presidente strappa) | dall'alto, piccola | consigliata: strappo (2 frame) | **generato, non ancora usato**: le scene lo descrivono a parole |
| `telefono.png` | 12x8 | Il telefono della scrivania (la chiamata del Capo, la Casa Comune) | dall'alto, appoggiato | consigliata: vibra quando squilla (2 frame) | **generato, non ancora usato**: lo squillo è solo sonoro (`drring.wav`) |

Sprite dei personaggi: la Presidente usa il foglio LimeZu `char_20` (grigio), il Capo `char_18` (grigio, per la prima volta),
Nives `char_13`. Uno sprite dedicato per la Presidente è da disegnare.
Dal foglio LimeZu `generic.png` (acquistato, non segnaposto): tappeto `Rect2(48,354,32,28)`, pianta `Rect2(212,408,23,31)`.
Dai props LimeZu: `palm.png`.

### Audio (segnaposto, generati da `tools/make_sfx_cima.py`)

| File | Durata | Funzione | Dove si usa |
|---|---|---|---|
| `audio/strap.wav` | breve | La bustina di zucchero strappata | `cima_c6.gd`, 6.02 |
| `audio/drring.wav` | breve | Il telefono della scrivania | `cima_c6.gd`, 6.08 (il Capo); `finale_c6.gd` (finale A) |
| `audio/music_cima.wav` | 12 s, in loop | Musica della Cima e della Direzione | `cima.tscn`, `direzione.gd`, inizio del finale |
| `audio/music_epilogo.wav` | 6 s, in loop | Musica degli epiloghi e dei titoli | `finale_c6.gd` |

## I personaggi (Character Generator LimeZu)

I personaggi delle persone vere sono fatti con il **Character Generator 2.0** di LimeZu e salvati dall'app in
`%USERPROFILE%/AppData/LocalLow/Gray Matter Studios/Character Generator 2.0/Saved Characters/`.
`tools/import_assets.ps1` li copia in `assets/limezu/characters/cheap_<id>.png` (fuori da git, come gli altri asset LimeZu).
Stesso formato dei personaggi già pronti (896x640, stesse righe: fermo, cammina, seduto, telefono, legge).

| File salvato | Chi | Dove si usa |
|---|---|---|
| `fermo.png` | Fermo | Fondo (`fondo.tscn`, `bake_c1_fondo.gd`, `room.gd`) |
| `mina.png` | Mina, l'elettricista (id `bulbo`) | Fondo |
| `tilde.png`, `ercole.png` | Tilde, Ercole | Sottoufficio |
| `leda.png`, `amir.png` | Leda, Amir | Mercato, ospiti in Città, epiloghi |
| `olga.png`, `teo.png` | Olga, Teo | Banca, ospiti in Città, epiloghi |
| `ada.png`, `nadir.png`, `rina.png` | Ada, Nadir, Rina | Città, Casa Comune, epiloghi |
| `capo.png` | Il Capo | Cima (6.08) |
| `rosa.png`, `sandro.png` | Rosa, Sandro | solo dati della versione precedente |

Mancano ancora: **Bulbo** (id `mina`, usa `char_08`), **la Presidente** (`char_20`), **Nives** (`char_13`).
Nel gioco le persone vere sono grigie ma non piatte: il grigio tiene il contrasto e un filo (30%) del colore
del personaggio (`shaders/greyscale.gdshader`, `person`), così restano sbiadite e riconoscibili.

## Le persone vere: il grigio e il gesto (`data/looks.json`, `scripts/looks.gd`)

Niente accessori (tolti: erano brutti). Ognuna ha un grigio suo (`tint`) e un gesto suo da ferma; chi diventa robot perde il gesto.

I gesti (da ferma, ogni qualche secondo, `tic` in `data/looks.json`) usano animazioni LimeZu che ci sono già:
Teo, Tilde, Olga e Ada leggono (`read`), Ercole e Amir guardano il telefono (`phone`), Nadir e Mina guardano
in alto (gli uccelli, le lampadine), Leda, Rina e Bulbo si guardano intorno.

Dove si usano: `scripts/npc.gd` (tutte le persone di `data/npcs.json`), `world/char_sprite.gd` (campo `person`:
Fermo nel Fondo, gli ospiti della Città, Leda e Amir sulle cassette, Teo e Olga allo sguardo indietro della Banca,
la Presidente e le persone del capitolo 6).

Fogli dei personaggi: Leda non usa più `char_01` (era lo stesso del protagonista) ma `char_03`;
Olga non usa più `char_14` (lo stesso di Fermo) ma `char_09`.

## Musica (`assets/music/`, estratta da `tools/import_music.py`)

Canzoni vere da due pacchetti in `../music/` (accanto al progetto): **28 High Quality 16-bit RPG Music** e
**FREE LOOPABLE MUSIC (Bishop)**. Come LimeZu, la cartella è esclusa da git: non si ridistribuisce.
**Gli zip non contengono una licenza**: prima di pubblicare il gioco va controllata sulla pagina da cui sono stati
scaricati (uso commerciale, obbligo di citare l'autore nei titoli).

Ogni atmosfera è una scaletta: finita una canzone ne parte un'altra, mai la stessa due volte di fila; con una canzone sola si ripete
(`autoload/sound.gd`, `PLAYLISTS`). Se i file mancano, si sentono i vecchi segnaposto `audio/music_*.wav`.

| Atmosfera | Dove | Canzoni |
|---|---|---|
| `festa` | Fondo (-5) | GettinSillyWithIt (una sola, in loop) |
| `attesa` | Sottoufficio (-4) | SoundfontJazzClub, SlyCooperClarinet, PkmnGoldLuckyCorner |
| `mercato` | Mercato (-3) | MarketJam, Lively City, East Town, TRUNK_KNOX_GO_BUCK |
| `banca` | Banca (-2) | TracerBulletPrivateEye, SleazyFurball, Malicious Scheme |
| `citta` | Città (0) | MetropolitanCosmopolitan, Peaceful Village, HeWillNeverBeTheApeEscapeSoundtrack |
| `quartiere` | Casa Comune, stanze di prima | Wood Forest Town, Ancient Library, The Old Magician |
| `cima` / `presidente` | Cima, Direzione | Royal Castle, Magic Temple, Traveling the Sky |
| `epilogo` | Epiloghi e titoli | Long Journey, Holy Sanctuary, Melancholic Bittersweet Groovy Cave Journey |
| `lavoro` | I TURNI (minigiochi) | HypnoticSynthLoop, Dark Factory, FrostyLabratory, Dwarven Mine |
| `notte` | La notte | NightTownWaltz, Melancholic Bittersweet |
| `fondo` | Stanze vecchie del Fondo | DripstoneCave, Tension1 |
| `battaglia` | Battaglie (versione precedente) | Battle Theme I, Battle Theme II, HaveYouEverPlayedGrimDawn |
| `tensione` | (pronta, non ancora usata) | Tension1, Tension2 |
| `ascensore` | L'ascensore dell'inizio (rallenta e si spegne quando si rompe) e quello dorato della Cima | SoundfontJazzClub, SlyCooperClarinet |
| `aiuto_mina` | Il minigioco dei fili di Mina (campo `music` del minigioco in `data/npcs.json`) | Unknown Island |
| `aiuto_bulbo` | Il minigioco delle lampadine di Bulbo | Goofy Monster |

## Capitolo 5 — La Città (`art/c5/`, generati da `tools/make_placeholders_citta.py`)

Posizioni in caselle (16 px). C = `chapters/c5/citta.tscn`, CC = `chapters/c5/casa_comune.tscn`, L = `chapters/c5/citta_c5.gd`.

| File | Misura (px) | Funzione | Prospettiva | Animazione | Dove si usa |
|---|---|---|---|---|---|
| `cielo.png` | 640x96 | Il cielo sopra la piazza: lo si vede all'arrivo, quando la camera sale (è già una sfumatura, non solo un segnaposto) | sfondo piatto | consigliata: nuvole che scorrono lente, uccelli | C, `Decori/Cielo` (sopra la riga 0) |
| `insegna_esterno.png` | 128x20 | "BENVENUTO ALL'ESTERNO. Servizio soggetto a disponibilità." sopra la porta della Torre | frontale, appesa | consigliata: neon che sfarfalla (2 frame) | C, `Decori/InsegnaEsterno` (0,8); esame `_insegna_esterno` |
| `porta_vetro.png` | 32x32 | La porta a vetri della Torre | frontale, nel muro | consigliata: si apre (3 frame) | C, `Decori/PortaVetro` (2,10) |
| `insegna_casa_comune.png` | 80x12 | Insegna "CASA COMUNE", dipinta a mano | frontale, sulla facciata | nessuna | C, `Decori/InsegnaCasaComune` (14,6) |
| `avviso_chiusura.png` | 24x16 | Il foglio "CHIUSURA FRA 3 GG" (il testo vero lo scrive il codice e cambia con la storia) | frontale, attaccato al muro | consigliata: angolo che sventola | C, `Decori/AvvisoChiusura` (18,9); CC, `Decori/AvvisoChiusura` (2,2); esame `_avviso` |
| `volantini.png` | 16x16 | Volantini della Casa Comune | frontale, sul muro | nessuna | C, `Decori/Volantini` (14,9); esame `_volantini` |
| `insegna_comunicazioni.png` | 80x12 | "CENTRO COMUNICAZIONI" (dove c'è il TURNO) | frontale, sulla facciata | nessuna | C, `Decori/InsegnaComunicazioni` (21,6) |
| `cartellone_premium.png` | 72x40 | "ANCHE IL CIELO HA UN LIMITE. SUPERALO CON PREMIUM." | frontale, su pali | lampeggia all'arrivo (fatto dal codice); consigliata: luci a scorrimento | C, `Decori/CartellonePremium` (27,7); esame `_cartellone` |
| `vetrina_rotta.png` | 32x24 | La vetrina di Rina: crepata da prima (decoro) e rotta dopo la manifestazione | frontale, nel muro della bottega | nessuna (lo schianto è un suono + flash) | C, `Decori/VetrinaGiaRotta` (37,9); L, `_broken_window` (33,7 +2,+6) |
| `cartone.png` | 32x24 | Il cartone "APERTO LO STESSO" sulla vetrina, se aiuti Rina | frontale, sopra la vetrina | nessuna | L, `_cardboard` (33,7 +2,+6) |
| `altoparlante.png` | 12x10 | Altoparlante sul lampione (la voce di CHEAP) | 3/4 frontale | consigliata: vibra quando parla (2 frame) | C, `Mondo/Lampione/Altoparlante`; esame `_altoparlante` |
| `terminale_presentazioni.png` | 16x24 | Terminale della sala presentazioni (un, due, tre, stella) | 3/4 frontale, a terra | consigliata: schermo acceso (2 frame) | C, `Mondo/TerminalePresentazioni` (26,12); esame `_presentazioni` |
| `tabellone_bus.png` | 32x32 | Tabellone della fermata: 6, 9, 14 minuti (le cifre le scrive il codice) | 3/4 frontale, su palo | consigliata: cifre LED che cambiano | C, `Mondo/Tabellone` (21,16); esame `_tabellone` |
| `cartello_protesta.png` | 20x14 | Cartello alzato da chi manifesta (lo slogan lo scrive il codice) | frontale, sopra la testa | consigliata: su e giù (2 frame) | L, `_sign_on` (figlio della persona, 0,-34) e `_dress_for_look_back` |
| `panca_premium.png` | 64x12 | "PANCA PREMIUM — ABBONAMENTO IN ARRIVO", la battuta finale della scena segreta | frontale, cartellino sopra la panchina | appare in dissolvenza (fatto dal codice) | L, `_secret` (sopra la panchina 6,18) |
| `libreria.png` | 32x48 | Librerie della Casa Comune | 3/4 frontale, piedi solidi | nessuna | CC, `Mondo/Libreria` (5,5) e `Libreria2` (8,5) |
| `tavolo_lungo.png` | 48x24 | Tavolo da studio | 3/4 frontale | nessuna | CC, `Mondo/Tavolo` (3,9) e `Tavolo2` (8,9) |
| `sedie_spaiate.png` | 32x16 | Sedie tutte diverse | 3/4 frontale | nessuna | CC, `Mondo/Sedie` (3,10) e `Sedie2` (8,10) |
| `bacheca.png` | 32x24 | Bacheca di sughero (Fermo, Bulbo, Mina se li hai conosciuti) | frontale, sul muro | nessuna | CC, `Decori/Bacheca` (10,2); esame `_bacheca` |
| `lettera_cheap.png` | 10x8 | La lettera rosa di CHEAP sul tavolo | dall'alto, appoggiata | nessuna | CC, `Mondo/LetteraCheap` (9,8 +3,+4); esame `_lettera` |
| `cartella_b4.png` | 12x8 | La cartella B-4 (dal capitolo 2) | dall'alto, su un mobile | nessuna | CC, `Mondo/CartellaB4` (11,3); esame `_cartella_b4` |
| `porta_archivio.png` | 16x32 | Porta chiusa dell'archivio (sparisce quando comincia la manifestazione) | frontale, nella parete | consigliata: si apre (3 frame) | CC, `Mondo/PortaArchivio` (14,8); esame `_porta_archivio` |
| `terminale_bilanci.png` | 16x32 | Il terminale dei conti della Casa | 3/4 frontale, a terra | consigliata: schermo acceso (2 frame) | CC, `Mondo/TerminaleBilanci` (17,5); esame `_bilanci` |
| `armadio_documenti.png` | 32x40 | Armadio dei faldoni (il documento nascosto) | 3/4 frontale, piedi solidi | nessuna | CC, `Mondo/Armadio` (19,5); esame `_armadio` |
| `contatore.png` | 16x24 | Contatore "RETE TORRE CHEAP — PIANO -5" | frontale, sul muro | consigliata: rotella che gira | CC, `Decori/Contatore` (15,3); esame `_contatore` |
| `mappa_citta.png` | 320x150 | La mappa della città vista dal primo gradino (rivelazione) | dall'alto, piatta | i simboli appaiono uno a uno (fatto dal codice) | L, `on_stairs_step` (pannello a schermo) |
| `simbolo_energia.png` | 24x24 | Il -5 (il Fondo, la dinamo) | icona piatta | nessuna | L, `on_stairs_step` |
| `simbolo_amministrazione.png` | 24x24 | Il -4 (il Sottoufficio) | icona piatta | nessuna | L, `on_stairs_step` |
| `simbolo_commercio.png` | 24x24 | Il -3 (il Mercato) | icona piatta | nessuna | L, `on_stairs_step` |
| `simbolo_finanza.png` | 24x24 | Il -2 (la Banca) | icona piatta | nessuna | L, `on_stairs_step` |

Riusati dal capitolo 4: `art/c4/antenna_robot.png` (Ada, Amir, Teo robot: `_antenna`, 0,-27).
Dai fogli LimeZu (acquistati): facciate `cheap_tower`, `condo_yellow`, `condo_blue`, `shop_big`; alberi, panchina,
fontana, lampione, la fermata del bus e i terreni del tileset `world/tilesets/citta.tres`.

**Suoni segnaposto** (`audio/`, generati da `tools/make_sfx_citta.py`, sintetici):
`crash.wav` (la vetrina, ~0,6 s), `thump.wav` (la testa di Ada contro lo scaffale), `crack.wav` (il biscotto della scena segreta),
`music_citta.wav` (12 s in loop: vento e uccelli; da sostituire con la musica vera della piazza).

## Capitolo 4 — La Banca (`art/c4/`, generati da `tools/make_placeholders_banca.py`)

| File | Misura (px) | Funzione | Prospettiva | Animazione | Dove si usa |
|---|---|---|---|---|---|
| `insegna_banca.png` | 128x28 | Insegna "BANCA CHEAP / IL TUO FUTURO È IL NOSTRO PRESENTE.", oro su rosso | frontale, appesa al muro | nessuna (eventuale: luccichio dell'oro) | `chapters/c4/banca.tscn`, nodo `Decori/InsegnaBanca` (casella 2,1) |
| `display_numeri.png` | 64x20 | Display "ORA SERVIAMO IL NUMERO 4" | frontale, appeso al muro | consigliata: 2 frame, cifre che lampeggiano | `banca.tscn`, `Decori/DisplayNumeri` (12,1) |
| `distributore_numeri.png` | 16x32 | Distributore dei biglietti (e del SALTAFILA) | 3/4 frontale, a terra | consigliata: 2 frame, il biglietto che esce | `banca.tscn`, `Mondo/Distributore` (5,9); esame `_distributore` |
| `bancone_sportello.png` | 48x24 | Sportello del TURNO (settore fiducia), con vetro | 3/4 frontale, piedi solidi 10 px | nessuna | `banca.tscn`, `Mondo/Bancone` (8,3) |
| `colonna_oro.png` | 16x40 | Colonna dorata ai lati dello sportello | 3/4 frontale, piedi solidi 6 px | nessuna | `banca.tscn`, `Mondo/ColonnaSinistra` (7,3) e `ColonnaDestra` (12,3) |
| `terminale_conto.png` | 16x32 | Terminale "CONSULTA IL TUO CONTO" (il debito vero) | 3/4 frontale, a terra | consigliata: schermo acceso/spento (2 frame); allo sguardo indietro una scritta rossa "RICERCA CONTRATTO..." lampeggia sopra (fatta dal codice) | `banca.tscn`, `Mondo/TerminaleConto` (14,4); esame `_conto` |
| `terminale_rapporto.png` | 16x24 | Terminale del RAPPORTO DI VERIFICA N. 404 | 3/4 frontale, da scrivania | consigliata: cursore che lampeggia (2 frame) | `banca.tscn`, `Mondo/TerminaleRapporto` (20,9); esame `_rapporto` |
| `archivio.png` | 32x40 | Archivio a cassetti (A-C, D-F...) | 3/4 frontale, piedi solidi 10 px | nessuna | `banca.tscn`, `Mondo/Archivio` (19,7); esame `_archivio` |
| `quaderno.png` | 10x8 | Il quaderno di fumetti di Teo, sulla scrivania | dall'alto, appoggiato | allo sguardo indietro dondola (fatto dal codice, rotazione) | `banca.tscn`, `Mondo/Quaderno` (17,7, spostato di 3,-14); esame `_quaderno` |
| `lettera.png` | 8x6 | La risposta alla contestazione, in mano a Olga | dall'alto, piccola | nessuna | `chapters/c4/banca_c4.gd`, `_dress_for_look_back` (figlia di Olga, +6,-14) |
| `timbro.png` | 8x10 | Il timbro di Teo robot | 3/4 frontale | il codice lo fa battere su e giù (0,25 s giù, 0,08 s su, pausa 0,4 s); l'arte può aggiungere 2 frame | `banca_c4.gd`, `_robot_teo` (figlio di Teo, +12,-16) |
| `antenna_robot.png` | 8x10 | Antenna sulla testa di Teo robot: il robot si riconosce **anche senza colori** | frontale | consigliata: lucina che lampeggia (2 frame) | `banca_c4.gd`, `_robot_teo` (figlio di Teo, 0,-27) |

Dal foglio LimeZu `generic.png` (acquistato, non segnaposto): tappeto rosso `Rect2(48,354,32,28)`,
panca `Rect2(1,254,30,18)`, pianta `Rect2(212,408,23,31)`. Dai props LimeZu: `office_desk.png` (scrivania di Teo).

## Capitolo 3 — Il Mercato (`art/`, generati da `tools/make_art_mercato.py`)

Sono disegnati dal codice (pixel art semplice): vanno considerati segnaposto anche loro.

| File | Misura (px) | Funzione | Prospettiva | Animazione | Dove si usa |
|---|---|---|---|---|---|
| `sign_saldi.png` | 116x16 | Insegna "OGGI TUTTO AL 50%*" | frontale, sul muro | nessuna | `chapters/c3/mercato.tscn`, `InsegnaSaldi` (3,1) |
| `price_board.png` | 112x34 | Tabellone dei prezzi, prima (pane, latte, acqua da `data/market.json`) | frontale, sul muro | nessuna | `mercato.tscn`, `Tabellone` (12,2) |
| `price_board_nuovo.png` | 112x34 | Lo stesso tabellone coi prezzi aumentati | frontale, sul muro | il cambio prezzi lampeggia (fatto dal codice) | `chapters/c3/mercato_c3.gd`, `_price_update` |
| `sign_leda.png` | 52x14 | Insegna "DA LEDA" | frontale, sul muro | nessuna | `mercato.tscn`, negozio di Leda |
| `cassa.png` | 32x24 | La cassa del TURNO | 3/4 frontale | nessuna | `mercato.tscn`, zona cassa |
| `shelf.png` | 32x32 | Scaffale del negozio di Leda | 3/4 frontale | nessuna | `mercato.tscn`, negozio di Leda |
| `chalkboard.png` | 16x20 | La lavagnetta di Leda | 3/4 frontale | nessuna | `mercato.tscn`, negozio di Leda |
| `crate.png` | 16x12 | Cassetta (ci si siedono Leda e Amir nella scena segreta) | 3/4 frontale | nessuna | `mercato.tscn`, magazzino |
| `water_machine.png` | 16x32 | Distributore d'acqua (10 €, poi 15 €) | 3/4 frontale | nessuna | `mercato.tscn`, piazza (9,4) |
| `terminal_consegne.png` | 16x32 | Terminale delle consegne (l'offerta del capo su Amir) | 3/4 frontale | nessuna | `mercato.tscn`, magazzino |

Gli altri PNG in `art/` (cartelli, poster, stelline, scale, tornelli, emote...) vengono dai capitoli 1-2
(`tools/make_art_fondo.py` e versioni precedenti) e sono segnaposto allo stesso modo.
