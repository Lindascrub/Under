# CHEAP — Primo passaggio dei minigiochi narrativi

7 novembre 2026. Implementati notiziario del Capo e breve scena del centralino.
Gli altri incarichi restano da trasformare secondo PROPOSTA_MINIGIOCHI_NARRATIVI.md.

## Tavolo di montaggio

Tre strisce con immagini e persone sostituiscono il menu di configurazione.
Si trascinano sulla pista, si riordinano e si riportano alle fonti per rimuoverle.
Forbici e RIMETTI operano sullo spezzone selezionato; il contesto originale resta
sul tavolo. Il televisore confronta il montaggio con la stessa persona selezionata,
anche dopo un riordino. Il servizio si guarda in anteprima, con pausa; FATTI include
il cartello verificato per dieci secondi. Sessanta secondi sono capienza, non fretta.

Tastiera: frecce e INVIO selezionano gli oggetti; fonte e poi pista inseriscono.
Con uno spezzone selezionato, MAIUSC + freccia cambia l'ordine e CANC lo rimuove.
Mouse e touch: trascinamento oppure selezione fonte e poi pista. Un rilascio fuori
annulla; un rullo già presente non viene inserito una seconda volta.

TRASMETTI apre una conferma separata e permette di tornare al tavolo. Le parole
trasmesse, le durate, il premio per i tagli, l'effetto sull'assemblea e la rettifica
seguono le regole precedenti. La trasmissione non ripete poi tutte le interviste
come pagine di dialogo: dopo la consegna restano compenso e conseguenze narrative.

Rimossi la scena a pulsanti precedente, il ramo notiziario del vecchio renderer
condiviso e il menu testuale di riserva. Le copie sono archiviate fuori da Godot.

## Richiesta della Banca

Il lavoro ordinario in Città rimane la linea 12. Con una verifica ancora da smistare,
la richiesta compare prima del primo turno: cassetto ARCHIVIO, tubo DIREZIONE,
stampante LA PORTO IO. Una breve scelta conserva il normale sistema dialoghi e
il foglio si muove fisicamente verso la destinazione selezionata.

Visitare prima il centralino consente la stessa scena. Senza richiesta non compare;
una scelta registrata non viene ripetuta. Partite già oltre il primo turno mantengono
il percorso precedente. Nessun nuovo costo, premio o turno consumato. Restano le
quattro condizioni riconosciute dalla Presidente e gli esiti successivi.

## Grafica e risorse

Riusati font Pixeloid, personaggi LimeZu, facciata home, insegna Casa Comune,
cartello e vetrina rotta già presenti. Strisce, pista, forbici e oggetti del
centralino sono disegnati dal motore. Nessun nuovo PNG o pacchetto scaricato.
La stampante del centralino è un disegno specifico, senza modificare quella della Cima.

Le aree principali del montaggio e i componenti del foglio sono modificabili nelle
scene. I conti e i dati serializzati restano in scripts/boss_missions.gd.

## Verifiche eseguite

- boss_montaggio_test: 111 controlli, PC e touch, 640×360 / 1280×720 / 1000×600.
  Input tramite il normale gestore del gioco. La sonda sostituisce solo il ritorno
  alla stanza dopo la consegna, per controllare il risultato senza cambiar scena.
- boss_rules_test: 721 controlli, zero errori.
- boss_integration_test: 81 controlli, zero errori.
- boss_playthrough_test: 56 controlli, zero errori; usa i nuovi oggetti del montaggio
  per completare entrambi i percorsi degli incarichi. Include volutamente un
  salvataggio corrotto per provare il recupero, che produce il relativo log JSON.
- aiuti_visivi_test: 71 controlli, zero errori.
- storia_test: 126 controlli, compresi sei nuovi sul passaggio prima del turno.
- testi_dispositivo_test: 173 file e 4902 stringhe controllate, esito OK.
- Schermate native fuori schermo: PC/touch, originale, taglio, conferma e fatti;
  centralino nelle tre scelte e nei tre esiti. Non sono foto da telefono fisico.

Alcune suite lasciano warning ObjectDB/resources alla chiusura: gli esiti delle
verifiche sono separati da questi messaggi. La comprensione e il piacere di gioco
restano da valutare con una persona che prova il prototipo.

## Archivio

Le versioni sostituite sono in ../cheap_da_cancellare/notiziario_20261107, comprese
le copie dei file condivisi prima della modifica. I file condivisi ancora necessari
agli altri incarichi restano nel progetto. Nessun salvataggio personale resettato,
nessun commit creato, nessuna riscrittura della storia Git.


# Sottoufficio — Il fascicolo incompleto

Secondo passaggio dei minigiochi narrativi, 7 novembre 2026.

Il corpo dei fascicoli viene sostituito da fogli sul tavolo e sagome da riempire.
Si usa un timbro sul fascicolo e poi si consegna. I quattro casi e le destinazioni
restano quelli canonici: rimborso già ricevuto; domanda di Ercole senza registro;
cambio turno con due firme, da autorizzare; acquisto di lampadine senza fattura.

Ogni documento presente si inserisce una volta nella sua sagoma. Quelli mancanti
non si possono produrre trascinando altro. Un rilascio fuori annulla e un foglio
già posato può tornare sul tavolo; togliere una prova invalida il timbro precedente.
Il timbro si può cambiare prima della consegna. Ercole + RISOLTA richiede una conferma
che spiega che la domanda si chiude senza risposta. La richiesta del registro
rimane IN ATTESA: nessun riconoscimento di anzianità inventato, nessuna modifica al B-4.

Il tutorial è una sola frase. Il testo completo originale resta in DETTAGLI,
facoltativo. Il gioco non introduce un conto alla rovescia per leggere o decidere.
Le animazioni di fogli e timbri sono brevi; le conseguenze si applicano con la
consegna, una sola volta. Il premio resta 900 euro esclusivamente per la chiusura
di E-27, alla fine dei quattro fascicoli. Non cambiano tempo di gioco, altri premi,
robotizzazioni o condizioni dei finali.

Mouse/touch: trascina oppure scegli oggetto e poi destinazione. Tastiera: frecce
per muoversi fra gli oggetti sulla scrivania, INVIO per prendere e applicare;
annulla restituisce l'utensile o chiude i dettagli. La bozza salva documenti
posati e impronta nel campo opzionale `paperwork`, usando gli ID dei fascicoli.
Le vecchie bozze senza quel campo continuano dal fascicolo corrente.

La grafica riusa font, ritratto di Ercole e lampadina esistenti; carte, sagome e
timbri vengono disegnati dal motore. Nessun nuovo PNG e nessun pacchetto scaricato.
Le aree di interazione sono modificabili in capo_documenti.tscn. Rimossi i vecchi
pulsanti, il ramo fascicoli nel renderer condiviso e il disegno testuale di riserva.

Controlli: boss_fascicoli_test 247 (due percorsi, mouse/touch, tre risoluzioni,
input da tastiera, ripresa della bozza, protezione da doppie consegne);
boss_rules 721; boss_integration 81; boss_playthrough 56; aiuti_visivi 71;
testi_dispositivo 174 file / 4969 frasi. Tutti superati. Il playthrough usa le
nuove azioni dei fogli e dei timbri, non le vecchie azioni del menu.

Schermate native fuori schermo a 640×360, PC e touch: quattro fascicoli,
impronta, richiesta di Ercole e conferma di chiusura, dettagli facoltativi.
Touch simulato; il piacere e la comprensione durante una partita restano da
valutare con una persona. Alcune suite riportano messaggi ObjectDB/resources
alla chiusura; il test di recupero di un salvataggio rotto genera volutamente
anche il relativo errore JSON, separato dagli esiti dei controlli.

Archivio: ../cheap_da_cancellare/fascicoli_20261107. Contiene le versioni precedenti
dei file sostituiti e condivisi, senza copie di sicurezza nel progetto Godot.
Nessun commit creato e nessun salvataggio personale resettato.


# Mercato — Lo sconto in vetrina

Terzo passaggio dei minigiochi narrativi, 7 novembre 2026.

Una stampante, una rotella, due listini e i prodotti sostituiscono la lista dei
parametri. La percentuale si regola sulla rotella; oggi/futuro si scelgono dai
listini, anche trascinandoli nell'ingresso BASE; uno o due prodotti rappresentano
il minimo richiesto e possono essere trascinati nella prova della cassa.

STAMPA produce due etichette, prezzo/sconto e condizioni, che si compongono
liberamente sul cartellino. Entrambe entrano nella superficie utile; sono accettate
disposizioni diverse. Sovrapporle o rilasciarle fuori non nasconde informazioni.
Le condizioni vanno al terminale solo con un gesto esplicito. Prima di applicare
un'offerta con condizioni materialmente nascoste compare una conferma distinta,
con possibilità di tornare al banco. La quantità e il costo effettivo restano
visibili alla prova della cassa. Il figurante è un cliente della simulazione,
non una vendita già avvenuta nella storia.

La stampa conserva gli importi effettivamente stampati. Cambiare base, minimo o
percentuale richiede una ristampa: il vecchio cartellino resta visibile ma non
si può consegnare. La firma comprende anche prezzi reali e prodotto corrente,
così un aggiornamento dei prezzi non rende valida una vecchia etichetta.
Con percentuale zero il cartellino mostra il prezzo, senza un falso «-0%».

Tastiera: frecce e INVIO selezionano e usano gli oggetti; MAIUSC + frecce sposta
l'etichetta presa, annulla la lascia. Mouse/touch: trascinamento oppure selezione
dell'etichetta e destinazione. Il tutorial è una frase, senza cronometro.

I conti restano in boss_missions.gd. Restano pane, latte, acqua, percentuali
0/10/50, oggi/futuro, minimo 1/2, il controllo contro un falso sconto e il premio
di 500 euro per cartellino opaco, fino a 1500. Nascondere condizioni prive di
effetti materiali non aggiunge premio. Il compenso si applica una sola volta alla
fine dei tre prodotti. Reclami, aggiornamento successivo dei prezzi, reazioni
di Leda e Amir, flag e condizioni dei finali non cambiano. Nessuna nuova robotizzazione.

Il campo opzionale label_work conserva stampa e disposizione della bozza, mentre
labels rimane la registrazione canonica delle offerte già consegnate. Le vecchie
bozze senza la stampa conservano scelte e cartellini conclusi e possono ristampare
il prodotto corrente. Non viene resettato alcun salvataggio personale.

Riusati font, illustrazioni dedicate dei prodotti e figurante LimeZu. L'acqua usa
una singola bottiglia del foglio grocery.png, regione (128, 872, 16, 24), senza
modificare il PNG. Stampante, cassa, tasca del terminale e carta sono disegnati
dal motore. Nessun nuovo PNG o pacchetto scaricato. Le aree si modificano nella
scena; superficie e dimensioni delle etichette sono vincoli del puzzle.

Rimossi la vecchia scena a pulsanti, il ramo Mercato del renderer condiviso, il
disegno testuale di riserva e le vecchie azioni di menu nel controller. Il renderer
condiviso rimane per l'incarico della Banca, ancora da trasformare.

Verifiche: boss_cartellini_test 281 controlli su mouse/touch e tre risoluzioni,
con tastiera, collisioni, ripresa, ristampa, conferma e tocchi ripetuti durante
l'applicazione. boss_market_test 22; boss_rules 721; boss_integration 81;
boss_playthrough 56; aiuti_visivi 71; testi_dispositivo 175 file / 5012 frasi.
Le suite sono superate; il playthrough usa la nuova stampante e le nuove etichette.
La sonda del test isolato sostituisce soltanto il ritorno alla stanza dopo il premio.

Schermate native fuori schermo: PC/touch, tre prodotti, stampa completa, condizioni
al terminale, conferma, vecchia stampa e disposizione alternativa. Touch simulato;
telefono fisico e comprensione durante una partita restano da provare. I warning
ObjectDB/resources di chiusura e il log del salvataggio volutamente rotto nel
test di recupero sono separati dagli esiti delle verifiche.

Versioni precedenti fuori dal progetto: ../cheap_da_cancellare/cartellini_20261107,
compresi i file condivisi prima della modifica e le build sostituite. Nessun commit
creato e nessuna riscrittura della storia Git.


# Banca — Il calendario di Olga

Il nuovo prestito di 1.200 euro si aggiunge al mutuo già esistente. Il giocatore
allunga il calendario a 12, 24 o 36 mesi e confronta la rata con i 65 euro
disponibili. La pila del totale distingue il capitale dai costi aggiuntivi;
durata, rata ordinaria, ultima rata, interessi, spesa iniziale e totale restano
leggibili. Tasso e spesa iniziale si regolano sul tavolo. Non c'è un cronometro.

Le due copie sono affiancate. Il riepilogo dei costi si può spostare dalla copia
per Olga alla tasca interna e recuperare senza modificare gli importi. Il totale
resta sempre visibile al giocatore nella copia interna. Un rilascio fuori dalle
copie annulla lo spostamento; selezione e destinazione sono un'alternativa al
trascinamento. Frecce e INVIO permettono le stesse azioni; annulla restituisce
il foglio o chiude la conferma.

INVIA apre una conferma separata per entrambe le proposte: completa e incompleta.
La conferma chiarisce cosa riceve Olga e che deve ancora decidere se accettare.
I tocchi ripetuti durante l'animazione non inviano o pagano due volte. Una rata
oltre il budget resta modificabile; non completa l'incarico.

Restano i calcoli di ammortamento ai centesimi, l'ultima rata di saldo, i parametri
originali e il premio di 3000 euro solo per il riepilogo nascosto, zero per la
proposta completa. I quattro campi della bozza sono quelli già salvati: nessuna
migrazione o cancellazione dei progressi. Restano l'offerta a Olga, il confronto
successivo, la possibilità di correzione e tutte le condizioni dei finali.
Nessun addebito automatico del prestito, nessuna robotizzazione di Teo.

La battuta immediata di Olga chiede ora quanto pagherà in tutto: la durata è già
scritta sulla sua copia. Tolto il lungo elenco numerico dopo l'invio, già leggibile
sul tavolo e nella conferma; conservate le reazioni e la distinzione proposta/firma.

La scena usa Pixeloid, il ritratto LimeZu di Olga e oggetti disegnati dal motore:
calendario, copie, tasca, manopola e monete. Nessun nuovo pacchetto o PNG. Le aree
si modificano in capo_contratto.tscn. Il renderer generico incarico.gd, rimasto senza
utilizzatori, è stato spostato con il suo UID fuori dal progetto. Tolti anche il
disegno testuale di riserva e le vecchie azioni di menu del prestito.

Verifiche: boss_calendario_test 222 controlli, mouse/touch su tre risoluzioni,
tastiera, bozza salvata e ripresa, foglio spostato e restituito, rata oltre budget,
conferma annullata e invio ripetuto. boss_rules 721; boss_integration 81;
boss_playthrough 56; aiuti_visivi 71; storia 126; testi_dispositivo 175 file / 5038
frasi. Tutte le suite sono superate. Schermate native PC e touch fuori schermo: proposta iniziale,
costi maggiori, riepilogo interno, conferma e rata fuori budget.

Il touch è simulato; comprensione durante una partita e telefono fisico restano
da provare. I warning ObjectDB/resources di chiusura e il messaggio della prova
con salvataggio volutamente rotto sono distinti dall'esito delle suite.

Versioni precedenti in ../cheap_da_cancellare/olga_calendario_20261107, comprese
le versioni dei file condivisi prima di questa modifica e le build sostituite.
Nessun commit creato e nessuna riscrittura della storia Git.


# Cima — Il tavolo della Direzione

Le cento unità sono gettoni fra quattro destinazioni: stipendi, servizi,
manutenzione e riserve. Trascinare sposta fondi; selezionare origine e destinazione
offre la stessa azione senza trascinare. Più e meno usano le unità libere sul tavolo.
GETTONE cambia quantità fra cinque e una unità. I residui hanno il loro valore
scritto: non si anima un trasferimento da cinque quando ne passa solo una.

I quattro riquadri mostrano persone e buste, autobus, ascensore merci e cassaforte.
Gli stipendi si confrontano con i prezzi, il servizio mostra accesso a pagamento
o ampliamento, la manutenzione anticipa arretrato e guasto previsto, la cassa
mostra le riserve dopo le spese. Sono anteprime: il mondo non viene modificato.
Una dicitura lo chiarisce. I conti estesi sono in DETTAGLI; nessun cronometro.

I calcoli restano in direzione_regole.gd. preview esegue apply su una copia profonda
e restituisce il risultato reale senza toccare dati, log o flag del giocatore.
allocate e transfer rispettano le stesse cento unità, minimi contrattuali e tetto
di sessanta per destinazione. Le soglie delle conseguenze e dei finali non cambiano.
Restano i quattro mandati, i costi ai lavoratori e il costo della consultazione,
la conferma del bilancio, gli stati della Casa e le quattro regole dei debiti.

La Casa è un edificio con Ada e con tornello o chiusura secondo la storia.
Il debito è un fascicolo con numero di prove e reti realmente raccolte. Selezionare
una scheda apre i dettagli; SCEGLI è un gesto distinto. I motivi di indisponibilità
rimangono visibili. Per le regole aperte dei debiti una breve riga indica l'effetto,
mentre il dettaglio conserva la spiegazione completa. Nessuna rete o prova inventata.

SALVA/ESCI conserva fondi, mandato, fase e Casa già scelta, senza applicare il turno.
La bozza riprende anche prima della decisione sui debiti. I campi nuovi sono
opzionali: una bozza vecchia con solo alloc resta valida. Le bozze di altri cicli
sono ignorate come prima; gli incarichi conclusi non ripartono e il turno viene
applicato una sola volta. Il formato dello stato concluso non cambia.

Le aree sono in direzione_tavolo.tscn; il flusso resta in direzione.gd. Rimossi
tabella e disegno precedenti, vecchio input duplicato e costanti grafiche inutili.
Riusati Pixeloid e personaggi LimeZu presenti nel gioco; gettoni, autobus, ascensore,
cassaforte e modellino della Casa sono disegnati dal motore. Nessun nuovo PNG.

Verifiche: direzione_tavolo_test 190 controlli su conservazione dei fondi, minimi,
anteprima esatta senza effetti, mouse/touch su tre risoluzioni, tastiera, annullamento,
residui, ripresa e vecchie bozze. La sonda salta l'introduzione e intercetta la fine;
le suite di integrazione e storia usano invece il turno e il completamento reali.
Passati anche boss_rules (721), boss_integration (81), storia (126), touch_test
e testi_dispositivo (177 file / 5095 frasi). La ripresa da Casa o debiti non ripete
l'introduzione alla distribuzione dei fondi, già conclusa.

Schermate native PC/touch fuori schermo: distribuzione iniziale, aumento con
manutenzione scoperta, servizio a pagamento, tre stati della Casa e regole dei debiti.
Touch simulato; telefono fisico e comprensione osservata durante la partita restano
da provare. I warning ObjectDB/resources di chiusura sono distinti dagli esiti dei test.

Versioni sostituite fuori da Godot in ../cheap_da_cancellare/direzione_tavolo_20261107,
comprese le build precedenti. Nessun commit creato e nessun salvataggio personale usato.


# Fondo — La festa e la pausa di Fermo

La leva regola il ritmo 1/2/3, il cartellino sposta 0/5/10/15/20 minuti extra,
il quadro della festa seleziona decorazioni spente, tre luci oppure sei luci.
I tre comandi sono indipendenti. Non si scelgono più automaticamente le luci
in funzione della leva e non si perdono scelte salvate fuori dalle vecchie tacche.
Il collegamento dei servizi essenziali è fisso e riconoscibile come presa, distinto
dalle lampadine. Il cavo parte dalla cyclette e arriva al quadro.

Si vedono energia prodotta e richiesta, le luci realmente alimentabili dopo i
servizi, la pausa sul cartellino e sotto Fermo, il ritmo delle sue pedalate, colore
e sudore. Le sei luci equivalgono ai due livelli esistenti di decorazioni: 15 energia
ogni gruppo di tre. Una richiesta senza corrente mostra le luci spente e un avviso;
la conferma resta bloccata. Il giocatore può spegnere la festa e alimentare i servizi
al ritmo normale senza togliere pausa e senza ricevere premio.

La pausa cambia solo per una scelta del giocatore. Animazione, inattività e attesa
non consumano minuti. Il cartellino si sposta trascinando o selezionando una tacca;
rilasciare fuori o annullare restituisce il valore di partenza. La leva ha lo stesso
annullamento. Tastiera: SU/GIÙ sceglie un oggetto, SINISTRA/DESTRA regola ritmo o
minuti, INVIO usa. L'uscita è raggiungibile con gli stessi comandi.

La conferma separata mostra ritmo, extra, luci, pausa rimasta e premio prima di
APPLICA, anche quando il premio è zero. RIVEDI torna ai controlli. Il secondo
tocco nella posizione del primo pulsante non applica; gli invii ripetuti non
accreditano due premi. Il fuoco da tastiera è visibile sopra la conferma.

Le battute brevi di Fermo seguono pausa e sforzo, senza cambiare le risposte del
protagonista. Restano i tre campi intensity, extra e decor, gli stessi conti di
energy_preview e finish_energy e i 600 euro solo per lo sforzo aggiuntivo. Non ci
sono nuove risorse, stelle o robotizzazioni. Restano la riparazione successiva,
la memoria del torto e le condizioni dei finali. Nessun reset dei salvataggi personali.

Riusati font Pixeloid, personaggio cheap_fermo, cyclette gym.png e lampadina del Fondo.
Cavi, quadro e cartellino sono disegnati dal motore. Corpo e cyclette vengono
disegnati nello stesso CanvasItem affinché la conferma li copra correttamente;
particelle e animazione mantengono le risorse precedenti. Il movimento della pausa
usa un tween breve, senza rallentare l'input o modificare i calcoli.

Tolti le vecchie tacche accoppiate, la selezione automatica delle decorazioni,
le etichette sostituite nella scena e il renderer testuale di riserva dal controller.
Le aree restano modificabili in capo_dinamo.tscn. Nessun nuovo PNG scaricato.

Verifiche: fermo_circuiti_test 218 controlli, con tutte le 45 combinazioni salvabili,
mouse/touch su tre risoluzioni, tastiera, annullamento, ripresa, servizi, pausa,
conferma e premi singoli. boss_rules 721; boss_integration 81; boss_playthrough 56;
testi_dispositivo 177 file / 5122 frasi. Tutte le suite superate. La sonda del test
dedicato intercetta solo il ritorno alla stanza; commit, premio e flag sono reali.
Integrazione e playthrough usano la telefonata e il ritorno al Fondo reali.

Schermate native PC/touch fuori schermo: corrente insufficiente, pausa intera con
luci spente, festa alimentata con minuti extra, ritmo forte e due conferme.
Touch simulato; telefono fisico e comprensione durante una partita restano da provare.
I warning ObjectDB/resources di chiusura e il messaggio del salvataggio volutamente
rotto nel test di recupero sono distinti dagli esiti delle verifiche.

Versioni precedenti in ../cheap_da_cancellare/fermo_circuiti_20261107, comprese le
build sostituite. Nessun commit creato e nessuna riscrittura della storia Git.
