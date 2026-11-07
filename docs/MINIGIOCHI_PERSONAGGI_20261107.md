# Minigiochi dei personaggi — revisione del 7 novembre 2026

Questa revisione riguarda gli aiuti ai personaggi; gli incarichi del Capo e i turni lavorativi
mantengono le proprie meccaniche. Mina è l'elettricista (ID storico bulbo); Bulbo è il nonno
delle lampadine (ID storico mina). Non rinominare gli ID usati nei salvataggi.

## Direzione visiva

Godot 4.6.3, 640×360, PC e Android in orizzontale. Riferimenti: i minigiochi già presenti,
la lampadina del Fondo, gli scaffali con i prodotti e i personaggi LimeZu già importati.
Pixel netti, campionamento nearest, inquadratura e proporzioni degli oggetti coerenti con
la grafica esistente. Testi e numeri rimangono leggibili e modificabili nel motore.

| Ruolo | Colori | Segnale aggiuntivo |
|---|---|---|
| Fondo e pannelli | #171d2a, #34485a | cornici e vani distinti |
| Carta | #eee4cc, #352b36 | righe, documenti e intestazioni |
| Selezione / azione utile | #ffe14d | bordo o parola esplicita |
| Errore | #ffb0a0 | X, spiegazione e tentativo escluso |
| Successo | #3ddc84 | filo collegato, merce sistemata, timbro o foglio consegnato |

Le lettere A–D accompagnano i colori dei fili. La X di Tilde resta un segno grafico,
non un semplice cambiamento di colore. Si riusano font, frecce, personaggi e oggetti
già presenti: nessun nuovo pacchetto Kenney o asset generato entra in questa revisione.
La scelta evita di mescolare famiglie grafiche senza necessità. Le licenze pregresse
restano quelle documentate in ASSET_LIST.md; questa revisione non le ridefinisce.

## Attività, miglioramenti e condizioni da mantenere

| Persona | Gesto del giocatore | Miglioramento | Invariante |
|---|---|---|---|
| Mina | collegare i fili | lettere oltre ai colori, tastiera oltre al trascinamento, contatore dei fili | niente collegamenti doppi; clic fuori dai connettori ignorati |
| Bulbo | riconoscere, avvitare e smistare | avviso di riparazione e di smistamento visibile anche dopo il tutorial | una lampadina riparata va nelle BUONE |
| Tilde | ricordare e filtrare una sequenza | quattro riquadri in posizioni stabili; la X si vede sul riquadro; dopo l'errore si riascolta lo stesso copione | un errore non genera un esercizio diverso; il clic fuori dai riquadri non è una risposta |
| Ercole | caricare e lasciare al momento opportuno | messaggi legati a sonno e forza, compreso LASCIA ORA | tenere sempre premuto continua a sovraccaricare il colpo |
| Leda | riconoscere il prodotto e metterlo nello scaffale | trascinamento reale, alternativa clic/tastiera, traccia visibile degli oggetti sistemati | lasciare fuori annulla; una consegna conta una volta sola |
| Amir | cambiare corsia e anticipare le porte | conservata la recente revisione; tolti i riferimenti narrativi al vecchio giro di sei pacchi | diciotto porte, quattordici consegne per il bonus, nove per l'aiuto parziale |
| Olga | confrontare le ricevute e timbrare il doppio | riferimento alla voce precedente, selezione da tastiera, primo doppio senza fretta | nessun rimborso anticipato; la prova della rata 63 resta necessaria |
| Teo | confrontare prove | evidenziata la stessa riga su entrambi i fogli, tre errori, tentativi errati riconoscibili | ripetere la stessa scelta errata non consuma tutte le possibilità; esistono pratiche senza anomalie |
| Ada | abbinare i volantini agli interessi | trascinamento dalla pila alla persona; mantenuto il verso precedente; primo esempio senza fretta | otto volantini letti; nessun doppio conteggio; la Casa chiusa non fa entrare persone |
| Nadir | scegliere un itinerario | anteprima di partenza, arrivo e costo; mappa più compatta per lasciare spazio ai dati | l'anteprima non prende corse e non spende soldi; restano cambio di tre minuti e budget |

Gli aiuti, gli oggetti e i finali usano gli stessi flag di prima. Non sono stati introdotti
nuovi premi, reset di salvataggi o nuove condizioni per i finali.

## Archivio e peso del progetto

I 300 file della vecchia scene_backup sono stati spostati in
../cheap_da_cancellare/pulizia_minigiochi_20261107/scene_backup: 325.889.978 byte.
Le copie precedenti alla revisione sono nella stessa cartella, sotto prima_revisione_personaggi.
Nessuna copia di sicurezza di questa revisione viene creata dentro il progetto Godot.
I backup erano già ignorati da Git e da Godot: lo spostamento libera la cartella di lavoro,
non riscrive la storia Git e non costituisce una misura dei tempi di avvio dell'editor.

## Prove

La regressione personaggi_minigiochi_test usa le scene reali e i comandi di tastiera o
puntamento. La sonda sostituisce soltanto la chiusura della partita per evitare di cambiare
storia e salvataggi durante i controlli isolati. Touch e aiuti_visivi verificano anche i
passaggi attraverso il normale gestore di input e gli esiti delle scene.
Le schermate PC e touch vengono catturate a 640×360 fuori schermo. Non sono foto da telefono.
Gli esiti dell'ultima esecuzione sono registrati nel resoconto della revisione.

## Stelle e risposte, verifica completa

Tutti i dieci aiuti dichiarano stelle=true e hanno risposte distinte per una, due e tre stelle,
oltre alla sconfitta. Regola comune: 3 stelle senza errori; 2 con un errore; 1 completando
l’obiettivo con almeno due errori; 0 se l’obiettivo non è completato. Mina ammette tre errori:
una vittoria con due errori, e quindi una stella, è ora raggiungibile. Il parziale di Amir
mantiene la risposta specifica e i flag di aiuto senza il bonus.

Il rigioco già disponibile per Mina, Bulbo, Tilde ed Ercole distingue un risultato migliore,
uguale o peggiore e mostra la battuta delle stelle appena ottenute. Il record non si abbassa;
il premio già ricevuto non viene ripetuto. Non sono state aggiunte scelte di rigioco ai dialoghi
di trama degli altri sei personaggi.

`tests/stelle_personaggi_test.tscn`: 489 controlli su 90 combinazioni tra esito e dispositivo,
con il vero pannello di risultato e i veri dialoghi. Confermati icone, battute visualizzate,
record, premi e parziale di Amir. Passano anche i 55 controlli dei minigiochi, i 34 di Ercole
e il controllo dei testi per dispositivo. I risultati sono simulati per verificare il sistema
delle stelle; non sono 90 partite giocate dall’inizio. La prova su telefono fisico resta distinta.


## Amir: furgone e ingressi, 7 novembre

Il carrello della spesa è sostituito da un furgone delle consegne LimeZu.
Tolte le tre grandi fasce di edifici ripetuti: strada e marciapiedi separano le corsie;
ogni destinazione mostra uno dei tre ingressi residenziali, con numero e luce.
Il pacco parte dal furgone; a consegna avvenuta si apre la porta, appare il destinatario
e la scritta PRESO! sostituisce il numero. Il tocco su una porta già servita non
consuma un altro pacco, anche se il dito era stato appoggiato prima della consegna.

Restano diciotto porte, quattro pacchi di scorta, quattordici consegne per il bonus,
nove per l'aiuto parziale, accelerazione, comandi, flag, stelle e risposte precedenti.
Gli ingressi e il furgone sono AtlasTexture a scala nativa con filtro nearest;
nessun nuovo asset generato. La cabina è quella originale del veicolo.

Controllati a schermo fuori schermo PC e touch a 640×360: gioco, lancio e consegna.
Passano aiuti_visivi (71 controlli), touch_test, testi_dispositivo (4865 frasi)
e la regressione esterna delle nuove interazioni (7 controlli).
Il simulatore touch non sostituisce una prova su telefono fisico.

Versioni precedenti di scene, script e documenti archiviate fuori dal progetto in
../cheap_da_cancellare/amir_consegne_20261107. Le texture del carrello restano perché
world/shopping_cart.gd le carica dinamicamente per il Mercato.
