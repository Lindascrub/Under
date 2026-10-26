# Grafica personalizzata CHEAP — aggiornamento Codex

Sono stati sostituiti i 100 PNG personalizzati, senza intervenire su mappe, dialoghi,
progressione, salvataggi, scene o sprite LimeZu acquistati.

| Cartella | PNG aggiornati |
|---|---:|
| art/ (Fondo, Sottoufficio, Mercato e grafica comune) | 42 |
| art/c4/ (Banca) | 12 |
| art/c5/ (Città) | 30 |
| art/c6/ (Cima) | 16 |
| Totale | 100 |

## Produzione

36 asset finali usano immagini create con il generatore integrato ImageGen e
esportate al formato nativo. 64 elementi usano sorgenti pixel nativi: insegne con
testi esatti, icone, micro-oggetti, fogli animati, mappa, cielo, tornello e scatola
delle lampadine. Sono stati scartati i prototipi generati meno leggibili nel formato piccolo.
Non è stata usata la modalità API/CLI di ImageGen e non occorre una chiave API.

I riferimenti generati a grande risoluzione e il set di prompt sono conservati nella
consegna `cheap_asset_refresh`; il gioco carica esclusivamente i PNG finali di `art/`.
La normalizzazione conserva le misure dei file: alpha trasparente esterno, palette
ridotta senza dithering, piedi appoggiati alla base. La vetrina mantiene alpha parziale.

`tools/make_art_codex.py` contiene le definizioni native, la tipografia Pixelify
senza antialiasing e l'esportazione. L'esecuzione richiede Python con Pillow e gli
argomenti `--out`, `--generated` e `--inventory`: i due ultimi JSON sono nella consegna.
Non disegna negli asset LimeZu e non modifica il codice di gioco.

`art/.codex_assets.json` identifica i file definitivi. I generatori precedenti di
Fondo, Mercato, Banca, Città e Cima usano `tools/asset_guard.py`: se un PNG definitivo
esiste, viene conservato. Per rigenerare volutamente i vecchi segnaposto si può
impostare `CHEAP_ALLOW_PLACEHOLDERS=1`; questa opzione non serve per usare il nuovo set.

## Compatibilità verificata

- 100 file presenti, tutti diversi dagli originali, con dimensioni originali esatte e RGBA valido.
- Fogli invariati: stellina 2×13×13, piccione 2×10×8, emote 4×11×10, lampadine 3×10×10.
- Tutti i fotogrammi previsti contengono pixel visibili.
- Hash del pacchetto acquistato confrontati prima/dopo: invariati.
- Importazione Godot e caricamento di tutte le 100 texture: nessun errore.
- Controllo delle scene di Fondo, Sottoufficio, Mercato, Banca, Città, Casa Comune e Cima.
- I cinque generatori precedenti sono stati rieseguiti: nessun PNG definitivo alterato.

Le verifiche del motore sono state eseguite su una copia di controllo del progetto,
con lo stesso codice e i nuovi PNG; nessun salvataggio della partita principale è stato usato.
Non costituiscono una nuova prova completa della storia o una nuova esportazione Android.

## Uso e ripristino

Aprire il progetto in Godot e lasciare terminare la normale reimportazione dei PNG.
Le scene continuano a usare i percorsi precedenti. Un'APK già esportata richiede
la normale nuova esportazione per includere le immagini aggiornate.

La consegna conserva `originali/`, `rifatti/`, i relativi ZIP, il manifest con hash,
il set di prompt e le catture reali delle scene. Per un ripristino grafico basta
ricopiare i PNG di `originali/` dentro `art/`, mantenendo le sottocartelle.
