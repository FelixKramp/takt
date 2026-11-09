---
feature: 10-koerperalter
freigegeben: offen (Entwurf, Felix: „erstmal nur planen“)
---
# Spec-Entwurf: Körperalter

## Nutzer und Nutzen
Felix will eine Zahl wie „WHOOP Age“: ein geschätztes Alter des Körpers aus dem eigenen Alltag.
Wichtiger als die Zahl ist, welche Gewohnheit wie viele Jahre ausmacht. Daraus wird ein
konkreter Hebel, zum Beispiel „Schlaf regelmäßiger: −1,2 Jahre“. Eigener Name, nicht WHOOPs.

## Kernablauf
Aus den letzten 30 Tagen bekommt jeder Faktor einen Wert. Jeder Wert wird über eine
Langzeitstudie in ein relatives Sterberisiko übersetzt. Das Risiko wird in Jahre umgerechnet:
Das Sterberisiko verdoppelt sich etwa alle 8 Lebensjahre, also Jahre = ln(Risiko) / ln 2 × 8.
Die Summe der Jahre plus das echte Alter ergibt das Körperalter. Neu berechnet wird einmal pro
Woche.

## Faktoren (MVP, nur was Takt schon misst)
| Faktor | Messgröße (30 Tage) | Takt hat es aus |
|---|---|---|
| Schlafdauer | Ø Stunden pro Nacht | Schlaf |
| Schlafregelmäßigkeit | Streuung von Einschlaf- und Aufwachzeit | Schlafscore, Teil Regelmäßigkeit |
| Ruhepuls | Ø bpm | Ruhepuls |
| Schritte | Ø pro Tag | Schritte |
| Moderate Bewegung | Minuten pro Woche in Zone 1–3 | Herzfrequenzzonen |
| Intensive Bewegung | Minuten pro Woche in Zone 4–5 | Herzfrequenzzonen |
| Krafttraining | Minuten pro Woche | Trainings mit Sportart Kraft |

Bewusst nicht im MVP: VO2max (Takt schätzt sie nur aus GPS-Läufen, bei Felix fast nie) und
Muskelmasse (keine Waage).

## Akzeptanzkriterien (Entwurf)
- **K1** – Zahl: Ausgangslage: Alter im Profil, mindestens 14 Tage Daten · Handlung: Karte
  öffnen · Ergebnis: Körperalter mit einer Nachkommastelle und die Abweichung zum echten Alter
  („−2,3 Jahre“).
- **K2** – Faktoren: Jeder Faktor steht mit Messwert, Zielbereich und seinem Beitrag in Jahren.
  Sortiert ist nach dem größten Hebel.
- **K3** – Herleitung: Antippen eines Faktors zeigt die Studie, die Umrechnung und was ihn um
  ein Jahr verschiebt.
- **K4** – Zu wenig Daten: Unter 14 Tagen erscheint „noch X Tage“ statt einer Zahl. Ein
  fehlender Faktor zählt mit 0 Jahren und ist als „fehlt“ markiert.
- **K5** – Woche: Die Zahl ändert sich nur montags. Daneben steht der Vergleich zur
  Vorwoche.
- **K6** – Displaystreifen: Keine Ziffer liegt auf dem Streifen.

## Randfälle
- Kein Alter im Profil: Hinweis mit Weg zum Profil.
- Jeder Faktor wird auf ±3 Jahre begrenzt, die Summe auf ±10. Sonst springt die Zahl bei
  Ausreißern, etwa einer krank im Bett verbrachten Woche.
- Importierte WHOOP-Tage zählen mit bei Schlaf, Zonen und Training. Bei diesen Faktoren gibt es
  kein Methodenproblem wie bei der Erholung.

## Nicht-Ziele
- Kein medizinischer Befund, keine Lebenserwartung.
- Kein „Tempo des Alterns“ im MVP.
- Keine Benachrichtigungen.

## Offene Thesen für Felix
1. Platz: im Profil oder unter „Mehr“, nicht auf Heute. Die Zahl ändert sich wöchentlich, und
   Heute ist schon voll.
2. 30 Tage statt WHOOPs 6 Monate, weil das Band erst kurz läuft.
3. Bei 18 Jahren stammen die Studien fast alle von Erwachsenen ab etwa 40. Die Jahre sind
   deshalb eher eine Richtung als ein Messwert. Nützlich ist die Aufteilung nach Faktoren.

## Belege
In der Architekturphase sind die Risikowerte je Faktor mit Quelle festzuhalten. Kandidaten:
- Schritte: Paluch 2022, Lancet Public Health
- Bewegungsminuten: Lee 2022, Circulation
- Krafttraining: Momma 2022, BJSM
- Schlafregelmäßigkeit: Windred 2024, Sleep
- Schlafdauer: Cappuccio 2010, Sleep
- Ruhepuls: Jensen 2013, Heart

Keine Zahl ohne Quelle.
