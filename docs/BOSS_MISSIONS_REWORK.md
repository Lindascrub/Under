# CHEAP — Rework degli incarichi del Capo, 28 ottobre 2026

## Audit prima delle modifiche

Verificati GDD, NARRATIVE_DESIGN, COHERENCE, documenti dei sei capitoli, ENDING_SYSTEM, asset/audio, autoload, stanze, minigiochi, input touch e prove esistenti. Il progetto usa Godot 4.6.3. Tutti e sei i capitoli sono presenti: le vecchie sezioni di pianificazione in NARRATIVE_DESIGN non descrivono lo stato attuale.

Prima: C1/C2 telefonata generica e furto del lavoro; C3 rapporto 018 di Amir (1500 €), C4 rapporto 404 di Teo (3000 €), C5 progetto di Ada (6000 €), tutti con lo stesso gioco stealth e robotizzazione. C6 aveva tre cicli da 100 unità, poi riuniti in un solo turno, e un'offerta finale di attribuzione globale. Non occorre duplicare il gestionale.

Riutilizzabili: Room.show_pending, postazioni TURNO, terminali, Ui.say/choose, Router, GameState.flags, FocusShot, Sound, regole Direzione e motore dei finali. Conservare: B-4 e tritatura, scontrino, contratto mancante, protesta/vetrina/assemblea, tre famiglie finali, aiuti e mestieri, robot e premi pregressi.

Salvataggio attuale: JSON non versionato, nessun incarico in corso serializzato. Numeri JSON sono float: i contatori vanno convertiti. I vecchi flag boss_call_floor e c3/c4/c5_capo impediscono nuove chiamate: migrarli senza riassegnare premi. Git non utilizzabile in questa sessione (directory fuori dal worktree accessibile); baseline SHA-256 di 1962 file, copie originali e controllo dei cambi concorrenti sostituiscono il diff Git. Nessun reset, bake delle mappe o modifica di asset acquistati.

Economia rilevata: badge 500/1000/2000/4000/8000 €. Turni base 200/275/120/800/1600; aiuti con badge gratuiti condizionati, Signor Rata dopo insuccessi. C3 è il collo di bottiglia (13–17 turni nominali): paga da riequilibrare senza cambiare prezzi dei prodotti né prezzo del badge. Il debito parte da 7 miliardi e cresce del 2% a notte: non è necessario saldarlo per finire. Il badge continua a scalare il debito come nel codice esistente; nessuna riscrittura implicita di questa regola.

Rischi: doppio premio al reload, nuove offerte sopra offerte legacy, terminali/revelazioni bloccati, citazioni inventate in Città, ritorno della musica nell'ufficio già svelato, salvataggio nel mezzo di una transizione, cifre dei prestiti incongruenti, scelte del bilancio che forzano un finale. Prevenzione: stato unico versionato per piano, commit idempotente, checkpoint in stanza, importazione conservativa dei legacy, archivio di dichiarazioni realmente pronunciate, conti in centesimi, famiglie A/B/C sempre esplicite.

## Piano incrementale

1. Audit e specifica (questo documento).
2. Prototipo completo C3: etichette, condizioni, prezzo reale, esito e salvataggio. Verifica prima di procedere.
3. C1 regolatore di energia e C2 pratiche.
4. C4 composizione contratto e conseguenze di Olga.
5. C5 montaggio con fonti effettivamente ascoltate.
6. C6 pressioni integrate nel TURNO di Direzione (in seguito riunito in un solo schermo).
7. Nives: annuncio, stacco musicale, camera, sportello; regressione ed economia.

## Contratto di persistenza

`flags.boss_missions_version = 2`; `flags.boss_missions[piano]`: status, seen, progress, result, reward, return, return_pos. Commit senza await: risultato e accredito diventano veri insieme, poi salvataggio. Progressi salvati a ogni scelta significativa. Un'offerta rinviata si riprende dalla postazione TURNO o dal terminale del piano.

Migrazione: un piano con chiamata/missione legacy già registrata resta legacy; nessun secondo incarico. Personaggi robot, soldi, rank, badge, aiuti e finali conservati. C6 già iniziata resta sul flusso storico. I piani ancora intatti usano il nuovo sistema. Il file principale viene sostituito tramite file temporaneo e conserva una copia di sicurezza valida; caricamento di backup se il principale è illeggibile. I test usano percorsi privati.

## Specifica delle missioni

| Piano | Attività | Convenienza del Capo | Alternativa giocabile | Conseguenza |
|---|---|---|---|---|
| Fondo | Intensità, minuti extra, consumo decorazioni; simulazione energia/riposo | Produzione e festa accesa, bonus 600 € | Equilibrare carico o spegnere parte delle decorazioni | Fermo perde o mantiene la pausa; resta umano |
| Sottoufficio | Leggere quattro fascicoli e scegliere ufficio/integrazione/chiusura | Chiudere Ercole senza documento, bonus 900 € | Richiedere integrazione e inoltrare correttamente | La sua richiesta resta perseguibile o viene archiviata |
| Mercato | Comporre tre etichette: sconto, riferimento, quantità e visibilità condizioni | Incasso con condizioni nascoste, bonus fino a 1500 € | Promozioni reali con costo del paniere leggibile | Reclami e commissioni per Leda; Amir umano |
| Banca | Capitale, durata, interesse, commissioni e riepilogo visibile | Commissioni e totale occultato, bonus 3000 € | Contratto leggibile, anche lungo se utile alla rata | Olga valuta/contesta, nessuna accettazione automatica |
| Città | Timeline di tre servizi in 60 secondi, fonti integrali o tagliate | Scontri e ascolti, bonus fino a 6000 € | Verifiche e contesto nei tempi disponibili | Partecipazione più difficile, recuperabile con rettifica |
| Cima | Mandato diverso dentro ciascun ciclo di bilancio | Scaricare costi e accorpare decisioni | Tutele/condivisione con costo di coordinamento | Effetti contabilizzati; la famiglia finale resta una scelta |

Nessuna nuova missione chiama `exploit(victim)`. LV e riconoscimento aziendale possono aumentare per i premi, ma le persone non diventano robot. Le vecchie missioni rimangono eseguibili solo per i salvataggi che le avevano già aperte.

## Implementazione consegnata

Implementati tutti e sei gli incarichi; nessuno è soltanto documentato. Le cinque prime attività condividono solo cornice, input e checkpoint: le regole sono distinte. Alla Cima non è stato aggiunto un secondo gestionale. Ogni ciclo sceglie un mandato: tutele (minimi 40/20), tariffe (+5 riserve pagati dai lavoratori), firma unica (5 trasferiti dai servizi alle riserve e niente veto), consultazione (5 di coordinamento dalle riserve, poi servizi). Due cicli a firma unica incidono sulle varianti dei finali, mai sulla famiglia A/B/C scelta dal giocatore. I mandati non distribuiscono denaro personale né trasformano gli abitanti. Nessun nuovo mandato è confermabile senza copertura delle spese annunciate; i cinque spostati dai servizi non possono essere spesi una seconda volta.

Il contratto di Olga usa capitale 1200 €, 12/24/36 mesi, tassi annui 4/8/12%, commissione iniziale 0/60/120 €. Ammortamento mensile in centesimi; ultima rata corregge gli arrotondamenti. Totale = rate + commissione = capitale + interessi + commissione. Soglia proposta 65 €/mese. Olga chiede il riepilogo, non firma automaticamente. Il giorno seguente confronta il totale e può richiedere chiarimenti. Teo resta disponibile e il rapporto 404 con il suo nome si può ancora inviare.

Il notiziario registra Studente, Ada (o un Lavoratore se Ada era già robot) e Rina solo dopo le loro effettive battute in piazza. I frammenti trasmessi sono sottostringhe delle registrazioni; titoli di scontro sono distinti dalle citazioni. Tre fonti, ordine libero, montaggio integrale o taglio, cartello di fatti verificati da 10 secondi, massimo 60 secondi. Si può togliere e rimontare. La trasmissione si rivede prima delle conseguenze. Senza rettifica il montaggio divisivo richiede tre risorse reali invece di due per la gestione comunitaria; una rettifica pubblica da 30 minuti ripristina il requisito normale. Restano necessari i conti e l'organizzazione delle stanze.

Le telefonate partono dopo il turno; in Città prima avviene la protesta, poi arriva l'incarico sui materiali appena registrati. Più tardi si riprende dalla postazione TURNO o dal terminale del piano. Le vecchie offerte aperte mantengono il loro flusso, compresi premi, robot e rivelazioni. I salvataggi già avviati alla Cima conservano la precedente offerta globale.

## Nives, asset e architettura

Inventariate e caricate tutte le 41 tracce OGG disponibili. Per Nives è selezionata `lively_city.ogg` (64,6 s), prima inutilizzata dalle atmosfere dei piani. Richiamo sonoro e battuta prima di uscire; camera sull'addetta, accompagnamento durante il percorso, restituzione di stream/posizione/pitch e dell'eventuale silenzio precedente. Rimane valida la scelta personale di volume/muto. Il bancone ha un'area di interazione di 64 pixel e si usa dal davanti; nessuna sedia nascosta dentro la biglietteria.

Su richiesta successiva: Fondo con pavimento LimeZu `room_builder` (38–40, 13–14), divisorio da 6 pixel, ritorno all'imbocco del corridoio, pilastro da 16 fra biglietteria e nuova posizione delle scale (512,48). Corridoio largo 32, attraversato fisicamente in entrambe le direzioni. Camera CHEAP originale dal foglio `room_builder`, sei esemplari fra Fondo, Sottoufficio e Banca. Ascensore del Fondo riutilizzato, visibile anche nell'editor, porte originali animate con stipite. La CycletteDinamo usa `gym.png`, regione (96,480,32,32), anche nel gioco della pedalata; rimossa l'anteprima sovrapposta del vecchio generatore. Nessun PNG acquistato modificato o rigenerato.

Durante il lavoro l'editor aveva risalvato Fondo, Sottoufficio e TileSet: incorporate quelle versioni prima delle modifiche, preservandone gli UID. Nessun reset o ripristino delle modifiche manuali. La utility `tools/update_ticket_lobby.gd` aggiorna soltanto la zona richiesta e conserva gli altri nodi; non è stato eseguito un bake completo delle mappe.

## Economia verificata

Paga cassa 400 € (fino a 500), durata breve dopo tre turni. Prima era 120–160 €. Prodotti e badge conservano i prezzi originali; la paga non sale insieme al successivo rincaro. La simulazione usa i dati effettivi, un solo turno al giorno, saldo condiviso fra piani, commissione B-4 di 300 € quando nessun NPC aiuta, interessi e pagamenti minimi reali.

| Scenario | Turni ordinari per arrivare alla Cima |
|---|---:|
| Sempre premio | 6 |
| Sempre alternativa senza premio | 23 |
| Misto | 13 |
| Nessun aiuto NPC e rata minima ogni notte | 37 |
| Tutti aiutati, badge regalati | 5 |
| Saldo iniziale zero, due premi, rata minima | 25 |
| Debito iniziale dieci volte maggiore, niente premi/aiuti, rata minima | 37 |

Sono simulazioni a paga base raggiunta, senza spese facoltative: non equivalgono a sette partite complete giocate a mano. Il caso più lungo richiede meno di 28 minuti di minigiochi ordinari anche assumendo 45 secondi a turno; dialoghi, esplorazione e aiuti aggiungono il proprio tempo. Si può non pagare la rata e proseguire con un debito maggiore. Non occorre azzerare il debito per scegliere un finale.

## Prove eseguite

- Prototipo Mercato: 22 verifiche, prezzi prima/dopo, paniere, condizioni, salvataggio a metà, nessun doppio premio, Amir umano e importazione legacy.
- Regole: 721 verifiche; alternative C1/C2, 27 combinazioni di prestito con tre identità contabili ciascuna, fonti vere e timeline, effetto assemblea/rettifica, tutte le 64 combinazioni dei tre mandati e famiglie finali A/B/C.
- Integrazione: 81 verifiche, telefonate reali e scene, mouse/tocco/tastiera a 1280×720 e 1000×800, uscita/rientro e caricamento, sportelli su cinque piani, decisioni del TURNO di Direzione e riepilogo finale. La prova ora le presenta in un solo turno.
- Partite degli incarichi: 56 verifiche, tutte le cinque attività completate dall'interfaccia sia con premio sia con alternativa, prezzo e inquadratura dopo il Mercato, caricamento dopo premio, telefonate non ripetute, save senza versione, vecchi robot, recupero da backup dopo corruzione intenzionale del file di prova.
- Biglietteria/corridoio: 109 verifiche, pavimento, una sola cyclette, ascensore, telecamere e attraversamento reale del corridoio; catture native esaminate.
- Accesso e scale: 315 verifiche, camminati tutti e cinque i passaggi fra piani; nessun oggetto sopra la biglietteria.
- Arredi e mondo: 212 verifiche; interazioni e rivelazioni dei capitoli: 64; reception: addetta raggiunge il giocatore, rientra, tornello animato; touch generale, input del gioco di Olga e quattro esiti dei lavori superati.
- Schermate native controllate per tutte le nuove attività e il bilancio, biglietteria, bici e ascensore.
- Suite storica completa dei capitoli/finali con fixture legacy: un solo fallimento già presente prima del rework, «si dovrebbe poter parlare con Fermo». Non viene presentata come interamente superata. Gli altri controlli della suite terminano; dettagli nei log del pacchetto.

Godot segnala ancora risorse vive alla chiusura di vari harness, come nel progetto precedente. La prova dedicata del primo dialogo di Fermo termina correttamente. Il recupero da salvataggio corrotto produce intenzionalmente un messaggio del parser nel relativo test. Nessun salvataggio reale del giocatore è stato aperto in scrittura dai test.

## Come provare

Usare una nuova partita o un piano che non aveva già ricevuto la vecchia offerta. Finire il primo TURNO: rispondere al Capo e aprire il lavoro. «Più tardi» conserva tutto e rende disponibile «Riprendi l'incarico» alla postazione. C1: regolare carico/minuti/luci e simulare; C2: leggere quattro pratiche; C3: preparare tre etichette; C4: comporre una rata compatibile e inviare la proposta. C5: finire il primo turno, assistere alla protesta, montare le registrazioni al telefono/terminale; all'assemblea provare anche la rettifica. C6: completare i tre bilanci scegliendo un mandato a ogni conferma, ascoltare le testimonianze e decidere il finale al tavolo.

Per Nives aiutare tutti al Fondo o Sottoufficio e restare nel piano: annuncia l'arrivo e si avvicina. Altrimenti parlarle davanti al bancone. Le versioni precedenti dei file cambiati e degli asset sostituiti sono in `backup/2026-10-28_rework/`, escluso dalla vista del progetto Godot tramite `.gdignore`. Elenco file e impronte nel manifest della consegna.

