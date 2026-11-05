# Revisione completa approvata il 5 novembre 2026

Linda ha scelto di eliminare la cifra dall'offerta di lavoro di Nadir e ha approvato il resto delle proposte narrative, dei minigiochi e della presentazione. Questa revisione conserva trama, condizioni dei finali, economia e battute del protagonista.

Skill applicate: sw-dialogue, joke-engineering, ux-writing e revision-continuity per testi e continuità; designing-mini-games per le decisioni e gli esiti; godot-nodes-scenes e godot-gdscript-patterns per scene e collegamenti. I controlli headless non sono presentati come una prova del divertimento.

## Testi e continuità

Applicate le proposte C1–C6, F e G del documento di revisione: partenza unica con l'introduzione della cucina; primo passo per il B-4; risposte di Ercole; sei pacchi per l'ultimo giro di Amir; conseguenze dei cartellini; offerta di Nadir senza cifra; significato delle scelte al centralino; conti della Casa; distinzione tra fascicolo, verifica e consenso; reazioni del Capo; epiloghi coerenti con offerte e riforme effettive.

Rimandare il ricordo facoltativo di Nives lo rende disponibile al piano successivo. Gli altri ricordi mantengono le rispettive condizioni.

I nomi delle vecchie variabili restano compatibili: `c4_olga_ordinati` indica il controllo completato anche nella nuova scena; `c5_ada_stanze` indica l'aiuto dei volantini, senza attribuire lavori alle stanze.

## Aiuti e presentazione

| Persona | Modifica |
|---|---|
| Tilde | Un segno valido e una X come primo esempio gratuito; poi parte la sequenza completa. |
| Ercole | Prima gomitata libera, sonno fermo e nessuna penalità fino al rilascio utile. |
| Leda | Prima scatola senza tempo o penalità; il prodotto si muove nello scaffale scelto. |
| Amir | Sei lanci da una bici su tre corsie. Le porte scorrono, la traiettoria anticipa l'arrivo, il destinatario prende il pacco. Sei consegne con almeno quattro precise danno il bonus; almeno tre danno aiuto parziale. Nessun nuovo premio monetario. |
| Olga | Contratto ed estratto consultabili. Le commissioni del 18 e 19 giugno riguardano la stessa rata 63. Un errore dà un indizio, senza togliere denaro; il rimborso resta successivo alla contestazione. |
| Teo | Originale e copia affiancati; differenze documentali, due pratiche pulite, comando NESSUNA ANOMALIA e timbro CONTROLLATA. |
| Ada | Facciata della Casa usata in Città, tre pile e tre interessi con simboli. Il foglio passa alla persona che lo legge. L'ingresso non viene usato durante la riconversione. |
| Nadir | Prima tratta senza tempo o penalità; il primo tratto valido conclude la guida. Restano orari, budget e tre minuti per il cambio. |

Fili e lampadine conservano la dimostrazione già approvata e l'immagine scelta per le lampadine. Le istruzioni dei lavori ordinari erano già distinte per dispositivo e fase; sono state controllate insieme agli altri testi. Le risposte del call center distinguono copione, sincerità e sgarbo.

Le scene nuove stanno in `scenes/minigame/rifatti/`. Gli oggetti usano nodi e risorse modificabili nell'editor, con tempi esportati. La bici, l'attrezzo e il fumetto sono composti da nodi; personaggi, porte, edificio, panca, prodotti e pacchi riusano gli asset presenti. Non sono stati acquistati o scaricati nuovi pacchetti.

## Capo e Direzione

| Piano | Presentazione e regola conservata |
|---|---|
| -4 | Fascicolo che va nella vaschetta scelta. E-27 richiede il registro; chiedere integrazione lascia la pratica in attesa. |
| -3 | Cartellino visibile al cliente e totale alla cassa. Riferimento, quantità e condizioni restano parte dei conti. |
| -2 | Copia interna completa e pagina letta da Olga. Nascondere il riepilogo copre solo la sua copia; non inventa una firma. |
| 0 | Registrazione e contesto accanto al montaggio, durata dei sessanta secondi e fatti verificati. |
| Cima | Ogni mandato ha la propria spiegazione. Prima di confermare si vede la ripartizione delle spese tra riserve e servizi. |

Le scene emettono azioni; i risultati continuano a essere calcolati da `boss_missions.gd` e `direzione_regole.gd`. Il Capo del Fondo conserva la leva già realizzata.

## Giochi accessori e percorsi precedenti

La presenza di un gioco nel codice non significa che sia nel percorso corrente. L'inventario deriva da `worklist.json`, `Room.add_station()`, dai nodi `PostoTurno` e dalle chiamate ai giochi.

| Gioco | Raggiungibilità |
|---|---|
| Cyclette, helpdesk, cassa del Mercato, sportello e centralino | Postazioni del percorso principale, rispettivamente Fondo, Sottoufficio, Mercato, Banca e Città. |
| Frogger delle consegne | Postazione in `scenes/world/street.gd`, stanza precedente conservata per percorsi e salvataggi storici. Non sostituisce l'aiuto attuale di Amir. |
| Mocio/Snake, bilancia, magazzino/Tetris, cassa/Pong | Voci `room: nessuno` in `worklist.json`: nessuna postazione generata nel percorso corrente. Conservate per configurazioni precedenti. |
| Simon e Breakout | Supportati dal motore arcade, senza assegnazione attuale in `worklist.json`. |
| Pulizia, smistamento generico, telefoni generici | Tipi precedenti del motore dei turni, provati anche dal test touch. Nessun nuovo ingresso aggiunto. |
| Vecchio furto | Ancora richiesto dai percorsi `legacy` del Capo; non convertito automaticamente nei nuovi incarichi. |
| Vecchie strade di Amir, Snake, documenti in ordine e pratiche a righe | Compatibilità delle vecchie configurazioni. Le configurazioni correnti dei quattro aiuti usano `visivo: true`. |

Il test dei testi continua a controllare anche i tipi conservati. Il test touch prova separatamente la compatibilità dello Snake e il lancio nuovo, così un rifacimento non nasconde una regressione del percorso precedente.

## Verifica

Controlli eseguiti con Godot 4.6.3, su salvataggi di prova:

| Controllo | Esito |
|---|---|
| `storia_test` | 120 controlli OK. |
| `smoke_test` | SMOKE TEST OK. Gli esiti dei minigiochi vengono pilotati; non misura la bravura. |
| `aiuti_visivi_test` | 63 controlli OK, comprese guide, esiti pieno/parziale, input e presentazioni PC/telefono. |
| `minigame_redesign_test` | 12 verifiche, nessun controllo fallito. |
| `touch_test` | TOUCH TEST OK, compreso il nuovo lancio e il vecchio Snake. |
| `boss_integration_test` | 81 verifiche, nessun controllo fallito. |
| `boss_playthrough_test` | 56 verifiche, comprese ricompense uniche e compatibilità. |
| `nives_memoria_test` | 93 controlli OK. |
| `testi_dispositivo_test` | Nessuna istruzione del dispositivo sbagliato nei testi controllati. |
| Riferimenti Godot | Nessun errore; resta l'avviso del percorso esemplificativo nel template di GdUnit4. |

I log includono avvisi ObjectDB/risorse ancora presenti all'uscita. I test di recupero generano intenzionalmente anche errori di lettura JSON da file corrotti: il loro esito si basa sul recupero verificato, non sull'assenza di messaggi nel log.

Le schermate sono prodotte da finestre fuori schermo. Banca, Città, Presidente e otto finali: 1.131 immagini PC senza testo fuori dal riquadro. La Presidente nel formato telefono 20:9: 530 immagini, senza testo fuori dal riquadro. Nuovi aiuti, incarichi e mandato: immagini per entrambi i dispositivi, con controllo delle varianti nascoste.

Il controllo PC ha raggiunto camminando dodici interazioni in Città; per il dialogo `_bilanci` ha usato la chiamata diretta. Quella prova verifica i testi, senza certificare il percorso fisico fino ai bilanci. Le righe più basse delle scelte ordinarie misurano circa 24–25 pixel su 360: la comodità del tocco rimane da provare su un telefono vero. Le nuove schede del mandato sono alte 63 pixel.

I test narrativi fanno avanzare i dialoghi e pilotano gli esiti: non sono una partita umana e non misurano quanto un primo giocatore capisce o si diverte. Non è stato collegato un telefono fisico e questa revisione non produce automaticamente una nuova APK.
