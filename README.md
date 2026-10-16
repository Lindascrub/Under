# CHEAP

Un piccolo RPG narrativo in stile Undertale per Android (telefono in orizzontale), fatto con Godot 4.

Inizi dentro un ascensore che scende, con un debito di 6.000 €. Al piano -5 si rompe: è tutto buio, tranne la luce intorno a Fermo, che ti spiega come funziona. Si sale la torre un piano alla volta: lavori, compri il badge del piano di sopra (che scala dal debito) e passi il tornello delle scale. I giorni non sono contati, ma ogni notte il debito cresce. Al lavoro scegli se firmare qualcosa che rovina una persona (un'ora, pagato tantissimo) o fare un turno duro di 8 ore (una battaglia alla Undertale, pagata pochissimo). Per strada e al parco le persone ti "attaccano" coi loro problemi: puoi PROMUOVERLE (cioè sfruttarle, ma con un nome più elegante), PARLARE con loro o AIUTARLE. Aiutando le persone si sbloccano posti nuovi, come il Rifugio. Aiutare qualcuno fa partire un piccolo minigioco a sorpresa. Si salva toccando le stelline. Ci sono anche piccole missioni (trovare il gatto di Elsa, dare ripetizioni al figlio di Marta…) che rubano tempo. Le persone che sfrutti spariscono, sostituite da robot con la loro faccia. Te ne accorgi solo alla fine.

Tre strade, cioè tre sistemi economici: **capitalismo** (sfrutti e sali di LV), **comunismo** (resti un ingranaggio) e **baratto** (convinci le persone a smettere di lavorare: se sono abbastanza, il sistema crolla). Design completo in [docs/GDD.md](docs/GDD.md).

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
| C | Stato e oggetti (ore rimaste, energia, caffè di Nico) |

## Comandi touch (telefono)

Joystick a sinistra per muoversi; a destra **OK** (parlare, confermare), **X** (correre, saltare il testo) e **C** (stato e oggetti). Nei dialoghi basta toccare lo schermo; nelle battaglie si toccano direttamente i pulsanti e le voci dei menu. I comandi compaiono solo quando servono.

Per provarli sul PC: avvia il gioco con l'argomento `-- --touch`.

## Esportare per Android

1. In Godot: **Editor → Gestisci modelli di esportazione → Scarica e installa** (versione 4.6.3).
2. Installa [Android Studio](https://developer.android.com/studio) (serve per l'Android SDK) e un JDK 17.
3. In **Editor → Impostazioni dell'editor → Esporta → Android** indica la cartella dell'Android SDK e quella del JDK.
4. **Progetto → Esporta… → Android → Esporta progetto**: il file viene creato in `build/Cheap.apk`.
5. Per provare subito sul telefono: attiva il *debug USB* sul telefono, collegalo al PC e premi l'icona Android in alto a destra nell'editor.

Il profilo di esportazione è già pronto in `export_presets.cfg` (nome pacchetto `com.lindascrub.cheap`).

## Test automatico

Il test gioca da solo tutte le scene e i tre finali:

```powershell
Godot_v4.6.3-stable_win64_console.exe --headless --path . res://tests/smoke_test.tscn
```

Alla fine stampa `SMOKE TEST OK` oppure l'elenco dei problemi.

## Modificare i testi

I dialoghi delle persone sono in `data/npcs.json`, gli incarichi in `data/jobs.json`. Si possono cambiare senza toccare il codice. Quando esporti il gioco, aggiungi `*.json` ai "filtri per esportare file non-risorsa" nelle impostazioni di esportazione.

## Crediti

- Grafica: [LimeZu](https://limezu.itch.io/) (Modern Interiors, Modern Exteriors).
- Font: [Pixelify Sans](https://github.com/eifetx/Pixelify-Sans), licenza SIL Open Font License (`fonts/OFL.txt`).
- Musica ed effetti sonori: generati da `tools/make_audio.py`.
