# CHEAP — Documento di design

## L'idea in una frase

Un RPG narrativo in stile Undertale in cui il giocatore, schiacciato da un debito, può diventare ricco senza fatica sfruttando gli altri. Scopre solo alla fine che, firma dopo firma, intorno a lui sono rimasti solo robot.

## Cosa deve provare il giocatore

- **Pressione:** il debito è sempre a schermo e sale ogni notte. Lavorare sembra un dovere.
- **Comodità sospetta:** il lavoro che sfrutta qualcuno è *facilissimo* (un clic) e paga tantissimo. Quello onesto è un minigioco faticoso e paga pochissimo.
- **Senso di colpa:** il gioco non giudica mai mentre giochi. Il giudizio arriva tutto nel finale.

## Il ciclo di una giornata (4 giorni, orologio di 24 ore)

Se il debito arriva a zero, il finale parte appena vai a dormire.

La giornata inizia alle 7:00 e finisce a mezzanotte. Ogni azione consuma tempo:

| Azione | Tempo |
|---|---|
| Firmare l'incarico facile | 1 ora |
| Turno duro (battaglia di lavoro) | 8 ore |
| Ascoltare una persona (battaglia) | 1 ora |
| Aiutarla col tuo tempo (minigioco a sorpresa, ti dà 10 €) | +1 ora |
| Riposare su una panchina | 1 ora (+8 energia) |
| Spostarsi tra casa, strada e ufficio | 10 minuti |

A mezzanotte crolli dal sonno e ti risvegli a casa, dove paghi (o no) la rata. La luce in strada cambia con l'ora.

## Luoghi

- **Casa**: letto (rata e salvataggio), computer della banca.
- **Strada**: auto che passano (si fermano se sei in mezzo), passanti, piccioni che volano via, il chiosco di Nico, la torre della CHEAP.
- **Parco** (in cima alla via laterale): Tano il musicista, la signora Elsa dei gatti, Rocco (ex dipendente CHEAP sostituito da un robot). Di sera, se hai già rifiutato il lavoro, c'è il mercato del baratto.
- **Ufficio**: il terminale degli incarichi. L'ascensore porta all'**ufficio del Capo** (Dottor Prezzi) dal grado di Supervisore: ogni giorno offre un "incarico extra" che promuove qualcuno al posto tuo.
- **Il Rifugio** (cantina del palazzo blu): si sblocca aiutando Ivo. Letto per riposare, pane gratis una volta al giorno, una bacheca con i messaggi del quartiere.
- **Casa di Marta** (portone giallo): dopo averla aiutata ti invita a cena (energia al massimo).

Dopo che le hai aiutate, le persone fanno altro per il resto della giornata (campo `after_help` in `data/npcs.json`): il signor Bruno torna a casa con la spesa, Dario va alla recita, Sami riparte a consegnare.

I personaggi hanno un ritratto nei dialoghi e mostrano nuvolette sopra la testa ("…", "!", una nota, un cuore). I robot no.

Di sera (dalle 18) molte persone cambiano posto: alcune vanno al parco, altre tornano a casa.

## Salvataggi

Le stelline gialle (strada e parco) salvano stanza, posizione e ora, e ridanno tutta l'energia. Anche dormire salva. "Continua" riporta esattamente lì.

## Minigiochi di aiuto

Quando aiuti qualcuno col tuo tempo parte un minigioco a sorpresa; se ci riesci ti danno 10 €.

| Tipo | Come si gioca | Chi |
|---|---|---|
| Tempismo | Premi Z quando il segno è nel verde | Signor Bruno (scale), Sami (catena), Tano (chitarra) |
| Raccolta | Muovi il cuore e raccogli tutto in tempo | Ivo (foglie), Elsa (croccantini) |
| Sequenza | Ricorda e ripeti le frecce | Dario (pratiche), Giulia (post-it), Rocco (curriculum) |

## Le battaglie (stile Undertale)

Il cuore rosso schiva gli "attacchi" dentro il riquadro. L'energia (20) scende quando vieni colpito; a zero crolli dallo stress e perdi tre ore.

- **Persone** (strada e ufficio): PROMUOVI (il nome aziendale per sfruttare: soldi subito, la persona diventa un robot), PARLA (aumenta la fiducia), OGGETTI, AIUTA (diventa giallo quando la fiducia è piena). Ogni persona attacca coi suoi problemi: bollette e giocattoli (Marta), briciole e piccioni (Bruno), libri e notifiche (Lea), auto e pioggia (Sami), chiavi (Ivo), pratiche ed email (Dario), post-it (Giulia).
- **Lavoro duro:** LAVORA (avanzi di un quarto di turno), PARLA, OGGETTI, MOLLA. Il caporeparto usa anche la telecamera blu: se ti muovi mentre la luce blu ti passa sopra, ti colpisce.
- **Lavoro facile:** tutti e quattro i pulsanti dicono FIRMA.

## Economia (in `autoload/game_state.gd`)

| Valore | Numero | Perché |
|---|---|---|
| Debito iniziale | 6.000 € | Lavorando onestamente scende un po', ma non sparisce |
| Interessi | 2% a notte | |
| Rata minima | 150 € al giorno | Se non la paghi: mora di 100 € |
| Lavoro facile | 900 € × 1,7 per ogni sfruttamento precedente | Più sfrutti, più vali: in 3 giorni ripaghi tutto |
| Lavoro duro | 30-260 € in base a quanto ne fai e ai colpi presi | Ti spacchi la schiena per poco |

## La meccanica dei robot

Ogni incarico facile ha una **vittima**, e anche scegliere PROMUOVI in una battaglia con una persona la trasforma (in `data/jobs.json`). Appena firmi, quella persona viene sostituita da un robot:

- stessa faccia e stesso posto;
- frasi aziendali vuote che ti chiamano per titolo ("Buongiorno, Supervisore.");
- l'animazione è ferma: non respira più. È l'unico indizio visivo e quasi nessuno lo nota.

Nel finale ricco lo shader `shaders/robot.gdshader` rivela tutti i robot.

| Giorno | Incarico facile | Vittima |
|---|---|---|
| 1 | Lettera di sfratto | Marta |
| 2 | Respingere il rimborso a un pensionato | Signor Bruno |
| 3 | Licenziare un collega | Dario |
| 4 | Aumentare gli affitti agli studenti | Lea |
| 5 | Turni da 14 ore per i rider | Sami |
| 6 | Tagliare l'assicurazione sanitaria | Giulia |
| 7 | Demolire il palazzo | Ivo |

## Personaggi

- **Nico:** vende caffè in strada. Simpatico, ironico, l'unico che nota come cambi. Nel finale ricco è lui ad aprire la finestra. Non diventa mai un robot.
- **Marta:** vicina di casa, madre sola, due figli.
- **Signor Bruno:** pensionato, dà da mangiare ai piccioni.
- **Lea:** studentessa che fa tre lavori.
- **Sami:** rider sfruttato da un'app.
- **Ivo:** portiere del palazzo, amico di tuo padre.
- **Dario:** collega cinico, tre figli.
- **Giulia:** collega gentile che ti insegna il lavoro.

## I tre finali (`route()` in `game_state.gd`)

| Finale | Condizione | Cosa succede |
|---|---|---|
| **Ricco** | 3 o più sfruttamenti (o debito pagato sfruttando) | Sei nell'attico, intorno a te i "colleghi". Nico sale a piedi, apre la finestra: sotto c'è la gente che dorme sui cartoni. Poi ti dice di guardarli davvero: sono tutti robot. Resti solo. |
| **Ribelle** | Almeno 2 rifiuti e almeno 3 aiuti | Il quartiere si riunisce di notte e assalta la banca. I registri dei debiti bruciano. Cosa succede ai creditori resta **ambiguo**. Il giorno dopo si vive di baratto. |
| **Onesto** | Tutti gli altri casi | Strada al tramonto. Il debito è più grande di prima e il sistema è uguale. Ma le persone che hai aiutato sono vere e sono lì. |

## Struttura del codice

```
autoload/      singleton sempre attivi
  game_state   soldi, debito, scelte, finali, salvataggio
  ui           HUD, dialoghi, scelte, dissolvenze, testo narrato
  router       cambio scena con dissolvenza
  controls     comandi da tastiera
scripts/       classi riusabili
  room         base delle stanze (mappa da griglia di caratteri)
  player, npc, interactable, assets
scenes/        main_menu, world/ (casa, strada, ufficio), minigames/, endings/
data/          testi dei personaggi e degli incarichi (JSON, modificabili senza toccare il codice)
shaders/       effetto robot
tests/         test automatico che gioca tutto il gioco
tools/         script per importare gli asset LimeZu
```

## Idee per i prossimi passi

- Musica e suoni (bip del testo come in Undertale).
- Un font pixel art (per esempio da Google Fonts, licenza OFL).
- Disegnare le stanze nell'editor con TileMapLayer invece che con le griglie di caratteri.
- Più indizi sui robot (riflessi, ombre, frasi ripetute parola per parola).
- Il parcheggio della sera nella strada ribelle, con un minigioco di baratto.
- Finale "nascosto": restare ricco senza mai sfruttare nessuno è impossibile, ma il gioco potrebbe farti provare.

## Domande ancora aperte

- Il protagonista ha un nome o resta "tu"?
- Sette giorni bastano, o la storia ne vuole di più (per esempio un mese diviso in settimane)?
- Nel finale ribelle si vede qualcosa della notte in banca, o resta tutto fuori scena?
