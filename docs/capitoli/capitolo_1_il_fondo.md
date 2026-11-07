# Capitolo 1 — Il Fondo (piano -5)

**Durata:** 10-15 minuti. **Obiettivo:** prendere il badge del piano -4.
**Tono:** ironico ma che fa male. **Stile:** colorato e finto, poi la verità.

## L'idea in una frase

Il Fondo sembra il posto più felice della torre: colori da asilo, poster che sorridono, musichetta.
Poi fai il tuo primo turno e scopri che quei colori li accendi tu, con la tua fatica. Se ti fermi, si spengono.

## La regola dei colori

- Le **persone vere**, quelle che contano, sono **grigie**. Fermo ha intorno un alone scuro e sfumato.
- La festa è colorata finché resta accesa. Alla rivelazione perdono colore anche Nives e lo sportello; la cyclette resta accesa e disponibile per lo straordinario.
- Chi lavora resta colorato **solo finché lavora**: "Scusa, non posso parlare. Devo mantenere il mio colore."

## I personaggi

| Chi | Com'è | Il suo aiuto (minigioco) |
|---|---|---|
| **Fermo** | L'unico grigio, con l'alone scuro. Undici anni al Fondo. Spiega le regole e la scritta TURNO. | Il Capo ti fa regolare il suo lavoro alla cyclette: ritmo, durata e pausa. Il quaderno rubato resta solo nei vecchi salvataggi. |
| **Bulbo** | Nonno anziano, sorride troppo, smista lampadine. Accanto ha le scatole di lampadine. | **Lampadine**: buona a DESTRA, rotta a SINISTRA, quella che sfarfalla si avvita con SU o GIÙ |
| **Mina** | Un'elettricista, scherza su tutto. Accanto ha i cavi aggrovigliati. | **Fili**: collega i fili dello stesso colore, come in Among Us |

Nives, l'addetta ai badge, dà prima le informazioni per salire. Se aiuti tutti, ti regala il badge e si presenta: «Quando ripassi, puoi salutarmi anche senza comprare niente.»
La prima volta allo sportello dice il prezzo così: "Cinquecento euro." / "Per una porta?" / "Per quella dopo."
Il commento sulle addette uguali arriva al primo sportello successivo al Fondo: «Un'addetta per piano. Stessa faccia, prezzi diversi.»
Dopo un finale, alla partita nuova, ti riconosce: "Oh. Sei tornato." (docs/NIVES_MEMORIA.md).

## La storia, passo per passo

1. **La cucina e l'ascensore (testo di Linda, 5/11).** Prima la cucina sottosopra, il biglietto del padre e la lettera della CHEAP; poi l'ascensore, la voce registrata e il riconoscimento del debito di sette miliardi (il display mostra 7 MLD). Le porte incastrate lasciano intravedere le luci abbaglianti del Fondo.
2. **Arrivo al Fondo: la festa.** Le porte si aprono su festoni, palloncini, coriandoli, una torta "AUGURI ALLA CHEAP".
3. **Lo schianto.** Dietro di te l'ascensore crolla: rumore, scossa, porte piegate, luce spenta. La musica della festa non si ferma.
4. **Fermo (testo di Linda e revisione approvata, 5/11).** Primo dialogo lineare, con il nome scelto dal giocatore. Fermo ha iniziato con nove miliardi e ora ne deve undici. Spiega gli interessi, indica la cyclette e manda da Nives vicino alle scale per badge e prezzo. Sonno e salvataggio si spiegano alla prima stellina. Chiude con «Stavo pensando... e poi cosa faccio, con le mani?». Le vecchie scelte e spiegazioni del primo incontro sono sostituite.
5. **Bulbo e Mina.** Ti chiedono una mano (i due minigiochi). Bulbo indica le due scatole, con etichette BUONE/ROTTE e una ripresa che le tiene visibili sopra il dialogo. Mina scherza sulle scosse prima di iniziare il lavoro. La prima volta, fili e lampadine mostrano il gesto; poi lo provi senza consumare tempo né errori. I comandi cambiano fra PC e telefono. Dal secondo dialogo: "devo mantenere il mio colore".
6. **Il primo turno: la cyclette.** Il gioco della lancetta: si tocca lo schermo a sinistra e a destra, alternando, per restare nel verde.
7. **La telefonata del Capo: Ancora cinque minuti.** «Le chiedo solo di regolare una leva.» Fermo pedala: la leva regola il ritmo, il cartellino i minuti extra e il quadro le luci della festa. La pausa si vede sotto di lui; presa e cavo distinguono i servizi essenziali dalle decorazioni. La conferma mostra sforzo, pausa e premio prima di applicare la scelta. Se aumenti intensità o durata il Capo ti dà 600 €; puoi completare l'incarico al ritmo normale, senza minuti in più e senza premio. Tornando da Fermo puoi coprire il suo turno e restituirgli quindici minuti: la riparazione non cancella il torto. Il vecchio furto del quaderno e Fermo robot restano compatibili con i salvataggi precedenti, non sono l'incarico delle partite nuove.
8. **La rivelazione, sul primo gradino.** Col badge, appena metti il piede sulle scale la festa perde colore: palloncini sgonfi, festoni caduti, anche Nives e lo sportello grigi. La cyclette resta accesa. Il grigio è malinconico (hai aiutato), grottesco (hai sfruttato) o neutro (hai solo lavorato). Nessuna domanda: decidi coi piedi.
   - Se ti volti e parli con Fermo, Bulbo o Mina, ti dicono la verità sui colori.
   - Se sali senza aver ascoltato nessuno, le scale dietro di te si chiudono (coni e nastro VIETATO, al piano -4): non si torna più giù.
9. **Lo straordinario.** Dopo la rivelazione la cyclette resta accesa: puoi pedalare ancora, al massimo tre volte. Ogni volta è più difficile e paga meno (120, 70, 35 €), ma per cinque secondi la festa si riaccende, poi si rispegne.
10. **Lo sguardo indietro (fine del capitolo).** In cima alle scale la telecamera scende sul Fondo com'è diventato, con Fermo laggiù, e compare una sola frase. Priorità: Fermo robot nei vecchi salvataggi, scale sbarrate, torto della leva (pausa accorciata, ritmo aumentato o riparazione), tre straordinari, tutte le verità, chi hai aiutato. Senza incarico nuovo concluso non si attribuiscono scelte sulla leva. Poi buio e il titolo "Capitolo 2 — Il Sottoufficio".

## La mappa (35x14 caselle): due stanze sullo stesso piano

Come nelle mappe di esempio di LimeZu, col bordo bianco e i separatori pieni tra le stanze (`world/room_outline.gd`).
La scena si genera con `tools/bake_c1_fondo.gd` (la mappa è scritta in `ROWS`).

| Stanza | Dove | Cosa c'è |
|---|---|---|
| La festa | a sinistra (1-22, 3-12), pavimento a piastrelle colorate | l'ascensore (11,1), Fermo sulla cassetta (14,4), la cyclette della palestra LimeZu col TURNO (3-4,6), Mina coi cavi, Bulbo con le scatole di lampadine, il tavolo con la torta e i regali, i palloncini, la stellina (5,11) |
| L'ufficio badge | a destra (24-33, 3-12), porta a (23, 9-10) | lo sportello dei badge (26,3), la bacheca coi prezzi (28,2), le sedie d'attesa (25-28, 8), il divano, le scale per il -4 (31,3); chi scende dal -4 arriva a (31,5) |

## Comandi: tutto col dito

Il gioco è per telefono. Nel mondo ci sono joystick e pulsanti; nei minigiochi no, si gioca direttamente sullo schermo:
- cyclette: tocca la metà sinistra o destra;
- lampadine: scorri a destra (buona), a sinistra (rotta), su e giù (avvita quella che sfarfalla);
- fili: tocca un filo a sinistra, poi il suo posto a destra;
- un, due, tre, stella: tieni il dito giù, staccalo quando si gira;
Le istruzioni dicono "tocca", non "premi". Su PC restano anche i tasti.

In alto resta la barra con piano, ora, debito ("7,00 mld €") e soldi. Quello che non si deve mai vedere è il fuori-mappa: la telecamera resta sempre dentro i muri della stanza, anche ai bordi.

## Cosa resta del gioco attuale

- Asset LimeZu, Fermo, i badge, le scale a piedi, Nives, l'autostima; compatibilità con il vecchio furto di merito nei salvataggi precedenti.
- La stanza verrà rifatta come **scena vera di Godot** (pavimenti, muri e oggetti come nodi), modificabile anche nell'editor.

## Da decidere più avanti

- Musica dell'ascensore e del Fondo colorato.
