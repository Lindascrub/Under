# Stelle, rigioco e badge — 9 novembre 2026

Nives regala il badge solo dopo tre stelle in tutti i minigiochi dei personaggi del piano.

| Piano | Minigiochi richiesti |
|---|---|
| Fondo | Mina (fili) e Bulbo (lampadine) |
| Sottoufficio | Tilde ed Ercole |
| Mercato | Leda e Amir |
| Banca | Olga e Teo |
| Città | Ada (anche nella Casa Comune) e Nadir |

Fermo e Rina non assegnano stelle. Turni e incarichi del Capo non contano per questo premio.
Chi è stato sostituito da un robot non può contribuire al regalo. Al Sottoufficio resta necessario il B-4 timbrato.
Alla Banca la contestazione di Olga e in Città l'aiuto a Rina restano azioni narrative autonome: non sono requisiti aggiuntivi per il badge.
Il badge si può sempre comprare alle condizioni del capitolo. Quelli già ottenuti nei vecchi salvataggi restano validi.

Si può riprovare finché il record è inferiore a tre stelle. Ogni tentativo costa un'ora;
i successi successivi pagano solo l'eventuale differenza rispetto al record, senza duplicare aiuti e ricompense.
A tre stelle spariscono le proposte di rigioco: si possono continuare conversazioni e vicende del personaggio.
Il record è salvato in `stelle_<id>`; il completamento non dipende dal giorno né dal numero di conversazioni.

Mina: collega colori uguali da sinistra a destra. Dimostrazione iniziale di 1,4 secondi, poi prova senza penalità.
Bulbo: rotte a sinistra, buone a destra. Una lampadina che sfarfalla richiede due swipe verso l'alto
(su PC due pressioni SU), quindi va nelle buone. Un unico swipe conta una sola volta, anche al rilascio.
Dinamo: alterna sinistra e destra e mantieni la lancetta nel verde; rimossi «TOCCA QUI» e «E QUI».

Nives al Fondo mantiene l'invito a salutare: dopo il badge risponde al ritorno, al turno e alla rivelazione,
poi alterna brevi saluti. Tutti i dieci personaggi hanno battute conclusive dopo le tre stelle.

Verifiche ripetibili: `tests/regole_stelle_test.tscn`, `tests/c1_chiarezza_test.tscn`,
`tests/c1_secondo_giro_test.tscn`, `tests/intro_fondo_test.tscn`, `tests/testi_dispositivo_test.tscn`.

## Aggiornamento del 14 novembre 2026

Al decimo tentativo sotto le tre stelle il personaggio chiude l'aiuto **e il record sale a tre stelle**:
compare la scritta «Tre stelle per l'impegno. Ci hai provato dieci volte: qui non devi più riprovare.»
(prima il record restava com'era). La soglia è in `scenes/minigame/minigame.gd` (`tentativi >= 10`).

## Il giorno che cambia (14 novembre 2026)

- Salire di piano fa passare una notte: `GameState.notte_tra_i_piani()` in `EditorRoom.look_back`.
  Il cartello del capitolo mostra anche «GIORNO N · NOME DEL GIORNO».
- Ogni tentativo costa un'ora: dopo 17 ore nello stesso giorno (dalle 7 a mezzanotte) il giorno cambia da solo.
- Ogni volta che comincia un giorno nuovo compare il cartello «GIORNO N» con la sveglia
  (`Router.cartello_giorno`, scritte in `world/sguardo_indietro.tscn`), poi la riga sul debito salito.

## Aggiornamento del 16 novembre 2026

- Al decimo tentativo il lavoro risulta fatto anche per la storia: si accendono i `win_flags` del minigioco
  (le stanze di Ada, la prova di Olga, l'inventario di Leda...). Restano fuori i premi in denaro (flag che finiscono in `_bonus`).
- Città: i volantini con Ada si possono fare anche in piazza durante la manifestazione (`_organizer_talk`).
  Il Capo telefona per il notiziario dopo che hai parlato col giornalista, o al più tardi prima dell'assemblea (`_capo_notiziario`).
  Il cartello «CHIUSURA PREVISTA» conta i giorni dall'arrivo in Città.
- Incarichi del Capo: titoli corti, premio sempre in vista (`ART.premio`), aiuti ridotti a una riga.
- Banca: le due comparse sedute nella sala (`SedutoSala0/1`) usano `world/cliente_seduto.gd`: solide e con una battuta.
