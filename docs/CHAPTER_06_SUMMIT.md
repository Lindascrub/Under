# Capitolo 6 — La Cima e i finali

L'ultimo piano. Niente scale dopo. Un ascensore dorato senza pulsanti, un corridoio di specchi,
l'ufficio enorme e quasi vuoto della Presidente. Qui il protagonista scopre da dove viene il debito,
fa tre cicli del TURNO di Direzione (il bilancio della Torre), riceve l'ultima telefonata del Capo
e decide cosa fare del posto più alto: prenderlo, lasciarlo, o aprirlo a tutti.
Poi i finali, gli epiloghi "sei mesi dopo", il sogno, e la domanda: **Quanto costa una vita?**

## File

| File | Cosa contiene |
|---|---|
| `chapters/c6/cima.tscn` | La Cima (32x14 caselle). **Generata** da `tools/bake_c6_cima.gd`: non modificarla a mano, rilancia il bake |
| `chapters/c6/cima_c6.gd` | La stanza: scene 6.01-6.09, la Presidente, il contratto, la scrivania del TURNO, le consultazioni, il Capo, la scelta finale, la finestra |
| `chapters/c6/direzione_regole.gd` | Le regole del TURNO di Direzione: solo dati e conti (niente scena). Usate da schermo, stanza, finali e test |
| `chapters/c6/direzione.tscn` + `direzione.gd` | Lo schermo del bilancio (più/meno sulle quattro voci, CONFERMA, Casa Comune, regola dei debiti) |
| `chapters/c6/finali.gd` | Il motore dei finali: **una funzione sola**, `decide(selected)`. Vedi `docs/ENDING_SYSTEM.md` |
| `chapters/c6/finale.tscn` + `finale_c6.gd` | Scena del finale, epiloghi, Nives, il sogno, CHEAP / Quanto costa una vita? / FINE, i titoli |
| `tools/make_placeholders_cima.py` | I segnaposto grafici (`art/c6/`), elenco in `docs/ASSET_LIST.md` |
| `tools/make_sfx_cima.py` | `audio/strap.wav`, `drring.wav`, `music_cima.wav`, `music_epilogo.wav` (segnaposto) |

Modifiche ai sistemi condivisi, piccole e compatibili con i capitoli 1-5:
- `autoload/router.gd`: `CIMA`, `DIREZIONE`, `FINALE`; la Cima è una stanza del mondo (stelline, salvataggio).
- `chapters/c5/citta_c5.gd`: le scale della città portano alla Cima nuova (prima: il vecchio ufficio del capo).
- `autoload/ui.gd`: alla Cima la barra in alto dice "TURNO di Direzione: N cicli su 3" invece del turno del giorno.

## Mappa

```
        ┌──────────── UFFICIO DELLA PRESIDENTE (pavimento viola) ────────────┐
        │ pianta  terminale(16,4)  scrivania(19,5)  finestra(23,2)  archivio(29,4)│
┌──────┐│                          la Presidente (23,6)                         │
│ASCEN-├┤ specchi (7,9,11)                                                    │
│SORE  ││ CORRIDOIO   ★(11,9)       tavolo della decisione (21,10)            │
│(oro) ├┤                                                                     │
└──────┘│ caffè (15,11)                                    piante             │
        └────────────────────────────────────────────────────────────────────┘
```

- **Ascensore** (1,5)-(4,10): niente pulsanti. Insegna, specchio, targhetta "PER SCENDERE, RIVOLGERSI ALLA PRESIDENZA".
- **Corridoio degli specchi** (6,6)-(12,9): tre specchi, ognuno riflette qualcuno che hai incontrato (o nessuno). La stellina salva.
- **Ufficio** (14,3)-(30,12): scrivania con la cartellina OBBLIGO DI ESISTENZA e il TURNO, terminale dei bilanci
  (consultazioni), finestra panoramica, archivio del debito, tavolo della decisione, macchina del caffè.
- **Arrivi:** `default` e `from_below` (2,8) nell'ascensore; `desk` (20,7) davanti alla scrivania, dopo ogni ciclo.

## Scene

| Scena | Dove | Cosa succede | Flag |
|---|---|---|---|
| 6.01 L'ascensore | ascensore | Sale da solo. Lo specchio: "HAI TROVATO QUELLO CHE CERCAVI?" (non ancora / non so / volevo solo finire) | `elevator.intro_seen`, `elevator.answer` |
| 6.02 La Presidente | ufficio | Grigia, capelli bianchi, occhiali. STRAP: strappa un foglio. Le chiede cosa desiderava da giovane | `president.met`, `president.first_wish` |
| 6.03 Il fascicolo | scrivania | OBBLIGO DI ESISTENZA: tre sezioni (chi, quanto, firma). Nessuna firma. Lette tutte e tre, è una prova | `president.debt_contract_read`, `c6_contratto_letto` |
| 6.04 L'origine e l'offerta | Presidente | Le domande sull'origine del debito; il timbro ANNULLATO mostrato ma **non usato**: "prima guarda il lavoro" | `president.origin_explained`, `president.offer_received` |
| 6.05 TURNO, ciclo 1 | scrivania → Direzione | QUANTO VALE IL LAVORO? | `director_turn.cycle_1_completed` |
| 6.06 TURNO, ciclo 2 | scrivania → Direzione | A CHI APPARTENGONO I SERVIZI? Prima: la telefonata sulla Casa Comune (Ada se è umana e l'hai conosciuta, se no una rappresentante degli studenti) | `cycle_2_completed`, `casa_call_seen` |
| 6.07 TURNO, ciclo 3 | scrivania → Direzione | CHI PAGA IL FUTURO? La regola dei debiti | `cycle_3_completed` |
| 6.07b Consultazioni | dopo ogni ciclo, terminale | Le persone conosciute dicono cosa è cambiato per loro; i robot rispondono da robot; "l'impiegata" c'è sempre | `director_turn.consulted`, `consulted_citizens` |
| 6.08 Il Capo | ufficio, dopo il ciclo 3 | DRRRRING. Il Capo, grigio per la prima volta. L'attribuzione globale: tutto il lavoro della Torre con il tuo nome | `boss.final_call_seen`, `global_credit_offer_resolved`, `global_credit_accepted` |
| 6.09 La scelta | tavolo | A / B / C / Non ancora, poi conferma esplicita ("Ci ripenso" torna indietro) | `final_decision.*`, `outcome.*` |
| 6.10 Sei mesi dopo | Finale | La scena della famiglia, poi la Torre dall'alto in basso: chi hai conosciuto, piano per piano. Nives per ultima | `epilogue.*` |
| 6.11 Il sogno | Finale | Il sogno (scelto prima, alla Presidente) secondo la famiglia del finale. CHEAP / Quanto costa una vita? / FINE. I titoli | `dream.*`, `completed` |
| Finestra | ufficio | Facoltativa: un ultimo sguardo ai piani (una riga per piano, secondo come li hai lasciati). Nessun premio | `panorama.locations_seen` |

Specchi, archivio, caffè (al secondo colpo esce lo zucchero) sono facoltativi e non danno niente.

## La Presidente e l'origine del debito

La Presidente non è un boss e non è magica. Il debito del protagonista nasce da un fascicolo,
OBBLIGO DI ESISTENZA, che nessuno ha firmato: un debito assegnato alla nascita, come a tutti.
Lei potrebbe annullarlo con un timbro, ma non lo fa subito: prima chiede di fare il suo lavoro per tre cicli.
**Il debito personale non sparisce mai prima della scelta finale.** Solo il finale A lo annulla (una volta).

## TURNO di Direzione

Tre cicli, sempre con **100 unità** da dividere in quattro voci, a passi di 5, massimo 60 per voce.
Ogni ciclo parte dalla distribuzione della Presidente: stipendi 40, servizi 20, manutenzione 25, riserve 15.
Le regole sono **deterministiche e tutte visibili** (pulsante REGOLE, e le righe sotto le voci dicono cosa
succederà prima di confermare). Niente barra della bontà, niente punteggio.

| Voce | Regola |
|---|---|
| STIPENDI | Minimo 30 (i contratti firmati). Sotto 35 tagliati, 35-44 fermi, 45-54 coprono metà dei prezzi, 55+ coprono i prezzi. Un aumento sopra 40 è per sempre: dal ciclo dopo non si scende sotto |
| SERVIZI | Sotto 15 a pagamento, 15-24 come ora, 25+ allargati (+5 al fabbisogno di manutenzione dei cicli dopo) |
| MANUTENZIONE | Fabbisogno 25 (+5 per ogni ciclo con servizi allargati). Quello che manca diventa arretrato. Con 10 di arretrato si annuncia un guasto: al ciclo dopo lo si paga tutto |
| RISERVE | Si accumulano. Al ciclo 2 arriva la bolletta della dinamo del Fondo (15, annunciata al ciclo 1) |

Le spese (bolletta, guasto) si pagano prima dalle riserve e poi dai servizi del ciclo: in quel caso
lo schermo lo dice ("ne restano X: Y vanno a coprire le spese"). CONFERMA funziona solo a 100 unità esatte;
se no dice perché ("Hai assegnato 90 unità su 100.").

Non c'è uno stipendio personale per il protagonista: il TURNO di Direzione non paga.

### Ciclo 2: la Casa Comune

Le opzioni dipendono da come è finita l'assemblea del capitolo 5 (`c5_esito`):

| Stato della Casa | Opzioni (più sempre "Non intervenire") | Condizione |
|---|---|---|
| riconversione | Accessi gratuiti al centro CHEAP | servizi effettivi ≥ 25 |
| | Rinegozia il contratto | `c5_rapporto` o `c5_documento` |
| comunitaria | Dai risorse alla gestione comunitaria | servizi effettivi ≥ 20 |
| | Lasciala autonoma | sempre |
| sospesa (o assemblea mai fatta) | Proroga (10 dalle riserve) | riserve dopo le spese ≥ 10 |
| | Nuovo modello (le stanze di Ada) | `c5_ada_stanze` |

Un'opzione chiusa resta visibile, grigia, con il motivo scritto.

### Ciclo 3: la regola dei debiti

| Regola | Condizione |
|---|---|
| Conserva il sistema dei debiti | sempre |
| Riduci gli interessi (2% → 0,5%) | riserve ≥ 15 |
| Avvia la revisione dei debiti imposti | almeno 2 prove, fra cui il fascicolo letto (`c6_contratto_letto`) |
| Sviluppa fonti alternative | almeno 2 reti vere |

**Prove:** il fascicolo letto, `c4_anomalia`, `c4_olga_doppia`, `c4_teo_copia`, `c5_documento`.
**Reti:** gli ordini di Leda (se non è robot), i pendolari di Nadir (`c5_nadir_rete`), la Casa Comune
gestita da chi la usa, la bottega di Rina (`c5_vetrina_aiuto`), le consegne di Amir (se non è robot),
la contestazione di Olga.

## Consultazioni

Dopo ogni ciclo (e prima della scelta finale almeno una volta) si sentono le persone dal terminale:
fino a 5 persone conosciute, in ordine di piano. Ognuna dice una cosa vera su come il bilancio la tocca.
I robot compaiono con "(robot)" e rispondono con frasi aziendali. Chi è stato liberato non lavora più nella Torre
e non c'è. "L'impiegata" (una persona senza nome) è sempre l'ultima, così la consultazione non è mai vuota.

## Il Capo (6.08)

Una volta sola, dopo il ciclo 3. Il Capo è **grigio**: anche lui è una persona. Offre l'attribuzione globale:
tutto il lavoro della Torre a tuo nome. Le battute cambiano con quante persone hai sfruttato.
Si può chiedere di più ("Chiedi") quante volte si vuole, poi accettare o rifiutare.
Accettare non cambia la famiglia del finale, ma chiude A2 e C2 e rende il potere "totale" in A.

## La scelta finale (6.09)

Al tavolo, quando i tre cicli sono fatti, il Capo è passato e hai sentito almeno una persona:

- **A — Prendi il posto della Presidente** (IL PADRONE)
- **B — Rifiuta, e vai via** (UN ALTRO DOMANI)
- **C — Proponi di decidere insieme** (NESSUNO SALE DA SOLO): si affidano tre ruoli (CONTI, SERVIZI, TURNI)
  alle persone con cui hai un legame; un ruolo può restare vuoto.
- **Non ancora.**

Dopo la scelta c'è sempre una conferma esplicita; "Ci ripenso" torna al tavolo. Confermata, la scelta è
definitiva: si salva con la stanza FINALE e rientrando si va direttamente lì.

## Famiglie e varianti

Le condizioni esatte stanno in `docs/ENDING_SYSTEM.md` e nel codice (`finali.gd`, `variant_rules()`).
In breve: A1 L'ATTICO / A2 IL DIRIGENTE CHE CAMBIA LE COSE; B1 LA PARTENZA / B2 LE PICCOLE ORE;
C1 LA PICCOLA COMUNITÀ / C2 LA TRASFORMAZIONE DELLA TORRE / C3 IL PROGETTO INCOMPLETO.

## Epiloghi "sei mesi dopo"

Struttura del Finale (`finale_c6.gd`, `epilogue.step`):

| Passo | Cosa |
|---|---|
| 0 | La scena della famiglia (A: l'attico / B: la partenza / C: i tavoli condivisi) e la sua frase |
| 1-5 | La Torre dall'alto in basso: Banca (-2), Mercato (-3), Sottoufficio (-4), Fondo (-5), Città (0). Per ogni piano solo le persone **conosciute**; se non ne hai conosciuta nessuna, una riga di fallback sul piano |
| 6 | Nives, sempre per ultima |
| 7 | Il sogno |
| 8 | CHEAP / Quanto costa una vita? / FINE, i titoli, poi il menu |

Ogni epilogo personale è coerente con lo stato: un robot resta robot (frasi aziendali, sorriso), chi hai
aiutato e poi sfruttato lo ricorda, la Casa Comune è come l'ha lasciata il ciclo 2, i ruoli del finale C
compaiono sulle persone che li hanno. Il finale salva dopo ogni passo e riprende da lì.

## Flag (`GameState.flags["chapter_6"]`)

```
entered, completed
elevator        intro_seen, answer
president       met, origin_explained, debt_contract_read, offer_received, first_wish
director_turn   cycle_1_completed, cycle_2_completed, cycle_3_completed, consulted_citizens,
                decisions[], consulted[], state{}, casa_call_seen, pending
boss            final_call_seen, global_credit_offer_resolved, global_credit_accepted
panorama        locations_seen[]
final_decision  selected, confirmed, roles{conti, servizi, turni}
outcome         family, variant, debt_status, governance_status
epilogue        started, seen_character_ids[], completed, step
dream           selected, final_scene_seen
debt_cancelled, debt_before, coffee
```

`director_turn.state` è lo stato del bilancio (`direzione_regole.new_state()`): riserve, arretrato,
minimo degli stipendi, servizi allargati, ciclo, registro dei cicli, Casa, regola dei debiti.
Fuori da `chapter_6`: `c6_contratto_letto` (la prova, letta da `evidence()`).

## Persistenza

- Tutto il capitolo è in `GameState.flags["chapter_6"]`: si salva con le stelline come il resto.
- `cima_c6.c6()` completa sempre lo schema con i valori di partenza (salvataggi vecchi, a metà, campi mancanti).
- Il JSON trasforma gli interi in decimali: il codice usa sempre `int()`.
- Un ciclo confermato scrive subito lo stato; se il gioco si chiude fra il ciclo e le consultazioni,
  `pending` fa ripartire le consultazioni al rientro.
- Il debito si annulla **una volta** (`debt_cancelled`); ricaricare non lo annulla di nuovo.
- Dopo la conferma il salvataggio punta a FINALE; il finale riprende dal passo salvato; a capitolo completato
  si va direttamente ai titoli.

## Test

`tests/smoke_test.gd`, `_test_chapter6()` (dopo il capitolo 5, nello stesso giro):
regole del bilancio (validità, minimo stipendi, bolletta pagata dai servizi, guasto annunciato, riserve,
servizi allargati); arrivo, ascensore una volta sola, specchi; Presidente, fascicolo, origine, offerta senza
annullamento anticipato; i tre cicli con lo stato condiviso; consultazioni (robot, impiegata, niente ripetizioni);
nessuno stipendio personale; il Capo una volta sola, attribuzione rifiutata e accettata; la finestra senza premi;
"Ci ripenso" prima della conferma; percorso C → C2 con i ruoli e il debito in revisione; percorso A → A1 con
potere, debito annullato una volta sola, robot che restano robot; varianti logiche; 1200 combinazioni casuali
sempre valide; salvataggio con campi mancanti (percorso I); opzioni dei debiti chiuse; ripresa del finale dal passo 7.

`tests/touch_test.gd`: lo schermo della Direzione col dito (più a 100 non aggiunge, togliere e dare,
minimo stipendi, CONFERMA rifiutata a 90, CONFERMA a 100).

Verificati **solo leggendo il codice**: alcune combinazioni di epiloghi con robot specifici (es. Teo robot
alla Banca), le varianti B1/B2 e C1/C3 percorse dalla scena vera (le condizioni sono testate sulla funzione).
**Non è stato fatto un test manuale su telefono.**

## Asset mancanti

Tutta la grafica di `art/c6/` e i quattro suoni sono segnaposto (elenco completo in `docs/ASSET_LIST.md`).
Mancano anche: un ritratto/sprite dedicato per la Presidente (ora usa `char_20` grigio), animazioni per il timbro
e per lo strappo, la sezione della Torre disegnata per gli epiloghi.

## Limiti noti

- I vecchi finali (`scenes/endings/`) e l'ufficio del capo (`scenes/world/boss_office.tscn`) restano nel progetto
  per i percorsi della versione precedente; il capitolo 6 nuovo non li usa.
- Il pulsante REGOLE mostra il testo per intero; su schermi molto piccoli va letto a pagine.
- Le battute degli epiloghi sono scritte per i 12 personaggi dei capitoli 1-5; nuovi personaggi vanno aggiunti
  in `finale_c6.gd`, `epilogue_for()`, e in `finali.gd`, `PEOPLE`.
