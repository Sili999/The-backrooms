# 🟡 SETUP — Das Spiel zum Laufen bringen (Schritt für Schritt)

Diese Anleitung ist bewusst einfach gehalten. Du brauchst **kein** Vorwissen.
Geschätzte Zeit: **~10 Minuten**.

---

## Schritt 1 — Godot herunterladen (einmalig)

1. Gehe auf **<https://godotengine.org/download>**.
2. Lade **Godot 4** (Version 4.2 oder neuer), Variante **„Godot Engine"** (Standard, **nicht** die .NET/C#-Variante).
3. Es ist eine **ZIP-Datei** — entpacken. Darin liegt eine einzelne ausführbare Datei
   (z. B. `Godot_v4.x-stable_win64.exe`). **Es gibt keine Installation** — Datei einfach starten.

> 💡 Godot ist kostenlos, Open Source und nur ~100 MB groß.

---

## Schritt 2 — Das Projekt öffnen

1. Starte Godot (Doppelklick auf die `.exe` aus Schritt 1).
2. Im Projekt-Manager oben auf **„Import"** klicken.
3. Navigiere in den Ordner dieses Projekts und wähle die Datei **`project.godot`** aus.
4. Auf **„Import & Edit"** klicken.

➡️ Der Godot-Editor öffnet sich mit dem geladenen Projekt.

---

## Schritt 3 — Das Spiel starten

- Drücke **`F5`** — oder klicke oben rechts auf den **▶ (Play)**-Button.
- Beim allerersten Mal fragt Godot ggf. nach der Hauptszene → wähle **`scenes/Main.tscn`**
  (sollte bereits voreingestellt sein, dann einfach bestätigen).

➡️ Ein Fenster öffnet sich: Startbildschirm **„THE BACKROOMS"**.

---

## Schritt 4 — Spielen

| Aktion | Taste |
|---|---|
| **Starten / Neustart** | `Enter` oder Mausklick |
| Bewegen | `W` `A` `S` `D` |
| Umsehen | Maus bewegen |
| Rennen | `Shift` gedrückt halten (verbraucht Ausdauer) |
| Pause | `Esc` |

**Ziel:** Überlebe so lange wie möglich. Halte Abstand zu der dunklen Gestalt,
die durch die Räume wandert — wenn sie dich erreicht, ist das Spiel vorbei.
Dein **Verstand** (rote Leiste) sinkt mit der Zeit und je näher die Bedrohung ist.

> 🖱️ Die Maus wird beim Spielen „gefangen". Mit **`Esc`** kommst du wieder heraus (Pause).

---

## Schritt 5 (optional) — Bessere Grafik & Sound einsetzen

Das Spiel enthält bereits **Platzhalter-Texturen und -Sounds**, sieht und klingt also
sofort nach Backrooms. Wenn du den Look auf ein höheres Niveau heben willst, ersetze die
Dateien im Ordner `assets/` durch hochwertige (CC0-)Assets.

➡️ Wie und wo: siehe **`docs/ASSETS.md`** (fertige Einkaufsliste mit Links).
Du musst dafür **nichts** am Code ändern — gleiche Dateinamen genügen.

---

## Schritt 6 (optional) — Eine fertige `.exe` erstellen

Wenn du das Spiel als **eigenständige Windows-Datei** weitergeben willst:

1. Im Godot-Editor: **`Editor → Manage Export Templates → Download and Install`**
   (lädt einmalig die Export-Vorlagen).
2. Dann: **`Project → Export…`**
3. **`Add… → Windows Desktop`** wählen.
4. Optional unten **„Embed PCK"** anhaken → es entsteht eine **einzige** `.exe`.
5. **`Export Project…`** → Speicherort + Dateiname (z. B. `TheBackrooms.exe`).

➡️ Fertig! Die `.exe` läuft auf jedem Windows-PC **ohne** Godot-Installation.

---

## ❓ Probleme?

| Problem | Lösung |
|---|---|
| „Projekt lässt sich nicht öffnen" | Stelle sicher, dass du **Godot 4** (nicht 3.x) verwendest. |
| Bildschirm ist sehr dunkel | Das ist gewollt (Atmosphäre). Die flackernden Deckenlampen sind die einzige Lichtquelle. |
| Maus lässt sich nicht bewegen | Die Maus ist „gefangen" — drücke `Esc` für die Pause. |
| Kein Ton | Platzhalter-Sounds liegen in `assets/audio/`. Prüfe deine System-Lautstärke. |
| „Export templates missing" | Schritt 6.1 ausführen (Export-Vorlagen herunterladen). |

Mehr technische Details findest du in **`docs/REALIZATION_PLAN.md`**.
