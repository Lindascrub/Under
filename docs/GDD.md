# CHEAP — Documento di design

> Aggiornato il 26/10/2026. La storia completa (capitoli, personaggi, tendenze, finali, variabili)
> è in [NARRATIVE_DESIGN.md](NARRATIVE_DESIGN.md). I capitoli già rifatti hanno il loro documento in
> [capitoli/](capitoli/). Le parti marcate **(versione precedente)** descrivono codice che esiste
> ancora ma che verrà rifatto: non sono più la direzione del gioco.

## L'idea in una frase

Un RPG narrativo in pixel art, per telefono in orizzontale, in cui il protagonista, schiacciato da un
debito di 7 miliardi, sale la Torre CHEAP un piano alla volta. La Torre promette che, lavorando
abbastanza, un giorno sarà libero. Salendo scopre che i problemi della Torre non sono solo persone
cattive, ma regole, incentivi e gerarchie che spingono tutti, lui compreso, a fare certe scelte.

**La domanda del gioco:** se passi tutta la vita a guadagnarti il diritto di vivere, quando inizi a vivere davvero?

## Tono

Divertente, surreale, a tratti assurdo all'inizio; poi, piano dopo piano, sempre più inquietante.
La critica non è mai una lezione: viene fuori dalle meccaniche e dalle conseguenze.
Il gioco non giudica mentre giochi. Alla fine non dà un voto: fa vedere cosa è successo.

## La Torre a piani

All'inizio sei nell'ascensore della Torre e scendi. Al piano -5 l'ascensore si rompe. Da lì si sale a piedi.

| Cap. | Piano | Posto | Tema | Badge per salire | Stato |
|---|---|---|---|---|---|
| 1 | -5 | Il Fondo | La festa finta | 500 € (per il -4) | **Rifatto** (`chapters/c1/`) |
| 2 | -4 | Il Sottoufficio | La burocrazia infinita | 1.000 € (per il -3) | **Rifatto** (`chapters/c2/`) |
| 3 | -3 | Il Mercato | Caro vita, salari e prezzi | 2.000 € (per il -2) | Da rifare (prossimo) |
| 4 | -2 | La Banca | Debito e dipendenza | 4.000 € (per il piano terra) | Da rifare |
| 5 | 0 | Ufficio e Città | Le conseguenze fuori dalla Torre | 8.000 € (per la Cima) | Da rifare |
| 6 | Cima | Direzione e Presidenza | Potere, responsabilità, libertà | — (finale) | Da rifare |

I soldi del badge vanno tutti a scalare dal **debito nominale**. Ogni notte gli interessi lo fanno risalire.
Il debito non si ripaga lavorando, e non deve: l'obiettivo è salire, e capire.

## Il ciclo di ogni piano

1. **TURNO.** Sopra al posto di lavoro c'è la scritta TURNO: gialla finché devi lavorare, grigia dopo.
   Il turno è un minigioco a tocco (uno al giorno). Paga.
2. **Le persone vere.** Sono grigie. Si conoscono parlando e si aiutano con un minigioco.
   Il sistema (sportelli, venditori, capi, macchine) è colorato, in modo artificiale.
3. **Il capo chiama** dopo il turno, **una volta per piano**: propone di prenderti il merito del lavoro di
   qualcuno del piano, con "un, due, tre, stella". Si può sempre rifiutare.
4. **Chi viene sfruttato diventa un robot sorridente.** Per sempre: stessa faccia, frasi aziendali, non respira.
5. **Il badge** del piano di sopra si compra allo sportello di Nives (che è uguale su ogni piano).
   Se hai aiutato davvero tutte le persone del piano, Nives te lo regala.
   Ogni piano può avere una condizione in più (al -4: il Modulo B-4).
6. **Il primo gradino:** la rivelazione del piano.
7. **In cima alle scale ti volti:** la telecamera mostra la stanza com'è diventata, compare una frase sola
   che dipende da cosa hai fatto, poi il titolo del capitolo dopo.
8. **Le stelline** salvano e fanno passare la notte. Ogni notte: interessi.

Alla Cima il ciclo cambia: niente scale, una conclusione (vedi NARRATIVE_DESIGN, capitolo 6).

### La regola dei colori

- Persone vere: grigie (al Fondo Fermo ha anche un alone scuro).
- Sistema: colorato e finto. Il capo è il più colorato di tutti (il suo ritratto cambia colore).
- Robot: sorridenti, colorati come i poster.

### Le scale sbarrate

Se al Fondo sali senza esserti voltato verso nessuno, le scale per il Fondo vengono chiuse (coni,
nastro, cartello VIETATO, al -4). Al Fondo non si torna più. Va resa più chiara: vedi NARRATIVE_DESIGN, "Incoerenze".

## Comandi

Il gioco è pensato per telefono in orizzontale.
- **Nel mondo:** joystick e pulsanti a schermo.
- **Nei minigiochi:** si gioca direttamente sullo schermo (tocca, tieni giù, scorri, trascina).
  Le istruzioni dicono "tocca", mai "premi".
- **Su PC:** frecce, Invio/Z, Esc/X.
- **Dialoghi:** le frasi lunghe vanno a pagine; un tocco mostra subito tutta la frase, un altro va avanti.
- **In alto:** la barra con piano, ora, debito ("7,00 mld €"), soldi, energia, autostima.
- **La telecamera** resta sempre dentro i muri: il giocatore non deve mai vedere il "fuori mappa".

## Economia

### Valori attuali (in `autoload/game_state.gd`)

| Valore | Numero |
|---|---|
| Debito iniziale | 7.000.000.000 € |
| Interessi | 2% a notte (+0,5% per ogni contratto col Signor Rata) |
| Badge | 500 / 1.000 / 2.000 / 4.000 / 8.000 € (raddoppia a ogni piano) |
| Paga del turno | paga del lavoro (200-320 €) × (1 + 0,1 × piano) × quanto bene hai lavorato (minimo 40 €) |
| Promozione (sfruttare) | 900 € × 1,7 per ogni sfruttamento precedente |
| Aiutare qualcuno | 10 € e +1 autostima (la prima volta) |
| Straordinario al Fondo | 120, 70, 35 € (tre volte al massimo) |
| Procedura d'urgenza al -4 | 300 € |

### Il problema da risolvere: la salita onesta è troppo lunga

Con i valori attuali, salire fino alla Cima senza sfruttare nessuno chiede circa **42 turni**
(il badge raddoppia, la paga sale solo del 10% a piano). Troppi.
La proposta (in NARRATIVE_DESIGN, "Verifica della salita") è di far crescere la paga piano per piano
e introdurre, dal Mercato, il **costo della vita**: guadagni di più, ma spendi di più. È il tema del capitolo 3,
e porta la salita onesta a circa **19 turni** (meno se aiuti tutti e Nives ti regala il badge).

### Pietà e contratti

Dopo tre giorni di seguito di turni falliti, qualcuno del piano ha pena di te e ti dà i soldi che mancano
(al -4 la Signora Agenda, al -3 Vito...). Oppure il Signor Rata ti dà il badge subito, se firmi:
il prezzo, più la metà, va sul debito, e gli interessi salgono.

## La meccanica dei robot

Chi viene sfruttato (promozione del capo, o PROMUOVI in una battaglia) viene sostituito da un robot:
stessa faccia e stesso posto, frasi aziendali che ti chiamano per titolo, nessun respiro.
Ogni sfruttamento fa salire il **LV** (come in Undertale, qui è "level of violence"): la promozione è il level up.
Nel finale `shaders/robot.gdshader` rivela tutti i robot.

Le promozioni per piano sono in `data/promotions.json` (Fermo, Tilde, e i vecchi personaggi della città).

## Minigiochi

### I turni (TURNO), in `scenes/minigame/work.gd`

| Piano | Lavoro | Come si gioca col dito |
|---|---|---|
| -5 | Cyclette (la dinamo) | Tocca a sinistra e a destra, alternando, per restare nel verde |
| -4 | Call center | Tocca il telefono che squilla, poi la risposta: copione (paga), sincera (autostima), sgarbata (errore). Finale: squillano tutti |
| altri (versione precedente) | Bilancia, magazzino (Tetris), consegne, bagni, cassa (Pong) | Tocco, scorrimento, trascinamento |

Il turno è sempre il minigioco: la vecchia "battaglia col caporeparto" ogni tre turni è stata tolta.

### L'aiuto alle persone, in `scenes/minigame/minigame.gd`

| Tipo | Come si gioca col dito | Chi |
|---|---|---|
| Lampadine | Scorri a destra (buona), a sinistra (rotta), su e giù (avvita) | Bulbo |
| Fili | Tocca un filo a sinistra, poi il suo posto a destra | Nonno Mina |
| Sequenza | Guarda le frecce, poi ripetile | Tilde (il copione) |
| Tempismo | Tocca quando il segno è nel verde | Ercole (tienilo sveglio) |
| Raccolta | Trascina il cuore e raccogli tutto | (versione precedente: Ivo, Elsa) |

### Un, due, tre, stella (il furto di merito), in `scenes/minigame/arcade.gd`

Tieni il dito giù per avvicinarti mentre il capo ti dà le spalle, e ancora per copiare. Quando si gira, stacca il dito.

## Le battaglie (stile Undertale)

Il cuore rosso schiva gli "attacchi" dentro il riquadro. L'energia (20) scende quando vieni colpito;
a zero crolli dallo stress e perdi tre ore. Restano per gli incontri con le persone
(PROMUOVI, PARLA, OGGETTI, AIUTA). Il testo del riquadro si rimpicciolisce se non ci sta.

## Salvataggi

Le stelline salvano stanza, posizione, ora e tutte le scelte (`user://cheap_save.json`), e possono
far passare la notte. Si salva tutto lo stato di `GameState` (soldi, debito, badge, robot, aiutati, liberati,
flag), più le scelte nuove descritte in NARRATIVE_DESIGN ("Stato narrativo").

## La città (versione precedente)

Esiste ancora, e verrà riusata nel capitolo 5 (Piano terra: Ufficio e Città):
- **Strada:** il chiosco di Nico, Marta, il Signor Bruno, Lea, Sami, Ivo.
- **Ufficio:** Dario e Giulia; l'ascensore per la Direzione (Dottor Prezzi, il capo).
- **Parco:** Tano il musicista, la Signora Elsa dei gatti, Rocco (sostituito da un robot).
- **Il Rifugio** (cantina del palazzo blu): diventerà la **Casa Comune** del capitolo 5.
- **Casa:** il letto, il robot giocattolo, il post-it e i vestiti di tuo padre.
- **Missioni** (`data/quests.json`): il gatto di Elsa, le ripetizioni a Luca, il pacco di Sami, gli occhiali di Ivo.

I personaggi di città hanno un "perché lavoro" (`motive` in `data/npcs.json`: debito, paura, abitudine, orgoglio)
e si possono **liberare**: conquisti la fiducia, chiedi perché lavora, e in AIUTA scegli Liberalo.
Chi smette rinuncia allo stipendio: ha ancora bisogno di mangiare e di una casa.

## I finali

Le vecchie tre strade (capitalismo, comunismo, baratto) e i finali Ricco/Ribelle/Onesto **non sono più la direzione**.
Al loro posto ci sono tre **tendenze**, che non si vedono mai durante il gioco e non decidono da sole il finale:

- **Ascesa** (potere e compromessi): dirigente opportunista, oppure qualcuno che prova a cambiare il sistema da dentro.
- **Sopravvivenza** (il tempo che scompare): si continua a vivere e lavorare; quello che resta sono le relazioni e i sogni conservati o persi.
- **Solidarietà** (la libertà collettiva): una comunità che deve trovare cibo, case, servizi e decidere insieme. Può funzionare, restare fragile o fallire.

Ogni famiglia ha più varianti, e c'è un epilogo in cui rivedi le persone conosciute. Dettagli e condizioni:
NARRATIVE_DESIGN, "Tendenze" e "Finali". Nel codice attuale c'è ancora `GameState.route()` con i vecchi nomi:
verrà sostituito senza rompere i salvataggi (vedi il piano di implementazione).

## Struttura del codice

```
autoload/      singleton sempre attivi
  game_state   soldi, debito, badge, scelte, flag, finali, salvataggio
  ui           barra in alto, dialoghi (a pagine), scelte, dissolvenze, testo narrato
  router       cambio scena con dissolvenza
  touch_controls  joystick, pulsanti e gesti dei minigiochi
  sound        musica e suoni (la voce dei dialoghi ha un canale suo)
chapters/      i capitoli rifatti: c1/ (Fondo), c2/ (Sottoufficio). Scena .tscn + script di logica
world/         EditorRoom (stanze fatte nell'editor), RoomFeature, NpcSpot, Examine, CharSprite, tileset
scripts/       Room (base di tutte le stanze), Player, Npc, Quests, Assets
scenes/        main_menu, world/ (stanze della versione precedente), minigame/, battle/, endings/
data/          testi e dati (JSON): persone, promozioni, lavori, missioni
tools/         gli script "bake" che creano le scene dei capitoli, la generazione di arte e audio
tests/         smoke_test (gioca tutto il gioco), touch_test (i comandi col dito)
```

I file `scenes/world/fondo.*` e `scenes/world/fall.*` non sono più usati (sostituiti dal capitolo 1 e dall'ascensore):
si possono togliere.

## Domande ancora aperte

- Il protagonista ha un nome scelto dal giocatore: resta così?
- Quanto deve durare tutta la salita? (Proposta: 2-3 ore, circa 20 giorni di gioco.)
- Il sogno del protagonista: tra quali possibilità? (Proposta in NARRATIVE_DESIGN, "Il sogno".)
