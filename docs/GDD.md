# CHEAP — Documento di design

> **28/10/2026 — Incarichi del Capo implementati:** per le nuove partite le missioni di furto ripetute sono sostituite da energia, pratiche, etichette, contratti e montaggio del notiziario; alla Cima le pressioni entrano nei tre bilanci esistenti. Alternative realmente giocabili, conseguenze persistenti, premi una sola volta, nessuna nuova robotizzazione. Il vecchio furto ("un, due, tre, stella") resta solo per i salvataggi che lo avevano già aperto. Regole in `scripts/boss_missions.gd`.

> Nives annuncia l'arrivo, usa una musica dedicata e viene seguita dalla camera; lo sportello si usa lungo il bancone. Nel Fondo la CycletteDinamo originale è condivisa col minigioco, la biglietteria ha pavimento beige LimeZu, divisorio sottile, ritorno di muro all'ingresso e pilastro separato dalle scale. Ascensore esistente con porte originali e stipite; sei telecamere originali nei luoghi di lavoro. Le versioni precedenti sono nella cronologia di git.

> Aggiornato il 5/11/2026: tolti le battaglie, la città vecchia (strada, parco, ufficio, casa), i suoi
> personaggi e le sue missioni, i vecchi finali e i minigiochi che nessun piano usava più.
> Le regole attuali sono in [COHERENCE.md](COHERENCE.md). I capitoli hanno il loro documento in
> [capitoli/](capitoli/) e nei file CHAPTER_*.

## L'idea in una frase

Un RPG narrativo in pixel art, per telefono in orizzontale, in cui il protagonista, schiacciato da un
debito di 7 miliardi, sale la Torre CHEAP un piano alla volta. La Torre promette che, lavorando
abbastanza, un giorno sarà libero. Salendo scopre che i problemi della Torre non sono solo persone
cattive, ma regole, incentivi e gerarchie che spingono tutti, lui compreso, a fare certe scelte.

**La domanda del gioco:** se passi tutta la vita a guadagnarti il diritto di vivere, quando inizi a vivere davvero?

## Tono

Divertente, surreale, a tratti assurdo all'inizio; poi, piano dopo piano, sempre più inquietante.
La critica non è mai una lezione: viene fuori dalle meccaniche e dalle conseguenze.
Il gioco non giudica mentre giochi. Alla fine non dà un voto: fa vedere cosa è successo.

## La Torre a piani

All'inizio sei nell'ascensore della Torre e scendi. Al piano -5 l'ascensore si rompe. Da lì si sale a piedi.

| Cap. | Piano | Posto | Tema | Badge per salire | Stato |
|---|---|---|---|---|---|
| 1 | -5 | Il Fondo | La festa finta | 500 € (per il -4) | **Rifatto** (`chapters/c1/`) |
| 2 | -4 | Il Sottoufficio | La burocrazia infinita | 1.000 € (per il -3) | **Rifatto** (`chapters/c2/`) |
| 3 | -3 | Il Mercato | Caro vita, salari e prezzi | 2.000 € (per il -2) | **Rifatto** (`chapters/c3/`) |
| 4 | -2 | La Banca | Debito e dipendenza | 4.000 € (per il piano terra) | **Rifatto** (`chapters/c4/`), [documento](CHAPTER_04_BANK.md) |
| 5 | 0 | La Città | Le conseguenze fuori dalla Torre | 8.000 € (per la Cima) | **Rifatto** (`chapters/c5/`), [documento](CHAPTER_05_CITY.md) |
| 6 | Cima | La Presidenza | Potere, responsabilità, libertà | — (finale) | **Rifatto** (`chapters/c6/`), [documento](CHAPTER_06_SUMMIT.md), [finali](ENDING_SYSTEM.md) |

I soldi del badge vanno tutti a scalare dal **debito nominale**. Ogni notte gli interessi lo fanno risalire.
Il debito non si ripaga lavorando, e non deve: l'obiettivo è salire, e capire.

## Il ciclo di ogni piano

1. **TURNO.** Sopra al posto di lavoro c'è la scritta TURNO: gialla finché devi lavorare, grigia dopo.
   Il turno è un minigioco a tocco (uno al giorno). Paga.
2. **Le persone vere.** Sono grigie. Si conoscono parlando e si aiutano con un minigioco.
   Il sistema (sportelli, venditori, capi, macchine) è colorato, in modo artificiale.
3. **Il capo chiama** dopo il turno, **una volta per piano**: propone di prenderti il merito del lavoro di
   qualcuno del piano, con "un, due, tre, stella". Si può sempre rifiutare.
4. **Chi viene sfruttato diventa un robot sorridente.** Per sempre: stessa faccia, frasi aziendali, non respira.
5. **Il badge** del piano di sopra si compra allo sportello di Nives (che è uguale su ogni piano).
   Se hai aiutato davvero tutte le persone del piano, Nives te lo regala.
   Ogni piano può avere una condizione in più (al -4: il Modulo B-4).
6. **Il primo gradino:** la rivelazione del piano.
7. **In cima alle scale ti volti:** la telecamera mostra la stanza com'è diventata, compare una frase sola
   che dipende da cosa hai fatto, poi il titolo del capitolo dopo.
8. **Le stelline** salvano e fanno passare la notte. Ogni notte: interessi.

Alla Cima il ciclo cambia: niente scale, niente badge, niente paga. Un solo TURNO di Direzione con bilancio,
Casa Comune e regola dei debiti, poi l'ultima
telefonata del Capo, la scelta finale (vedi [CHAPTER_06_SUMMIT](CHAPTER_06_SUMMIT.md)).

### La regola dei colori

- Persone vere: grigie (al Fondo Fermo ha anche un alone scuro).
  Ognuna col suo personaggio (Character Generator), in un grigio sbiadito ma riconoscibile, un po' più caldo
  o più freddo, e con un gesto suo quando sta ferma. Chi diventa robot li perde. Dati in `data/looks.json`, codice in `scripts/looks.gd`.
- Sistema: colorato e finto. Il capo è il più colorato di tutti (il suo ritratto cambia colore).
- Robot: sorridenti, colorati come i poster.

### Le scale sbarrate

Se al Fondo sali senza esserti voltato verso nessuno, le scale per il Fondo vengono chiuse (coni,
nastro, cartello VIETATO, al -4). Al Fondo non si torna più.

## Musica

Canzoni vere (due pacchetti in `../music/`, estratti in `assets/music/` da `tools/import_music.py`, esclusi da git).
Ogni piano ha una scaletta di 3-4 canzoni: finita una ne parte un'altra, mai la stessa due volte di fila
(`autoload/sound.gd`, `PLAYLISTS`). Elenco e licenze da controllare: `docs/ASSET_LIST.md`.

## Comandi

Il gioco è pensato per telefono in orizzontale.
- **Nel mondo:** joystick e pulsanti a schermo.
- **Nei minigiochi:** si gioca direttamente sullo schermo (tocca, tieni giù, scorri, trascina).
  Le istruzioni dicono "tocca", mai "premi".
- **Su PC:** frecce, Invio/Z, X/Shift (Esc due volte chiude il gioco).
- **Dialoghi:** le frasi lunghe vanno a pagine; un tocco mostra subito tutta la frase, un altro va avanti.
- **In alto:** la barra con piano, ora, debito ("7,00 mld €"), soldi, energia, autostima.
- **La telecamera** resta sempre dentro i muri: il giocatore non deve mai vedere il "fuori mappa".

## Economia

### Valori attuali (in `autoload/game_state.gd`)

| Valore | Numero |
|---|---|
| Debito iniziale | 7.000.000.000 € |
| Interessi | 2% a notte (+0,5% per ogni contratto col Signor Rata) |
| Badge | 500 / 1.000 / 2.000 / 4.000 / 8.000 € (raddoppia a ogni piano) |
| Paga del turno | paga del lavoro (200-320 €) × (1 + 0,1 × piano) × quanto bene hai lavorato (minimo 40 €) |
| Paga della cassa al -3 | 120 € fissi (fino a 160 € se vai più veloce dell'obiettivo), in `data/worklist.json` |
| Prezzi del Mercato | pane 18 → 25, latte 24 → 32, acqua 10 → 15, in `data/market.json` |
| Premio del capo al -3 | 1.500 € (il merito di Amir), una volta |
| Paga dello sportello al -2 | 800 € (fino a 1.000 €); dal 3° turno anche le "pratiche raggruppate" (800 €, senza minigioco) |
| Premio del capo al -2 | 3.000 € (il rapporto 404 di Teo), una volta |
| Paga del centralino al piano 0 | 1.600 € (fino a 2.000 €); dal 3° turno anche il turno rapido (1.600 €, senza minigioco). 5 turni per il badge della Cima |
| Premio del capo al piano 0 | 6.000 € (il progetto di Ada), una volta |
| TURNO di Direzione alla Cima | Non paga. Un turno: 100 unità fra stipendi, servizi, manutenzione e riserve; poi Casa Comune e regola dei debiti nello stesso schermo. Regole in `chapters/c6/direzione_regole.gd` |
| Debito personale | Si annulla solo con il finale A, una volta; B e C lo contestano o lo mettono in revisione se ci sono prove |
| Promozione (sfruttare) | 900 € × 1,7 per ogni sfruttamento precedente |
| Aiutare qualcuno | 10 € (almeno 1/8 del badge di sopra) e +1 autostima la prima volta; Leda e Amir non pagano (biscotti, gratitudine) |
| Straordinario al Fondo | 120, 70, 35 € (tre volte al massimo) |
| Procedura d'urgenza al -4 | 300 € |

### Il problema da risolvere: la salita onesta è troppo lunga

Con i valori attuali, salire fino alla Cima senza sfruttare nessuno chiede circa **42 turni**
(il badge raddoppia, la paga sale solo del 10% a piano). Troppi.
La proposta era di far crescere la paga piano per piano
e introdurre, dal Mercato, il **costo della vita**: guadagni di più, ma spendi di più. È il tema del capitolo 3,
e porta la salita onesta a circa **19 turni** (meno se aiuti tutti e Nives ti regala il badge).

**Capitolo 3, com'è adesso:** la specifica ha fissato la cassa a 120 € a turno. Per i 2.000 € del badge servono
13-17 turni, a meno del badge regalato (Leda e Amir aiutati), del premio del capo o del contratto. Dal 4° turno
il turno è più breve (24 s), ma resta da decidere se alzare la paga: vedi `docs/capitoli/capitolo_3_il_mercato.md`.

### Pietà e contratti

Dopo tre giorni di seguito di turni falliti, qualcuno del piano ha pena di te e ti dà i soldi che mancano
(al -4 la Signora Agenda, al -3 Vito, che ormai si vede solo in questa scena). Oppure il Signor Rata ti dà il badge subito, se firmi:
il prezzo, più la metà, va sul debito, e gli interessi salgono.

## La meccanica dei robot

Chi viene sfruttato (la promozione del capo) viene sostituito da un robot:
stessa faccia e stesso posto, frasi aziendali che ti chiamano per titolo, nessun respiro.
Ogni sfruttamento fa salire il **LV** (come in Undertale, qui è "level of violence"): la promozione è il level up.
Nel finale `shaders/robot.gdshader` rivela tutti i robot.

Le promozioni per piano sono in `data/promotions.json` (Fermo, Tilde, Amir, Teo, Ada).

## Minigiochi

### I turni (TURNO), in `scenes/minigame/work.gd`

| Piano | Lavoro | Come si gioca col dito |
|---|---|---|
| -5 | Cyclette (la dinamo) | Tocca a sinistra e a destra, alternando, per restare nel verde |
| -4 | Call center | Tocca il telefono che squilla, poi la risposta: copione (paga), sincera (autostima), sgarbata (errore). Finale: squillano tutti |
| -3 | La cassa | Tocca l'articolo, poi CONFERMA o CORREGGI il prezzo (dal 2° turno lo schermo a volte chiede più del cartellino) |
| -2 | Lo sportello | Leggi la pratica, poi APPROVA (subito) o RICHIEDI VERIFICA (più lento). CHEAP paga le pratiche chiuse, non quelle giuste |
| 0 | Il centralino | Tocca la destinazione della richiesta. A volte il sistema ne propone una sbagliata: CONFERMA (veloce), VERIFICA (lenta, giusta) o SEGNALA |
| Cima | TURNO di Direzione (il bilancio) | Tocca più e meno sulle quattro voci, poi CONFERMA (solo a 100 unità); REGOLE mostra tutte le regole |

Il turno è sempre un minigioco. I lavori dei turni sono in `data/worklist.json`.

### L'aiuto alle persone, in `scenes/minigame/minigame.gd`

| Tipo | Come si gioca col dito | Chi |
|---|---|---|
| Lampadine | Scorri a destra (buona), a sinistra (rotta), su e giù (avvita) | Bulbo |
| Fili | Tocca un filo a sinistra, poi il suo posto a destra | Mina |
| Sequenza | Guarda le frecce, poi ripetile | Tilde (il copione), Ines (le pratiche) |
| Tempismo | Tocca quando il segno è nel verde | Ottavio (l'ombrello), Sandro (il lucchetto) |
| Tieni sveglio Ercole | Due fasce che si accendono a turno: vale solo quella accesa | Ercole |
| Raccolta | Trascina il cuore e raccogli tutto | Rosa (la frutta) |
| Scatole e scaffali | Tocca lo scaffale giusto (alimentari, igiene, scuola, casa) | Leda |
| L'ultima consegna | Guida il furgone come uno snake: raccogli sei pacchi e portali alle case illuminate senza urtare ostacoli o la tua coda | Amir |
| Le rate mancanti | Tocca i 6 documenti dal più vecchio, poi la voce doppia dell'estratto conto | Olga |
| La pratica impossibile | Per ogni pratica tocca il problema: in ordine, manca un documento, dati diversi, doppione, errore di registrazione | Teo |
| Volantinaggio | In piazza passa la gente: dai il volantino a chi ti guarda, non a chi ha fretta, è al telefono o è una guardia CHEAP | Ada |
| L'orario delle coincidenze | Trascina il dito da una fermata all'altra lungo una linea: Nadir deve arrivare al lavoro in orario e nel budget | Nadir |

### Un, due, tre, stella (il furto di merito), in `scenes/minigame/arcade.gd`

Tieni il dito giù per avvicinarti mentre il capo ti dà le spalle, e ancora per copiare. Quando si gira, stacca il dito.
Al -3 la vittima è Amir, al -2 Teo (il rapporto 404), al piano 0 Ada (il progetto della Casa Comune): il furto non promuove subito, arrivato al terminale scegli se firmare (`win_flag` in `start_steal`).

## Salvataggi

Le stelline salvano stanza, posizione, ora e tutte le scelte (`user://cheap_save.json`), e possono
far passare la notte. Si salva tutto lo stato di `GameState` (soldi, debito, badge, robot, aiutati, liberati,
flag).

Le regole globali (debito, badge, robot, notte) sono fissate in [COHERENCE](COHERENCE.md).

## I finali

Le vecchie tre strade (capitalismo, comunismo, baratto) e i finali Ricco/Ribelle/Onesto sono stati tolti.
Al loro posto ci sono tre **tendenze**, che non si vedono mai durante il gioco e non decidono da sole il finale:

- **Ascesa** (potere e compromessi): dirigente opportunista, oppure qualcuno che prova a cambiare il sistema da dentro.
- **Sopravvivenza** (il tempo che scompare): si continua a vivere e lavorare; quello che resta sono le relazioni e i sogni conservati o persi.
- **Solidarietà** (la libertà collettiva): una comunità che deve trovare cibo, case, servizi e decidere insieme. Può funzionare, restare fragile o fallire.

**Come sono fatti davvero (capitolo 6):** la scelta al tavolo della Cima decide la famiglia
(A PRENDERE LA DIREZIONE, B IL TEMPO CHE RESTA, C NESSUNO SALE DA SOLO); la variante (A1/A2/A3, B1/B2, C1/C2/C3) dipende da fatti
contati: legami, reti, prove, il bilancio del turno, l'attribuzione del Capo. Una funzione sola,
`chapters/c6/finali.gd`, `decide()`. Condizioni esatte: [ENDING_SYSTEM](ENDING_SYSTEM.md).
Poi gli epiloghi "sei mesi dopo" piano per piano (solo le persone conosciute, Nives per ultima), il sogno,
e CHEAP / Quanto costa una vita? / FINE.

## Struttura del codice

```
autoload/      singleton sempre attivi
  game_state   soldi, debito, badge, scelte, flag, finali, salvataggio
  ui           barra in alto, dialoghi (a pagine), scelte, dissolvenze, testo narrato
  router       cambio scena con dissolvenza
  touch_controls  joystick, pulsanti e gesti dei minigiochi
  sound        musica e suoni (la voce dei dialoghi ha un canale suo)
chapters/      i capitoli rifatti: c1/ (Fondo), c2/ (Sottoufficio), c3/ (Mercato), c4/ (Banca), c5/ (Città), c6/ (Cima, Direzione, finali). Scena .tscn + script di logica
world/         EditorRoom (stanze fatte nell'editor), RoomFeature, NpcSpot, Examine, CharSprite, tileset
scripts/       Room (base di tutte le stanze), Player, Npc, Assets, boss_missions, storia
scenes/        main_menu, minigame/ (turni, aiuti, furto)
data/          testi e dati (JSON): persone (npcs), promozioni, lavori dei turni (worklist), market (prezzi del -3), bank (documenti e pratiche del -2), city (la Città)
art/           grafica fatta apposta: per ora segnaposto, elenco in docs/ASSET_LIST.md
tools/         gli script "bake" che creano le scene dei capitoli, la generazione di arte e audio
tests/         smoke_test (gioca tutto il gioco), storia_test, route_walk_test, touch_test (i comandi col dito) e altri
```

## Domande ancora aperte

- Il protagonista ha un nome scelto dal giocatore: resta così?
- Quanto deve durare tutta la salita? (Proposta: 2-3 ore, circa 20 giorni di gioco.)
