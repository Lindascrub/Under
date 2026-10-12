# CHEAP — Documento di design

## L'idea in una frase

Un RPG narrativo in stile Undertale in cui il giocatore, schiacciato da un debito, può diventare ricco senza fatica sfruttando gli altri. Scopre solo alla fine che, firma dopo firma, intorno a lui sono rimasti solo robot.

## Cosa deve provare il giocatore

- **Pressione:** il debito è sempre a schermo e sale ogni notte. Lavorare sembra un dovere.
- **Comodità sospetta:** il lavoro che sfrutta qualcuno è *facilissimo* (un clic) e paga tantissimo. Quello onesto è un minigioco faticoso e paga pochissimo.
- **Senso di colpa:** il gioco non giudica mai mentre giochi. Il giudizio arriva tutto nel finale.

## Il ciclo di una giornata (7 giorni)

1. **Casa:** il computer mostra il debito e le email della banca e della CHEAP.
2. **Strada:** parli con le persone del quartiere. Puoi aiutarle con soldi o con tempo libero.
3. **Ufficio:** al terminale scegli l'incarico del giorno.
   - **Facile:** leggi cosa stai facendo a chi, poi premi FIRMA. Guadagno alto e una promozione.
   - **Duro:** un minigioco (magazzino o consegne). Paga bassa.
   - **Rifiuta:** zero soldi.
4. **Sera:** aiuti le persone, se ti resta tempo libero (3 al giorno, 2 se hai fatto un turno duro).
5. **Letto:** paghi la rata (o no) e dormi. Durante la notte gli interessi aumentano il debito.

## Economia (in `autoload/game_state.gd`)

| Valore | Numero | Perché |
|---|---|---|
| Debito iniziale | 48.000 € | Abbastanza da sembrare impossibile |
| Interessi | 1% a notte (circa 480 €) | Il lavoro onesto non riesce nemmeno a coprirli |
| Rata minima | 400 € al giorno | Se non la paghi: mora di 250 € |
| Lavoro facile | 1.500 € × 1,7 per ogni firma precedente | Più sfrutti, più vali |
| Lavoro duro | 50-400 € in base al minigioco | Ti spacchi la schiena per niente |

Il sistema è truccato apposta: chi lavora onestamente finisce la settimana con più debito di quando ha iniziato.

## La meccanica dei robot

Ogni incarico facile ha una **vittima** (in `data/jobs.json`). Appena firmi, quella persona viene sostituita da un robot:

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
| **Ricco** | 4 o più firme | Sei nell'attico, intorno a te i "colleghi". Nico sale a piedi, apre la finestra: sotto c'è la gente che dorme sui cartoni. Poi ti dice di guardarli davvero: sono tutti robot. Resti solo. |
| **Ribelle** | Almeno 3 rifiuti e almeno 4 aiuti | Il quartiere si riunisce di notte e assalta la banca. I registri dei debiti bruciano. Cosa succede ai creditori resta **ambiguo**. Il giorno dopo si vive di baratto. |
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
