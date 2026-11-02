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
  - **La stellina** (`Mondo/Stellina`) è la scena `world/stellina.tscn`: `Sprite` (la stellina),
    `Tocco` (da dove la usi), `Risveglio` (dove ti ritrovi dopo aver salvato o dormito); nell'Inspector
    `zona_tocco`. Si sposta a caselle: tieni lo snap a 16 px.
  - **Il posto del TURNO** (`Mondo/Posto...`, nel Fondo `UsaCycletteDinamo`) è la scena
    `world/posto_turno.tscn`: i figli sono modificabili, trascini `PuntoUso` (da dove si comincia) e
    `Targhetta` (la scritta TURNO). Nell'Inspector: `job`, `avvicinamento` (da che parte ci si avvicina),
    `guarda_verso`, i due colori e il `dondolio`.
  - **Le persone** sono `NpcSpot`; nel gioco diventano la scena `scripts/npc.tscn` (`Ombra`, `Sprite`,
    `Collisione`, `Fumetto` con la nuvoletta). Nell'Inspector di `npc.tscn`: `seduto_abbassa` e
    `seduto_spostamento` (come si siede sulle panchine).
  - **I clienti che girano** (Mercato: `Cliente0`...) sono la scena `world/comparsa.tscn`. Il loro giro
    sono i puntini dentro `Giro` (`Punto0`, `Punto1`...): trascinali, aggiungine o toglili. Nell'Inspector
    anche `velocita`, `distanza_stop` e la sosta.
  - **Dove compaiono le persone nelle scene della storia**: il nodo `Posti` (Città e Cima). Ogni
    `Posto...` è dove comparirà quella persona (per esempio `PostoManifestante`, `PostoPancaAda`,
    `PostoTavolo` per la Presidente). Nella Banca, `Punti/UscitaOlga` è dove va Olga alla fine.
  - **Cose nascoste che il gioco mostra quando serve** (si vedono nell'editor togliendo l'occhio
    chiuso): nella Città `VetrinaRottaNuova`, `Cartone`, `InsegnaEsito`, `CartelliATerra`,
    `CartelloPremium`, `Mondo/Tabellone/InArrivo`; nel Sottoufficio, dentro `Mondo/Tritacarte`,
    `IngressoFoglio/Foglio` e `UscitaStrisce/StrisciaA`/`StrisciaB` (i tempi del tritacarte sono
    nell'Inspector della radice: `tritacarte_...`).
  - **Pezzi piccoli che si attaccano alle persone** (si aprono e si cambiano lì): `world/antenna_robot.tscn`,
    `chapters/c4/timbro_robot.tscn` (anche il ritmo), `chapters/c4/lettera_olga.tscn`,
    `chapters/c4/ricerca_contratto.tscn`, `chapters/c5/cartello_in_mano.tscn`, `world/signor_rata.tscn`
    (lo `Sprite` è dove compare rispetto a te), `world/gatto.tscn` e `world/occhiali.tscn` (le missioni).
  - **Le scale chiuse del Sottoufficio** (quando il Fondo è sbarrato): `chapters/c2/scale_chiuse.tscn`
    (`Botola`, `Sbarramento` con coni, nastro e cartello, `Collisioni`, `Guarda`, `Arrivo`).
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

- **Inquadrature** (nodo `Inquadrature`): dove va la telecamera nelle scene animate. Ognuna è un
  `Inquadratura` (script `world/inquadratura.gd`): il centro dello schermo è il nodo, e nell'editor si vede
  il **rettangolo giallo** di quello che inquadra. Trascinalo per spostare la ripresa; nell'Inspector:
  `zoom` (2 è quello normale del gioco, più alto è più vicino), `durata` (secondi per arrivarci),
  `durata_ritorno` (secondi per tornare al giocatore).
  - `SguardoIndietro`: la ripresa larga di fine capitolo (Fondo, Sottoufficio, Mercato, Banca, Città).
  - `Tritacarte` (Sottoufficio), `Tabellone` (Mercato), `Cielo` (Città, all'uscita dalla Torre).
  - Nives che esce dallo sportello: `InquadraturaAddetta` dentro `world/badge_booth.tscn`
    (`velocita_inseguimento` = quanto in fretta la telecamera la segue mentre cammina).
- **I pannelli delle scene animate** sono scene da aprire nell'editor: sposti, allarghi, cambi colori e
  font dei nodi; i tempi (secondi) sono nell'Inspector della radice.
  - `world/sguardo_indietro.tscn`: le scritte di fine capitolo (`Striscia` e `Frase` in basso, `Buio`,
    `Premessa/Prima` e `Premessa/Altra`, `Capitolo`, `Titolo`, `Sottotitolo`).
  - `chapters/c4/rivelazione_banca.tscn` e `chapters/c5/rivelazione_citta.tscn`: il riquadro del primo
    gradino. Le righe sono le Label dentro `Righe` (la prima dà il colore normale; `colore_evidenza`
    nell'Inspector è quello delle righe importanti). La Città ha anche `Mappa` e i `Simboli`.
  - `chapters/c3/scontrino.tscn`: lo scontrino che scende (`Carta`, `Testo`; nell'Inspector
    `durata_discesa`, `arrivo_y`, `altezza_riga`...).
  - `chapters/c6/specchio.tscn` (`Cornice`, `Vetro`, `Persone`: dove stanno i piedi; `scala_persone`),
    `chapters/c6/timbro.tscn`, `chapters/c6/finestra_torre.tscn`.
- **Il giocatore** è la scena `scripts/player.tscn`: `Ombra`, `Sprite` (l'`offset` è dove stanno i piedi;
  da seduto si abbassa partendo da lì), `Collisione` (i piedi) e `Camera` (lo `zoom` normale del gioco).
- Nell'Inspector della radice di ogni piano: `camera_lift` (di quanti pixel sale la visuale verso il
  muro in alto: lo usa il Sottoufficio), `camera_lift_riga`/`camera_lift_righe` (da che riga comincia a salire
  e in quante righe arriva in cima). Il Fondo ha anche `scossa_forza`, `scossa_colpo` e `scossa_durata`
  (quando crolla l'ascensore); il Sottoufficio `camera_spazio_sopra`.

## L'interfaccia

- **Il riquadro dei dialoghi e l'HUD** sono la scena `autoload/ui.tscn`: `Hud` (la riga in alto),
  `TurnoDiOggi`, `Riquadro` (con `Nome`, `Ritratto`, `Testo`), `Scelte` (con `Righe`), `Buio` (le
  dissolvenze) e `Narrazione` (il testo sul nero). Nell'Inspector della radice: `velocita_scrittura`,
  i colori della riga del turno, dove stanno le scelte (`angolo_scelte`, `altezza_riga_scelte`,
  `margine_scelte`) e lo `spazio_dopo_ritratto`. Le scelte si allargano da sole secondo le frasi.
- **La schermata del titolo** è `scenes/main_menu.tscn`: `Titolo`, `Sottotitolo`, `Voci`, `Persone`,
  `Crediti` e `SceltaNome` (nascosta: `Velo`, `Domanda`, `Campo`, `Ok`, `Risposta`).
- **I minigiochi**: in `scenes/minigame/work.tscn` (i turni) e `scenes/minigame/minigame.tscn` (gli aiuti)
  ci sono `Sfondo`, `Titolo` e `Info`; negli aiuti anche `TitoloPercorso` e `InfoPercorso` (quelli del
  gioco del percorso di Amir). Il gioco vero e proprio (la cassa, i telefoni, i fili...) è ancora
  disegnato dallo script.

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
