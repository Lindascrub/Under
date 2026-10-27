# Capitolo 3 — Il Mercato (piano -3)

**Durata:** 15-20 minuti. **Obiettivo:** il badge della Banca (-2), che costa 2.000 €.
**Tema:** il costo della vita. Guadagnare non vuol dire stare meglio.
**Sottotitolo:** "Qui puoi comprare tutto. Tranne quello che ti manca."

Questo documento è l'equivalente di `docs/CHAPTER_03_MARKET.md` chiesto dalla specifica: i capitoli
stanno tutti in `docs/capitoli/`.

## L'idea in una frase

Il Mercato è coloratissimo e in offerta perenne ("OGGI TUTTO AL 50%*", *rispetto al prezzo di domani).
Leda tiene aperto un negozio che le rende 20 € in quattordici ore, Amir è a una consegna dal bonus che
gli paga il treno per andare da sua sorella. Dopo il tuo primo turno i prezzi salgono. La paga no.

## La regola dei colori

Come ai piani di sotto: le persone vere sono **grigie** (Leda, Amir), il sistema è **colorato** (insegne,
tabellone, cassa, clienti, Nives). Il grigio non vuol dire "cattivo" o "perdente": è la vita vera sotto la
superficie commerciale. Se Amir viene robotizzato, ha lo shader del robot ed è immobile.

## La mappa (24x14 caselle, `chapters/c3/mercato.tscn`)

```
 +------------------------------------------------+
 | [OGGI TUTTO AL 50%*]   [TABELLONE PREZZI]      |  muro bianco da supermercato
 | CASSA  carrello acqua           Nives  scale↑ |  (21,3) → Banca
 |                          cestini di frutta     |
 | scaffali  lavagnetta   clienti                 |
 | bancone   Leda  carrello        pallet  Amir   |
 | frigo scale↓ frigo frigo stellina corsia  term.|
 +------------------------------------------------+
```

| Zona | Dove | Cosa c'è |
|---|---|---|
| Ingresso | in basso a sinistra (4,12) | le scale dal Sottoufficio; si arriva qui |
| TURNO — Cassa | in alto a sinistra (2-4, 4) | la cassa, il posto del TURNO (4,4) |
| Negozio di Leda | a sinistra, stesse piastrelle della piazza (1-6, 6-9) | due scaffali (5 prodotti), il bancone, la lavagnetta, Leda (5,8) |
| Piazza | al centro, piastrelle azzurre | distributore d'acqua (9,4), tabellone (sopra, 12-18: due immagini, prima e dopo, disegnate da `tools/make_art_mercato.py` coi prezzi di `data/market.json`), tre clienti, stellina (11,11), sportello badge (19,3: fuori dal tabellone, se no l'addetta non si vede). Niente carretto, teli o cassonetto |
| Supermercato | sparso in piazza, mai sui passaggi | tre frigo in fondo (1, 6, 8 sulla riga 12), una corsia di scaffali (13,12), cinque cestini di frutta (16-18 e 20-21, riga 6), due carrelli (6,5) e (8,9). Grafica LimeZu `assets/limezu/grocery/` (copiata da `tools/import_assets.ps1`). Niente insegna "DA LEDA" |
| Magazzino di Amir | in basso a destra, cemento (15-22, 8-12) | pallet, scatole, il terminale delle consegne (22,11), Amir (19,10) |
| Nives e l'uscita | in alto a destra | sportello badge (19,3), scale per la Banca (21,3) |

La scena si genera una volta con `tools/bake_c3_mercato.gd` (grafica nuova: `tools/make_art_mercato.py`), poi
si modifica nell'editor. La logica è in `chapters/c3/mercato_c3.gd`.

## I personaggi

| Chi | Com'è | Il suo aiuto |
|---|---|---|
| **Leda** (char_01) | Grembiule largo, matita dietro l'orecchio. Ironica, pratica, affettuosa senza essere ingenua. Il negozio era di sua madre. | **SCATOLE E SCAFFALI** |
| **Amir** (char_04) | Casco con gli adesivi, borsa enorme. Ironico, stanco, ama cucinare (solo il riso, ma benissimo). | **L'ULTIMA CONSEGNA** |
| **Nives** | L'addetta ai badge del -3. "Mi pagano per rispondere alla seconda domanda." | — |
| Altoparlante, Distributore, Cassa, Voce CHEAP | Il sistema che parla. Sempre allegro. | — |
| Tre clienti | Colorati, sorridono a tutto, anche al tabellone. | — |

## Le scene

| Scena | Quando | Cosa succede | Flag |
|---|---|---|---|
| 3.01 Arrivo | prima volta che entri | DING, l'altoparlante ("compatibilmente con il tuo saldo"), l'insegna dei saldi. Nives parla la prima volta che la tocchi; la seconda volta, la frase sul prezzo e il desiderio. | `c3_arrivo`, `c3_nives`, `c3_nives_prezzo` |
| 3.02 Distributore | toccando il distributore | Compra (10 €, poi 15), Lascia perdere, Chiedi perché ("pacchetto Curiosità Plus"). Una bottiglia sola per partita; senza soldi non si compra. | `c3_acqua` |
| 3.03 Leda | primo incontro | CRASH, tre risposte con la loro battuta, l'adesivo "piccolo commerciante indipendente", la lavagnetta (780 / 390 / 240 / 130 / **20**), "sono stata aperta quattordici ore". Poi chiede una mano. I cinque prodotti si guardano sugli scaffali. | `c3_leda` |
| 3.04 Scatole e scaffali | "Dai una mano" | Vedi Minigiochi. Si riprova finché riesce. Vinto: "Sei più bravo della macchina…", i biscotti in scadenza (oggetto vero, si mangiano dal menu). | `c3_leda_inventario` |
| 3.05 Amir | primo incontro | "Sembri uno che sa contare fino a tre", tre scatole per quattro consegne, il terminale 17/18, il treno per la sorella. | `c3_amir` |
| 3.06 L'ultima consegna | "Dai una mano" | Vedi Minigiochi. Tutto in tempo: "DICIOTTO!". A metà: aiutato, ma niente bonus (si riprova). Poi, tornando, il sogno (il riso). Se hai l'acqua puoi regalargliela. | `c3_amir_aiutato`, `c3_amir_bonus`, `c3_amir_sogno`, `c3_acqua_amir` |
| 3.07 TURNO: la cassa | al posto TURNO, una volta al giorno | Vedi Minigiochi. Primo turno: "Benvenuto, nuovo collaboratore!". | `c3_turni`, `c3_corretti`, `c3_accettati` |
| 3.08 Il capo | uscendo dal primo turno, una volta | "ECCOLO! Il mio cassiere preferito!", tre risposte, 1.500 € per il rapporto 018. Se hai aiutato Amir: "avete collaborato, perfetto!". Scelte: **Va bene** / **Ci penso** (l'offerta resta aperta sul terminale del magazzino) / **No** (chiusa per sempre). | `c3_capo`, `c3_capo_sospeso`, `c3_capo_chiuso` |
| 3.09 Un, due, tre, stella | al terminale, con l'offerta aperta | Il minigioco del furto di merito già esistente (`steal`), con Amir. Se ti vede: niente, l'offerta resta aperta. Se arrivi: il rapporto 018 e la scelta **Firma** / **Lascia il nome di Amir** / **Chiedi di dividere** ("Ahah! No.", si torna alla scelta). Si può chiudere l'offerta anche dal terminale. | `c3_furto_ok`, `c3_capo_firmato`, `c3_amir_rubato` |
| 3.10 I prezzi | entrando, dopo il primo turno e con l'offerta del capo chiusa (in un modo o nell'altro) | La musica si ferma, DING, il tabellone gira: pane 18→25, latte 24→32, acqua 10→15. "Guadagna di più!". Reazioni di Leda (aiutata o no) e di Amir (umano o robot). La paga del TURNO non cambia. | `c3_prezzi` |
| 3.11 Leda, la fattura | parlandole dopo i prezzi | +40, +35, +25. "Mi fanno pagare per vendere…". Perché non chiudi? (e, se l'hai aiutata, la madre). Scelte: aiutarla con 50 € / **ordini condivisi** (solo se hai fatto l'inventario: conosci il negozio e hai letto la fattura) / non posso permettermelo / non approfondire (si può tornare a parlarne). | `c3_leda_fattura`, `c3_leda_mamma`, `c3_leda_dono`, `c3_leda_ordini`, `c3_leda_seconda` |
| 3.12 Nives e il badge | allo sportello | Se hai aiutato Leda e Amir e Amir non è un robot: il badge "cade dal cassetto", gratis (soldi e debito restano uguali). Se no lo compri (2.000 €, a scalare dal debito). "I badge aprono le porte. Non garantiscono che dietro ci sia qualcosa di meglio." | `c3_badge` = `regalo` / `comprato` / `contratto` |
| 3.13 Lo scontrino | primo gradino, col badge | La musica sfuma, CLANK, lo scontrino lunghissimo (RIEPILOGO ECONOMICO, paga 120 €, pane 18 → 25, aumento retribuzione 0 €, RISULTATO: POSITIVO). "Il Mercato sta meglio." I rumori da giù (Leda e Amir). "Perché non sorridi?" | `c3_rivelazione`, `c3_riepilogo` |
| 3.14 Sguardo indietro | in cima alle scale | La stanza com'è diventata, la frase, poi CAPITOLO 4 / LA BANCA / "I tuoi soldi sono al sicuro. Il tuo futuro è ancora in verifica." Salvataggio automatico, poi la Banca. | `c3_fine`, `c3_esito` |
| Segreta | Amir umano, tutti e due aiutati, le loro storie sentite (il sogno, la madre) | Leda e Amir seduti su due cassette in piazza (11-12, 6, accanto al distributore; si parla toccando le cassette). Ti siedi sulla terza (13,6): ti rialzi muovendoti col panino ("Riso buonissimo." / "Io porterò il pane."). Ti puoi sedere con loro. Nessun premio. | `c3_segreta` |

Dopo lo scontrino, Leda e Amir dicono le frasi "reveal" di `data/npcs.json` (una volta).

## Minigiochi

### SCATOLE E SCAFFALI (Leda) — `minigame.gd`, type `inventory`
Un prodotto alla volta (pane, sapone, matita, riso, quaderno, scopa…) va su uno dei quattro scaffali:
ALIMENTARI, IGIENE, SCUOLA, CASA. Si **tocca** lo scaffale (o si clicca col mouse; tastiera: SINISTRA/DESTRA e OK).
8 prodotti, 35 secondi, 3 errori al massimo. Conta come aiuto **solo se riesce** (`help_on_win_only`).

### L'ULTIMA CONSEGNA (Amir) — `minigame.gd`, type `route`
Due giri, due mappe (`RT_MAPS`). Si tocca un incrocio vicino per andarci. Le strade grigie sono sicure; quelle
rosse a tratti passano dal cantiere: brevi, ma una volta su due c'è da girare intorno (+40).
- **Mattina**: sei incroci, tre pacchi (Scala B, Via dei Fiori, Piazza), 120 minuti. Strada sicura giusta:
  Scala B → Piazza → Via dei Fiori, 110 minuti.
- **Pomeriggio**: sette incroci, tre pacchi (Scuola, Via Roma, Ospedale), 150 minuti. Strada sicura giusta:
  Scuola → Via Roma → Ospedale, 140 minuti.
Finita la mattina (tutti i pacchi o niente più tempo) parte il pomeriggio. Sei su sei: bonus. Da uno a cinque:
"diciassette e mezzo", conta come aiuto ma senza bonus. Zero: si riprova.

### TURNO — La cassa — `work.gd`, game `cassa`
L'articolo arriva sul nastro col cartellino giallo dello scaffale. Lo **tocchi** (lo scanner fa BIP), lo schermo dice
il prezzo, poi **CONFERMA** o **CORREGGI**. Lo schermo costa più del cartellino (+3, +5 o +8 €) un articolo su quattro
al primo turno e più di uno su due dopo; il cliente lo fa notare. Correggere costa 1,4 secondi; confermare è istantaneo
e la cassa ti fa i complimenti, ma sullo schermo appare in rosso "+N € AL CLIENTE" e in alto si contano i
"Sovrapprezzi passati". **Errori** (rossi, contano e abbassano la paga): un articolo lasciato sul nastro, o
"correggere" un prezzo che era giusto. Il TURNO parte toccando la cassa (`PostoCassa` sulla cassa stessa).

## Economia e ricompense

Tutti i numeri sono in **un posto solo**:

| Cosa | Valore | Dove |
|---|---|---|
| Paga del TURNO | 120 € (fissa: niente moltiplicatore del piano) | `data/worklist.json`, `cassa_mercato.battle.pay` |
| Bonus massimo del TURNO | fino a 160 € (chi supera l'obiettivo) | `pay_max` |
| Durata del TURNO | 40 s; dal 4° turno "turno breve" di 24 s, stessa paga | `duration`, `short_duration`, `short_after` |
| Sovrapprezzi | dal 2° turno | `mismatch_from` |
| Prezzi prima/dopo | pane 18/25, latte 24/32, acqua 10/15, sogno 99, aria 35, tazza 12 | `data/market.json`, `prezzi` |
| Premio del capo | 1.500 € (una volta) | `data/market.json`, `premio_capo` |
| Aiuto a Leda | 50 € (una volta) | `data/market.json`, `donazione` |
| Badge per il -2 | 2.000 € | `FLOORS` in `autoload/game_state.gd` |

Leda e Amir non pagano chi li aiuta (non hanno soldi da dare: `fixed_reward`). Leda regala i biscotti.

**Attenzione: la salita onesta è lunga.** Con 120 € a turno, 2.000 € sono 13-17 turni (cioè 13-17 notti),
a meno di: badge regalato da Nives (aiutando tutti e due), premio del capo (1.500 €), contratto del Signor Rata.
Il turno breve dal 4° turno rende la ripetizione più leggera, ma i turni restano tanti. Vedi "Problemi aperti".

## Stato (flag in `GameState.flags`, salvati nel JSON)

La specifica proponeva `chapter_3.*`; il progetto usa flag piatti col prefisso del capitolo (`c1_`, `c2_`), quindi:

| Specifica | Flag |
|---|---|
| entered / completed | `c3_arrivo` / `c3_fine` |
| water.purchased / given_to_amir | `c3_acqua` / `c3_acqua_amir` (l'oggetto è "Acqua economica" nell'inventario) |
| turn.completed_count / price_mismatch_corrected / accepted | `c3_turni` / `c3_corretti` / `c3_accettati` |
| leda.met / inventory_helped / financial_problem_discovered / donation_given / shared_orders_proposed | `c3_leda` / `c3_leda_inventario` / `c3_leda_fattura` / `c3_leda_dono` / `c3_leda_ordini` (+ `c3_leda_mamma`, `c3_leda_seconda`) |
| amir.met / deliveries_helped / bonus_earned / dream_discovered / credit_stolen / robotized | `c3_amir` / `c3_amir_aiutato` / `c3_amir_bonus` / `c3_amir_sogno` / `c3_amir_rubato` / `GameState.is_robot("amir")` |
| boss.call_received / offer_resolved / offer_accepted | `c3_capo` / `c3_capo_chiuso` / `c3_capo_firmato` (+ `c3_capo_sospeso`, `c3_furto_ok`) |
| market.price_update_seen / economic_report_read | `c3_prezzi` / `c3_riepilogo` |
| secret_scene_seen | `c3_segreta` |
| exit.badge_obtained / badge_source / stairs_revelation_seen / lookback_seen | `GameState.has_badge("-2")` / `c3_badge` / `c3_rivelazione` / `c3_fine` |

Soldi, debito, LV, inventario, robot, tempo restano nel sistema generale (`GameState`).

**Integrità.** Ogni evento unico accende il suo flag *prima* di qualunque attesa, e ogni premio controlla il flag
prima di pagare (l'acqua, il premio del capo, il badge, i prezzi). Si salva solo alle stelline e allo sguardo
indietro, mai a metà dialogo. Le scelte rimaste a metà riprendono entrando nel Mercato: la firma al terminale
(`c3_furto_ok` senza `c3_capo_chiuso`), il sogno di Amir (`c3_amir_aiutato` senza `c3_amir_sogno`), l'aggiornamento
dei prezzi. I vecchi salvataggi non hanno flag `c3_`: il capitolo parte da capo.

## Conseguenze future (`GameState.flags["c3_esito"]`, scritto in cima alle scale)

```
{ "leda": "rete" | "aiutata" | "sola",  "leda_dono": bool,  "leda_credito": bool,
  "amir": "umano" | "robot",  "amir_sorella": bool,  "amir_simbolo": bool,
  "badge": "regalo" | "comprato" | "contratto",  "turni": n,  "sovrapprezzi": n,  "prezzi_aggiornati": bool }
```

- **Leda:** `leda_credito` (ha letto la fattura senza rete) → al Capitolo 4 può chiedere credito alla Banca;
  `leda: "rete"` → al Capitolo 5 gli ordini condivisi diventano una rete di negozianti; `leda_dono` → una spesa
  coperta, non tutti i problemi.
- **Amir:** `amir_sorella` → è andato dalla sorella (lo si può ritrovare dopo); `amir_simbolo` → la CHEAP lo usa come
  simbolo dell'efficienza; si può scoprire chi gestisce la robotizzazione.
- **Mercato:** `prezzi_aggiornati` e `sovrapprezzi` → i prezzi della Città (Capitolo 5).

Niente di questo è ancora usato: i capitoli 4-6 non sono rifatti.

## Lo sguardo indietro

La frase ha una priorità fissa (la prima vera vince):

1. Amir robot: "Il Mercato era più efficiente di quando eri arrivato."
2. Ordini condivisi: "Per la prima volta, qualcuno aveva smesso di fare i conti da solo."
3. Tutti e due aiutati: "Non avevi risolto i loro problemi. Almeno avevi imparato i loro nomi."
4. Uno solo: "Laggiù Leda (o Amir) ti saluta con la mano. Il Mercato non se n'era accorto. Lei (lui) sì."
5. Solo lavoro: "Il Mercato non aveva bisogno di sapere chi fossi per continuare a funzionare."
6. Niente: "Il Mercato continuava a vendere. Non aveva notato che eri passato. Nemmeno i prezzi."

Indipendentemente dalla frase, la stanza si mostra com'è: con gli ordini condivisi due negozianti grigi al bancone
di Leda; Leda non aiutata girata verso la lavagnetta; Amir col bonus non c'è (è al treno), senza bonus cammina
avanti e indietro, robot è immobile e i clienti si muovono il doppio più veloci.

## Uscita

Badge del -2 (comprato, regalato o col contratto) → primo gradino (scontrino) → in cima (sguardo indietro,
salvataggio) → la Banca (`scenes/world/banca.gd`, ancora la versione vecchia). Dalla Banca si scende al Mercato.

## Test e criteri di accettazione

Automatici in `tests/smoke_test.gd` (`_test_chapter3`) e `tests/touch_test.gd`:

- 9-10 si arriva dal Sottoufficio, alle scale; l'arrivo una volta. 11 Leda e Amir ci sono.
- 12 inventario sbagliato (non conta) e riprovato (conta, biscotti, niente euro). 13 consegne a metà e poi riuscite.
- 14-15, 23 la cassa paga 120 € una volta al giorno, anche dopo l'aumento dei prezzi. 16 il capo chiama una volta.
- 17, 19, 20 firma: 1.500 € una volta, LV +1, Amir robot con le sue frasi. 18 chiudere l'offerta non robotizza.
- 21-22 prezzi una volta, tabellone aggiornato. 24 ordini condivisi solo dopo inventario e fattura.
- 25-27 badge regalato (soldi e debito uguali), comprato con 2.000 € esatti, non con 1.999, mai due volte.
- 28-30 scontrino, frasi dello sguardo indietro, arrivo alla Banca, salvataggio. 31 scena segreta solo se tutto vero, una volta.
- 32-34 si finisce senza sfruttare, senza aiutare, o aiutando e poi sfruttando. 35 salva e ricarica.
- Economia: saldo zero e sotto i 10 € (acqua), 2.000 € esatti, 2.500 €, regalo, premio, rifiuto, due notti di interessi.
- Touch: scaffali, incroci, cassa (tocca l'articolo, CORREGGI, CONFERMA).

Da provare a mano: leggibilità dello scontrino e del tabellone sul telefono, il ritmo del turno, la scena segreta.

## Problemi aperti

- **Il grinding.** 120 € a turno contro un badge da 2.000 € (vedi Economia). Proposte: paga 200 €, oppure due turni
  al giorno, oppure badge del -2 a 1.200 €.
- La Banca è ancora quella vecchia (tre aspetti, porta in basso): il Capitolo 4 la rifarà.
- Il vecchio Mercato (Vito, Rosa, Ottavio, i tre aspetti asta/coda/scambi) è stato tolto: Vito, Rosa e Ottavio sono
  "nessuno" in `data/npcs.json` (restano i dati, per un eventuale riuso).
