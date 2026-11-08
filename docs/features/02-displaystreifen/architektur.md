---
feature: 02-displaystreifen
freigegeben: 2026-11-08 (mit der Spec, kleines Feature)
---
# Architektur: Displaystreifen

## Bestandteile
- `lib/takt/stripe/stripe.dart`
  - `TaktStripe`: die gespeicherte Position als Anteil der Bildschirmbreite (`ValueNotifier<double?>`, Schlüssel `takt.stripe_x` in den Prefs). `null` heißt aus.
  - `placeBlock(...)`: reine Funktion. Sie legt fest, wohin ein Wert mit Breite `w` in seinem Platz rückt, damit er den Streifen nicht berührt, und wie stark er schrumpft, wenn er auf keiner Seite passt.
  - `StripeDodge`: Hülle um eine Zahl oder Zeile. Ist der Streifen aus, reicht sie Layout und Zeichnen unverändert durch (B4).
    - Ist er an, rechnet sie beim Zeichnen die eigene Bildschirmposition aus. Im Modus `Block` verschiebt oder skaliert sie das Kind als Ganzes.
    - Im Modus `Zeile` teilt sie eine Textzeile an der Wortgrenze vor dem Streifen und setzt den Rest rechts daneben (B2, B3).
- `lib/takt/stripe/stripe_setup.dart`: Einstellscreen mit Linie, Schieberegler, Feinschritten, „Speichern" und „Entfernen" (B1).
- `lib/takt/about.dart`: Gruppe „Anzeige" mit der Zeile „Displaystreifen", eingehängt in die Einstellungen neben „Über diese App".
- Heute-Screen: Ringwerte, Ring-Unterzeile, Puls, Karten, Strain und Detailzeile der Aktivitäten sowie die Statuszeile laufen über `StripeDodge` (B2, B5).

## Entscheidungen
- **Verschieben beim Zeichnen statt beim Layout.** Die Bildschirmposition steht erst nach dem Layout fest. Würde das Layout neu gerechnet, flackert es einen Frame lang und kann pendeln. Beim Zeichnen ist die Position bekannt und das Layout bleibt stabil.
- **Kinder bleiben normale `Text`-Widgets.** Dadurch funktionieren `find.text`, Bedienungshilfen und die bestehenden Tests weiter.
- **Platz ohne Breitenvorgabe** (Strain in der Aktivitätszeile): Ist der Streifen an, reserviert die Hülle zusätzlich 36 Punkte (`kStripeReserve`), damit die Zahl ausweichen kann. Mehr nicht: Bei großer Schrift lief die Aktivitätszeile sonst über. Beim Puls ist die Reserve 0, er schrumpft notfalls (B3).
- Verworfen: den ganzen Bildschirm schmaler machen (verschenkt ein Drittel) und Zahlen pauschal links ausrichten (hilft nur für diesen einen Streifen).

## Daten
Eine Zahl in den lokalen Prefs. Sie wird nicht gesynct und nicht exportiert.
