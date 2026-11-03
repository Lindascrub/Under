# Il sistema dei finali

Un solo punto decide il finale: `chapters/c6/finali.gd`, `decide(selected)`.
Non esistono punteggi né variabili di "bontà": le varianti leggono **fatti contati** dal salvataggio.
La storia approvata è in `docs/STORIA_BANCA_CIMA.md` (sezioni 5-7): questa pagina dice come il codice la segue.

## 1. La famiglia

È la scelta conclusiva al tavolo della Cima (6.09), confermata in modo esplicito.

| Scelta | Famiglia |
|---|---|
| A — Prendi il posto della Presidente | **A — PRENDERE LA DIREZIONE** |
| B — Rifiuta, e vai via | **B — IL TEMPO CHE RESTA** |
| C — Proponi di decidere insieme | **C — NESSUNO SALE DA SOLO** |
| qualunque altro valore (salvataggio rotto) | B |

## 2. I fatti (`facts()`)

| Fatto | Come si calcola |
|---|---|
| `bonds` (legami) | Persone di `PEOPLE` (fermo, bulbo, mina, tilde, ercole, leda, amir, olga, teo, ada, nadir, rina) **conosciute**, **aiutate** (`helped_ids`) e **non robot** |
| `betrayed` | Aiutate e poi diventate robot |
| `networks` (reti) | `direzione_regole.networks()`: ordini di Leda (non robot), pendolari di Nadir, Casa Comune gestita da chi la usa, bottega di Rina, consegne di Amir (non robot), contestazione di Olga |
| `evidence` (prove) | `direzione_regole.evidence()`: fascicolo letto alla Cima, `c4_anomalia`, `c4_olga_doppia`, `c4_teo_copia`, `c5_documento` |
| `power` | Attribuzione globale del Capo accettata (`chapter_6.boss.global_credit_accepted`) |
| `roles_filled` | Ruoli del finale C (conti, servizi, turni) affidati a qualcuno |
| `improved` | Nel turno stipendi ≥ 45 **oppure** servizi effettivi ≥ 25 |
| `rule_changed` | Regola dei debiti scelta nel turno diversa da "conservare" |
| `policy.maintenance_ok` | Arretrato di manutenzione < 10 alla fine |
| `policy.reserve_ok` | Riserve ≥ 10 alla fine del turno |
| `kept_by_choice` | "Conserva il sistema dei debiti" scelto **mentre almeno un'altra regola era aperta** (`debt_other_open` nello stato del turno, scritto da `direzione.gd`). Un salvataggio di prima non lo sa: vale falso |
| `contested` | La contestazione fatta alla Cima (`c6_contestazione`) |

"Conosciuta" (`met`): flag `met_<id>`, oppure aiutata, oppure robot, oppure liberata (per Fermo anche `fermo_talked`).

## 3. Le varianti

Le regole si leggono in ordine: **la prima vera vince**. L'ultima di ogni famiglia è sempre vera (fallback),
quindi ogni combinazione ha un finale.

### A — PRENDERE LA DIREZIONE (ordine A2 → A1 → A3)

| Variante | Condizione |
|---|---|
| **A2** IL DIRIGENTE CHE CAMBIA LE COSE | `improved` **e** `bonds ≥ 2` **e** `rule_changed` **e non** `power` |
| **A1** ADESSO CHIAMI TU | `kept_by_choice` |
| **A3** IL TELEFONO SQUILLA ANCORA | altrimenti (anche con l'attribuzione del Capo: quella cambia solo il potere, e si vede in A3) |

### B — IL TEMPO CHE RESTA

| Variante | Condizione |
|---|---|
| **B2** LE PICCOLE ORE | `bonds ≥ 2` |
| **B1** LA PARTENZA | altrimenti |

### C — NESSUNO SALE DA SOLO

| Variante | Condizione |
|---|---|
| **C2** LA TRASFORMAZIONE DELLA TORRE | `networks ≥ 3` **e** `bonds ≥ 4` **e** `roles_filled == 3` **e** `maintenance_ok` **e** `reserve_ok` **e** `rule_changed` **e non** `power` |
| **C3** IL PROGETTO INCOMPLETO | `bonds < 2` **oppure** `networks == 0` **oppure** `roles_filled == 0` |
| **C1** LA PICCOLA COMUNITÀ | altrimenti |

## 4. Il debito personale (`debt_status`)

| Famiglia | Stato |
|---|---|
| A | `annullato` (il debito va a 0 **una volta**: `debt_cancelled`, il valore prima in `debt_before`) |
| C2 | `in_revisione` se la regola adottata è "revisione"; altrimenti come sotto |
| B, C1, C3 (e C2 senza revisione) | `contestato` **solo** con `contested`; altrimenti `registrato`. Le prove e la richiesta di verifica, da sole, non bastano |

Il finale mostra sempre **due righe separate** (`finale_c6.debt_lines()`): il tuo debito e i debiti degli altri
(`others_debts()`: registrati come prima, interessi allo 0,5%, in revisione, o con le fonti alternative).

## 4b. Cosa vale davvero nella Torre (`in_force`, `effective_summary`)

Le decisioni del turno diventano vere **solo in A e in C2** (`in_force(family, variant)`).
Negli altri finali `effective_summary()` restituisce le regole di prima: stipendi 40, servizi 20,
manutenzione 25, riserve 15, debiti conservati, la Casa Comune com'è uscita dal capitolo 5.
Il Finale usa sempre `effective_summary()` (stampante, epiloghi, foglio delle decisioni in C2).
Aiuti, riparazioni e risultati dei capitoli prima restano veri in **tutti** i finali.

## 4c. Il finale B: ogni pezzo dalla sua fonte

| Pezzo | Fonte | Se manca |
|---|---|---|
| Casa | `offers(HOME_OFFERS)`: Ada, Rina, Fermo (solo se liberato) | "un posto letto in affitto, per un mese" |
| Lavoro | `offers(WORK_OFFERS)`: Nadir, Leda, Amir | un annuncio cerchiato, senza risposta |
| Sul frigo | "Debito: CONTESTATO" solo se contestato | il riepilogo o la ricevuta della Banca, in un cassetto |
| "Ci sei stasera?" | `evening_sender()`: il legame più recente, poi l'offerta più recente | la vicina sconosciuta |

Un'offerta è il flag `offerta_<id>` (con il suo numero d'ordine), scritto solo dal dialogo che la fa; un robot non offre.
Senza offerte e senza legami: la stanza in affitto, la valigia mezza piena, il volantino "Porta una sedia".

## 4d. Reazioni negli epiloghi (`Storia.reazione`)

Prima dell'epilogo di Fermo, Ercole, Leda, Rina e Olga, se c'è un torto della missione del Capo,
la persona lo ricorda secondo l'ordine delle azioni (`flags["seq"]`, `Storia.segna`/`Storia.ordine`):
aiuto poi torto → ricorda tutte e due; torto poi aiuto → il torto resta; torto poi riparazione → riconosce la
riparazione. Un salvataggio vecchio senza numeri usa la riga di prima (nessun ordine inventato).

## 5. Il governo della Torre (`governance`)

| Famiglia / variante | Stato |
|---|---|
| A | `concentrata_totale` con `power`, altrimenti `concentrata` |
| B | `invariata` |
| C2 | `condivisa` |
| C1 | `comunita_indipendente` |
| C3 | `in_discussione` |

## 6. Dove finisce il risultato

`decide()` restituisce `{family, variant, debt_status, governance_status}`, che `cima_c6.commit()` salva in
`chapter_6.outcome` insieme a `engine: 2`. Un `outcome` senza `engine` (salvataggio di prima) viene
ricalcolato all'apertura del Finale con quello che il salvataggio sa. Il Finale (`finale_c6.gd`) legge solo `outcome`, i fatti e i flag dei capitoli:
la frase finale dipende dalla variante, gli epiloghi dallo stato delle singole persone,
il sogno dalla famiglia (`dream_line(dream, family)`).

Quando il Finale arriva ai titoli di coda, la variante si scrive anche nella memoria di Nives
(`MemoriaNives.record`, docs/NIVES_MEMORIA.md), che vive fuori dal salvataggio. La memoria non entra mai in
`facts()` né in `decide()`: i finali si decidono uguali con o senza ricordi.

## 7. Come si cambia

Modificare `variant_rules()` in `finali.gd` (testo e condizione stanno insieme) e aggiornare questa pagina.
Il test `_test_chapter6` prova 1200 combinazioni casuali: ogni combinazione deve dare una variante della famiglia scelta.
`tests/storia_test.tscn` prova A1/A2/A3, lo stato del debito, le combinazioni del finale B, le reazioni e
gioca ogni variante fino ai titoli di coda.
