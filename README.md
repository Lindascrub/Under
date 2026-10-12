# CHEAP

Un piccolo RPG narrativo in stile Undertale, fatto con Godot 4.

Inizi con un debito di 48.000 €. Ogni giorno scegli come guadagnare: firmare qualcosa che rovina una persona (facile, pagato tantissimo) oppure spaccarti la schiena (difficile, pagato pochissimo). Le persone che sfrutti spariscono, sostituite da robot con la loro faccia. Te ne accorgi solo alla fine.

Tre finali: **ricco**, **onesto**, **ribelle**. Design completo in [docs/GDD.md](docs/GDD.md).

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
| C | Stato (debito, soldi, tempo libero) |

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
