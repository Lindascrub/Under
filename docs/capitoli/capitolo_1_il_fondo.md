# Capitolo 1 — Il Fondo (piano -5)

**Durata:** 10-15 minuti. **Obiettivo:** prendere il badge del piano -4.
**Tono:** ironico ma che fa male. **Stile:** colorato e finto, poi la verità.

## L'idea in una frase

Il Fondo sembra il posto più felice della torre: colori da asilo, poster che sorridono, musichetta.
Poi fai il tuo primo turno e scopri che quei colori li accendi tu, con la tua fatica. Se ti fermi, si spengono.

## La regola dei colori

- Le **persone vere**, quelle che contano, sono **grigie**. Fermo ha intorno un alone scuro e sfumato.
- Le **cose finte** (il lavoro, le macchine, la festa, Nives dello sportello) sono **colorate**.
- Chi lavora resta colorato **solo finché lavora**: "Scusa, non posso parlare. Devo mantenere il mio colore."

## I personaggi

| Chi | Com'è | Il suo aiuto (minigioco) |
|---|---|---|
| **Fermo** | L'unico grigio, con l'alone scuro. Undici anni al Fondo. Spiega le regole e la scritta TURNO. | — (è lui la "vittima" della prima promozione: il suo quaderno di idee) |
| **Bulbo** | Ragazza di 19 anni, sorride troppo, smista lampadine. Accanto ha le scatole di lampadine. | **Lampadine**: buona a DESTRA, rotta a SINISTRA, quella che sfarfalla si avvita con SU o GIÙ |
| **Mina** | Vecchio elettricista, scherza su tutto. Accanto ha i cavi aggrovigliati. | **Fili**: collega i fili dello stesso colore, come in Among Us |

Nives, l'addetta ai badge, è colorata (fa parte del sistema): si presenta solo se aiuti tutti.

## La storia, passo per passo

1. **L'ascensore.** Musichetta allegra, voce registrata: "Benvenuto nella Torre CHEAP! Il futuro costa poco!". Niente più scritta del debito sul display.
2. **Arrivo al Fondo: la festa.** Le porte si aprono su festoni, palloncini, coriandoli, una torta "AUGURI ALLA CHEAP".
3. **Lo schianto.** Dietro di te l'ascensore crolla: rumore, scossa, porte piegate, luce spenta. La musica della festa non si ferma.
4. **Fermo.** Spiega: lavoro, badge (500 € il primo, poi ogni piano il doppio: 1.000, 2.000, 4.000, 8.000), la scritta TURNO, le stelline per far passare la notte.
5. **Bulbo e Mina.** Ti chiedono una mano (i due minigiochi). Dal secondo dialogo: "devo mantenere il mio colore".
6. **Il primo turno: la cyclette.** Il gioco della lancetta: si tocca lo schermo a sinistra e a destra, alternando, per restare nel verde.
7. **La telefonata del capo.** Ti propone di prenderti il merito del **quaderno di Fermo**: un, due, tre, stella. Tieni il dito sullo schermo per avvicinarti mentre ti dà le spalle, e ancora per copiare; quando si gira, stacchi il dito. Se ti vede muovere, ti rimanda indietro. Tempo limite visibile. Se lo fai, Fermo sorride come i poster.
8. **La rivelazione, sul primo gradino.** Col badge, appena metti il piede sulle scale la festa si spegne: palloncini sgonfi, festoni caduti, tutto grigio tranne le cose finte (cyclette, sportello). Il grigio è malinconico (hai aiutato), grottesco (hai rubato) o neutro (hai solo lavorato). Nessuna domanda: decidi coi piedi.
   - Se ti volti e parli con Fermo, Bulbo o Mina, ti dicono la verità sui colori.
   - Se sali senza aver ascoltato nessuno, le scale dietro di te si chiudono (coni e nastro VIETATO, al piano -4): non si torna più giù.
9. **Lo straordinario.** Dopo la rivelazione la cyclette resta accesa: puoi pedalare ancora, al massimo tre volte. Ogni volta è più difficile e paga meno (120, 70, 35 €), ma per cinque secondi la festa si riaccende, poi si rispegne.
10. **Lo sguardo indietro (fine del capitolo).** In cima alle scale la telecamera scende sul Fondo com'è diventato, con Fermo laggiù, e compare una sola frase che dipende dalle tue scelte (quaderno rubato, scale sbarrate, tre straordinari, tutte le verità, chi hai aiutato). Poi buio e il titolo "Capitolo 2 — Il Sottoufficio".

## La mappa (35x14 caselle): due stanze sullo stesso piano

Come nelle mappe di esempio di LimeZu, col bordo bianco e i separatori pieni tra le stanze (`world/room_outline.gd`).
La scena si genera con `tools/bake_c1_fondo.gd` (la mappa è scritta in `ROWS`).

| Stanza | Dove | Cosa c'è |
|---|---|---|
| La festa | a sinistra (1-22, 3-12), pavimento a piastrelle colorate | l'ascensore (11,1), Fermo sulla cassetta (14,4), la cyclette della palestra LimeZu col TURNO (3-4,6), Bulbo coi cavi, Mina con le scatole di lampadine, il tavolo con la torta e i regali, i palloncini, la stellina (5,11) |
| L'ufficio badge | a destra (24-33, 3-12), porta a (23, 9-10) | lo sportello dei badge (26,3), la bacheca coi prezzi (28,2), le sedie d'attesa (25-28, 8), il divano, le scale per il -4 (31,3); chi scende dal -4 arriva a (31,5) |

## Comandi: tutto col dito

Il gioco è per telefono. Nel mondo ci sono joystick e pulsanti; nei minigiochi no, si gioca direttamente sullo schermo:
- cyclette e magazzino: tocca la metà sinistra o destra;
- lampadine: scorri a destra (buona), a sinistra (rotta), su e giù (avvita quella che sfarfalla);
- fili: tocca un filo a sinistra, poi il suo posto a destra;
- un, due, tre, stella: tieni il dito giù, staccalo quando si gira;
- gli altri: tocca il telefono che squilla, trascina spugna, barra e racchetta, scorri per Snake e Tetris.
Le istruzioni dicono "tocca", non "premi". Su PC restano anche i tasti.

In alto resta la barra con piano, ora, debito ("7,00 mld €") e soldi. Quello che non si deve mai vedere è il fuori-mappa: la telecamera resta sempre dentro i muri della stanza, anche ai bordi.

## Cosa resta del gioco attuale

- Asset LimeZu, Fermo, i badge, le scale a piedi, il Breakout, il furto di merito, Nives, l'autostima.
- La stanza verrà rifatta come **scena vera di Godot** (pavimenti, muri e oggetti come nodi), modificabile anche nell'editor.

## Da decidere più avanti

- Musica dell'ascensore e del Fondo colorato.
