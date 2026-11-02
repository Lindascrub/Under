# Nives, la persona che resta

Nives è l'addetta ai badge: una per piano, "tutte uguali". È anche l'unica che si ricorda le partite finite.
Il giocatore arriva a un finale e ricomincia; Nives si ricorda dove erano arrivati.
Parla sempre come allo sportello: badge, prezzi, porte, turni, piccole osservazioni. Che sappia di essere in un
gioco si capisce poco per volta, e lo dice una volta sola, alla Banca.

Cosa Nives **sa**: i finali raggiunti davvero (titoli di coda), nel loro ordine, e pochi dettagli per raccontarli
senza inventare. Cosa **non sa**: le conversazioni private, le intenzioni del giocatore, il perché delle scelte.
Non controlla la Torre, non risolve il debito, non punisce chi ricomincia.

**La memoria aggiunge solo battute.** Prezzi, premi, badge, accesso ai capitoli e condizioni dei finali non
cambiano (lo controlla `tests/nives_memoria_test.gd`).

Il codice è tutto in `scripts/memoria_nives.gd` (`MemoriaNives`). Le scene lo chiamano in pochi punti:

| Dove | Cosa | Chi lo chiama |
|---|---|---|
| Fondo, primo sportello | prima partita: "Cinquecento euro." / "Per una porta?" / "Per quella dopo." al posto della riga del prezzo | `room.gd` `_badge_machine` → `fondo_price` |
| Fondo, primo sportello | dopo un finale: "Oh. Sei tornato." (Ci conosciamo? / Quanto costa?), poi lo sportello di sempre. Nessun badge in più | `room.gd` → `return_scene` |
| Ogni sportello dei badge (Fondo, -4, Mercato, Banca, Città) | al massimo un ricordo per visita (vedi sotto) | `at_booth` all'inizio di `_badge_machine` |
| Banca, scale, dopo la ricevuta | "Tienila." / "Servirà?" in ogni partita; dopo un finale, la domanda della rivelazione | `banca_c4.gd` `_nives_receipt` |
| Finale, epilogo di Nives | dopo la prima partita conclusa: "Questa me la ricorderò." / "Anche se ricomincio?" / "Anche." | `finale_c6.gd` `nives_scene` → `epilogue` |
| Finale, passo 8 (titoli di coda) | il finale si scrive nella memoria | `finale_c6.gd` `run` → `record` |
| Menu | importa un vecchio salvataggio finito; nelle Impostazioni della schermata iniziale, "Dimentica le partite" | `main_menu.gd`, `ui.gd` `settings_menu` → `forget_dialog` |

## Allo sportello: un ricordo per volta

`at_booth` sceglie, in quest'ordine, la prima cosa che vale (una sola per visita):

1. **Olga** (anche nella prima partita): se la proposta nascosta è stata ritirata davvero (`c4_olga_corretta`):
   "Ho saputo che hai ritirato la proposta." / "Basta?" / "Questo devi chiederlo a Olga." Nives non perdona al
   posto degli altri.
2. **Prima solidale, adesso un danno vero**: nell'ultima partita ricordata avevi aiutato almeno due persone e
   nessuno era diventato un robot; adesso qualcuno è un robot per te, oppure Olga è stata ingannata e non hai
   rimediato. "Ricordare non mi dà il controllo delle tue mani." Una risposta brusca non basta.
3. **Prima opportunista, adesso aiuti**: nell'ultima partita qualcuno era diventato un robot; adesso nessuno, e hai
   aiutato almeno due persone (dopo il ricordo). "Sto guardando anche quello che fai adesso."
4. *facoltativa* — **la rivelazione**, se non l'hai ascoltata alle scale della Banca (allo sportello della Banca o
   della Città, solo dopo aver scoperto che il contratto non c'è).
5. *facoltativa* — **il ricordo dell'ultimo finale** ("Ti ricordi di me?"): una variante sola, quella dell'ultimo
   finale delle partite prima. A1 chiede come chiamarti (il tuo nome o "Come vuoi."), senza conseguenze. A2 nomina
   la regola adottata davvero in quella partita; se il ricordo non la sa, non la nomina.
6. *facoltativa* — **più finali diversi** ("Quale delle due volte ti ricordi?"), dopo il ricordo: gli ultimi due
   finali diversi, nell'ordine in cui sono successi ("Una volta eri il Direttore." / "Un'altra volta avevo una
   sedia dove potevo risponderti."). Con tre o più finali diversi: "Tutte."

Le facoltative si possono saltare ("Niente, grazie."): sullo stesso piano non insistono, allo sportello del
piano dopo tornano. Le reazioni 1-3 e le scene 5-6 si sentono una volta per partita (flag `nives_mem_*` nel
salvataggio della partita).

## La rivelazione della Banca

Dalla partita dopo un finale, alle scale della Banca, dopo "Tienila." si può chiedere
"Perché mi parli come se tutto fosse già successo?". È prima della salita, quindi prima di uscire dalla Banca.
Se la salti, torna allo sportello della Città. Si sente **una volta per sempre** (finché non cancelli la memoria).
Musica ferma, una pausa, niente finti errori. Poi quattro domande facoltative, in qualunque ordine:
- "Allora sai che è un gioco?"
- "Ti ricordi tutto?" (cita un solo dettaglio, quello dell'ultimo finale)
- "Posso sistemare quello che ho fatto?" (nomina le persone di questo piano che conosci e sono ancora persone:
  i robot no)
- "Ti dà fastidio che sia tornato?"

Si chiude col numerino: "Lui ricomincia da uno e basta."

## La memoria

Un file a parte, `user://cheap_memoria.json`, fuori dal salvataggio della singola partita:

```json
{"version": 1,
 "endings": [{"run": "1761...-123", "family": "A", "variant": "A2", "past": "solidale", "debt_rule": "revisione", ...}],
 "heard": ["rivelazione"],
 "cleared_runs": []}
```

- `endings`: i finali arrivati ai **titoli di coda**, in ordine. Per A2 anche la regola dei debiti e se stipendi
  o servizi sono migliorati. `past` è `opportunista` (qualcuno è diventato un robot), `solidale` (almeno due
  persone aiutate e nessun robot) o vuoto.
- `heard`: le scene speciali che si sentono una volta per sempre (la rivelazione).
- `cleared_runs`: le partite già finite che c'erano quando la memoria è stata cancellata.

Le regole:
- Ogni partita ha un numero, `flags.run_id`, dato dal menu con **Nuova partita**. Un finale si scrive una volta
  sola per numero: rivedere i titoli, salvare e ricaricare lo stesso finale non lo duplica.
- **Nuova partita** non tocca la memoria. **Caricare** una partita non è ricominciare: è la stessa partita.
- Nives distingue: il finale della partita in corso non è un ricordo (`past()` lo esclude).
- Un finale **non** si scrive se è solo scelto, o aperto per una prova senza numero di partita (i test che usano
  `new_game()` da soli).
- Un vecchio salvataggio senza numero diventa `legacy` quando si carica. Se era già arrivato ai titoli di coda
  (`chapter_6.completed` con la variante), il menu lo importa una volta (solo se la memoria non esiste ancora).
  Se non era finito, non si inventa niente. L'ordine delle azioni di partite vecchie non si ricostruisce.
- **Dimentica le partite** (Impostazioni della schermata iniziale, solo se c'è qualcosa da dimenticare): due conferme, poi la memoria è vuota.
  Il salvataggio resta. Una partita già finita nel salvataggio non torna nella memoria, nemmeno rivedendone i titoli.
- I test usano un file accanto al loro salvataggio (`<salvataggio>_memoria.json`): la memoria vera non si legge
  e non si tocca.

## Il nome

Nella schermata del nome (`main_menu.gd`) si scrivono solo lettere (anche accentate), spazi e apostrofi: numeri
e simboli spariscono appena li scrivi, e la torre lo dice. Le parolacce (italiane e inglesi, anche staccate o
con gli accenti) non si possono prendere: la torre risponde, ogni volta in modo diverso, e svuota il campo.
Le liste sono `RUDE_PARTS` (pezzi vietati ovunque) e `RUDE_WORDS` (parole vietate solo intere, così "Negroni" o
"Pasculli" vanno bene).

## Le prove

- `tests/nives_memoria_test.tscn` (headless): prima partita senza falsi ricordi, ritorno, ogni variante,
  due finali in ordine, rivelazione (anche saltata e ripresa in Città), reazioni, epilogo, vecchi salvataggi,
  memoria rotta, cancellazione, economia e finali invariati, il nome.
- `tests/schermate_test.tscn -- --solo=nives --out=<cartella>` (finestra): le schermate del primo ritorno al
  Fondo, dei due ricordi al Mercato, della rivelazione in Banca e del nome.
