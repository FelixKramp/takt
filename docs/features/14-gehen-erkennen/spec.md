---
feature: 14-gehen-erkennen
freigegeben: offen (Entwurf, wartet auf Felix)
---
# Spec: Gehen und Spaziergänge automatisch erkennen

## Nutzer und Nutzen
Felix fragte, ob Takt Spaziergänge automatisch als Aktivität erkennt. Bisher nicht: Die
Workout-Erkennung aus `openstrap_analytics` (`autoDetectWorkouts`) schlägt nur Bouts vor, die
mindestens 12 Minuten bei ≥ 45 % der Herzfrequenzreserve liegen. Ein Spaziergang mit Puls um
90–110 liegt darunter und wird nie gefunden. Ziel: Längeres Gehen erscheint wie jedes erkannte
Training auf Heute, mit der Sportart „Walking“.

## Regel
Quelle ist der Schrittzähler des Bands (Gen5, ein kumulativer Zählerstand pro Sekunde in
`decoded_onehz.step_count`, im Substrat `stepCount`). Die Handy-Schritte taugen nicht: Sie liegen
nur als Stundensummen vor, ein 15-Minuten-Gang lässt sich darin nicht verorten.

- Eine Minute zählt als **Gehen** ab **80 Schritten**.
- **Pausen bis 2 Minuten** werden überbrückt (Ampel, kurz stehen bleiben).
- Ein **Gang zählt ab 15 Minuten**, gemessen von der ersten bis zur letzten Gehminute.
- **Gesperrt** sind Minuten in gespeicherten Trainings und in Bouts, die die Puls-Erkennung im
  selben Lauf gefunden hat. Sie unterbrechen einen Gang und werden nicht überbrückt. Schlaf
  sperrt `ActivityStore.reconcile` ohnehin.
- Zählerstände mit mehr als 10 s Abstand werden nicht verrechnet, Sprünge über 50 Schritte pro
  Sekunde gelten als Zählerreset. Überlauf bei 65536 wird mitgerechnet.

### Warum 80 und nicht 90 Schritte/Minute
Geprüft an vier Tagen echter Banddaten von Felix: Gleichmäßige Gehminuten liegen bei 96–145
Schritten, einzelne Minuten mitten im Gang aber bei 75–89 (Abbiegen, Tür, langsamer werden).
Mit 90 als Minutenschwelle zerfällt ein Gang an solchen Minuten, und ein gemütlicher
Spaziergang liegt oft unter 100. Unter 80 bleibt Herumlaufen in der Wohnung, das in den Daten
nie mehrere Minuten am Stück erreicht. Die 15 Minuten trennen Wege von Spaziergängen: In den
vier Tagen gab es nur Wege von 8–10 Minuten und keinen einzigen Fehlalarm.

## Akzeptanzkriterien
- **W1** – Ausgangslage: 20 Minuten mit 100 Schritten/Minute · Ergebnis: ein Gang über genau
  diese 20 Minuten, Sportart `walking`, Schritte und Ø-Puls in den Details.
- **W2** – Spaziergang mit 85 Schritten/Minute und Puls um 100 wird erkannt (die
  Puls-Erkennung findet ihn nicht).
- **W3** – 14 Minuten Gehen sind kein Gang, 15 Minuten sind einer.
- **W4** – 2 Minuten Pause werden überbrückt, 3 Minuten trennen.
- **W5** – Unter 80 Schritten/Minute entsteht kein Gang, egal wie lange.
- **W6** – Ein gespeichertes Training sperrt seine Minuten. Der Heimweg danach bleibt ein Gang,
  wenn er allein 15 Minuten lang ist.
- **W7** – Zählerüberlauf bei 65536 verfälscht die Schrittzahl nicht.
- **W8** – Datenlücken und Zählerresets erfinden keine Schritte.
- **W9** – Ein Band ohne Schrittzähler (Gen4, Wert -1) liefert keine Gänge.
- **W10** – Der Vorschlag landet über `ActivityStore.reconcile(ActivityKind.workout, …)` in
  derselben Liste wie erkannte Trainings, `sport: walking` passt auf „Walking“ im Katalog.
- **W11** – Auf dem Pixel erscheint nach einem echten Spaziergang (≥ 15 Minuten) ein Vorschlag
  „Walking“ auf Heute. *Noch offen: In den vorhandenen Daten gibt es keinen solchen Gang.*

## Verhalten danach
Wie jedes erkannte Training: Der Vorschlag steht auf Heute und wird nach `auto_confirm.dart`
30 Minuten nach dem Ende ohne Rückfrage gespeichert. Die Sportart lässt sich wie gewohnt ändern.

## Umsetzung
- `lib/takt/walk/walk_detect.dart`: `detectWalks` (rein) und `walkSuggestionRows`.
- `lib/compute/derivation_engine.dart`, `_computeWorkouts`: hängt die Gänge an die
  Vorschlagsliste an (TAKT-Kommentar). Das Upstream-Paket bleibt unverändert.
- Tests: `test/takt/walk_detect_test.dart` (synthetische Daten).

## Nicht im Umfang
- Laufen, Radfahren oder Wandern unterscheiden. Ein Lauf mit hohem Puls findet weiter die
  Puls-Erkennung, deren Bouts sind hier gesperrt.
- Gänge nur aus Handy-Schritten (Stundensummen sind zu grob).
- Bereits gerechnete vergangene Tage neu rechnen: Gänge erscheinen ab der nächsten Rechnung
  eines Tages.
