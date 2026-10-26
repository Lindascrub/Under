# Il sistema dei finali

Un solo punto decide il finale: `chapters/c6/finali.gd`, `decide(selected)`.
Non esistono punteggi né variabili di "bontà": le varianti leggono **fatti contati** dal salvataggio.

## 1. La famiglia

È la scelta conclusiva al tavolo della Cima (6.09), confermata in modo esplicito.

| Scelta | Famiglia |
|---|---|
| A — Prendi il posto della Presidente | **A — IL PADRONE** |
| B — Rifiuta, e vai via | **B — UN ALTRO DOMANI** |
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
| `improved` | All'ultimo ciclo stipendi ≥ 45 **oppure** servizi effettivi ≥ 25 |
| `rule_changed` | Regola dei debiti del ciclo 3 diversa da "conservare" |
| `policy.maintenance_ok` | Arretrato di manutenzione < 10 alla fine |
| `policy.reserve_ok` | Riserve ≥ 15 alla fine |

"Conosciuta" (`met`): flag `met_<id>`, oppure aiutata, oppure robot, oppure liberata (per Fermo anche `fermo_talked`).

## 3. Le varianti

Le regole si leggono in ordine: **la prima vera vince**. L'ultima di ogni famiglia è sempre vera (fallback),
quindi ogni combinazione ha un finale.

### A — IL PADRONE

| Variante | Condizione |
|---|---|
| **A2** IL DIRIGENTE CHE CAMBIA LE COSE | `improved` **e** `bonds ≥ 2` **e** `rule_changed` **e non** `power` |
| **A1** L'ATTICO | altrimenti |

### B — UN ALTRO DOMANI

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
| B | `contestato` se prove ≥ 2, altrimenti `registrato` |
| C | `in_revisione` se la regola del ciclo 3 è "revisione"; altrimenti come B |

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
`chapter_6.outcome`. Il Finale (`finale_c6.gd`) legge solo `outcome`, i fatti e i flag dei capitoli:
la frase finale dipende dalla variante, gli epiloghi dallo stato delle singole persone,
il sogno dalla famiglia (`dream_line(dream, family)`).

## 7. Come si cambia

Modificare `variant_rules()` in `finali.gd` (testo e condizione stanno insieme) e aggiornare questa pagina.
Il test `_test_chapter6` prova 1200 combinazioni casuali: ogni combinazione deve dare una variante della famiglia scelta.
