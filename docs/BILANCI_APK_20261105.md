# Bilanci e APK — 5 novembre 2026

## Accesso ai bilanci

Il problema segnalato dal precedente test delle schermate era legato alla fase della storia: il dialogo veniva provato quando l'archivio era ancora chiuso. La verifica dedicata parte dal punto d'ingresso della Casa Comune e usa la fisica e i comandi di movimento del giocatore. Non teletrasporta il personaggio e non chiama `_bilanci()` direttamente.

`tests/bilanci_accesso_test.tscn`: **32 controlli OK**, sia headless sia con finestra fuori schermo e immagini.

- Prima della protesta: nessun percorso attraverso la porta chiusa.
- Dopo la protesta: percorso dall'ingresso al terminale, selezione dell'oggetto giusto, apertura del rapporto con il comando di interazione e ritorno al movimento.
- Dopo l'assemblea, con gestione comunitaria: stesso percorso e interazione.
- Le tre condizioni vengono provate con azioni di movimento PC simulate e con eventi touch sul joystick e sul pulsante OK. Il gesto finale verso il terminale determina anche l'orientamento.

Non sono state necessarie modifiche a muri, oggetti, collisioni o storia. Le immagini sono in `reports/bilanci_*_pc.png` e `reports/bilanci_*_tel.png`; log conclusivo `reports/bilanci_accesso_schermate_finali.log`. Il salvataggio è isolato in `user://bilanci_accesso_test.json`.

## APK aggiornata

- File datato: `build/Cheap_5novembre.apk`.
- Copia corrente identica: `build/Cheap.apk`, con il relativo `.idsig` aggiornato.
- Dimensione: 154.701.575 byte, circa 148 MiB.
- Identificativo: `com.lindascrub.cheap`; versione 0.3, codice 3; architettura ARM64.
- Build di debug per le prove, con la stessa firma Android della build precedente. Non è una pubblicazione su uno store.
- SHA-256: `2288a2a83d94f7898da71ac19b053d635fdf72ab515c00b4801033791bce7d3d`.

Verificati firma con `apksigner`, integrità ZIP, manifest identico alla build precedente e presenza delle nuove configurazioni di Amir, Olga, Teo e Ada. Il preset esclude test, report, backup, strumenti e addon dell'editor. L'avvio del menu e il caricamento delle scene sono stati verificati con Godot sulle risorse estratte dall'APK: non è un'installazione o una prova su telefono fisico.

La vecchia APK e la sua firma associata sono conservate in `scene_backup/bilanci_apk_20261105/build/`. Nessun salvataggio della partita è stato cancellato o sostituito.

Esportazione con Godot 4.6.3 e gli strumenti Android già installati. Il manifest usa SDK 36; Godot segnala l'uso dei build tools 35.0.0 disponibili. Firma e verifica dell'esportatore terminano correttamente. `aapt2` segnala il riferimento all'icona tematica del template; il manifest non è stato modificato rispetto all'APK precedente.

## Altri controlli

Ripassati `storia_test` (120 controlli), `touch_test`, `minigame_redesign_test` (12 verifiche) e `testi_dispositivo_test`: tutti con esito positivo. L'avvio delle risorse esportate termina senza problemi di caricamento. Restano gli avvisi ObjectDB/risorse all'uscita già documentati.

La prova del ritmo, della comprensione e del divertimento della partita completa, e quella su telefono vero, restano a Linda come richiesto.
