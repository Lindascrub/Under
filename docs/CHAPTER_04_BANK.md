# Capitolo 4 — La Banca (piano -2)

**Obiettivo:** il badge del Piano Terra, che costa **4.000 €**. **Persone:** Olga e Teo.
**Tema:** debito e dipendenza. La Banca è elegante e quasi buffa, poi diventa inquietante: il debito di
7 miliardi non ha un contratto. L'origine vera del debito resta per il Capitolo 6.
**Sottotitolo all'ingresso (fine del Capitolo 3):** "I tuoi soldi sono al sicuro. Tu no."

| Cosa | Dove |
|---|---|
| Scena (fatta nell'editor) | `chapters/c4/banca.tscn`, creata una volta da `tools/bake_c4_banca.gd` |
| Logica | `chapters/c4/banca_c4.gd` |
| Dati (documenti di Olga, pratiche di Teo e dello sportello, premi) | `data/bank.json` |
| Persone | `data/npcs.json` (`olga`, `teo`); promozione in `data/promotions.json` (`teo`) |
| Lavoro | `data/worklist.json` (`sportello_banca`) |
| Minigiochi | `scenes/minigame/minigame.gd` (`rate`, `pratiche`), `scenes/minigame/work.gd` (`sportello`) |
| Il foglio della pratica (condiviso) | `scripts/practice_card.gd` |
| Segnaposto grafici | `art/c4/`, elenco in `docs/ASSET_LIST.md` |
| Test | `tests/smoke_test.gd` (`_test_chapter4`), `tests/touch_test.gd` |

La vecchia Banca (`scenes/world/banca.*`, il Signor Tasso, il conto del padre) è stata tolta:
contraddiceva la nuova specifica. `Router.BANCA` ora punta a `chapters/c4/banca.tscn`.

## La regola dei colori

Come ai piani di sotto: **Olga e Teo sono grigi**, come le quattro persone in fila. Il sistema è colorato e lucido:
marmo, oro, tappeti rossi, il distributore, i terminali, Nives.
**Teo robot si riconosce anche senza colori:** ha un'antenna sulla testa e un timbro che batte sempre allo
stesso ritmo, è fermo (animazione congelata) e non fa emote.

## La mappa (40x17 caselle): quattro stanze sullo stesso piano

Come nelle mappe di esempio di LimeZu: pareti e pavimenti diversi per stanza, il bordo bianco intorno
(`world/room_outline.gd`). La scena si genera con `tools/bake_c4_banca.gd` (la mappa è scritta in `ROWS`).

```
 +--------------+ +------------------------------+ +---------------+
 | TV           | | [BANCA CHEAP]  [NUMERO 4]    | | bacheca Nives scale↑ |  ufficio badge
 | divano divano merendine | pianta SPORTELLO  sportello chiuso  conto |      (porta 28,4-5)
 |  tavolino  Olga         |   fila   cordone            +---------------+
 |  sedie sedie            |   fila   cordone            | librerie  404 |  ufficio di Teo
 |  (porta 11,11-12) ----- |  distributore  tappeto   stellina  Teo scrivania leggio | (porta 28,12-13)
 |  sedie sedie  pianta    | scale↓ (13,15)          pianta | |               |
 +--------------+ +------------------------------+ +---------------+
```

| Stanza | Dove | Cosa c'è |
|---|---|---|
| Sala d'attesa | a sinistra (1-10, 3-15), parete verde chiaro | due divani grigi, il distributore di merendine (9,4), la TV, il tavolino con le riviste (2,7), due file di sedie di plastica (righe 10 e 13), Olga (8,7) |
| Atrio | al centro (12-27, 3-15), marmo, parete crema e verde | insegna e display dei numeri sulla parete; due banconi da reception: il primo (13-16) è il TURNO, posto di lavoro (13,6); nel secondo (20-23) un'impiegata colorata ("chiuso"); la fila grigia (15, 6-9); due cordoni rossi; il terminale del conto (26,4); il distributore dei numeri (16,13); il tappeto; la stellina (24,13); le scale dal Mercato (13,15), arrivo `default` (19,12) |
| Ufficio badge | in alto a destra (29-38, 3-6) | lo sportello di Nives (32,3), la bacheca, le scale per il Piano Terra (36,3): `on_stairs_step` (rivelazione), `on_stairs_top` (sguardo indietro) |
| Ufficio di Teo | in basso a destra (29-38, 10-15), parquet | due librerie = l'archivio (32-37, 10), la scrivania (31,13) col quaderno, Teo (30,13), il leggio col libro aperto (37,13), il terminale del rapporto 404 (38,11) |

Grafica LimeZu: `assets/limezu/themes/` (ospedale: banconi, sedie, cordoni, merendine, TV, bacheca;
soggiorno: divani; biblioteca: librerie e leggio), `tiles/generic.png` (tavolino, tappeti).

## Lo svolgimento

**4.01 L'arrivo** (una volta, `c4_arrivo`). Porta, campanello, l'insegna, la fila, il biglietto
N. 7.000.000.001 e il display "ORA SERVIAMO IL NUMERO 4". Il distributore: "La pazienza è gratuita." … "Per ora."
Esaminandolo di nuovo offre il **SALTAFILA** (Sì / No / Quanto costa? → "Un minuto del tuo futuro.").
È una battuta: non costa soldi e non cambia niente (flag `c4_saltafila`).

**4.02 Olga.** "Sei in fila anche tu? Io sono qui da martedì." → "Quale martedì?" → "Non ricordo. Il calendario è
stato pignorato." Poi le ricevute, e l'offerta di aiuto.

**4.03 LE RATE MANCANTI** (aiuto, 1 ora). Prima si mettono in ordine 6 documenti (dal più vecchio), poi
nell'estratto conto si tocca la voce che c'è due volte. 3 errori = si riprova. Conta solo se riesce.
I numeri tornano: saldo 1.200 € − rata 520 − mora 25 − commissione 35 − commissione 35 + pensione 900 = **1.485 €**;
la commissione di 35 € è addebitata il 18 e il 19 giugno, ma il contratto dice "una per ogni ritardo".
Tornando dal minigioco si prepara la **contestazione** (`c4_olga_contestazione`).
Il minigioco non paga in euro.

**4.04 Teo.** "Benvenuto! Hai un appuntamento?" → No → "Perfetto! Neanche io. Eppure siamo entrambi qui."
Lo valutano sulla velocità. Il quaderno sulla scrivania: "Quello? È un progetto… Appena avrò un lavoro un po' più tranquillo."

**4.05 LA PRATICA IMPOSSIBILE** (aiuto, 1 ora). Sei pratiche (lo stesso foglio dello sportello): per ognuna si
tocca TUTTO IN ORDINE, MANCA UN DOCUMENTO, DATI DIVERSI, DOPPIONE o ERRORE DI REGISTRAZIONE. 2 errori = si riprova.
Vincendo: "Aspetta. Abbiamo finito?" / "E abbiamo controllato tutto?" / "Non sapevo si potessero fare entrambe le cose."

**4.06 Il TURNO allo sportello.** Si legge la pratica e si tocca **APPROVA** (0,35 s) o **RICHIEDI VERIFICA**
(1,2 s). CHEAP paga le pratiche chiuse, non quelle giuste: approvare in fretta non è punito, ma viene contato
(`c4_frettolosi`). Introduzione: "Benvenuto nel settore fiducia! … Per questo ti chiediamo di prenderle velocemente."
Esempi della specifica: 018 (in ordine), 027 e 041 (da verificare). Turno 45 s (obiettivo 12 pratiche), dal 3°
turno 30 s. **Dal 3° turno** c'è anche **"Pratiche raggruppate"**: stessa paga, nessun minigioco
(così non si ripete venti volte lo stesso gioco).

**4.07 Il capo** chiama dopo il primo turno, una volta: monocolo, "ECCO IL MIO INVESTIMENTO PREFERITO!",
"Come va, piccolo capitale umano?", tre risposte, poi l'offerta: 3.000 € per il rapporto di Teo.
Va bene / Ci penso / Perché io? / No. È di Teo. "Perché io?" spiega e richiede. "No" chiude l'offerta.
Il rapporto esiste anche se Teo non è stato aiutato.

**4.08 Il rapporto 404** (terminale accanto all'archivio). Con l'offerta aperta: un, due, tre, stella con Teo che
sistema i documenti, poi al terminale: **Firma con il tuo nome / Lascia la firma di Teo / Leggi il rapporto**
(leggere è solo informazione e si torna alla scelta).
- **Firmare:** 3.000 € una volta sola, LV +1, Teo diventa un robot ("LA PRECISIONE È PRODUTTIVITÀ."), il capo:
  "Fantastico. Sei proprio nato per questo lavoro!". Il quaderno resta sulla scrivania; esaminarlo:
  "ATTIVITÀ NON RILEVANTE." / "TORNARE ALLE PRATICHE.".
- **Lasciare:** Teo: "Hai lasciato il mio nome? Oh. Non so cosa dire." Poi si può aiutare Teo a segnalare il
  rapporto (`c4_teo_copia`). Si arriva qui anche rifiutando al telefono o chiudendo l'offerta al terminale.

**4.09 Il terminale del conto** (dopo che l'offerta è chiusa). Mostra il debito vero (`GameState.debt`),
l'importo d'origine, le notti, gli interessi. "Desideri conoscere l'origine del debito?" Sì / No / Voglio soltanto pagarlo.
Sì → "Contratto originale non disponibile. … Causale: OBBLIGO DI ESISTENZA." (`c4_anomalia`). Se Teo è una persona
ed è stato aiutato, arriva lui: "Questo numero non dovrebbe essere qui. … forse stai cercando di ripagare qualcosa che
non hai mai chiesto." Pagare: la rata minima (150 €) o tutto quello che puoi.

**4.10 Il ritorno di Olga** (dopo almeno una notte dalla contestazione): "Avevo ragione." Il rimborso è quello
del documento (35 €, a lei). Ci compra un gelato al pistacchio: lo desidera dal 2016.

**4.11 Nives.** "Quattromila euro." Se il badge del -2 era un regalo: "Oh, sei tu. Hai ancora quel badge che non ti ho
regalato?". **Badge regalato** se la contestazione di Olga è partita, Teo è stato aiutato e non è un robot:
"Oh. Hai aiutato le persone anche qui. Che strano. … Ne è caduto un altro." Altrimenti si compra (4.000 €,
scalati anche dal debito). Senza soldi: dopo tre turni falliti di fila arrivano la pietà (il "contributo" della banca,
che va sul debito) o il contratto del Signor Rata. Nessun vicolo cieco.

**4.12 Il primo gradino.** Il display rosso: DATA DI APERTURA DEL DEBITO: NON DISPONIBILE. / CONTRATTO FIRMATO:
NESSUNO TROVATO. / IMPORTO ORIGINARIO ASSEGNATO: 7.000.000.000 €. / STATO DEL DEBITO: ATTIVO. /
RICERCA DOCUMENTO DI CONSENSO... / NESSUN DOCUMENTO TROVATO. Poi la Voce CHEAP: "Non preoccuparti. Non è necessario
capire un debito per pagarlo. È necessario soltanto continuare."

**4.13 Lo sguardo indietro.** Una frase sola, con priorità fissa:
1. Teo robot → "La Banca aveva guadagnato un impiegato perfetto. Nessuno aveva chiesto cosa avesse perso."
2. Olga (contestazione) e Teo aiutati → "Non avevi cancellato i debiti. Avevi aiutato qualcuno a non affrontarli da solo."
3. Anomalia scoperta → "Per la prima volta, non eri sicuro di dovere davvero ciò che ti chiedevano."
4. Altrimenti → "Avevi attraversato la Banca. La Banca sarebbe rimasta."

La stanza invece mostra tutto quello che è vero: la fila che avanza piano, Teo robot che timbra o Teo che disegna,
Olga che esce con la lettera, il terminale che continua a cercare il contratto. Poi
"CAPITOLO 5 / LA CITTÀ / Fuori dalla Torre, qualcuno sta ancora pagando." e il salvataggio automatico.
Le scale portano a `chapters/c5/citta.tscn` (il Capitolo 5) se esiste, altrimenti al vecchio Piano Terra.

**La scena segreta.** Se la contestazione è partita, Teo è stato aiutato ed è una persona, entrando di nuovo in
Banca (prima della rivelazione) Olga è alla scrivania di Teo a guardare il quaderno. Il supereroe, la borsetta
come arma: "Ho sconfitto tre direttori con questa. E un piccione." Una volta sola, nessun premio.

## I flag

Durante il capitolo (`GameState.flags`, tutti assenti nei salvataggi vecchi = `false`/0):

| Flag | Vuol dire |
|---|---|
| `c4_arrivo` | l'ingresso è stato visto |
| `c4_saltafila_chiesto`, `c4_saltafila` | il distributore ha offerto il SALTAFILA; accettato |
| `c4_olga`, `c4_olga_ordinati`, `c4_olga_doppia` | Olga conosciuta; documenti in ordine; commissione doppia trovata |
| `c4_olga_contestazione`, `c4_olga_giorno`, `c4_olga_risposta` | contestazione partita (e il giorno); risposta ricevuta |
| `c4_teo`, `c4_teo_sogno`, `c4_teo_aiutato` | Teo conosciuto; il quaderno visto; pratiche controllate |
| `c4_teo_rapporto`, `c4_rapporto_letto` | il rapporto 404 visto; letto |
| `c4_teo_lasciato`, `c4_teo_grazie`, `c4_teo_copia` | lasciata la firma di Teo; Teo ne ha parlato; rapporto segnalato col suo nome |
| `c4_teo_rubato`, `c4_quaderno_robot` | merito rubato; il quaderno visto con Teo robot |
| `c4_turni`, `c4_corretti`, `c4_frettolosi`, `c4_raggruppate` | turni fatti; pratiche giuste; approvate con un problema; turni veloci |
| `c4_capo`, `c4_capo_sospeso`, `c4_capo_chiuso`, `c4_capo_firmato`, `c4_furto_ok` | telefonata; offerta aperta; chiusa; firmata; arrivato al terminale senza farti vedere |
| `c4_conto`, `c4_anomalia`, `c4_teo_codice` | conto consultato; anomalia scoperta; Teo ha letto il codice |
| `c4_nives`, `c4_nives_debito`, `c4_nives_ricorda`, `c4_badge` | Nives; la domanda sul debito; le finestre; `"regalo"`/`"comprato"`/`"altro"` |
| `c4_rivelazione`, `c4_fine`, `c4_segreta` | il primo gradino; lo sguardo indietro; la scena segreta |

Alla fine (in cima alle scale) il riepilogo per i capitoli dopo, coi nomi della specifica:

```
flags["chapter_4"] = {
  entered, completed,
  olga: { met, documents_reconstructed, duplicate_fee_found, complaint_submitted, complaint_resolved },
  teo:  { met, dream_discovered, practices_helped, report_discovered, credit_stolen, robotized, report_copy_saved },
  turn: { completed_count, correct_reviews, rushed_reviews, grouped },
  boss: { call_received, offer_resolved, offer_accepted },
  debt: { account_inspected, anomaly_discovered, original_contract_missing, teo_code_explained },
  secret_scene_seen,
  exit: { badge_obtained, badge_source, stairs_revelation_seen, lookback_seen }
}
```

Invarianti (controllate dai test): `credit_stolen` ⇒ `robotized` e niente badge regalato; il premio del capo una volta
sola; `complaint_submitted` ⇒ `duplicate_fee_found`; la scena segreta mai con Teo robot.
Il Capitolo 5 legge anche `GameState.is_robot("teo")`.

## L'economia

| Valore | Numero | Dove |
|---|---|---|
| Paga del turno | **800 €** all'obiettivo, fino a 1.000 € se vai più veloce (minimo 200 €) | `worklist.json` (`pay`, `pay_max`) |
| Turno veloce (pratiche raggruppate) | 800 €, dal 3° turno | `bank.json` (`rapido`) |
| Premio del capo | 3.000 €, una volta | `bank.json` (`premio_capo`) |
| Badge del Piano Terra | 4.000 € | `GameState.FLOORS` |
| Aiutare Olga e Teo | 1 ora ciascuno, niente euro | `npcs.json` |

La specifica proponeva 200 € più un bonus "da verificare con l'economia". Con 200 € servirebbero **20 turni**:
proprio la ripetizione che la specifica chiede di evitare. Con 800 € la salita onesta è di **5 turni**,
e i 3.000 € del capo restano una tentazione vera (meno di un giorno invece di quattro), non un obbligo.

### Simulazioni (partendo dalla Banca, un turno al giorno)

| Percorso | Cosa fai | Turni / giorni | Soldi alla fine | Conseguenze |
|---|---|---|---|---|
| **A — solo lavoro** | lavori e basta, da 0 € | 5 turni, 5 giorni (4 col turno perfetto a 1.000 €) | 0 € | frase generale |
| **B — solidarietà** | aiuti Olga (contestazione) e Teo, rifiuti il capo | 0 turni: badge regalato (anche il primo giorno) | quello che avevi, più i turni fatti | frase dell'aiuto, scena segreta, Teo legge il codice |
| **C — sfruttamento** | 1 turno, firmi il rapporto | 2 turni (800 + 3.000 + 800), 2 giorni; 1 col turno perfetto | 600 € | Teo robot, LV +1, niente regalo |
| **D — misto** | aiuti solo Olga (o solo Teo), rifiuti | 5 turni come A | 0 € | contestazione o pratiche, niente regalo |
| **E — saldo zero, turni falliti** | arrivi senza soldi e non riesci a lavorare | minimo 200 € a turno; dopo 3 turni falliti di fila: pietà o contratto | — | il "contributo" va sul debito, oppure il contratto del Signor Rata |

Gli interessi (2% a notte) fanno salire il debito ma non toccano i soldi: il badge costa sempre 4.000 €.

## I test

`tests/smoke_test.gd`, funzione `_test_chapter4` (e il pezzo finale di `_test_chapter3`, che ora arriva alla Banca nuova):

1. Dal Mercato si arriva alla Banca al -2, con l'arrivo, sulle scale.
2. Olga e Teo ci sono, Teo non è un robot; il riepilogo non c'è ancora.
3. SALTAFILA: "Quanto costa?", poi no; nessun soldo speso.
4. Olga: primo incontro senza aiuto.
5. LE RATE MANCANTI sbagliate: nessun aiuto, si riprova.
6. Riuscite: documenti in ordine, voce doppia trovata, aiuto contato.
7. Al ritorno la contestazione; nessun premio in euro. L'aritmetica dell'estratto conto torna.
8. La risposta di Olga solo dopo una notte; il rimborso è suo.
9. Teo: primo incontro.
10. LA PRATICA IMPOSSIBILE sbagliata: Teo non aiutato.
11. Riuscita: Teo aiutato. Il quaderno: il sogno.
12. Il turno paga 800 €.
13. Il capo chiama dopo il primo turno; "Perché io?" e "Ci penso" lasciano l'offerta aperta.
14. Secondo turno nello stesso giorno: niente paga.
15. Il giorno dopo si lavora ancora; il capo non richiama.
16. Dal 3° turno le pratiche raggruppate: 800 €, un turno solo.
17. Il terminale del conto è spento finché l'offerta è aperta.
18. Chiudere l'offerta al terminale: Teo resta Teo, rifiuto contato.
19. Il rapporto si segnala col nome di Teo.
20. Il conto mostra il debito vero; guardarlo non lo cambia.
21. L'anomalia, e Teo che legge il codice.
22. "Voglio soltanto pagarlo": la rata scala debito e soldi.
23. La scena segreta: compare, si vede una volta, nessun premio.
24. Nives: prima il prezzo, poi il badge regalato (soldi e debito invariati).
25. Mai due badge.
26. Il primo gradino: la rivelazione.
27. La frase dell'aiuto; lo sguardo indietro.
28. Il riepilogo `chapter_4` (contestazione, pratiche, badge regalato, anomalia, scena segreta, 3 turni, rapporto); si
    arriva al Capitolo 5 col salvataggio.
29. Un, due, tre, stella → leggere → firmare: 3.000 €, Teo robot, LV +1; il premio non si prende due volte; frasi da
    robot (anche quelle del quaderno); il quaderno resta; frase dell'impiegato perfetto; niente regalo né scena segreta;
    l'antenna; l'anomalia senza Teo.
30. Senza regalo: con 3.999 € no, con 4.000 € sì (soldi 0, debito −4.000); salvare e ricaricare conserva tutto.

E inoltre: lasciare la firma di Teo (niente premio, niente robot, il rapporto segnalato), le frasi generale e del dubbio,
l'economia A (5 turni = 4.000 €).

`tests/touch_test.gd`: le rate (un documento fuori ordine è un errore; sei in ordine; la rata non è la voce doppia;
la seconda commissione sì), le pratiche (tipo sbagliato / giusto), lo sportello (APPROVA frettolosa, VERIFICA giusta,
le pratiche chiuse contano tutte).

### Da provare a mano (sul telefono)

- [ ] L'arrivo: l'insegna e il display si leggono (non finiscono sotto la barra in alto).
- [ ] Le persone in fila non bloccano il passaggio verso lo sportello e verso Nives.
- [ ] Olga, Teo, il distributore, i terminali, l'archivio e il quaderno si raggiungono e si toccano.
- [ ] LE RATE MANCANTI: le carte si leggono (il dettaglio va a capo) e si toccano bene col dito.
- [ ] LA PRATICA IMPOSSIBILE: i cinque pulsanti in basso sono abbastanza grandi.
- [ ] Lo sportello: APPROVA e RICHIEDI VERIFICA si distinguono; il timbro si vede.
- [ ] Un, due, tre, stella con Teo all'archivio.
- [ ] Teo robot: l'antenna e il timbro si vedono anche in bianco e nero.
- [ ] La rivelazione sul primo gradino e lo sguardo indietro (Olga con la lettera, il quaderno, il terminale rosso).
- [ ] La salita al Capitolo 5 e il ritorno in Banca dalla Città (si arriva in cima alle scale).

## Punti aperti

- La grafica di `art/c4/` è tutta segnaposto (vedi `docs/ASSET_LIST.md`).
- Il "contributo di solidarietà" della pietà al -2 è ancora del Signor Tasso, personaggio della vecchia Banca
  (`scripts/room.gd`, `PITY`): funziona, ma il personaggio non si vede altrove.
- La musica è ancora quella della vecchia Banca (`banca`).
