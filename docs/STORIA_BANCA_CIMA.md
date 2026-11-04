# CHEAP — La storia dalla Banca alla Cima

Riferimento narrativo approvato da Linda (versione unica, con tutte le correzioni approvate). Non aggiungere altre sottotrame o finali.

Le due regole nuove sono nella sezione 5:
- la prova di bilancio non è la stessa cosa delle riforme fatte davvero;
- il tuo debito è separato dalla regola per i debiti di tutti gli altri.

Legenda: **[NUOVO]** = dialogo nuovo · **[ESISTENTE]** = c'è già nel gioco · **[RITOCCATO]** = c'è già ma va cambiato.

---

## 1. Parere breve

**Cosa funziona già bene:**
- I personaggi hanno desideri piccoli e concreti.
- L'umorismo burocratico funziona.
- I finali leggono fatti, non punteggi.

**Cosa sistema questa versione:**
1. La Banca diceva due volte la stessa scoperta e anticipava il nome del fascicolo, che spetta alla Cima.
2. Nella Città il debito del protagonista spariva dalla storia.
3. Il finale A aveva un'etichetta morale («IL PADRONE»).

La ricevuta della Banca diventa il filo che tiene insieme Banca, Città e Cima. Torna solo nei momenti importanti.

---

## 2. La trama in sei capitoli

**Fondo — «Per andare avanti devo lavorare».** Il protagonista si sveglia con 7 miliardi di debito e una cyclette che accende le luci. Fermo pedala da sempre e vuole solo fermarsi. Il Capo chiede di accorciargli la pausa o di alzargli il ritmo. Pedalare paga, ma il debito non si muove. Salire sembra l'unica cosa sensata.

**Sottoufficio — «Se seguo le regole risolverò il problema».** Moduli, firme e timbri. Ercole aspetta una risposta, Tilde ha il timbro. Il Capo chiede di archiviare la richiesta di Ercole senza risolverla. Il protagonista impara che una regola si può seguire alla perfezione senza risolvere niente.

**Mercato — «Se guadagno di più starò meglio».** Ci sono Leda, Amir e i cartellini degli sconti. Il Capo chiede offerte ingannevoli. Il saldo sale, ma gli interessi corrono più veloci dei guadagni.

**Banca — «Almeno questo debito avrà un motivo».**
- Olga legge gli estratti conto con la lente e vorrebbe anche lei il suo gelato.
- Teo timbra pratiche e vorrebbe disegnare. Nives vende badge.
- Il Capo chiede di preparare per Olga una proposta di prestito: il protagonista decide quanto lasciarle leggere.

Alle scale il protagonista cerca il contratto del suo debito, e il contratto non c'è. **È la svolta:** prima saliva per pagare, da qui sale per avere una risposta. Porta con sé una richiesta di verifica, oppure almeno un riepilogo con l'indirizzo della Direzione.

**Città — «Quello che succede a me riguarda anche gli altri».**
- Casa Comune, Ada, Nadir, Rina e il centralino.
- Il Capo chiede di montare le dichiarazioni registrate per il notiziario **[ESISTENTE]**.
- Chi ha visto la Banca riconosce nei bilanci della Casa Comune la stessa frase: qualcuno è «autorizzato a riscuotere», ma il documento non c'è.
- Se il protagonista ha chiesto la verifica, la sua richiesta passa dal centralino, e il protagonista decide dove mandarla.
- Ada, Rina, Nadir, Leda e Amir possono offrire casa o lavoro, se li ha aiutati.

**Cima — «Ora posso decidere cosa fare del potere che mi offrono».**
- La Direzione è la Presidente.
- Il fascicolo OBBLIGO DI ESISTENZA spiega l'origine **[ESISTENTE]**: chi entra nella Torre diventa beneficiario dei suoi servizi e riceve una quota. Oggi la assegna una stampante, da sola.
- La Presidente risponde alla richiesta di verifica. Il protagonista può contestare esplicitamente il suo debito.
- Poi c'è un turno di bilancio, che è una prova: soldi, Casa Comune e debiti nello stesso schermo; seguono la pressione del Capo e la scelta finale.

---

## 3. Il finale della Banca

### 3a. Il terminale della sala (`_anomaly`)

- **[RITOCCATO]** «Causale: OBBLIGO DI ESISTENZA.» diventa:
  > TERMINALE: «Causale: riservata alla Direzione.»
- **[RITOCCATO]** La battuta di Teo, se è stato aiutato e non è robot:
  > TEO: «Questo è un codice delle pratiche interne. Non l'ho mai visto sul conto di un cliente.»
  
  Il resto resta **[ESISTENTE]**: «Non lo so. Ma forse stai cercando di ripagare qualcosa che non hai mai chiesto.»

### 3b. Le scale (sostituisce il pannello rosso)

**Azione [NUOVO]:** ai piedi delle scale c'è un lettore di badge, «USCITA CLIENTI — VERIFICA POSIZIONE». Il protagonista appoggia il badge e la musica rallenta **[ESISTENTE]**. Qui si accende `c4_anomalia`, anche se il terminale della sala non è stato consultato. È la stessa informazione, quindi conta una volta sola.

**Se il terminale della sala non è stato consultato:**
> TERMINALE: «Verifica posizione in corso.»
> TERMINALE: «Debito attivo: {debito}.»
> TERMINALE: «Ricerca del contratto originale...»
> \* *(tre blip)*
> TERMINALE: «Contratto originale: nessun documento trovato.»

**Se il terminale della sala è già stato consultato:**
> TERMINALE: «Bentornato. La ricerca del contratto originale risulta già effettuata.»
> PROTAGONISTA: «Lo so. Non c'era.»
> TERMINALE: «Confermiamo.»

**Da qui la scena è uguale per tutti:**
> PROTAGONISTA: «Allora perché devo pagare?»
> TERMINALE: «Questa filiale è autorizzata a riscuotere. Non a modificare l'origine dell'obbligazione.»
> PROTAGONISTA: «E chi la modifica?»
> TERMINALE: «La Direzione.»

Scelta: **[Chiedo una verifica.]** / **[Ritiro la ricevuta e salgo.]**

- **Chiedo una verifica** (flag `c4_verifica`):
  > TERMINALE: «Richiesta inoltrata alla Direzione.»
  > \* *La stampante fa uscire una ricevuta: RICHIESTA DI VERIFICA — DESTINATARIO: DIREZIONE, ULTIMO PIANO.*
  > PROTAGONISTA: «Nel frattempo?»
  > TERMINALE: «Gli interessi continuano a maturare.»
- **Ritiro la ricevuta e salgo** (flag `c4_riepilogo`):
  > TERMINALE: «Riepilogo della posizione.»
  > \* *Esce un foglio: DEBITO ATTIVO: {debito}. CONTRATTO ORIGINALE: NON TROVATO. In fondo, piccolo: «Per informazioni sull'origine: Direzione, ultimo piano.»*
  > TERMINALE: «Nessuna richiesta registrata. Buona salita.»

**La voce resta [ESISTENTE]:**
> VOCE: «Non preoccuparti. Non è necessario capire un debito per pagarlo. È necessario soltanto continuare.»

**Chiusura:**
- con la richiesta: «\* *L'indirizzo è stampato. Mancano solo i piani in mezzo.*»
- con il riepilogo: «\* *Sul foglio c'è un indirizzo. Nessuno ti ha chiesto se volevi usarlo.*»

### 3c. I saluti

L'ordine delle azioni si legge da un contatore unico, `GameState.flags["seq"]`, anche se due azioni sono successe nello stesso giorno (vedi sezione 7).

**SOLIDALE** (reclamo di Olga fatto, nessuna condizione nascosta, Teo aiutato e non robot)
> \* *Teo arriva di corsa con il quaderno.*
> TEO: «Dammi la ricevuta un secondo.»
> \* *Mette sotto la carta carbone e ricalca. Nell'angolo disegna un supereroe piccolissimo con una borsetta.*
> TEO: «Una la tieni tu. Una la tengo io, nel cassetto dei fumetti. Lì non la cerca nessuno.»
> \* *Olga si alza dalla sedia d'attesa con il suo numerino.*
> OLGA: «Chiedi sempre la copia. E leggila due volte.»
> OLGA: «Quando ti rispondono, me lo dici. Io intanto mi compro il gelato. Quello col biscotto. Me lo merito anche io.»

La copia di Teo (`c4_ricevuta_copia`) serve a conservare il documento e conta per il legame con Teo. **Non è una prova in più.**

**INTERMEDIA** (nessuna condizione nascosta, ma non è il caso solidale)
> \* *Metti la ricevuta in tasca, vicino al badge. Pesa più del badge.*
> \* *Olga, dalla sedia d'attesa, alza il numerino come per salutare. Poi guarda di nuovo il tabellone.*
> \* *Nives, in cima alla prima rampa:*
> NIVES: «Ricevute. Le colleziono anche io. Nessuna risposta, finora. Ma la carta è bella.»

**Proposta trasparente** (`boss_olga_offer.visible == true`): al saluto solidale o intermedio si aggiunge la valutazione di Olga. La regola: confrontare il costo totale e la commissione con quello che Olga paga adesso. Questo valore va aggiunto ai dati della missione.
- Le conviene:
  > OLGA: «L'ho letta tutta. Mi conviene. La firmo dopo averla riletta una volta da sola.»
- Non le conviene:
  > OLGA: «L'ho letta tutta. Non mi conviene. Ma ho potuto dirlo.»

**Condizioni nascoste** (`visible == false`), al posto del saluto:
> \* *La ricevuta esce piegata a metà. «Gli interessi continuano a maturare» è sul retro.*
> \* *Olga è dietro di te, con la proposta che le hai portato. Piegata a metà nello stesso modo.*
> OLGA: «Io avevo chiesto solo di leggere il contratto.»
> \* *Apre il foglio. Le condizioni erano sul retro, scritte piccole.*
> OLGA: «Non ho firmato. Ma mi ero fidata di te.»

Poi una riga secondo l'ordine delle azioni:
- **reclamo prima della proposta nascosta:**
  > OLGA: «Il reclamo me l'hai fatto scrivere tu. Questo foglio piegato me l'hai portato tu. Me le ricordo tutte e due.»
- **reclamo dopo la proposta nascosta:**
  > OLGA: «Prima il foglio piegato. Poi il reclamo. Il reclamo mi è servito. Il foglio non lo dimentico.»

Scelta:
- **[«La ritiro. Adesso.»]**, oppure **[«L'ho già ritirata.»]** se la correzione è stata fatta allo sportello. Flag `c4_olga_corretta`:
  > TERMINALE: «Proposta ritirata. Nuova proposta con tutte le condizioni inviata alla titolare.»
  > TERMINALE: «Il premio non è restituibile. Il Capo non accetta restituzioni.»
  > OLGA: «L'ho vista. Adesso la proposta è giusta. Te lo riconosco.»
  > OLGA: «Per fidarmi di nuovo serve più di un foglio.»
- **[«Avevi ragione a leggerla.»]** (flag `c4_olga_ammesso`):
  > OLGA: «Lo so. Mi fa piacere che lo sappia anche tu.»
- **[«Non è la stessa cosa.»]**
  > OLGA: «No. Io il foglio l'ho girato.»
- **[...]**
  > \* *Olga ripiega il foglio e torna a sedersi.*

Teo, se è stato aiutato e non è robot:
> TEO: «Te la copio lo stesso. Anche a lei ho fatto una copia. Completa.»

### 3d. Sguardo indietro [RITOCCATO]

Prima riga che vale, in ordine:
1. Teo robot: **[ESISTENTE]** «La Banca aveva guadagnato un impiegato perfetto. Nessuno aveva chiesto cosa avesse perso.»
2. Richiesta inoltrata: «Avevi una richiesta in viaggio, un indirizzo e nessuna risposta. Era già più di prima.»
3. Olga e Teo aiutati: **[ESISTENTE]**
4. Solo riepilogo: **[ESISTENTE]** «Per la prima volta, non eri sicuro di dovere davvero ciò che ti chiedevano.»

---

## 4. I ponti: Città e Cima

### Città

La missione del Capo resta il montaggio delle dichiarazioni registrate **[ESISTENTE]**. Non c'è nessun annuncio in piazza sulla pratica del protagonista.

**Ada, alla Casa Comune [NUOVO]** (con `c4_anomalia`):
> ADA: «Anche la Casa paga una quota. Per i servizi della Torre. Ho chiesto chi l'ha decisa.»
> ADA: «Mi hanno detto: è sempre stata così.»

**I bilanci (5.14) [NUOVO]**, accanto al canone passato da 7.000 a 19.000 €:
> \* *Nota: «Documento di variazione: non disponibile. Ente autorizzato a riscuotere.»*

Se Teo legge i conti con te:
> TEO: «È la stessa frase della Banca. Anche le virgole.»

La copia del rapporto 404 sulle commissioni duplicate resta **[ESISTENTE]**.

**Il centralino [NUOVO]**, solo con `c4_verifica` e una volta sola: la tua richiesta arriva con la destinazione proposta dal sistema, ARCHIVIO.
- CONFERMA: va in archivio.
- VERIFICA: va alla Direzione.
- SEGNALA: la richiesta si ferma e resta a te; la porti a mano.

**Olga in piazza [RITOCCATO]** (con `c4_olga_risposta`):
> OLGA: «La mia risposta è arrivata perché l'avevo chiesta per iscritto. Le cose scritte due volte pesano di più.»

**Offerte di casa e lavoro [NUOVO].** Ognuna accende il suo flag `offerta_<id>`:

| Chi | Quando | Dialogo |
|---|---|---|
| Ada | dopo l'assemblea, con `c5_ada_stanze` ed esito diverso da «riconversione» | «Una delle stanze resta vuota la notte. Se un giorno ti serve, chiedi. Si paga con un turno di pulizie.» |
| Rina | dopo l'aiuto alla vetrina (`c5_vetrina_aiuto`) | «Dietro la bottega c'è una brandina. Non è comoda. È mia, quindi è gratis.» |
| Nadir | dopo il percorso (`c5_nadir_tratta`) | «Alla zona industriale cercano gente per il turno corto. Con la tratta che hai trovato, ci arrivi anche tu. Sei euro esatti.» |
| Leda (non robot) | se collabora agli ordini condivisi | «Gli ordini condivisi hanno bisogno di qualcuno che li porti. Paga poco, ma all'ora giusta.» |
| Amir (non robot) | se è umano a fine Mercato | «Se esci, il giro delle consegne fuori lo conosco io. Ti porto con me il primo giorno.» |

**Personaggi liberati** (strada baratto): quando li liberi lasciano un recapito. Fermo, per esempio:
> FERMO: «Fuori ho trovato una stanza con due letti. Uno è per le gambe. Se esci, cercami.»

Flag: `offerta_fermo`.

### Cima

**6.02, la Presidente [NUOVO]**, prima di STRAP:
- **Richiesta arrivata:**
  > PRESIDENTE: «Richiesta di verifica. È arrivata.»
  > PRESIDENTE: «La Direzione sono io. Non mi immaginavi così.»
- **Richiesta finita in archivio** (rivisto: l'hai presentata, quindi conta come presentata):
  > PRESIDENTE: «La tua richiesta è arrivata. Poi è stata archiviata.»
  > PRESIDENTE: «Possiamo riprenderla adesso.»
  
  Con la copia di Teo:
  > \* *Le mostri la copia, con il supereroe nell'angolo.*
  > PRESIDENTE: «Una copia. Firmata da un supereroe. Va bene: la metto sopra.»
- **Solo riepilogo:**
  > PRESIDENTE: «Hai un riepilogo, non una richiesta. Sei salito lo stesso.»

**6.03, il fascicolo [ESISTENTE]:** «OBBLIGO DI ESISTENZA» compare qui per la prima volta.

**6.04, l'origine.** La spiegazione **[ESISTENTE]**: la Torre doveva funzionare, ogni nuovo abitante veniva registrato come beneficiario e gli veniva assegnata una quota. Subito dopo **[NUOVO]**:
> \* *Dietro la Presidente, una stampante. Vrrr. Esce un fascicolo.*
> PRESIDENTE: «Adesso non serve più un Consiglio. Ogni nuovo abitante viene registrato, e la stampante gli assegna la sua quota. Da sola.»
> \* *Vrrr. Un altro.*

**Verifica e contestazione [NUOVO].** Sono due cose diverse.
- Con la richiesta arrivata (o consegnata a mano):
  > PRESIDENTE: «La verifica è fatta. Per il regolamento, la registrazione è valida.»
- Con la richiesta archiviata (con o senza la copia di Teo):
  > \* *La Presidente apre un cassetto, sfoglia, tira fuori un foglio con il timbro ARCHIVIATA.*
  > PRESIDENTE: «Ripresa. La verifica è fatta. Per il regolamento, la registrazione è valida.»
- Senza richiesta (solo il riepilogo, o un salvataggio vecchio):
  > PRESIDENTE: «Non hai chiesto una verifica. Te la faccio qui, gratis. Valida.»

Scelta: **[Contesto la registrazione.]** / **[Non adesso.]**
> PRESIDENTE: «Registro la contestazione. Non annulla niente. Ma adesso c'è scritto che non sei d'accordo.»

Flag `c6_contestazione`. La scelta resta disponibile alla voce «Il debito, ancora.» **[ESISTENTE]** fino alla decisione finale.

**Il Capo prima del turno [NUOVO]:**
> CAPO: «Togli cinque dai servizi. Mettili in riserva. La tua pratica la chiudiamo noi. Timbro e via.»

---

## 5. Le regole comuni dei finali

**Chi compare:**
- Un personaggio compare solo se è stato conosciuto. Un robot compare da robot.
- Un personaggio liberato non lavora nella Torre e non prende ruoli, ma può offrire casa o lavoro e venire alle feste da fuori.
- Un ruolo compare solo se qualcuno ce l'ha davvero.

**La prova e le riforme vere.** Il turno è una prova **[ESISTENTE]**. Le sue decisioni diventano realtà solo così:

| Finale | Cosa vale nella Torre |
|---|---|
| **A** | le decisioni del turno, perché il protagonista le adotta prendendo la Direzione |
| **C2** | le decisioni adottate dal nuovo governo condiviso (le condizioni di C2 le rendono già sostenibili) |
| **C1** | solo i risultati concreti della piccola comunità (le reti, la Casa Comune com'è uscita dal capitolo 5). Le politiche della Torre restano quelle di prima |
| **C3** | nessuna riforma realizzata; si vede il progetto ancora aperto. Le politiche della Torre restano quelle di prima |
| **B** | le politiche della Torre restano quelle di prima. **Restano anche** aiuti, riparazioni e risultati dei capitoli precedenti (reclami, pause restituite, procedure riaperte, esito della Casa Comune) |

«Quelle di prima» vuol dire la distribuzione della Presidente (stipendi 40, servizi 20, manutenzione 25, riserve 15) e la regola dei debiti conservata.

**La stampante** segue la regola che vale davvero. La si vede nell'ufficio in A e, in tutti i finali, nella prima riga della Torre vista dall'alto **[ESISTENTE]**:

| Regola | Cosa si vede |
|---|---|
| Conserva (o quella di prima) | vrrr regolare, fascicolo dopo fascicolo |
| Riduci gli interessi | vrrr regolare; sui fascicoli «interessi 0,5%» |
| Revisione dei debiti imposti | stampante ferma, cartello «In revisione», la pila non cresce |
| Fonti alternative | vrrr regolare; accanto, una bacheca con le reti vere |

**Stipendi, servizi e manutenzione:** si mostrano solo in A e C2. Negli altri finali vale la distribuzione della Presidente e non si mostrano miglioramenti della Torre.

| Decisione | Cosa si vede |
|---|---|
| stipendi 45-54 | «metà dei prezzi coperti» |
| stipendi 55 o più | «prezzi coperti» |
| servizi 25 o più | «servizi allargati» |
| servizi sotto 15 | «servizi a pagamento» |
| arretrato di manutenzione 10 o più | il foglio «Caldaia: mancano…» |
| Casa Comune | in A e C2 la decisione presa nel turno; negli altri finali l'esito dell'assemblea del capitolo 5 |

**Il tuo debito e quello degli altri.** Due righe separate, in tutti i finali:

| Finale | Il tuo debito | I debiti degli altri |
|---|---|---|
| A | **annullato** | secondo la regola adottata: registrati / interessi allo 0,5% / in revisione |
| C2 | in revisione se è stata adottata la revisione; altrimenti contestato (con `c6_contestazione`) o registrato | secondo la regola adottata |
| C1, C3, B | contestato (con `c6_contestazione`) o registrato | registrati, come prima |

La richiesta di verifica da sola non rende il debito «contestato».

---

## 6. I finali

### A — prendere la Direzione

Le varianti si leggono in quest'ordine: **A2 → A1 → A3**.

| Variante | Condizione |
|---|---|
| **A2** IL DIRIGENTE CHE CAMBIA LE COSE [ESISTENTE] | come adesso |
| **A1** «ADESSO CHIAMI TU» | nel turno hai scelto «Conserva il sistema dei debiti» **mentre almeno un'altra regola era aperta** |
| **A3** IL TELEFONO SQUILLA ANCORA | tutti gli altri casi |

Non porta ad A1:
- conservare perché nessun'altra regola era aperta;
- non raggiungere un miglioramento;
- accettare l'attribuzione del Capo. Quella cambia solo il potere e si vede in A3.

**A2** resta **[ESISTENTE]**, con la stampante e le righe del debito della sezione 5.

**A1 «ADESSO CHIAMI TU» [NUOVO]**
> \* *L'ufficio. Il tuo debito: annullato. Il timbro ANNULLATO è sulla scrivania, usato una volta.*
> \* *La Presidente esce con una scatola.* «Le chiavi del salottino. I cuscini sono ancora nella plastica.»
> \* *Vrrr. La stampante butta fuori un fascicolo. OBBLIGO DI ESISTENZA. Un nome nuovo. 7.000.000.000 €.*
> \* *Il telefono ha un solo tasto: FONDO. Lo premi.*
> \* *Dall'altra parte qualcuno respira forte, come chi ha appena pedalato.* «...Pronto?»
> PROTAGONISTA: «È tutto molto semplice!»
> \* *Nero.*

**A3 IL TELEFONO SQUILLA ANCORA [NUOVO]**
> \* *L'ufficio. Il tuo debito: annullato. La stampante: {riga della regola adottata}.*
> \* *{Se hai accettato l'attribuzione del Capo: sui registri del lavoro della Torre c'è il tuo nome. Su tutti.}*
> \* *Sei solo alla scrivania. La Presidente ha lasciato le chiavi del salottino. I cuscini sono ancora nella plastica.*
> \* *Il telefono suona. Tasto FONDO.*
> \* *Rispondi.* «Pronto?» \* *Dall'altra parte qualcuno parla a lungo.*
> \* *Non dici «È tutto molto semplice». Non dici niente. Prendi una penna.*
> \* *Nero.*

### B — «IL TEMPO CHE RESTA» (rifiutare e andare via)

Ogni pezzo viene da un'offerta sentita davvero (sezione 4):

| Pezzo | Da dove viene | Se manca |
|---|---|---|
| Casa | Ada, Rina o un personaggio liberato | «un posto letto in affitto, per un mese» |
| Lavoro | Nadir, Leda, Amir o un personaggio liberato | un annuncio cerchiato, ancora senza risposta |
| Lettera sul frigo | solo se il tuo debito è contestato | il riepilogo della Banca, in un cassetto |
| Messaggio | la persona con il legame più recente, anche una liberata | vedi B1 |

**B2 (almeno due legami)**
> \* *Sei mesi dopo [ESISTENTE]. Una cucina piccola, nella stanza che ti ha trovato {chi ha fatto l'offerta}. Dalla finestra si vede la Torre, ancora accesa.*
> \* *Sul frigo: «Debito: CONTESTATO. Pratica in attesa.»* (solo se contestato)
> \* *Il calendario: i giorni del lavoro {dall'offerta} sono cerchiati. Gli altri sono vuoti. Vuoti apposta.*
> \* *Il telefono vibra. {Nome}:* «Ci sei stasera?»
> **[Sì.]**
> \* *Prendi le chiavi.*

**B1 (pochi legami)**
- Se c'è almeno un'offerta, la stanza o il lavoro vengono da lì, e il messaggio arriva da chi l'ha fatta.
- Se non c'è nessuna offerta e nessun legame:
  > \* *Una stanza in affitto, per un mese. La valigia è ancora mezza piena.*
  > \* *Sul tavolo: il riepilogo della Banca e un annuncio cerchiato.*
  > \* *Sotto la porta qualcuno ha infilato un volantino: «Stasera cena di chi è appena arrivato. Porta una sedia.»*
  > \* *Sul pianerottolo, una vicina che non conosci:* «Ci sei stasera?»
  > **[Sì.]**
  > \* *Non sai ancora se resterai. Prendi la sedia.*

### C — «NESSUNO SALE DA SOLO» (decidere insieme)

**C2 — La trasformazione della Torre**
> \* *Il Fondo. Sopra la cyclette, l'orologio segna la fine del turno. Arriva {persona del ruolo TURNI}, puntuale.* «Tocca a me.»
> \* *Fermo scende dalla cyclette. Le gambe tremano un po'. Sale.*
> \* *I tavoli condivisi [ESISTENTE]. {CONTI} ha il quaderno. {SERVIZI} sposta le sedie.*
> \* *Su un foglio: le decisioni del tavolo. {Righe di stipendi, servizi e Casa Comune, dalla sezione 5.}*
> \* *{Solo con arretrato di 10 o più:} Sul muro: «Caldaia: mancano…». Sotto, alcuni nomi a matita.*
> \* *Il tuo fascicolo è sul tavolo. {Stato personale, dalla sezione 5.}*
> \* *Una sedia vuota. Fermo ci si siede.*
> FERMO: «È la prima volta che mi siedo prima che faccia buio.»

Fermo scende dalla cyclette solo se è umano, non è stato liberato e il ruolo TURNI è coperto. Altrimenti il cambio di turno lo fa chi pedala adesso, e Fermo compare secondo la sua storia: da robot, oppure da fuori se è stato liberato.

**C1 — La piccola comunità**
> \* *La festa c'è, {dove si riunisce la comunità: la Casa Comune se è rimasta aperta, oppure la bottega di Rina}. Non ci sono tutti.*
> \* *Su un foglio: quello che la comunità fa davvero. {Le reti: gli ordini condivisi, i pendolari, la bottega come punto di raccolta…}*
> \* *I ruoli: quelli coperti hanno un nome. Gli altri hanno un punto interrogativo.*
> \* *Al Fondo, la dinamo gira ancora. Qualcuno scende con un piatto per Fermo.*
> FERMO: «Mangio pedalando. Ma oggi qualcuno è sceso.»
> \* *Il piatto torna su vuoto.*

Fermo:
- da robot: «MANGIARE NON È PREVISTO DAL TURNO»;
- se è stato liberato, la cyclette la pedala un'altra persona e lui arriva alla festa da fuori:
  > FERMO: «Sono venuto da fuori. Mi hanno detto che c'erano le sedie.»

**C3 — Il progetto incompleto**
> \* *Una stanza con sei sedie. Ne avete portate due.*
> \* *Sul foglio dei ruoli: CONTI, SERVIZI, TURNI. {Nomi, se ci sono}, il resto è vuoto.*
> \* *Il tuo fascicolo è ancora nella borsa. {Stato personale: contestato / registrato.}*
> \* *{L'unica persona del legame, una persona liberata che è venuta da fuori, o l'impiegata}:* «Domani ne portiamo un'altra.»
> \* *Sistemate le due sedie una davanti all'altra. Per ora basta per parlare.*

---

## 7. Reazioni e riparazioni

Ogni azione che conta per le reazioni salva un numero dal contatore unico `GameState.flags["seq"]`. Si confrontano i numeri, non i giorni.

La reazione si sceglie dall'ordine:
- **aiuto, poi torto:** il personaggio ricorda tutte e due le cose;
- **torto, poi aiuto:** riconosce l'aiuto, non dimentica il torto;
- **torto, poi riparazione:** riconosce la riparazione, ma la fiducia non torna piena.

Una riparazione deve riparare proprio il danno fatto.

| Personaggio | Torto e ricordo | Riparazione |
|---|---|---|
| **Fermo** | pausa accorciata o ritmo alzato. «Mi hai ascoltato. Poi mi hai tolto la pausa. Mi ricordo tutte e due le cose.» | tornare al Fondo e coprire tu un suo turno: «Quindici minuti. Li conto io.» Alla fine vale anche il ruolo TURNI, in C2. Uno stipendio più alto, da solo, non basta: «Mi pagate di più per non fermarmi.» |
| **Ercole** | richiesta archiviata senza risposta: **[ESISTENTE]** «Ma io non ho ricevuto una risposta…»; **[NUOVO]** «La firma me l'hai fatta tu. Anche l'archiviazione. Bella calligrafia, tutte e due.» | aprire con lui la nuova procedura (citata già nel testo **[ESISTENTE]**), con il timbro di Tilde: «È di nuovo aperta. Non è una risposta. Ma adesso si può aspettarla.» |
| **Leda** | etichette ingannevoli: la riga **[ESISTENTE]** sui reclami | riscrivere con lei i cartellini veri: «Vendo meno. Ma oggi nessuno torna indietro alla cassa.» |
| **Rina** | montaggio divisivo: **[ESISTENTE]** «Io ho parlato del mio vetro. Non ho detto di chiudere la Casa Comune.» | la rettifica pubblica (`boss_news_rectified`): «Hanno rimesso la frase intera. Adesso si capisce che ero arrabbiata con il vetro, non con la Casa.» |
| **Olga** | condizioni nascoste (sezione 3c) | ritirare e correggere la proposta (`c4_olga_corretta`). Epilogo: «Nella cartellina ho tutte e due le proposte. Quella piegata e quella giusta. Le tengo vicine.» |

Le riparazioni dei capitoli precedenti restano vere in **tutti** i finali, anche in B, C1 e C3.

---

## 8. Scene da rivedere (per dopo)

1. `chapters/c4/banca_c4.gd`:
   - `_anomaly`: causale riservata, battuta di Teo;
   - `on_stairs_step` / `revelation_lines`: il lettore di badge, i due rami, verifica e riepilogo, `c4_anomalia`, i saluti e la correzione della proposta;
   - `look_back_line`: le righe della sezione 3d.
2. `scripts/boss_missions.gd`:
   - valutazione della proposta trasparente (costo attuale di Olga);
   - ritiro della proposta;
   - numeri `seq`;
   - righe di aiuto, torto e riparazione.
3. Fondo: l'azione «copri il turno di Fermo». Sottoufficio: la nuova procedura di Ercole. Liberazione: le battute con il recapito.
4. `chapters/c5/citta_c5.gd` e `chapters/c5/casa_comune_c5.gd`:
   - Ada e la quota;
   - la nota nei bilanci e Teo;
   - la richiesta al centralino;
   - Olga in piazza;
   - le offerte di casa e lavoro.
5. `chapters/c6/cima_c6.gd`:
   - 6.02 con le tre versioni;
   - la stampante in 6.04;
   - verifica e contestazione (`c6_contestazione`);
   - la battuta del Capo prima del turno.
6. `chapters/c6/finali.gd` e `docs/ENDING_SYSTEM.md`:
   - ordine A2 → A1 → A3, con A1 legato alla scelta consapevole;
   - cosa vale nella Torre per ogni finale;
   - il tuo debito separato dai debiti degli altri;
   - «contestato» solo con `c6_contestazione`.
7. `chapters/c6/finale_c6.gd`:
   - le scene finali della sezione 6;
   - la prima riga della Torre vista dall'alto (stampante e debiti);
   - gli epiloghi secondo la sezione 7.
8. Documenti da aggiornare quando si implementa: `docs/CHAPTER_04_BANK.md`, `docs/CHAPTER_05_CITY.md`, `docs/CHAPTER_06_SUMMIT.md`.
---

## 9. I tre casi annotati (approvati)

**1. Richiesta consegnata a mano alla Presidente**
- Succede quando al centralino il giocatore sceglie SEGNALA: la richiesta resta a lui e la porta su di persona.
- Alla scena 6.02 va trattata come **richiesta arrivata**: la verifica è fatta e la contestazione resta un gesto separato.
- Serve solo una riga che dica che la richiesta è stata consegnata a mano, nello stesso tono.

**2. Finale B: tutte le combinazioni di legami e offerte**
- Ogni pezzo si prende solo dalla sua fonte. Se manca, si usa il suo ripiego: «posto letto in affitto, per un mese», l'annuncio cerchiato, il riepilogo nel cassetto.
- Combinazioni da provare: solo casa; solo lavoro; casa e lavoro da due persone diverse; legami ma nessuna offerta; offerta da un personaggio liberato ma pochi legami; niente di tutto questo.
- Chi manda «Ci sei stasera?», in quest'ordine: la persona con il legame più recente, poi chi ha fatto un'offerta, poi la vicina sconosciuta.
- Una casa o un lavoro non compare mai senza il dialogo che l'ha offerto.

**3. Sguardo indietro della Banca, anche con l'inganno a Olga**
- Se le condizioni erano nascoste e la proposta non è stata corretta, la riga «Non avevi cancellato i debiti. Avevi aiutato qualcuno a non affrontarli da solo.» non deve comparire: si passa alla riga della richiesta o del riepilogo, oppure a una riga apposta per l'inganno.
- Se la proposta è stata corretta, la riga deve riconoscere la correzione senza far finta che l'inganno non ci sia stato.
