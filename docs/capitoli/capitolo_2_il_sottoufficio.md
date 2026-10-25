# Capitolo 2 — Il Sottoufficio (piano -4)

**Durata:** 10-15 minuti. **Obiettivo:** il badge del Mercato (-3), che costa 1.000 €.
**Tema:** la burocrazia infinita. **Stile:** ufficio anni '80 finto allegro.

## L'idea in una frase

Al -4 tutto sorride: moquette arancione, carta da parati a righe, piante di plastica, poster ("SORRIDI! È GRATIS",
"UN MODULO AL GIORNO TOGLIE IL PENSIERO", "RESTI IN LINEA!") e una musichetta d'attesa che non si ferma mai.
Per il badge serve il Modulo B-4, e il B-4 gira in tondo. Se ne esce solo insieme alle due persone vere del piano.

## La regola dei colori

Come al Fondo: le persone vere sono **grigie** (Tilde ed Ercole), il sistema è **colorato** (la Signora Agenda,
i colleghi al telefono, l'addetta ai badge, il tritacarte).

## I personaggi

| Chi | Com'è | Il suo aiuto (minigioco) |
|---|---|---|
| **Signora Agenda** | Allo sportello B-4, al centro. Sorride più di tutti. Dà il B-4 e spiega il giro. | — |
| **Tilde** | Dodici anni di call center, grigia, col telefono in mano. Dice "resti in linea" anche a sua madre. | **Il copione di Tilde**: ripeti la sequenza di frecce |
| **Ercole** | Custode dell'archivio, grigio, sempre mezzo addormentato. Custodisce cartelline vuote. | **Tieni sveglio Ercole**: tocca quando il segno è nel verde |
| I colleghi | Quattro, colorati, al telefono. Sorridono senza guardarti. | — |

Tilde è anche la "vittima" della promozione del capo: il suo copione scritto a mano.

## La storia, passo per passo

1. **Arrivo.** Si sale dal Fondo (o dalle scale sbarrate, se al Fondo non ti sei voltato). Musichetta, sorrisi, due persone grigie.
2. **Il Modulo B-4.** L'Agenda te lo dà: lo firma l'archivio, lo timbra il responsabile. Ma l'archivio firma solo moduli
   timbrati e il responsabile timbra solo moduli firmati. Lo sportello dei badge non vende senza B-4 timbrato.
3. **Il lavoro: il call center.** Squilla un telefono: lo tocchi, leggi il cliente, tocchi una risposta.
   - **Copione**: paga (conta per il turno).
   - **Sincera**: non paga, ma alla fine del turno ti resta (autostima +1, massimo +2).
   - **Sgarbata**: è un errore. Se non rispondi in tempo, il cliente riattacca.
   I clienti diventano più cattivi man mano che il turno va avanti.
4. **Ercole.** Dopo che l'hai tenuto sveglio, firma il B-4 anche senza timbro ("l'archivio sono io") e ti manda da Tilde:
   il responsabile non l'ha mai visto nessuno, c'è solo una voce al telefono.
5. **Tilde.** Dopo che l'hai aiutata col copione, chiama l'Agenda imitando la voce del responsabile: "timbri il B-4".
   La prima frase inventata da lei in dodici anni.
6. **Il timbro e il badge.** L'Agenda timbra (e il B-4 "lo tiene lei, agli atti"). Ora il badge si compra.
   - Scorciatoia: la **procedura d'urgenza**, 300 €, e il B-4 è timbrato subito.
   - Se hai aiutato tutti, Nives ti regala il badge, ma solo col B-4 a posto: anche l'amicizia ha bisogno di un modulo.
7. **La rivelazione, sul primo gradino.** La musichetta si interrompe a metà di una nota. Silenzio, neon, e il tritacarte:
   l'Agenda ci infila il tuo B-4, sorridendo. I colleghi restano con la cornetta in mano. Poi la musica riparte, più lenta.
   Tilde ed Ercole, se ci parli, ti dicono la verità (i moduli finiscono tutti nel tritacarte; l'archivio è vuoto).
8. **Lo sguardo indietro.** In cima alle scale, una frase sola: copione rubato, urgenza pagata, uscita con Tilde ed Ercole,
   le due verità, oppure l'Agenda che sorride. Poi "Capitolo 3 — Il Mercato".

## La musica

"Attesa": una bossa nova da centralino, sempre accesa. Si ferma una volta sola, sulla rivelazione, e riparte più lenta.

## La scena

`chapters/c2/sottoufficio.tscn` (fatta una volta con `tools/bake_c2_sottoufficio.gd`, poi si modifica nell'editor);
la logica è in `chapters/c2/sottoufficio_c2.gd`. In alto lo sportello B-4 col tritacarte, a destra lo sportello dei badge
e le scale per il -3; a sinistra il call center con Tilde; in basso a destra l'archivio con Ercole; in basso a sinistra
le scale per il Fondo.
