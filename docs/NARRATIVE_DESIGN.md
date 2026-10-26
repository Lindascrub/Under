# CHEAP — Design narrativo

> Documento guida per la storia e le conseguenze. Il GDD ([GDD.md](GDD.md)) descrive le regole del gioco;
> qui c'è il perché, cosa succede, e come lo si traduce in codice senza rifare quello che funziona.
> I capitoli 1 e 2 sono già fatti e restano come sono: [capitolo 1](capitoli/capitolo_1_il_fondo.md),
> [capitolo 2](capitoli/capitolo_2_il_sottoufficio.md).

---

## 1. Analisi: cosa c'è, cosa manca, cosa non torna

### Già fatto e funzionante (da conservare)

- **Capitoli 1 e 2**, come scene vere dell'editor (`chapters/c1`, `chapters/c2`), con rivelazione, sguardo indietro, test automatici.
- **Il ciclo del piano**: TURNO a tocco, persone grigie, telefonata del capo una volta per piano, robot, badge che raddoppia, Nives, scale, stelline e interessi.
- **I sistemi di supporto**: la pietà dopo tre turni falliti (con la fregatura del Signor Rata), lo straordinario al Fondo, la procedura d'urgenza del -4, il regalo di Nives se aiuti tutti, le scale sbarrate.
- **Il materiale vecchio riusabile**: la città (Nico, Marta, Lea, Sami, Ivo, Bruno, Dario, Giulia, Tano, Elsa, Rocco), il Rifugio, le missioni, il "perché lavoro" e la liberazione, le battaglie, la Presidenza con tuo padre, il conto in banca "del padre" garantito dal Presidente.

### Solo pianificato

- Capitoli 3-6 nella nuova forma (oggi Mercato, Banca, Ufficio e Cima sono stanze della versione precedente, fatte a codice, che cambiano aspetto con le vecchie strade).
- Le tre tendenze, i finali nuovi, l'epilogo, il sogno del protagonista, la comunità.

### Incoerenze trovate

| # | Dove | Problema | Soluzione meno distruttiva |
|---|---|---|---|
| 1 | GDD | Prezzi dei badge vecchi (200-1.000 €), Fondo "buio", -4 con bagni | Corretto nel GDD |
| 2 | GDD | Tre nomi diversi per le stesse strade (Ricco/Ribelle/Onesto e capitalismo/comunismo/baratto) | Sostituite dalle tendenze (sezione 4) |
| 3 | Economia | Il badge raddoppia, la paga sale del 10% a piano: salita onesta ≈ 42 turni | Paga che cresce col piano + costo della vita (sezione 9) |
| 4 | `route()` | "Debito pagato" porta al finale ricco, ma con 7 miliardi non succede mai (le promozioni rendono 900 × 1,7ⁿ) | Il debito non è più una condizione di finale; diventa la rivelazione del capitolo 4 |
| 5 | Presidenza | Tuo padre cancella il debito con una scelta: soluzione magica | Può cancellare **il tuo** debito, non il sistema; e cancellarlo ha un prezzo (capitolo 6) |
| 6 | Codice | `LAST_DAY = 4`, "si apre dal secondo/terzo/quarto giorno" nei commenti di Mercato, Banca, Presidenza | Si accede ai piani solo col badge; i riferimenti ai giorni si tolgono quando si rifà ogni piano |
| 7 | Codice | `scenes/world/fondo.*` e `fall.*` non sono più raggiungibili | Toglierli (nessun effetto sul gioco) |
| 8 | Dati | `data/jobs.json` (gli "incarichi facili" a 7 giorni: Marta, Bruno, Dario...) e `promotions.json` (a piani) convivono | Tenere solo `promotions.json`; le vittime di città passano al capitolo 5 |
| 9 | Capitolo 1 | Le scale si sbarrano se non hai sentito la verità **dopo** la rivelazione: chi ha parlato con tutti prima, ma non dopo, viene punito senza capire | Contare anche chi hai conosciuto (`met_*`), e sul gradino far chiamare il protagonista per nome da Fermo ("Non ti volti?"): così il "non voltarsi" è una scelta che si vede |
| 10 | Personaggi | Vito, Rosa e Ottavio sono già al Mercato; Ines e Sandro già in Banca; Lea è già una studentessa | Diventano il "contorno" colorato o le voci secondarie dei capitoli nuovi (sezioni 5-6), non si cancellano |
| 11 | Mondo | L'aspetto di Mercato e Banca dipende da `world_look()` (asta/coda/scambi) | Si riusa come "come ti vede il piano" in base alle tendenze, non come strada scelta |

---

## 2. Visione

CHEAP racconta un mondo in cui il tempo, i bisogni e i desideri delle persone vengono dopo la produttività,
il debito e il profitto. Ma lo fa ridendo: una festa per l'azienda, un modulo che chiede un modulo,
una musichetta d'attesa che non si ferma mai. Il disagio arriva dopo, quando la risata non torna.

**Tema:** se passi tutta la vita a guadagnarti il diritto di vivere, quando inizi a vivere davvero?

**La Torre promette** che chi lavora abbastanza sale, e chi sale è libero.
**Il giocatore scopre**, piano per piano, che nessuno, nella Torre, è il cattivo per intero:
- Fermo non sale perché ha fatto i conti;
- l'Agenda tritura i moduli perché il regolamento lo chiede;
- Ines in banca paga lo stesso mutuo che vende;
- tuo padre è arrivato in cima e non sa cosa farsene.

Sono le regole, gli incentivi e le gerarchie a spingere tutti. Il protagonista compreso.

### Le regole della scrittura

1. Nessun indicatore di moralità, nessuna parola ideologica nel gioco (niente "capitalismo", "comunismo").
2. Nessuna scelta da sola decide il finale. Il giocatore può cambiare strada fino alla fine.
3. Aiutare non vuol dire avere ragione. Diventare ricchi non vuol dire diventare cattivi. Sopravvivere non è un fallimento.
4. Chi viene liberato continua ad avere fame. La libertà ha bisogno di risorse.
5. Le conseguenze possono sorprendere, ma ripensandoci devono tornare.
6. Il giocatore non deve mai "capire quale pulsante è quello buono".
7. Ispirati a Undertale per la profondità e la persistenza, mai per dialoghi, personaggi o scene.

---

## 3. Il protagonista e il sogno

Il protagonista ha il nome scelto dal giocatore e un padre sparito, che gli ha lasciato una casa,
un robot giocattolo, un post-it sullo specchio e un debito di 7 miliardi.
Ha smesso di desiderare qualcosa il giorno in cui è entrato nell'ascensore.

### Come far emergere il sogno senza riscrivere i capitoli 1 e 2

Il sogno si ricompone a **frammenti**, uno per piano, raccolti in modo facoltativo.
Ognuno è un oggetto da guardare o una domanda di un personaggio. Nei capitoli 1 e 2 bastano **aggiunte piccole**,
fatte nell'editor o con un `talk_<id>` in più, senza cambiare scene o dialoghi esistenti.

| Piano | Frammento | Come si aggiunge |
|---|---|---|
| -5 | Fermo: "E se smettessi?" → "E poi cosa faccio, con le mani?" (esiste già). Nuovo: un disegno a pastelli dimenticato sotto la torta (Examine nell'editor) | Un nodo Examine |
| -4 | Tilde, dopo l'aiuto: "Cosa volevi fare, da piccolo? Non dirmelo. Ricordatelo e basta." | Una riga in `talk_tilde` dopo il timbro |
| -3 | Amir porta pacchi a tutti i piani: ne ha uno per te, di anni fa, mai consegnato | Scena del capitolo 3 |
| -2 | In banca, tra le carte del conto del padre, una tua lettera di quando eri bambino | Scena del capitolo 4 |
| 0 | A casa, il robot giocattolo: lo guardi davvero per la prima volta | Riuso di `home.gd` |
| Cima | La domanda finale | Capitolo 6 |

I frammenti non dicono mai quale sia il sogno: lo indicano. Alla fine il giocatore lo nomina, scegliendo tra
le possibilità che ha raccolto: **costruire** (il robot giocattolo, i fili di Nonno Mina), **raccontare**
(la voce di Tilde, le lettere), **stare con qualcuno** (la cena di Marta, l'ora seduto con tuo padre),
**andare via** (il pacco di Amir, il mare sul poster della banca).
Se non ne hai raccolto nessuno, la risposta possibile è una sola: "...Non me lo ricordo."

**La domanda finale:** *"Adesso che sei arrivato in cima, cosa volevi fare prima di iniziare a salire?"*

---

## 4. Le tre tendenze

Non sono strade, non si scelgono e non si vedono. Sono il modo in cui il mondo **ti legge**, calcolato da tante
azioni diverse. Il finale lo decidono la tua ultima scelta alla Cima **e** quello che c'è dietro di te.

### A. Ascesa — potere e compromessi

Accumuli soldi, grado e influenza. Puoi salire più in fretta prendendoti il merito degli altri,
ma il potere serve anche a cambiare qualcosa: dal capitolo 4 il grado sblocca **decisioni**
(chiudere un occhio su una pratica, alzare una paga, firmare un regolamento).
- **Si nutre di:** promozioni accettate, grado (`rank`), soldi tenuti, decisioni prese col potere.
- **Il rischio:** ogni promozione è una persona in meno. Il potere senza persone intorno è un ufficio vuoto.
- **Due facce:** il dirigente che usa le regole a suo vantaggio, o quello che le usa per cambiarle (e paga un prezzo: lo isolano, lo controllano).

### B. Sopravvivenza — il tempo che scompare

Lavori, paghi, sali. Non sfrutti nessuno, non salvi il mondo. È la tendenza "di base", e **non è una colpa**.
Il gioco mostra il suo prezzo con dolcezza: inviti saltati, amici che smettono di aspettarti, la stanchezza,
il sogno che si allontana.
- **Si nutre di:** turni fatti, straordinari, giorni passati, inviti rifiutati per lavorare, frammenti del sogno persi.
- **Mai punita** se non avevi le risorse per aiutare: chi non poteva non viene giudicato. Il gioco distingue tra "non ho potuto" (stanco, senza soldi) e "non ho voluto" (avevi tempo e hai detto di no). Lo sa, ma non te lo dice.

### C. Solidarietà — la libertà collettiva

Aiuti, liberi qualcuno, costruisci fiducia. Ma chi smette di lavorare perde lo stipendio:
la comunità deve trovare cibo, case, servizi e un modo di decidere.
- **Si nutre di:** persone aiutate, liberate, fiducia, risorse della comunità, decisioni prese insieme.
- **Il rischio:** liberare troppe persone senza risorse fa crollare tutto. Una persona liberata e poi lasciata sola torna alla Torre, più stanca di prima.
- **I disaccordi** sono veri: chi vuole restare un gruppo piccolo e sicuro, chi vuole occupare, chi vuole trattare con la Torre.
- Un singolo salvataggio non basta: servono persone, risorse e decisioni.

### Si può cambiare strada

Le tendenze sono pesi, non binari. Chi ha accettato due promozioni e poi aiuta tutti nel capitolo 5
avrà un finale di Solidarietà, ma con dentro i suoi robot: Tilde che sorride al telefono, per sempre.

---

## 5. I sei capitoli

### Capitolo 1 — -5 Il Fondo · *La festa finta* (fatto)

TURNO: la cyclette-dinamo. Persone: Fermo, Bulbo, Nonno Mina. Il capo: il quaderno di Fermo.
Rivelazione: i colori della festa li accendi tu pedalando, e senza di te si spengono.
Conseguenze già nel codice: lo straordinario (fino a tre volte), le scale sbarrate se non ti volti,
la tinta del Fondo (calda se hai aiutato, acida se hai rubato).
**Ritocco proposto:** la condizione delle scale sbarrate (incoerenza 9).

### Capitolo 2 — -4 Il Sottoufficio · *La burocrazia infinita* (fatto)

TURNO: call center a tocco (copione, sincera, sgarbata; finale con tutti i telefoni). Persone: Tilde, Ercole.
Il capo: il copione di Tilde. Il giro del Modulo B-4, l'uscita con Ercole e Tilde o la procedura d'urgenza (300 €).
Rivelazione: la musica si ferma, il B-4 finisce nel tritacarte.
**Ritocco proposto:** il frammento del sogno di Tilde (sezione 3).

### Capitolo 3 — -3 Il Mercato · *Caro vita, salari e prezzi*

Progettato in dettaglio nella sezione 7. In breve: un supermercato sotterraneo pieno di luci, con un tabellone
dei prezzi che cambia ogni minuto. TURNO: la cassa. Persone: Leda e Amir.
Rivelazione: il tuo aumento l'hai pagato tu, alla cassa.

### Capitolo 4 — -2 La Banca · *Debito e dipendenza*

- **Atmosfera:** marmo finto, piante finte, silenzio da biblioteca. Un orologio enorme che segna gli interessi al secondo.
- **TURNO: lo sportello crediti.** Arrivano pratiche: le controlli (firma, data, garanzia) e le timbri APPROVATA o RESPINTA. Toccando le voci si scoprono gli errori. La paga dipende da quante pratiche respingi, e il gioco non lo nasconde: il supervisore te lo dice al primo turno.
- **Persone vere:**
  - **Ines** (esiste già): impiegata, paga alla sua banca lo stesso mutuo che vende. Non è cattiva, è intrappolata. Aiuto: le sue pratiche (sequenza).
  - **Sandro** (esiste già): guardia giurata, "ho giurato di proteggere i soldi, nessuno mi ha chiesto le persone". Aiuto: il lucchetto (tempismo).
- **Nel colore:** il direttore di filiale (sorride sempre), l'orologio degli interessi, le cassette di sicurezza.
- **Il capo:** "Le pratiche di Ines": il suo metodo per trovare chi può ancora pagare un po' di più. Se lo rubi, le pratiche dei capitoli dopo (le persone della città) diventano più dure da pagare.
- **Interessi spiegati giocando:** la prima notte al -2, invece del solito messaggio, Ines ti mostra il tuo conto. Ogni notte paghi più di interessi che di badge in tutta la tua vita. Il conto è "del padre", garante il Presidente (esiste già in `banca.gd`).
- **Rivelazione:** sul primo gradino suona l'allarme. Sandro, invece di fermarti, ti dà una cartellina: il debito di 7 miliardi non è un prestito. È una **garanzia**: tuo padre ha impegnato il futuro di suo figlio per comprare il suo posto in cima. Il debito non doveva essere ripagato, doveva tenerti dentro. Non lo dice nessuno di cattivo: lo dice un modulo, con calma.
- **Sguardo indietro:** l'orologio degli interessi, che continua a girare.

### Capitolo 5 — Piano terra, Ufficio e Città · *Le conseguenze fuori dalla Torre*

Si esce, per la prima volta, alla luce. La città della versione precedente torna, cambiata da quello che hai fatto sotto
(prezzi del Mercato, pratiche della Banca, robot).
- **TURNO: comunicazione aziendale.** Trasformi annunci veri in annunci CHEAP: tocchi le parole da sostituire ("chiusura" diventa "riorganizzazione", "licenziati" diventa "liberati da vincoli"). Le parole giuste pagano; le parole vere fanno arrivare lettere.
- **La Casa Comune:** il Rifugio della versione precedente, cresciuto. Ci si studia, si mangia, ci si aiuta. Ma la Torre vuole il palazzo: ha venti giorni per chiudere.
- **Persone vere:**
  - **Ada**, studentessa, studia alla Casa Comune perché a casa non c'è posto. Vuole che resti aperta, e vuole anche finire gli esami: non ha tempo per tutte le riunioni. Aiuto: le ripetizioni (riuso dell'esame di Luca come sistema).
  - **Nadir**, pendolare, due ore di treno al giorno. Vorrebbe aiutare, ma se sciopera perde il posto e la casa. Non è contro la Casa Comune: ha paura. Aiuto: arrivare in orario (tempismo).
- **Le voci della città** (personaggi esistenti, ognuno con la sua idea): Ivo vuole trattare, Lea vuole occupare, Marta ha paura per i figli, Nico fa il caffè per tutti e non vota, Dario dice che "tanto non cambia niente" e poi viene lo stesso.
- **La protesta:** una serie di riunioni la sera (scelte di dialogo che spostano le risorse e le relazioni), un corteo con persone diverse e motivi diversi, e una notte in cui si decide cosa fare. Mai una folla uguale, mai solo disordini.
- **Il capo:** la proposta più grande: il piano della Casa Comune scritto da Ada (come trasformarla in una cooperativa). Se lo rubi, la Torre lo usa per farne una "Casa Comune CHEAP" a pagamento.
- **Rivelazione:** dalla finestra dell'ufficio vedi che le decisioni della Torre (prezzi, pratiche, chiusure) sono i servizi della città. La scuola, il treno di Nadir, la Casa Comune: stanno tutti su un foglio di bilancio, al piano di sopra.

### Capitolo 6 — La Cima · *Potere, responsabilità, libertà*

Niente scale dopo: è l'ultimo piano.
- **Direzione:** il Dottor Prezzi, il capo (finalmente in persona: il più colorato di tutti, troppo, in modo quasi doloroso da guardare).
- **TURNO: il bilancio.** Hai una cifra e cinque voci (Mercato, Banca, Città, Casa Comune, Torre). Trascini le monete. Ogni scelta si vede subito in una finestra sulla città: una luce che si spegne, un negozio che chiude, una festa. Non c'è combinazione giusta: c'è quella che hai scelto.
- **La scorciatoia finale del capo:** "Firmi qui, e il suo debito sparisce. Prenda il mio posto. Basta che nella prima riunione approvi la chiusura della Casa Comune." È l'ultima telefonata; si può rifiutare.
- **Presidenza:** tuo padre (esiste già in `presidency.gd`). Non è un boss. Ha tutto e non sa cosa farne.
- **Rivelazione:** il debito è uno strumento della Torre. Tiene in basso chi è in basso, e in alto chi ha paura di cadere. Anche tuo padre è garantito da qualcun altro.
- **Senza magia:** tuo padre può strappare il **tuo** debito, ma non quello degli altri: sono in registri che non sono suoi. Strapparlo ti costa: senza debito, la Torre non ha più motivo di tenerti. Ti offre di scendere a casa, oppure di restare, con un posto e una scrivania.
- **La scelta finale** (sezione 8): tre azioni, sempre disponibili, ma il loro significato dipende da quello che hai dietro.

---

## 6. I personaggi, in una tabella

| Capitolo | Persone vere (grigie) | Sistema (colorato) | Promozione del capo |
|---|---|---|---|
| 1 | Fermo, Bulbo, Nonno Mina | La festa, la cyclette, Nives | Il quaderno di Fermo |
| 2 | Tilde, Ercole | Signora Agenda, i colleghi, il tritacarte | Il copione di Tilde |
| 3 | Leda, Amir | Vito (affittuario del suo banco), Rosa, Ottavio, il tabellone | Il quaderno dei prezzi di Leda |
| 4 | Ines, Sandro | Il direttore, l'orologio degli interessi | Il metodo di Ines |
| 5 | Ada, Nadir (+ le voci: Ivo, Lea, Marta, Nico, Dario) | La comunicazione CHEAP, gli annunci | Il piano di Ada |
| 6 | Tuo padre | Il Dottor Prezzi | La firma finale |

Personaggi della versione precedente non elencati (Bruno, Sami, Giulia, Tano, Elsa, Rocco, Gino) restano
come comparse della città o vengono tolti più avanti; non servono per la storia principale.

---

## 7. Capitolo 3 — Il Mercato (progetto dettagliato)

### L'idea in una frase

Il Mercato sembra pieno di occasioni: luci, offerte, un tabellone che cambia i prezzi ogni minuto.
Dal -3 la paga sale tanto. Ma anche tutto il resto sale. E la gente comincia a fare i conti ad alta voce.

### Atmosfera

- Supermercato sotterraneo, fluorescente. Pavimento a scacchi lucidi, scaffali alti, carrelli che cigolano.
- Colori pastello finti (la luce dei frigoriferi). Musica: una marcetta da supermercato con un annuncio ogni tanto: "Offerta lampo al reparto speranza!".
- **Il tabellone** al centro della stanza: prezzi rossi e verdi che scorrono. Toccandolo si legge cosa è salito oggi.
- Sotto il colore, i banchi vecchi del mercato di una volta, ancora lì, in affitto dentro il supermercato.

### La mappa (scena dell'editor, `chapters/c3/mercato.tscn`)

- In alto, le casse del supermercato CHEAP (il TURNO), il tabellone al centro, lo sportello di Nives e le scale per il -2 a destra.
- A sinistra, i banchi: "Da Leda — prezzi onesti" e il banco di Vito.
- In basso, la rampa di carico dove passa Amir col carrello, verso il magazzino.
- In basso a sinistra, le scale per il -4.

### Le persone

**Leda** (grigia, cinquant'anni, grembiule a quadretti).
Vendeva frutta quando la frutta "cresceva sugli alberi e non nei magazzini". Adesso è in affitto nel suo stesso banco,
dentro il supermercato. L'affitto sale ogni settimana. Tiene un **quaderno dei prezzi veri**: quanto costa davvero ogni cosa,
quanto ci guadagna lei, quanto ci guadagna la Torre. Non lo fa per protesta: lo fa per non impazzire.
- Aiuto: **La frutta di Leda** (raccolta): i controllori passano a misurare il banco, tu raccogli le arance cadute prima che vengano multate.
- Dopo l'aiuto: ti dà il quaderno da guardare (scopri i margini; serve per la rivelazione e per il gruppo d'acquisto).

**Amir** (grigio, ventisei anni, cappellino, sempre di corsa).
Consegna tra i piani: è l'unico che sale e scende senza badge, perché porta le cose degli altri. Conosce i prezzi di tutti i piani
e li dice a memoria come una poesia. Manda soldi a sua sorella che studia. Ride molto.
- Aiuto: **Il carrello di Amir** (tempismo): tocca quando la rampa del montacarichi è allineata, o il carrello si ribalta.
- Dopo l'aiuto: ha un pacco per te, indirizzato a te bambino, mai consegnato (frammento del sogno: c'è dentro un catalogo di robot da costruire).

**Vito** (colorato, esiste già): affittuario del banco del nonno, orgoglioso. Difende il supermercato perché gli manda i clienti delle offerte.
Non è un nemico: è quello che ci rimette quando cambia qualcosa. Resta anche la sua offerta di pietà (già nel codice).

**Rosa e Ottavio** (colorati, esistono già): venditori di frutta di plastica e ombrelli. Comparse comiche.

### Il TURNO: la cassa (`game "cassa"` in `work.gd`)

- Prodotti sul nastro, da sinistra a destra. **Tocca** ogni prodotto per passarlo (bip). Il totale del cliente sale.
- Ogni tanto il tabellone lampeggia: **prezzo aggiornato**. Lo stesso prodotto, passato un minuto dopo, costa di più. Non puoi farci niente: il gioco lo mostra e basta.
- Un cliente non ce la fa: il totale supera il suo portafoglio (si vede). Tocca un prodotto per **toglierlo** (perdi tempo, il cliente ringrazia) oppure lascia passare (il cliente se ne va senza niente, nessun errore).
- Finale del turno: arriva l'ora di punta, il nastro accelera.
- **Paga:** più alta dei piani sotto (sezione 9). Il riepilogo dice anche: *"Con la paga di oggi compri: 31 pagnotte. Il primo giorno: 34."*

### Il costo della vita (nuovo, dal capitolo 3)

Dal -3 si **paga per vivere**: ogni notte, quando la stellina fa passare la notte, scontrino automatico per
"branda e cena" (sezione 9). I prezzi salgono di qualche punto ogni giorno, come le paghe.
- **Se non hai i soldi**, la spesa va sul debito (che tanto non si ripaga) e il giorno dopo hai meno energia. Mai bloccati, mai Game Over.
- **Dove fai la spesa** si sceglie la prima sera (scena completa sotto), poi resta finché non cambi idea a un banco.

### La telefonata del capo

*"Ottimo turno! Senta, una cosetta da niente. La signora Leda, quella dei prezzi onesti, tiene un quaderno. Ci sono scritti i prezzi veri.
Lei lo usa per non fregare nessuno. Noi lo useremmo per sapere fin dove si può salire prima che la gente smetta di comprare.
Lo porti a me col suo nome sopra, e lei sale di grado. Leda continuerà a pesare le arance. È il suo talento."*

Se accetti, Leda diventa un robot: il cartello del suo banco diventa "PREZZI DINAMICI". **Conseguenze dopo:**
i prezzi della città nel capitolo 5 sono più alti (`c3_listino_rubato`), la Casa Comune ha meno cibo, e Amir smette di salutarti.

### Le uscite dal piano

- **Il lavoro:** 4 turni bastano per il badge (2.000 €) con la paga proposta.
- **Nives:** se aiuti Leda e Amir, il badge è in regalo (come sempre).
- **Il gruppo d'acquisto** (facoltativo, solo se hai aiutato tutti e due e Leda non è un robot): Amir porta la merce dalla rampa a prezzo di magazzino, Leda la vende al costo. La tua spesa costa la metà per il resto del gioco, e la comunità ha `cibo +1`. Ma Vito perde clienti e si arrabbia: è un conflitto vero, e si risolve solo parlandogli (lo inviti nel gruppo: accetta se l'hai aiutato o se non l'hai mai giudicato, se no si chiude nel banco e nel capitolo 5 vota contro la Casa Comune).

### La rivelazione (primo gradino)

Metti il piede sul primo gradino. Il tabellone si blocca, poi si aggiorna da solo, con una voce allegra:
*"Gentili clienti, per la vostra trasparenza!"*. Per ogni prodotto compaiono quattro colonne:

`ARANCIA — costo 0,12 · affitto banco 0,40 · CHEAP 1,28 · prezzo 1,80`

Sotto, due righe una accanto all'altra:
`ADEGUAMENTO SALARI PIANO -3: +15%` e `ADEGUAMENTO PREZZI PIANO -3: +15%`.
È la stessa voce di bilancio. Il tuo aumento l'hai pagato tu, alla cassa, scontrino dopo scontrino.
Il tabellone torna a scorrere come se niente fosse. Leda e Amir, se ci parli, ti dicono la loro verità.

### Lo sguardo indietro (frasi, in ordine di priorità)

1. Leda robot: *"Laggiù il banco di Leda dice PREZZI DINAMICI. Lei sorride e pesa le arance. Il quaderno è tuo, adesso. Cioè loro."*
2. Gruppo d'acquisto con Vito: *"Laggiù tre banchi hanno spento le luci della CHEAP. Vendono al costo, litigando sui prezzi. Ma insieme."*
3. Gruppo d'acquisto senza Vito: *"Laggiù Leda e Amir fanno la spesa per venti persone. Vito li guarda dal suo banco, da solo."*
4. Hai fatto la spesa sempre in offerta: *"Laggiù le offerte lampeggiano ancora. Erano per te. Anche la chiusura del banco di Leda."*
5. Altrimenti: *"Laggiù il tabellone scorre. Hai guadagnato più di sempre, e hai comprato meno di prima."*

### Le variabili del capitolo

| Flag | Significato |
|---|---|
| `c3_arrivo`, `c3_rivelazione`, `c3_fine` | Come nei capitoli 1-2 |
| `c3_spesa` | Dove fai la spesa: `"offerta"`, `"leda"`, `"salto"` |
| `c3_sere_offerta` | Quante sere hai comprato in offerta (fa chiudere il banco di Leda a 3) |
| `leda_chiusa` | Il banco di Leda ha chiuso (Leda resta, senza banco: è "liberata" per forza, senza risorse) |
| `c3_gruppo`, `c3_vito_dentro` | Gruppo d'acquisto, con o senza Vito |
| `c3_listino_rubato` | Promozione accettata (Leda robot) |
| `sogno_pacco` | Il pacco di Amir |

---

## 7b. Una scena completa: "Il primo carrello"

**Quando:** la prima sera al -3, dopo il primo turno, quando tocchi una stellina per far passare la notte.
**Dove:** tra le casse CHEAP e il banco di Leda.

> *La stellina non si accende. Al suo posto, un cartello: "Prima della notte, la spesa. Branda e cena: obbligatorie."*
>
> *Dal tabellone, una voce allegra:* "Offerta della sera! Cena completa a 90 €! Solo per oggi, solo per te!"
>
> *Al banco di Leda, scritto a gesso:* "Cena: 140 €. Mele vere."

**Scelta:** `[Offerta CHEAP (90 €)]` `[Da Leda (140 €)]` `[Salto la cena]`

**Offerta CHEAP:**
> *La cassa fa bip. La cena è in una vaschetta con un sorriso stampato sopra. È buona. È proprio buona.*
> *Dal banco di Leda, nessuno ti guarda. Leda sta contando le mele. Le conta due volte.*
→ `c3_spesa = "offerta"`, `c3_sere_offerta += 1`. Il giorno dopo l'offerta è finita: la cena CHEAP costa 150 €.
Se torni da Leda il giorno dopo:
> **Leda:** "Ieri c'era il sottocosto, vero? Lo fanno quando uno di noi sta per chiudere. Due sere, tre. Poi il banco chiude, e il sottocosto finisce."
> **Leda:** "Non ti sto dando la colpa. Novanta è meno di centoquaranta. Lo so fare il conto anch'io."

**Da Leda:**
> **Leda:** "Centoquaranta. Lo so, lo so. Di là costa novanta."
> **Leda:** "Ti dico perché costa di più: perché a me la mela costa dodici centesimi, e il banco quaranta. La CHEAP la mela la paga uguale, il banco non lo paga."
> **Leda:** "Tieni. Questa è in più. Non è un regalo: è che è un po' ammaccata, e nessuno la vuole."
> *È la mela più buona che hai mangiato da quando sei entrato nell'ascensore.*
→ `c3_spesa = "leda"`, `trust.leda += 1`. Se Leda non ti conosceva ancora, questa è la sua presentazione.

**Salto la cena:**
> *Ti siedi sulla stellina con la pancia vuota. Il tabellone, sopra di te, ti fa l'occhiolino: "Hai fame? Offerta!"*
> *(Se hai già conosciuto Amir:)* *Amir passa col carrello, ti vede, frena.*
> **Amir:** "Tu non hai cenato. Si vede dalla faccia: fai la faccia da prezzo."
> **Amir:** "Mezzo panino. L'altra metà è mia, eh. Non sono mica un santo, sono un rider."
> *(Se non l'hai conosciuto:) La notte passa lunga. Domani avrai meno energia.*
→ `c3_spesa = "salto"`, energia del giorno dopo −5 (oppure, con Amir, `trust.amir += 1` e niente perdita).

**Reazioni dopo (non prevedibili, ma spiegabili):**
- Tre sere di offerta di fila: la mattina il banco di Leda è chiuso. Lei è seduta sulla cassetta delle mele.
  > **Leda:** "Non è colpa tua. È che di là costava meno. Funziona così, lo sapevo da anni. Adesso ho tempo libero. Tantissimo. Non so che farci."

  Leda diventa "liberata" (`leda_chiusa`, aggiunta a `freed`), ma senza reddito: nel capitolo 5 si presenta alla Casa Comune e ha bisogno di cibo. **Non è un premio: è una persona da sostenere.**
- Comprare sempre da Leda costa: arrivi al badge un turno dopo. In cambio Leda ti offre il quaderno senza bisogno di aiutarla.
- Saltare la cena tre volte: Amir ti porta da Leda "a credito", e il gruppo d'acquisto nasce anche senza che tu lo proponga.

---

## 8. I finali

### La scelta alla Cima

Dopo il bilancio, la telefonata finale e tuo padre, restano tre azioni. **Tutte e tre sono sempre possibili.**
Il loro esito dipende da quello che hai dietro.

| Azione | Famiglia | Cosa cambia l'esito |
|---|---|---|
| **"Prendo la scrivania."** | Ascesa | Quante persone hai sfruttato; se hai usato il potere per qualcuno (decisioni prese); chi ti è rimasto vicino |
| **"Torno a casa."** | Sopravvivenza | Le relazioni rimaste (fiducia), i frammenti del sogno, quanto tempo hai lasciato andare |
| **"Apro i registri alla Casa Comune."** | Solidarietà | Le risorse della comunità, chi hai liberato e se l'hai sostenuto, le decisioni prese insieme, i robot che hai lasciato |

### Varianti

**Ascesa**
- *Il dirigente* (molti robot, nessuna decisione per gli altri): l'attico, la vista, la città che dorme. Intorno, i colleghi sorridono. Lo shader rivela che sono tutti robot. Nico non sale.
- *Il riformatore isolato* (pochi robot, decisioni prese): cambi tre regole. Una funziona (la paga del -3), due no. Ti spostano in un ufficio più piccolo, con una finestra più grande. Ines ti manda una lettera: "Ha funzionato. Per noi, almeno."
- *Il riformatore con le persone* (nessun robot, fiducia alta, decisioni): la Torre resta, ma con dentro qualcuno che sa i nomi. Dura? Il gioco non lo dice. Fermo, al Fondo, ha una sedia vera.

**Sopravvivenza**
- *La vita che continua* (fiducia alta, sogno ricordato): torni a casa. Il debito c'è ancora, la vita anche. Marta ti invita a cena, e stavolta ci vai. Sul tavolo, un pezzo del robot che volevi costruire.
- *Il tempo perso* (fiducia bassa, sogno dimenticato): torni a casa. Lavori, dormi, lavori. Nessuno ti aspetta, ma nessuno ti odia. La domanda finale ha una risposta sola: "Non me lo ricordo." Non è una punizione: è quello che è successo.
- *Il sopravvissuto stanco* (molti turni, pochi soldi, nessuna colpa): Fermo ti scrive dal Fondo: "Hai fatto i conti anche tu, eh? Vieni a trovarmi. La festa ti aspetta."

**Solidarietà**
- *La comunità piccola* (risorse basse, poche persone): la Casa Comune resta aperta in sei. Si litiga sui turni di cucina. Si mangia poco, insieme.
- *Il progetto fragile* (risorse medie, disaccordi aperti): i registri si aprono, mezza città smette di pagare. Una settimana dopo, metà torna alla Torre perché ha fame. L'altra metà resiste. Il finale si ferma lì, prima di sapere chi ha ragione.
- *La trasformazione* (risorse alte, liberati sostenuti, decisioni collettive, pochi robot): la Torre non crolla. Si svuota. I piani diventano case, scuole, un mercato. Il debito non esiste più perché nessuno lo riscuote. Disordinato, rumoroso, vivo.
- *Il fallimento* (hai aperto i registri senza comunità): la gente scende in strada, nessuno sa cosa fare. La Torre ristampa i registri in una notte. Ti ritrovi a casa: il finale diventa "il tempo perso", ma con un ricordo in più.

### L'epilogo

Dopo il finale, come una galleria: ogni persona conosciuta, una alla volta, con una frase su cosa le è successo
(viva, robot, liberata, alla Casa Comune, salita, rimasta). Chi non hai mai conosciuto non compare.
Ultima immagine: il protagonista e la domanda: *"Adesso che sei arrivato in cima, cosa volevi fare prima di iniziare a salire?"*
Le risposte sono i sogni che hai raccolto (sezione 3). La risposta scelta chiude il gioco con una scena di dieci secondi.

---

## 9. Verifica della salita (economia)

### Oggi

Paga del turno (con il turno fatto bene): Fondo ~200 €, -4 ~275 €, Mercato ~340 €, Banca ~390 €, Piano terra ~450 €.
Badge: 500 + 1.000 + 2.000 + 4.000 + 8.000 = 15.500 €.
→ **circa 42 turni** senza sfruttare nessuno (cioè 42 giorni). Troppi.

### Proposta: la paga segue il badge, la vita si mangia una parte

| Piano | Badge da comprare | Paga lorda (turno fatto bene) | Costo della vita a notte | Netto | Turni onesti |
|---|---|---|---|---|---|
| -5 | 500 | 200 | 0 | 200 | 3 |
| -4 | 1.000 | 300 | 0 | 300 | 4 (o il B-4 + Nives) |
| -3 | 2.000 | 800 | 300 | 500 | 4 |
| -2 | 4.000 | 1.500 | 500 | 1.000 | 4 |
| 0 | 8.000 | 2.800 | 800 | 2.000 | 4 |
| **Totale** | **15.500** | | | | **≈ 19 turni** |

- Con i turni fatti male (paga ridotta) si arriva a 5-6 per piano: lungo, non impossibile; e dopo tre turni falliti arriva la pietà.
- **Aiutando tutti su un piano**, Nives regala il badge: da 0 a 4 turni in meno a piano. Una salita tutta solidale chiede circa **8-10 turni**, più il tempo per aiutare.
- **Senza sfruttare nessuno si arriva in cima**, sempre. Le promozioni rendono di più e prima (900 € × 1,7ⁿ), ma non sono mai necessarie.
- Il costo della vita **non blocca mai**: se mancano i soldi, va sul debito e costa energia.
- Il debito nominale scende di 15.500 € in tutta la salita e sale di centinaia di milioni a notte: è voluto, ed è la rivelazione del capitolo 4.

In codice: `FLOORS` in `game_state.gd` riceve due campi, `pay_mult` e `living`; `work.gd` usa `pay_mult` al posto di `1 + 0,1 × piano`.

---

## 10. Stato narrativo (variabili)

### Visibile al giocatore

| Cosa | Dove si vede |
|---|---|
| Soldi, debito, energia, autostima, piano, ora | Barra in alto |
| LV e grado ("Supervisore") | Menu, e nelle frasi dei robot |
| Badge | Menu |
| Il turno di oggi (fatto o da fare) | Barra in alto e scritta TURNO |
| Le persone e cosa fanno | Nel mondo: grigie, colorate, robot, assenti |

### Interno (mai mostrato come numero)

| Variabile | Tipo | Esiste? | Uso |
|---|---|---|---|
| `day`, `minutes` | int | sì | Giorni passati (Sopravvivenza) |
| `exploited`, `robots` | int, lista | sì | Ascesa, epilogo |
| `helped_ids` | lista | sì | Nives, Solidarietà, epilogo |
| `freed` | lista | sì | Solidarietà (persone da sostenere) |
| `rank` | int | sì | Potere (Ascesa) |
| `refused` | int | sì | Promozioni rifiutate |
| `hard_work` | int | sì | Turni fatti (Sopravvivenza) |
| `self_esteem` | int | sì | Varianti dei finali |
| `trust` | dizionario id → 0..3 | **nuovo** | Fiducia per persona, anche fuori dalle battaglie |
| `community` | dizionario `cibo`, `casa`, `servizi`, `voce` → 0..3 | **nuovo** | Le risorse della comunità |
| `decisions` | lista di id | **nuovo** | Le decisioni prese col potere (capitoli 4-6) |
| `dream` | lista di frammenti | **nuovo** | Le risposte possibili alla domanda finale |
| `time_lost` | int | **nuovo** | Inviti saltati, straordinari, cene saltate |
| `flags` | dizionario | sì | Eventi e rivelazioni (`c1_*`, `c2_*`, `c3_*`, `svelato_*`, `met_*`...) |

I salvataggi esistenti si caricano senza problemi: le variabili nuove partono vuote se mancano nel file.

### Come una scelta raggiunge i capitoli dopo (senza moltiplicare i rami)

Non si fanno capitoli diversi: si cambiano **dettagli** nelle stanze che esistono già.
- **Persone:** grigia, robot, liberata, assente, o presente in un piano diverso (Leda alla Casa Comune).
- **Frasi:** una riga diversa per chi ricorda cosa hai fatto ("Tu sei quello delle offerte").
- **Stanze e oggetti:** un banco chiuso, un cartello cambiato, la tinta della stanza.
- **Risorse:** `community` sale o scende, e il capitolo 5 lo fa vedere (piatti a tavola, letti, luci accese).
- **Sguardo indietro:** una frase per piano, scelta per priorità.

Per ogni capitolo bastano 4-6 flag che contano, più le liste già esistenti.

---

## 11. Le tendenze in codice (senza contatore morale)

Le tendenze non si sommano in un numero solo. Si chiede allo stato tre cose diverse, **solo alla fine**:

```gdscript
## Quanto potere hai: grado, soldi tenuti, decisioni prese.
func power() -> int:
	return rank + decisions.size() + (1 if money >= 20000 else 0)

## Quante persone hai intorno, vive e non robot, e quanto si fidano.
func bonds() -> int:
	var n := 0
	for id in trust:
		if trust[id] >= 2 and not is_robot(id):
			n += 1
	return n

## Quanto è solida la comunità: risorse, e le persone liberate che sono state sostenute.
func community_strength() -> int:
	var s: int = community.values().reduce(func(a, b): return a + b, 0)
	for id in freed:
		if flags.get("sostenuto_" + id, false):
			s += 1
	return s
```

Il finale:

```gdscript
func ending() -> Dictionary:
	match flags.get("scelta_cima", "casa"):
		"scrivania":
			if exploited >= 3 and decisions.is_empty():
				return {"family": "ascesa", "variant": "dirigente"}
			return {"family": "ascesa", "variant": "riformatore_persone" if bonds() >= 4 else "riformatore_solo"}
		"registri":
			var c := community_strength()
			if c <= 2:
				return {"family": "solidarieta", "variant": "fallimento"}
			if c >= 9 and exploited <= 1:
				return {"family": "solidarieta", "variant": "trasformazione"}
			return {"family": "solidarieta", "variant": "fragile" if c >= 5 else "piccola"}
		_:
			if bonds() >= 3 and not dream.is_empty():
				return {"family": "sopravvivenza", "variant": "vita"}
			return {"family": "sopravvivenza", "variant": "stanco" if hard_work >= 15 else "tempo_perso"}
```

Nessuna di queste soglie dipende da una sola azione. `route()` resta per compatibilità finché esistono il Mercato e la Banca vecchi;
poi `world_look()` si appoggia alle tendenze: Mercato e Banca hanno l'aspetto "asta" se `power()` è alto,
"scambi" se `community_strength()` è alto, "coda" negli altri casi.

---

## 12. Piano d'implementazione

Ogni passo lascia il gioco funzionante, con i test che passano, e si può provare sul telefono.

**Passo 0 — Pulizia (piccolo).**
- Togliere `scenes/world/fondo.*`, `fall.*`, `data/jobs.json` (se non più letto).
- Ritoccare la condizione delle scale sbarrate (incoerenza 9).
- Aggiungere a `GameState` le variabili nuove (`trust`, `community`, `decisions`, `dream`, `time_lost`), salvate e caricate con valori di default.

**Passo 1 — Economia.**
- `pay_mult` e `living` in `FLOORS`; scontrino notturno dal -3; test che controlla i "≈ 19 turni" della salita onesta.

**Passo 2 — Capitolo 3: la stanza.**
- `tools/bake_c3_mercato.gd` → `chapters/c3/mercato.tscn` + `mercato_c3.gd` (come i capitoli 1-2).
- Leda e Amir in `npcs.json` (grigi, con `reveal_flag: c3_rivelazione`), Leda in `promotions.json`.
- `Router.MERCATO` punta alla scena nuova; le scale del -4 restano uguali.

**Passo 3 — Capitolo 3: il lavoro e la storia.**
- Il minigioco `cassa` in `work.gd` (tocco, aggiornamento prezzi, cliente senza soldi).
- La scena "Il primo carrello", il banco che chiude, il gruppo d'acquisto con Vito.
- Rivelazione del tabellone, sguardo indietro, "Capitolo 4 — La Banca".
- Documento `capitoli/capitolo_3_il_mercato.md`, test, APK.

**Passo 4 — Capitolo 4: la Banca.** Stessa struttura; lo sportello crediti; il conto del padre; la cartellina di Sandro.

**Passo 5 — Capitolo 5: Ufficio e Città.** Riuso della strada e del Rifugio come Casa Comune; Ada e Nadir; le riunioni serali che muovono `community`.

**Passo 6 — Capitolo 6, finali ed epilogo.** Il bilancio, la telefonata finale, tuo padre senza magia, `ending()`, la galleria, la domanda finale.
Si toglie `route()` e i finali vecchi.

**Passo 7 — Il sogno nei capitoli 1 e 2.** Le due aggiunte piccole (il disegno sotto la torta, la domanda di Tilde).
Si può fare in qualsiasi momento: non cambia nient'altro.
