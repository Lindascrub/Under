# Capitolo 5 — La Città (piano 0)

Il protagonista esce dalla Torre per la prima volta. Fuori c'è il cielo. C'è anche un cartellone:
"ANCHE IL CIELO HA UN LIMITE. SUPERALO CON PREMIUM." La Casa Comune sta per chiudere, la gente protesta,
e alla fine, dal primo gradino delle scale verso la Cima, si vede che i quattro piani di sotto
erano pezzi della stessa città.

Questo capitolo è stato **rifatto da zero**. La versione precedente (di Codex) è conservata fuori dal progetto,
in `C:/Users/linda/Documents/app/play/cheap_c5_codex_backup/`. Non è usata.

## File

| File | Cosa contiene |
|---|---|
| `chapters/c5/citta.tscn` | La piazza (42x21 caselle). **Generata** da `tools/bake_c5_citta.gd`: non modificarla a mano, rilancia il bake |
| `chapters/c5/citta_c5.gd` | Tutta la logica della piazza: scene 5.01-5.18, assemblea, esiti, badge, rivelazione, scena segreta |
| `chapters/c5/casa_comune.tscn` | La Casa Comune e la stanza dei bilanci. Generata da `tools/bake_c5_casa_comune.gd` |
| `chapters/c5/casa_comune_c5.gd` | Ada, la lettera di CHEAP, la bacheca, i bilanci, il documento nascosto, il contatore |
| `world/tilesets/citta.tres` | Il tileset della città (marciapiede, asfalto, fermata, aiuole: fogli LimeZu) |
| `data/city.json` | Tutti i numeri del capitolo: stanze, percorso, smistamento, bilanci, premio del capo, turno rapido |
| `data/npcs.json` | Ada (`char_19`), Nadir (`char_02`), Rina (`char_16`) |
| `data/promotions.json` | `ada`: "La proposta di riutilizzo della Casa Comune" |
| `data/worklist.json` | Il TURNO `comunicazioni_citta` (gioco `smistamento`) |
| `scenes/minigame/minigame.gd` | I minigiochi d'aiuto `stanze` (Ada) e `percorso` (Nadir) |
| `scenes/minigame/work.gd` | Il TURNO `smistamento` (il centralino) |
| `tools/make_placeholders_citta.py` | I segnaposto grafici (`art/c5/`), elenco in `docs/ASSET_LIST.md` |
| `tools/make_sfx_citta.py` | `audio/crash.wav`, `thump.wav`, `crack.wav`, `music_citta.wav` (segnaposto) |

Modifiche ai sistemi condivisi, tutte piccole e compatibili con i capitoli 1-4:
- `scripts/npc.gd`: un robot può avere una battuta speciale della stanza (`robot_talk_<id>`).
- `world/editor_room.gd`: `look_back` accetta un prologo (righe su nero prima del titolo del capitolo).
- `autoload/router.gd`: `CASA_COMUNE`, e `CITY` punta a `chapters/c5/citta.tscn`.

## Mappa

```
 cielo (si vede solo all'arrivo: la camera sale)
 ┌──────────┬──────────────┬────────────────┬─────────┬──────────────┐
 │  TORRE   │ CASA COMUNE  │ COMUNICAZIONI  │CARTELLONE│ BOTTEGA RINA │
 │ porta,   │ avviso,      │ TURNO (23,10)  │ PREMIUM │ vetrina      │
 │ Nives(6,9)│ volantini   │ presentazioni  │         │ Rina (31,11) │
 │ scale(9,9)│ porta(17,10)│  (26,11)       │         │              │
 ├──────────┴──────────────┴────────────────┴─────────┴──────────────┤
 │  strada (righe 12-13)          fermata del bus (22,12)            │
 ├───────────────────────────────────────────────────────────────────┤
 │ albero(3,17) panchina(6,18)  ★(13,16)  fontana(18,18)  Nadir(24,15)│
 │                                         tabellone (21,15)          │
 └───────────────────────────────────────────────────────────────────┘
```

- **Arrivi:** `default` (3,11) dalle scale della Banca, `from_below` (3,10), `from_casa` (17,10).
- **Uscite:** in basso a sinistra si torna alla Banca; la porta (17,10) porta alla Casa Comune;
  le scale (9,9) portano alla Cima (serve il badge "cima").
- **Casa Comune** (22x13): la sala a sinistra (librerie, tavoli, bacheca, Ada), l'archivio a destra
  (terminale dei bilanci, armadio dei documenti, contatore). La porta dell'archivio (14,7) si apre
  quando comincia la manifestazione.

## Personaggi

| Chi | Dove | Cosa vuole | Aiuto |
|---|---|---|---|
| **Ada** | Casa Comune | Tenere aperta la Casa: è l'unico posto dove si studia, si ripara, ci si incontra gratis | UNA STANZA PER TUTTI |
| **Nadir** | fermata | Arrivare al lavoro in tempo con 6 € al giorno; guarda gli uccelli | IL PERCORSO POSSIBILE |
| **Rina** | bottega | Che la vetrina resti intera; ha paura della protesta e della Casa che chiude | un'ora del tuo tempo (il cartone) |
| **Nives** | banco dei badge | Vende l'ultimo badge (8.000 €). Se hai aiutato tutti, lo "perde" | — |
| Il capo | telefono | Il progetto di Ada, con il tuo nome sopra | — |

Ospiti dai capitoli prima, **solo se li hai conosciuti**: Leda (ordini condivisi), Amir (consegne;
se è robot fa il corriere CHEAP), Olga (racconta la banca), Teo (legge i conti; se è robot timbra).

## Scene

| Scena | Dove | Cosa succede | Flag |
|---|---|---|---|
| 5.01 L'uscita | piazza | La camera sale al cielo, il cartellone lampeggia, l'altoparlante parla. L'albero: tre battute diverse | `c5_arrivo` |
| 5.02 Ada | Casa Comune | "Sei alto?" THUMP. La Casa, cosa si fa lì, cosa manca | `c5_ada`, `c5_casa` |
| 5.03 Minigioco di Ada | Casa Comune | UNA STANZA PER TUTTI (vedi sotto) | `c5_ada_stanze`, `c5_stanze` |
| 5.04 La proposta CHEAP | Casa Comune, tavolo | La lettera rosa: ristrutturazione, tornello, "centro di formazione" | `c5_lettera`, `c5_ada_vorrebbe` |
| 5.05 Nadir | fermata | Il tabellone dice 6 minuti, poi 9, poi 14. Lavoro, cambiare, uccelli | `c5_nadir` |
| 5.06 Minigioco di Nadir | fermata | IL PERCORSO POSSIBILE | `c5_nadir_percorso`, `c5_nadir_tratta` |
| 5.07 Rina | bottega | "Non toccare quella." Le preoccupazioni; la domanda sulla Casa Comune | `c5_rina`, `c5_rina_ascoltata` |
| 5.08 TURNO | Comunicazioni | Il centralino (vedi sotto). Dal 3° turno c'è il turno rapido | `c5_turni`, `c5_rapidi` |
| 5.09 Il capo | telefono, dopo il 1° turno | "Il progetto di Ada. Il tuo nome. 6.000 €." Sì / No, è di Ada / Ci penso | `c5_capo`, `c5_capo_chiuso` |
| 5.10 Un, due, tre, stella | sala presentazioni | Solo se hai detto sì. Al terminale: firma / lascia il nome di Ada / leggi prima | `c5_furto_ok`, `c5_progetto_letto`, `c5_capo_firmato` |
| 5.11 La manifestazione | piazza | Il giorno dopo il turno (o subito, se il capo è chiuso). Persone diverse, opinioni diverse | `c5_protesta` |
| 5.12 Tre proposte | piazza | A ristrutturazione CHEAP, B gestione comunitaria, C rinvio, o nessuna | `c5_proposta` |
| 5.13 La vetrina | bottega | CRASH. Rina, il manifestante, il giornalista | `c5_vetrina`, `c5_giornalista`, `c5_dichiarazione` |
| La notizia | piazza | Il titolo del giorno dopo dipende da chi ha parlato col giornalista, non da cosa inventa | `c5_titolo` |
| 5.14 I bilanci | archivio | I conti veri, le note, il documento nascosto, i collegamenti coi piani di sotto | `c5_rapporto`, `c5_documento` |
| 5.15 L'assemblea | piazza | Presentare i conti, chi mette cosa, il voto | `c5_assemblea`, `c5_sostegno`, `c5_esito` |
| 5.16 L'ultimo badge | Nives | Comprarlo, o trovarlo per terra | `c5_badge` |
| 5.17 La rivelazione | primo gradino | La mappa, i quattro simboli (energia, amministrazione, commercio, finanza), la voce | `c5_rivelazione` |
| 5.18 Lo sguardo indietro | scale | La piazza vista dall'alto, una riga per l'esito; poi "CAPITOLO 6 — LA CIMA" | `chapter_5` |
| Segreta | panchina | Ada, Rina e Nadir sulla panchina, i biscotti, la PANCA PREMIUM | `c5_segreta` |

### Ordine e blocchi

Niente è obbligatorio tranne un TURNO: la manifestazione parte dopo almeno un turno, il giorno dopo
(o subito se l'offerta del capo è già chiusa). Se l'offerta è ancora "ci penso", la manifestazione la chiude da sola:
la presentazione è passata. Ada, Nadir e Rina si possono non conoscere mai: la manifestazione e l'assemblea
funzionano lo stesso (se Ada è robot, organizza uno studente).

## Minigiochi

### UNA STANZA PER TUTTI (Ada, `type: "stanze"`)
Sei mobili (2 tavoli, 2 scaffali, 2 gruppi di sedie), tre stanze (studio, laboratorio, incontri), 3 posti per stanza.
Tocca un mobile, poi una stanza; tocca un mobile già messo per riportarlo nel vassoio. FATTO controlla:
va bene **ogni** distribuzione in cui ogni stanza ha il mobile che le serve. Nessuna è "quella giusta":
i mobili in più cambiano una riga del risultato (dove si studia meglio, dove si lavora stretti).
Tre errori = fallito, si può riprovare.

### IL PERCORSO POSSIBILE (Nadir, `type: "percorso"`)
Da casa di Nadir alla zona industriale, tratta dopo tratta. Si entra alle 8:00, si hanno 6 €.
Il percorso economico (bus 12 + bus 30) arriva tardi; il veloce (bus 4 + navetta Premium) costa 10 €;
l'unico valido è il compromesso (bus 4 + treno, 6 € esatti). Il gioco non lo dice: lo si trova.

### Il centralino (TURNO, `game: "smistamento"`)
Arrivano richieste dei cittadini: toccare la destinazione giusta. Dopo le prime quattro, una su tre arriva con
una destinazione "proposta dal sistema" sbagliata: CONFERMA (veloce, non conta come errore tuo),
VERIFICA (lenta, la richiesta arriva dove deve), SEGNALA (ferma la richiesta). CHEAP paga le richieste chiuse.
Il conteggio delle discrepanze trovate va nei bilanci e nel riepilogo.

## L'assemblea e gli esiti

Nessun punteggio: regole esplicite in `citta_c5.gd`, `outcome()`.

**Pronta** = i conti sono stati presentati (`c5_rapporto_presentato`) + le stanze sono organizzate
(`c5_ada_stanze`, vale anche se poi Ada è diventata robot) + almeno **due risorse vere**
(la rete dei pendolari di Nadir, la bottega di Rina come punto di raccolta, gli ordini condivisi di Leda,
le consegne di Amir umano).

| # | Condizione | Esito |
|---|---|---|
| 1 | pronta, e non sostieni A | gestione comunitaria (fragile: mancano ancora soldi, ma c'è un foglio con dei nomi) |
| 2 | pronta, ma sostieni A | rinvio (l'assemblea si divide) |
| 3 | sostieni A | riconversione CHEAP |
| 4 | CHEAP ha il progetto di Ada e nessuno ha i conti | riconversione |
| 5 | ci sono i conti, o chiedi tempo (C), o Ada è umana | rinvio |
| 6 | altrimenti | riconversione (era l'unica proposta con dei soldi) |

L'esito cambia l'avviso sulla porta, la piazza nello sguardo indietro, la frase finale. Non decide il finale del gioco.

## I bilanci

In `data/city.json`, `bilanci`: manutenzione 42.000, canone CHEAP 19.000 (era 7.000), oneri 11.000, entrate 28.000.
Il deficit è 44.000 €, e il canone pagato a CHEAP è passato da 7.000 a 19.000 €. Il documento nascosto
(nell'armadio, solo dopo aver letto i conti) è una "valutazione opportunità" di CHEAP: chiudere le attività gratuite
aumenta il valore dell'immobile. Nessun complotto: lo stesso conto, visto dall'altra parte del tavolo.
Collegamenti coi piani di sotto, se li hai vissuti: il contatore (capitolo 1), la cartella B-4 (capitolo 2),
la copia dei conti fatta da Teo (capitolo 4).

## Badge ed economia

| Valore | Numero |
|---|---|
| Badge della Cima | 8.000 € |
| TURNO (centralino) | 1.600 € (fino a 2.000 € se vai veloce), paga fissa |
| Turno rapido | dal 3° turno, 1.600 € senza minigioco (30 s di gioco in meno) |
| Premio del capo | 6.000 €, una volta, solo firmando |
| Aiutare Rina | costa un'ora, non paga |

**Badge regalato** (Nives lo "perde"): Ada aiutata nelle stanze, Nadir aiutato nel percorso, Rina ascoltata,
Ada non robot. Non serve un esito dell'assemblea. Non tocca saldo né debito. Si può avere una volta sola,
come quello comprato.

### Simulazioni (verificate dai test dove indicato)

| Percorso | Come | Risultato |
|---|---|---|
| A — solo lavoro | da 0 €, si rifiuta il capo | 5 turni = 8.000 € (**testato**) |
| B — aiuto | Ada, Nadir, Rina aiutati, Ada umana | badge regalato, 1 turno (per la manifestazione) (**testato**) |
| C — sfruttamento | si firma | 6.000 € + 2 turni; Ada robot; la manifestazione c'è comunque (**testato**, insieme a D) |
| D — misto | aiuti Ada e poi le rubi il progetto | le stanze restano fatte, Ada diventa robot, niente regalo; 6.000 € + turni (**testato**) |
| E — saldo zero | si entra con 0 € | come A: 5 turni, niente blocchi (**testato**: il test A parte da 0 €) |
| F — condizioni pregresse | Amir/Teo umani o robot, Leda, Olga | gli ospiti compaiono solo se conosciuti; Amir/Teo robot hanno righe e antenna loro (**testato** in parte: ospiti presenti/assenti e Amir robot; Teo robot e "nessuna liberazione precedente" verificati solo leggendo il codice) |

## Flag e persistenza

Durante il capitolo si usano flag `c5_*` in `GameState.flags` (salvati con le stelline come tutto il resto).
Alla fine, sulle scale, `_write_outcome()` scrive un riepilogo in `flags["chapter_5"]` con lo schema della specifica:
`entered, completed, ada{...}, nadir{...}, rina{...}, turn{...}, boss{...}, protest{...}, report{...},
secret_scene_seen, exit{...}`. Denaro, debito, LV, giorno e robot **non** sono duplicati: restano in `GameState`.

Scene uniche (arrivo, telefonata, manifestazione, vetrina, assemblea, regalo, segreta) controllano il loro flag
prima di partire, anche dopo un caricamento. I vecchi salvataggi non hanno flag `c5_*`: valgono tutti "falso".

## Test

- `tests/smoke_test.gd`, `_test_chapter5()`: 72 controlli. Arrivo dalla Banca; Rina; Nadir e il percorso
  (sbagliare e riprovare); Ada, stanze e lettera; TURNO, capo rifiutato, manifestazione, proposte, vetrina;
  la notizia; gli ospiti; bilanci e documento; l'assemblea (comunitaria); la scena segreta (una volta);
  il badge regalato (una volta, saldo invariato); rivelazione, sguardo indietro, riepilogo, capitolo 6;
  percorso D; badge comprato a 8.000 € esatti; "Ci penso" che scade; le regole dell'assemblea; economia A da zero.
- `tests/touch_test.gd`: stanze (stanza piena, errore, completamento), percorso (tratta che non parte,
  troppo tardi, troppo caro, compromesso), centralino (destinazione sbagliata, VERIFICA, CONFERMA).
- I capitoli 1-4 restano nello stesso smoke test e passano.

## Limitazioni

- **Grafica e suoni sono segnaposto** (`art/c5/`, `audio/crash|thump|crack|music_citta.wav`). Elenco in `docs/ASSET_LIST.md`.
- Le scale portano alla Cima del capitolo 6 (`chapters/c6/cima.tscn`, vedi `docs/CHAPTER_06_SUMMIT.md`).
- Il riepilogo `chapter_5` viene scritto solo alla fine del capitolo; durante il gioco valgono i flag `c5_*`.
- Non è stato provato a mano su telefono: solo test automatici e screenshot su PC.
