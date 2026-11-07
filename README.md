# CHEAP

Un piccolo RPG narrativo per Android (telefono in orizzontale), fatto con Godot 4.

Inizi dentro un ascensore che scende, con un debito di 7 miliardi di €. Al piano -5 si rompe: è tutto buio, tranne la luce intorno a Fermo, che ti spiega come funziona. Si sale la torre un piano alla volta (Fondo, Sottoufficio, Mercato, Banca, Città, Cima): a ogni piano fai il TURNO (un minigioco, uno al giorno), conosci le persone e le aiuti con un minigioco a sorpresa, compri il badge del piano di sopra (che scala dal debito) e passi il tornello delle scale. I giorni non sono contati, ma ogni notte il debito cresce. Il Capo ti propone degli incarichi: prenderti il merito di qualcuno conviene, ma chi viene sfruttato diventa un robot con la sua faccia. Si salva toccando le stelline. Alla Cima una scelta decide il finale; quello che hai fatto prima decide come va.

Design in [docs/GDD.md](docs/GDD.md), regole attuali in [docs/COHERENCE.md](docs/COHERENCE.md), finali in [docs/ENDING_SYSTEM.md](docs/ENDING_SYSTEM.md).

## Requisiti

- [Godot 4.6](https://godotengine.org/) o successivo.
- Gli asset **Modern Interiors** e **Modern Exteriors** di [LimeZu](https://limezu.itch.io/). Sono a pagamento e **non sono inclusi** in questo repository, perché la licenza non permette di ridistribuirli. Senza asset il gioco parte lo stesso, ma con dei rettangoli colorati al posto della grafica.

## Come avviarlo

1. Metti `moderninteriors-win.zip` e `modernexteriors-win.zip` nella cartella sopra il progetto (oppure dove vuoi).
2. Copia gli asset nel progetto:

   ```powershell
   powershell -ExecutionPolicy Bypass -File tools\import_assets.ps1 -Source "C:\percorso\degli\zip"
   ```

3. Apri `project.godot` con Godot e premi **F5**.

## Comandi

| Tasto | Azione |
|---|---|
| Frecce / WASD | Muoversi |
| Z / Invio / Spazio | Parlare, interagire, confermare |
| X / Shift | Correre, saltare il testo |
| C | Stato e oggetti (ora, energia, badge), e le Impostazioni |
| F11 | Schermo intero (sul computer) |

Le **Impostazioni** (dal menu iniziale o con C) cambiano il volume di musica ed effetti e lo schermo intero; dal
menu iniziale c'è anche "Dimentica le partite" (la memoria di Nives). Si salvano in `user://impostazioni.cfg`.
Nel menu iniziale ci sono anche i **Comandi** (i tasti disegnati; non sul telefono) e i **Crediti**.
I tasti disegnati vengono dal pacchetto *gdb-gamepad-2* (cartella `ui` accanto al progetto) e non sono nel
repository: `python tools/make_tasti.py "<cartella>/gdb-keyboard-2.png"` crea `assets/ui/tasti.png`.
Senza, la pagina disegna dei tasti semplici con la scritta.

## Comandi touch (telefono)

Joystick a sinistra per muoversi; a destra **OK** (parlare, confermare), **X** (correre, saltare il testo) e **C** (stato e oggetti). Nei dialoghi basta toccare lo schermo; nei menu si toccano direttamente le voci. I comandi compaiono solo quando servono.

Per provarli sul PC: avvia il gioco con l'argomento `-- --touch`.

## Esportare per Android

1. In Godot: **Editor → Gestisci modelli di esportazione → Scarica e installa** (versione 4.6.3).
2. Installa [Android Studio](https://developer.android.com/studio) (serve per l'Android SDK) e un JDK 17.
3. In **Editor → Impostazioni dell'editor → Esporta → Android** indica la cartella dell'Android SDK e quella del JDK.
4. **Progetto → Esporta… → Android → Esporta progetto**: il file viene creato in `build/Cheap.apk`.
5. Per provare subito sul telefono: attiva il *debug USB* sul telefono, collegalo al PC e premi l'icona Android in alto a destra nell'editor.

Il profilo di esportazione è già pronto in `export_presets.cfg` (nome pacchetto `com.lindascrub.cheap`).

## Test automatico

Il test gioca da solo tutti i piani, dal Fondo alla Cima, fino ai finali:

```powershell
Godot_v4.6.3-stable_win64_console.exe --headless --path . res://tests/smoke_test.tscn
```

Alla fine stampa `SMOKE TEST OK` oppure l'elenco dei problemi.

La memoria di Nives (i finali delle partite concluse, [docs/NIVES_MEMORIA.md](docs/NIVES_MEMORIA.md)) ha un test suo,
che usa una memoria di prova e non tocca quella vera:

```powershell
Godot_v4.6.3-stable_win64_console.exe --headless --path . res://tests/nives_memoria_test.tscn
```

## Modificare i testi

I dialoghi delle persone sono in `data/npcs.json`, i turni di lavoro in `data/worklist.json`. Si possono cambiare senza toccare il codice. Quando esporti il gioco, aggiungi `*.json` ai "filtri per esportare file non-risorsa" nelle impostazioni di esportazione.

## Crediti

Gli stessi del gioco (voce **Crediti** del menu e titoli di coda), scritti in `data/crediti.json`.

- Grafica: [LimeZu](https://limezu.itch.io/) (Modern Interiors, Modern Exteriors, Character Generator);
  [Emanuelle](https://emanuelledev.itch.io/farm-rpg) (Tiny Farm RPG, i prodotti del mercato);
  [greatdocbrown](https://greatdocbrown.itch.io/gamepad-ui) (Gamepad UI, i tasti della pagina Comandi).
- Musica: [The Bishop](https://itsthebishop.itch.io/freeloopablemusic) (Free Loopable Music, CC0);
  [HydroGene](https://hydrogene.itch.io/high-quality-16-bit-music) (28 High Quality 16-bit RPG Music);
  [Abstraction](https://abstractionmusic.com/) ([Music Loop Bundle](https://tallbeard.itch.io/music-loop-bundle), CC0),
  con *Jester's Distraction* di Dani Maccari.
- Caratteri: [Pixeloid Sans](https://ggbot.net/fonts/) di GGBotNet (`fonts/OFL-Pixeloid.txt`) e
  [Silkscreen](https://github.com/googlefonts/silkscreen) (`fonts/OFL-Silkscreen.txt`), licenza SIL Open Font License.
- Effetti sonori (e le musiche di riserva): generati da `tools/make_audio.py`.
- Motore: [Godot Engine](https://godotengine.org/), licenza MIT.
