# Takt

Takt ist eine geänderte Fassung von OpenStrap Edge. Änderungen von Felix Kramp seit dem 6. November 2026, Details in der Git-Historie. Takt ist nicht mit OpenStrap verbunden.

Doto: SIL Open Font License, siehe `assets/fonts/Doto/OFL.txt`.

# Notice

Edge is an independent, open-source project (AGPL-3.0, see `LICENSE`; versions up to
commit 1140dac1 were MIT, see `NOTICE`). It
is not affiliated with, sponsored by, or endorsed by WHOOP, Inc. or any of its
trademarks.

No WHOOP source code, binaries, firmware, or copyrighted assets are included
in this repository.

## wger exercise data

`lib/ui2/activity/wger_exercises.g.dart` contains selected fields (names,
aliases, muscles, equipment, categories) from the [wger](https://wger.de)
exercise database, limited to the movements listed in
`tool/wger_weightlifting_selection.dart`. Each entry is available under
CC BY-SA 3.0, CC BY-SA 4.0 or CC0, and each row keeps its source UUID and the
author/license credits of its base data and translations. This data stays under
those licenses, separate from the AGPL-licensed code. Refresh with
`dart run tool/update_wger_exercises.dart`.
