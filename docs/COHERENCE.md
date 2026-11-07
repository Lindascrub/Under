# CHEAP — Regole attuali e continuità

Aggiornato il 5 novembre 2026, dopo l'approvazione della revisione completa. Questa pagina descrive il comportamento attuale. Il vecchio piano P1–P5 è conservato nella cronologia Git e nel backup della revisione; le sue proposte non sono istruzioni per cambiare automaticamente il gioco.

## Fonti

- `autoload/game_state.gd`: economia, tempo, badge, aiuti e salvataggi.
- `scripts/boss_missions.gd`: incarichi attuali e migrazione dei precedenti.
- `chapters/c6/direzione_regole.gd`: conti del turno di Direzione.
- `chapters/c6/finali.gd` e `docs/ENDING_SYSTEM.md`: condizioni dei finali.
- `chapters/c6/finale_c6.gd`: messa in scena ed epiloghi.

## Economia e progressione

| Tema | Regola attuale |
|---|---|
| Debito | Sette miliardi assegnati alla registrazione; il fascicolo della Presidente non è il contratto del padre. |
| Badge acquistato | Il costo viene sottratto sia al denaro sia al debito, come fa `buy_badge()`. Non è stata approvata una nuova economia. |
| Badge gratuito | Nessuna spesa e nessuna diminuzione del debito. Seguono i requisiti del relativo capitolo. |
| Notte | Salvare non fa passare la notte. Riposare applica tempo e interessi. |
| Aiutare | Si registra un aiuto concreto; liberare e rinunciare al Capo restano atti distinti. |
| Premi | I rifacimenti visivi mantengono premi e spesa di tempo dei giochi sostituiti. Pacchi e volantini non generano nuovi soldi. |
| Olga | Trovare il doppione non rimborsa subito. Contestazione e risposta dopo una notte rimangono separate; rimborso documentato di 35 €. |
| Nadir | Il gioco calcola il costo del percorso. La successiva offerta di lavoro non anticipa una cifra. |
| Casa Comune | Il minigioco di Ada distribuisce volantini; non ristruttura stanze e non crea voti aggiuntivi. |
| Direzione | Una prova sola, con bilancio, Casa e debiti. Le regole diventano effettive con A o con la decisione condivisa riuscita, secondo il sistema dei finali. |

## Incarichi del Capo e salvataggi

Le nuove partite usano sei decisioni distinte: energia e pausa di Fermo; fascicoli; cartellini; proposta a Olga; montaggio del notiziario; bilancio della Direzione. La scena del Capo non assegna automaticamente nuove robotizzazioni.

I salvataggi con incarichi precedenti conclusi o vecchi robot conservano il percorso `legacy`. I furti già registrati non vengono convertiti in incarichi nuovi, né ripagati. Un incarico attuale si riprende dalla postazione TURNO; premio e conseguenza si applicano una sola volta.

Per E-27, chiedere il registro lascia la richiesta in attesa. Non equivale a riconoscere gli anni di Ercole. Segnarla risolta la chiude senza la verifica.

Una proposta a Olga può essere completa e comunque sconveniente. Rendere leggibili le condizioni non impone una firma. Una correzione successiva riconosce anche il primo inganno.

Nel notiziario, il giocatore confronta fonte e montaggio. La rettifica ripristina il contesto, senza cancellare la prima trasmissione.

## Richiesta alla Presidente

Quattro casi distinti: arrivata, portata a mano, archiviata, assente. La richiesta archiviata viene ripresa; la copia di Teo aggiunge il suo momento, senza essere indispensabile alla contestazione.

La verifica del regolamento è diversa dal consenso del giocatore. La contestazione si registra solo quando il giocatore compie quel gesto. Possedere prove o aver richiesto la verifica non basta. La contestazione personale, da sola, non sospende o cancella il debito.

## Personaggi e finali

- Gli ID storici restano invariati: `bulbo` è Mina, un'elettricista donna; `mina` è Bulbo, il nonno delle lampadine.
- Le battute del protagonista restano quelle concordate; il protagonista è maschile.
- La conclusione di ogni piano considera anche il torto del nuovo incarico, la riparazione e la presenza visibile della persona.
- Finale B: casa, lavoro, riepilogo e invito provengono dalle rispettive fonti. Nessuna offerta appare senza il dialogo che la propone.
- Tilde cambia le procedure solo con una revisione effettiva dei debiti o una trasformazione istituzionale C2.
- La cucina di Amir richiede il sogno ascoltato e la Casa effettivamente aperta.
- In C3 servirebbero sei sedie; ne avete portate due.
- Nives può ricordare le partite precedenti. Rimandare il ricordo facoltativo permette di ritrovarlo al piano successivo; non lo ripete nello stesso posto.

## Input, esempi e compatibilità dei giochi

Le istruzioni mostrano soltanto i comandi del dispositivo in uso. Le prime prove di fili, lampadine, Tilde, Ercole, Leda e Nadir non consumano tempo o errori fino al gesto previsto. Non si ripetono integralmente dopo averle completate.

Amir, Olga, Teo e Ada usano le scene in `scenes/minigame/rifatti/` quando la configurazione ha `visivo: true`. Lo Snake di Amir resta solo per le configurazioni vecchie; la partita corrente non lo apre.

Le scene del Capo -4/-3/-2/0 sono modificabili nell'editor. I conti e gli stati restano in `boss_missions.gd`; le scene non inventano premi o esiti.

## Revisione dei dialoghi approvata da Linda (5 novembre 2026)

- L'apertura passa dalla sveglia alla cucina e alla camera del padre. Il titolo TORRE CHEAP precede la cabina. La voce CHEAP ha battute separate dalla narrazione.
- Fermo spiega il turno di dieci ore, la stellina (salvataggio oppure notte), gli interessi e l'acquisto dei badge. Indica Mina, donna elettricista, e Bulbo, nonno delle lampadine.
- Alla Banca Teo constata che il contratto non si trova; l'assenza del consenso e l'origine della quota sono chiarite alla Cima. Il protagonista può quindi distinguere la propria registrazione dal debito che attribuiva al padre.
- La proposta da 1.200 euro a Olga è un prestito aggiuntivo al mutuo, non la rinegoziazione del mutuo. L'invio non equivale a firma o addebito.
- Un solo turno di Direzione: gli avvisi riguardano conseguenze future, senza promettere altri turni da giocare. Le vecchie consultazioni restano per compatibilità dei salvataggi.
- Le istruzioni complete degli incarichi sono mostrate alla prima apertura; le scene conservano promemoria brevi.

## Notiziario: tavolo di montaggio, 7 novembre 2026

Le tre fonti sono registrazioni raccolte in piazza, rappresentate da rulli e miniature.
Il giocatore sposta gli spezzoni sulla pista, li riordina, taglia o ripristina il contesto
e guarda l'anteprima. Sessanta secondi sono capienza del servizio, non tempo per leggere.
Ogni taglio conserva l'originale. La trasmissione richiede una conferma separata;
nessun gesto impreciso applica automaticamente un taglio o manda in onda il servizio.
Restano tre fonti, limiti di durata, premi, rettifica e conseguenze precedenti.
Le versioni sostituite sono fuori dal progetto: ../cheap_da_cancellare/notiziario_20261107.

La richiesta della Banca è mostrata una volta prima del primo turno in Città, se esiste
e non è stata ancora smistata. Cassetto, tubo e stampante mostrano la destinazione;
il lavoro ordinario resta l’autobus. La scelta non paga e non consuma un turno.

## Fascicoli del Capo: fogli e timbri, 7 novembre 2026

I documenti presenti si posano nelle sagome; registro e fattura assenti restano assenti.
Timbrare non consegna: si può cambiare impronta. RISOLTA su E-27 richiede una conferma
che chiarisce la chiusura senza risposta; chiedere il registro lascia la domanda in attesa.
Il campo opzionale paperwork conserva fogli e timbro senza alterare le decisioni canoniche.
Le vecchie bozze continuano dal fascicolo corrente. Il testo completo è nei dettagli facoltativi.
Le versioni sostituite sono in ../cheap_da_cancellare/fascicoli_20261107.

## Cartellini del Capo: stampa e composizione, 7 novembre 2026

La rotella, i listini e i prodotti scelgono gli stessi parametri precedenti.
La stampa conserva i dati mostrati: cambiarli richiede una ristampa. Le etichette
non possono coprire accidentalmente le condizioni, che si spostano al terminale
con un gesto esplicito. Una conferma distinta precede l'applicazione di condizioni
materialmente nascoste. La cassa di prova mostra sempre quantità e costo effettivo.
Premi, prezzi, reclami, Leda, Amir e finali seguono le regole precedenti.
Il campo opzionale label_work salva la bozza senza cambiare le offerte concluse.
Le vecchie versioni sono in ../cheap_da_cancellare/cartellini_20261107.

## Prestito del Capo: calendario e due copie, 7 novembre 2026

Il calendario mostra durata e compromesso fra rata e totale del nuovo prestito,
aggiuntivo al mutuo di Olga. I costi restano sempre visibili nella copia interna.
Spostare il riepilogo nella tasca lo toglie dalla copia per Olga senza cambiare
gli importi. La durata resta sulla copia: Olga chiede il totale mancante.
Ogni invio richiede una conferma distinta e lascia a Olga la scelta se firmare.
Restano soglia mensile, conti, premio, bozza, correzione successiva e finali.
Il renderer generico non più utilizzato è fuori dal progetto insieme alle versioni
precedenti: ../cheap_da_cancellare/olga_calendario_20261107.

## Direzione: gettoni e anteprima, 7 novembre 2026

Il turno unico conserva cento unità, mandati, Casa, debiti e calcoli dei finali.
I gettoni si spostano fra le stesse quattro voci, da cinque o una unità. L'anteprima
applica le regole su una copia profonda e non cambia il mondo reale. Soglie,
contratti minimi, limite per voce e costi della consultazione restano quelli esistenti.
Selezionare una scheda della Casa o dei debiti apre i dettagli; SCEGLI applica.
Prove, reti e disponibilità dipendono ancora dalle azioni compiute nei capitoli.
I campi opzionali phase, mandate e casa_id nella bozza permettono la ripresa;
le vecchie bozze con sola alloc restano valide e il risultato concluso non cambia.
Le versioni precedenti sono in ../cheap_da_cancellare/direzione_tavolo_20261107.

## Fermo: ritmo, cartellino e luci, 7 novembre 2026

Leva, minuti extra e decorazioni sono indipendenti e conservano gli stessi tre
campi salvati. Il collegamento fisso dei servizi precede le luci della festa;
solo l'energia disponibile le accende. Spegnerle permette di mantenere il ritmo
normale e tutta la pausa senza premio. L'inattività non consuma pausa.
La conferma mostra sforzo, pausa e premio prima dell'applicazione. Restano i conti,
il compenso una sola volta, riparazione, torto e finali. Le 45 combinazioni esistenti
si riprendono senza passare per le vecchie tacche e senza cambiare le decorazioni.
Le versioni precedenti sono in ../cheap_da_cancellare/fermo_circuiti_20261107.
