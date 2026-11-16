# Fermo e suo fratello — implementato il 9 novembre 2026

La versione approvata da Linda è ora giocabile. Il sosia è il fratello gemello di Fermo.
«La festa continua» significa «Io sono ancora qui. Ti sto ancora aspettando».
Non è una copia robotica, un attore o un personaggio di un'altra partita.

## Percorso

1. Al Fondo, Fermo affida il messaggio: «Se lassù incontri qualcuno con la mia faccia, digli che qui sotto la festa continua. Lui capisce.» La vecchia battuta già ascoltata conta nei salvataggi precedenti.
2. In Banca il fratello aspetta nell’atrio, vicino alla sala d’attesa. Ha la stessa faccia di Fermo, vestiti colorati e un badge. Si può incontrare prima del messaggio: in quel caso, tornando da Fermo, lo si riceve senza dover comprare un altro badge.
3. Se il messaggio è conosciuto, si può consegnarlo o scegliere «Non adesso». Il fratello racconta l'arrivo insieme, la promessa «Vado a vedere come funziona lassù. Poi torno» e la vergogna che gli ha impedito di mantenere la parola. «Pensavo che ormai non volesse più vedermi.»
4. Con le scale aperte, il fratello cammina verso il Fondo. Il giocatore può tornare, parlare con Fermo e riferire la risposta: «Poteva almeno scendere a chiedermelo.» Il fratello raggiunge la cassetta a piedi e si siede accanto a lui.
5. Fermo: «Ci hai messo un po’. La torta è ancora quella.» Il fratello resta nel Fondo, con brevi dialoghi successivi; non compare contemporaneamente in Banca.
6. Se il messaggio è stato consegnato ma il giocatore prosegue senza tornare al Fondo, la visita viene mostrata nell'epilogo, in qualunque variante del finale. Se la riunione era già avvenuta, si vede invece che il fratello continua a tornare: la prima scena non si ripete.

## Varianti coerenti con il mondo

- **Scale sbarrate:** il fratello lascia la Banca e si ferma al Sottoufficio, davanti al blocco del Fondo. «Potevo tornare quando erano aperte.» Non attraversa lo sbarramento e non riapre il percorso al giocatore. Nell'epilogo torna alle scale durante la pausa, bussa e riceve una risposta da sotto; non si inventa la riunione accanto alla cassetta.
- **Fermo robot, nei vecchi salvataggi:** la visita resta possibile se le scale sono aperte. Il fratello si siede accanto a lui, ma la risposta è quella del robot. La sottotrama non lo guarisce e non usa la battuta della torta come se fosse umano.
- **Messaggio non consegnato:** nessuna riunione viene attribuita al giocatore nell'epilogo.

Il nome proprio e il mestiere specifico del fratello restano non definiti: il gioco lo chiama «Il fratello di Fermo».
Non si attribuiscono al fratello sfruttamenti o furti di merito mai raccontati.

## Implementazione

- `data/fratelli_fermo.json`: tutte le nuove battute, la scelta e i rami.
- `scripts/fratelli_fermo.gd`: consegna, risposta, ricongiungimento ed epiloghi.
- `world/fratello_fermo.tscn` / `.gd`: personaggio, collisione ai piedi, interazione, camminata e posa.
- `chapters/c1/fondo.tscn`: fratello, punti d'ingresso e seduta, inquadratura della coppia.
- `chapters/c4/banca.tscn`: primo incontro, cammino verso le scale e inquadratura dei dialoghi.
- `chapters/c2/sottoufficio.tscn`: il fratello compare soltanto dopo la consegna, se il Fondo è sbarrato.
- `chapters/c6/finale_c6.gd`: richiamo dopo il segmento del Fondo.

Punti spostabili nell'editor: `Mondo/FratelloFermo`, `Punti/FratelloIngresso`, `Punti/FratelloSeduto`,
`Punti/FratelloScale`, `Punti/FratelloScaleChiuse`, `Inquadrature/FratelliFermo` e `Inquadrature/FratelloFermo`.

Lo stato è in `GameState.flags.fratelli_fermo`: `met`, `message`, `delivered`, `answer`, `reunited`,
`robot_visit_seen`, `closed_epilogue_seen` e `visits`. Si salva con la partita; non entra nella memoria fra partite di Nives.

Nessuna modifica a debito, soldi, tempo, autostima, stelle, aiuti, requisiti dei badge o scelta del finale.
Il fratello non viene aggiunto al gruppo degli aiuti o al conteggio dei legami.

Verifica: `tests/fratelli_fermo_test.tscn` — 83 controlli; con `-- --solo-storia` esegue le 59 verifiche delle scene senza la ripetizione degli epiloghi.
