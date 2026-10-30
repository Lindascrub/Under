# Spostare le cose a mano (editor di Godot)

Queste stanze sono scene vere: si aprono in Godot e si sistemano trascinando i nodi.

| Piano | Scena |
|---|---|
| Piano terra | `scenes/world/office.tscn` |
| L'ascensore dell'inizio | `scenes/world/elevator_intro.tscn` |
| -5 Il Fondo | `chapters/c1/fondo.tscn` |
| -4 Il Sottoufficio | `chapters/c2/sottoufficio.tscn` |
| -3 Il Mercato | `chapters/c3/mercato.tscn` |
| -2 La Banca | `chapters/c4/banca.tscn` |
| La Città, la casa comune | `chapters/c5/citta.tscn`, `chapters/c5/casa_comune.tscn` |
| La Cima | `chapters/c6/cima.tscn` |

## Come sono fatte

- **Pavimento**, **Muri**: i livelli di tessere. Si dipingono con il pannello TileMap in basso
  (i muri hanno già le collisioni).
- **Decori**: le cose sulla parete o per terra che stanno *sotto* le persone (poster, tappeti, bacheche).
- **Mondo**: tutto il resto, ordinato dall'alto in basso (chi sta più in basso si disegna davanti).
  - Uno sprite si sposta trascinandolo. La sua collisione (`Collisione`) e il suo testo (`Guarda...`)
    sono figli: si spostano con lui.
  - Le persone sono `NpcSpot` (si vede il loro sprite): si spostano uguali.
  - I segnaposto speciali (`RoomFeature`) mostrano un'anteprima di quello che comparirà:
    `Stellina` (il salvataggio), `Posto...` (il TURNO). Si spostano a caselle: tieni premuto
    lo snap (o metti la griglia a 16 px) così restano allineati.
  - **Le biglietterie** (`Mondo/SportelloBadge`, su tutti i piani) sono la scena `world/badge_booth.tscn`:
    trascini il nodo e si sposta tutto (vetri, bancone, porta, addetta, collisione e il punto dove si
    compra il badge). Per cambiarne i pezzi: tasto destro → *Apri nell'editor*.
  - Le telecamere (`Telecamera_...`) girano da sole: si spostano trascinandole, e in `facing` scegli da che parte guardano.
  - I carrelli del Mercato (`Carrello...`) hanno le ruote che girano: nell'Inspector scegli `color`, `load_kind` (vuoto o pieno) e `facing` (da che parte guardano).
  - **Le collisioni**: la `CollisionShape2D` che vedi sotto un mobile (dentro `Collisione`) è quella vera del gioco. Se la allarghi o la sposti, nel gioco cambia uguale.
  - L'ascensore (`Ascensore` al piano terra, `AscensoreOriginale` al Fondo) è un nodo vero: si sposta e
    la porta e il cartello lo seguono.
  - **I muri sottili del Fondo** (`MuriBiglietteria/MuroTramezzo`, `MuroTramezzoBasso`, `MuroRitorno`,
    `PilastroScale`): ognuno ha la sua `Forma` (CollisionShape2D). Sposti il muro trascinandolo; per
    allungarlo/accorciarlo tiri le maniglie della `Forma`, e il disegno la segue. I muri grandi sono le
    caselle del livello `Muri` (TileMapLayer): si dipingono col pennello.
- **Le scale** stanno nel livello **Decori** (a terra: chi ci passa si vede sopra):
  - `Decori/ScaleSu` (scena `world/stairs_up.tscn`): scalini, `Tornello`, `Fiancate`, `Sbarra` (la
    collisione del tornello chiuso, sparisce quando hai il badge), `GuardaTornello` (la frase). Nell'Inspector:
    `target` (il piano di sopra), `spawn`, `need` (il badge che serve). Trascinala a caselle (snap 16).
  - `Decori/ScaleGiu` (scena `world/stairs_down.tscn`): scalini con l'ombra e i `Bordi`. Nell'Inspector
    `target` e `spawn`.
  - Il muro dietro le scale che salgono si apre da solo dove le metti.
- **Arrivi**: i punti dove compari arrivando (il nome dice da dove: `default`, `from_below`, `elevator`...).
  Si spostano come gli altri nodi.

Griglia consigliata: nel menu della vista 2D, *Snap* attivo con passo 16x16 (una casella).

## Cose da sapere

- **Se Godot è aperto mentre Claude cambia una scena**, Godot chiede se ricaricarla: rispondi di sì
  (Ricarica). Se invece salvi prima, la tua versione vecchia copre quella nuova.

- **Gli script di bake non sovrascrivono più le scene**: se esiste già, `tools/bake_*.gd` si ferma.
  Per rifare una scena da zero (perdendo gli spostamenti fatti a mano) serve `-- --force`.
- Le persone che si muovono secondo l'orario (quelle in `data/npcs.json`, come Dario e Giulia al piano
  terra) compaiono dove dice il loro orario, non sono nodi della scena.
- Fatte ancora solo col codice (non si spostano nell'editor): la casa, la strada, il parco, il rifugio,
  l'ufficio del capo, la Presidenza.
