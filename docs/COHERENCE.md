# Le regole globali di CHEAP (documento di coerenza)

Questo documento fissa le regole che valgono **in tutti i capitoli**, prima di cambiare altri sistemi.
Nasce dalla revisione della storia (capitoli 1-6). Ogni regola dice com'è adesso nel codice e cosa manca.
Le modifiche si fanno in quest'ordine: P1 regole e salvataggi → P2 progressione senza blocchi →
P3 continuità → P4 finali → P5 rifinitura.

Stato: **già così** (il codice la rispetta), **fatto ora** (aggiunto in questa revisione), **da fare** (con dove).

## Le decisioni

| Tema | Regola | Stato |
|---|---|---|
| **Debito** | Sette miliardi: una posizione contabile *assegnata* (OBBLIGO DI ESISTENZA) alla registrazione di ogni nuovo abitante di certe categorie, non un prestito. Non è uguale per tutti: Nives, la Presidente, i bambini nati in città non ce l'hanno uguale | Origine: **già così** al cap. 6. Le categorie: **da fare** (una riga della Presidente in `_origin()`) |
| **Badge** | Il badge è una *rata di accesso* a un piano: non estingue il debito. Più sali, più opportunità hai per pagare il resto | **Da fare (P1).** Oggi `GameState.buy_badge()` scala il costo dal debito. Va tolto lì e detto chiaramente (allo sportello di Nives, nel cap. 2). Attenzione: cambia il saldo mostrato nei capitoli 1-5 e i test dell'economia |
| **Tracce del mistero** | Cap. 2: nel Modulo B-4 un campo "ORIGINE DELL'OBBLIGAZIONE: AUTOMATICA". Cap. 4: il contratto manca. Cap. 6: la registrazione era automatica | Cap. 4 e 6: **già così**. Cap. 2: **da fare (P3)** |
| **Notte e salvataggio** | Salvare non applica interessi. Solo riposare fa passare la notte | **Già così**: la stellina offre "Salva" e "Salva e lascia passare la notte" (`scripts/room.gd`) |
| **LV** | Misura aziendale del riconoscimento ottenuto (quanto merito il sistema ti attribuisce). Non è un livello morale | **Da fare (P1)**: va detto in un testo (barra in alto o Nives), nessun cambio di regole |
| **Robotizzazione** | Procedura aziendale: quando CHEAP registra il lavoro di qualcuno come proprietà di un superiore, può assegnarlo al PROGRAMMA DI OTTIMIZZAZIONE DEL PERSONALE. Il robot sorride perché il sistema misura la soddisfazione dai comportamenti standard | **Da fare (P3)**: un documento nell'archivio della Banca (cap. 4): "La standardizzazione riduce gli errori e migliora la soddisfazione dichiarata." |
| **Robot e identità** | Chi diventa robot perde quello che lo rendeva riconoscibile: il suo grigio, il dettaglio a colori, il gesto | **Fatto ora** (`scripts/looks.gd`, `data/looks.json`) |
| **Aiutare** | Migliora una situazione concreta. Non è liberare | **Già così** (`helped_ids`) |
| **Non sfruttare** | Rinunciare alla scorciatoia del Capo. È una scelta a sé, sempre possibile | **Già così** |
| **Liberare** | Interrompe un rapporto di lavoro, ma non risolve da solo i bisogni materiali (mangiare, una casa) | Meccanica esistente (`GameState.free_npc`) usata solo dalla vecchia città. **Da fare (P3)**: poche occasioni con gli NPC che ci sono già; peso nel finale |
| **Badge gratuito** | Non premia la bontà: è una piccola disobbedienza di Nives, con una causa che si vede (qualcuno che hai aiutato le ha raccontato di te). Il gesto cambia piano per piano: al Fondo segue le regole, al -4 guarda altrove, al -3 lo lascia cadere, al -2 vuole dire qualcosa, in Città dice di averlo scelto, alla Cima si scopre perché | **Da fare (P3)**: le battute di Nives per piano, e la riga del "chi le ha parlato di te" |
| **TURNO** | Ripetizione limitata: pochi turni a mano, poi contratti cumulativi abbreviati che consumano tempo. Ci devono essere alternative non sfruttatrici praticabili | -2 e Città: **già così** (pratiche raggruppate, turno rapido). Piani -5, -4, -3: **da fare (P2)** |
| **Il Capo** | Stessa telefonata, significato che cresce: dal furto nascosto (Fondo) al potere aperto (Cima). Ogni volta dice: "È tutto molto semplice." Il tono cambia: simpatico, poi interessato, poi "responsabile verso la comunità", alla Cima quasi serio | Cima: **fatto ora** (la Presidente dice la frase prima del primo ciclo, poi "Be'. Sulla carta."). Capitoli 1-5: **da fare (P3)**: la frase e una battuta condizionale per piano |
| **Il progetto di Ada** | Rubarlo non toglie il merito solo ad Ada: ti prendi la rappresentanza di chi ci ha lavorato | **Da fare (P3)**: due righe nella telefonata del cap. 5 |
| **Assemblea** | L'esito è collettivo, non una decisione del protagonista | **Già così** nel cap. 5 (l'esito dipende da chi c'è e dalle prove). Da scrivere in `CHAPTER_05_CITY.md` come si calcola |
| **Bilanci della Cima** | Tre cicli = una *prova gestionale*. Le decisioni valgono per la prova; dopo la scelta finale diventano effettive solo se compatibili col nuovo assetto | **Fatto ora** (la Presidente lo dice nell'offerta). **Da fare (P4)**: negli epiloghi del finale B le decisioni della prova non devono risultare permanenti |
| **La Presidente** | Non è cattiva né magica. Ha ereditato regole, le ha tenute e anche strette (gli interessi). Teme che cambiare tutto in fretta fermi i servizi. Cerca un successore, non un salvatore | **Fatto ora**: "Perché non lo cambi tu?" e il dialogo "Pensi che basti cancellare i numeri?" |
| **Il finale C** | Proporre non è avere il potere di imporre. Se lo annunci dalla sedia della Presidente, hai deciso da solo per tutti. Le persone possono non accettare: lavoro, orari, documenti | **Fatto ora**: la reazione della Presidente e la proposta come proposta. **Da fare (P4)**: "il primo incontro", in cui chi partecipa dipende da tempo e condizioni (Leda non può chiudere il negozio, Nadir chiede orari, Olga vuole i documenti, Teo propone come dividersi i compiti) |
| **Tre finali** | Scelta finale + stato materiale, relazionale e istituzionale. Mai un contatore di moralità | **Già così** (`chapters/c6/finali.gd`, `docs/ENDING_SYSTEM.md`) |
| **Epiloghi** | Ognuno reagisce alle scelte e ha una vita sua: non esiste solo in funzione del protagonista | **Già così** in buona parte; da rileggere in P4 |
| **La dinamo** | Alla Cima, in una stanza laterale, la prima cyclette. Pedalando si accende una lampadina sulla scrivania della Presidente | **Fatto ora** (`_dinamo()` in `cima_c6.gd`, stanza nel bake) |

## I piccoli ritorni (P3)

Ogni piano nuovo può portare notizie di qualcuno già conosciuto: una lettera, un oggetto, una battuta.
Sempre coerenti con lo stato: un robot non scrive cartoline.

| Chi | Ritorno | Dove |
|---|---|---|
| Fermo | Una nota sul contatore energetico | Città (Casa Comune) |
| Tilde | Un riferimento al Modulo B-4 fra i documenti | Casa Comune |
| Leda | Una fattura | Banca |
| Amir | Una cartolina dalla sorella (umano) / una consegna robotica (robot) | Banca o Città |
| Olga | Una lettera sull'esito della contestazione | Città |
| Teo | Una pagina del fumetto (umano) / un documento timbrato col suo nome (robot) | Città o Cima |
| Ada | Il progetto della Casa Comune sulla scrivania della Direzione | Cima |
| Nadir | L'orario dei trasporti cambiato dal bilancio | Cima, consultazione |
| Rina | La bottega sei mesi dopo | Epilogo (già così) |

## Il lessico visivo del bilancio (P3)

Il TURNO della Cima non deve arrivare dal nulla. La stessa lingua visiva va imparata prima:
la lavagnetta di Leda (-3), rate e commissioni (-2), le proposte con i costi della Casa Comune (0).
Alla Cima ritornano gli stessi elementi, e finalmente si possono cambiare i valori.

## Cosa non si tocca

- Le meccaniche dei capitoli 1-2 (cyclette, festa, call center, tritacarte).
- La telefonata del Capo e "un, due, tre, stella".
- Il raddoppio dei prezzi dei badge (500 → 8.000 €). Le cifre dei premi del Capo per ora restano.
- Nessun contatore nascosto di bontà.

## Domande aperte

- Il badge che non scala più il debito: con quale saldo si arriva alla Cima? Va simulato (P2) prima di cambiarlo.
- Le categorie a cui si assegnano i sette miliardi: chi sono (chi arriva da fuori? chi nasce al Fondo?).
