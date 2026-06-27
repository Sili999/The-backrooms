# The Backrooms — Level 0

Ein kurzes 3D-Horror-Spiel im Stil der **Backrooms**, gebaut mit **Godot 4** und **GDScript**.
Erkunde endlose, neblig-gelbe Räume mit flackernden Leuchtstoffröhren — und halte Abstand zu dem,
was dort mit dir wandert. Kein Kampf. Nur Flucht.

![Status](https://img.shields.io/badge/Status-MVP%20Pr%C3%A4totyp-yellow)

## Inhalt

- **➡️ `SETUP.md`** — **einfache Schritt-für-Schritt-Anleitung zum Starten** (hier anfangen!).
- **`docs/ASSETS.md`** — Asset-Einkaufsliste (Platzhalter ersetzen, mit Links).
- **`docs/BACKROOMS_GAME_DESIGN.md`** — Wissensdatei: alle Backrooms-Konzepte für Game-Designer.
- **`docs/REALIZATION_PLAN.md`** — Realisierungsplan: Tech-Stack, Assets, Asset-Selbstanalyse, `.exe`-Weg.
- **Lauffähiges Godot-4-Gerüst** (`scenes/`, `scripts/`) — Level-0-MVP mit Platzhalter-Assets.

## Features (MVP)

- First-Person-Controller mit Maus-Look, Sprint und **Ausdauer**
- **Prozedural endlose** Räume (Chunk-basiert, deterministisch geseedet)
- Atmosphäre: gelblicher Nebel, **flackernde Leuchtstoffröhren**, Glow/Bloom
- **Verstand-System** (Sanity) mit Tunnelblick-Vignette; **Almond Water**-Pickups stellen den
  Verstand wieder her (über die Räume verstreut, einfach hineinlaufen)
- **Geräusch-/Stealth-System**: umstoßbare Physik-Objekte und lautes Rennen erhöhen einen
  Geräuschpegel; übersteigt er die Schwelle, wird die Bedrohung **alarmiert** und durchsucht den
  Umkreis der Geräuschquelle. Schleichen hält dich leise.
- Eine **wandernde Bedrohung** mit Zuständen *Wandern → Untersuchen → Verfolgen* — Kontakt = Game Over
- Start-/Pause-/Tod-Menü

## Steuerung

| Aktion | Taste |
|---|---|
| Bewegen | `W` `A` `S` `D` / Pfeiltasten |
| Umsehen | Maus |
| Rennen (laut!) | `Shift` (verbraucht Ausdauer) |
| Schleichen (leise) | `Strg` oder `C` |
| Interagieren | `E` |
| Pause | `Esc` |
| Starten / Neustart | `Enter` oder Mausklick |

> ⚠️ **Lärm zieht die Bedrohung an.** Rennen ist schnell, aber laut; Schleichen ist langsam, aber
> fast lautlos. Pass auf, was du umstößt — die orange **GERÄUSCH**-Leiste warnt dich.

## Starten (Entwicklung)

1. **Godot 4.x** installieren: <https://godotengine.org>
2. Repo klonen und in Godot über *Import* die Datei `project.godot` öffnen.
3. ▶ (oben rechts) oder `F5` drücken — oder per CLI:
   ```bash
   godot project.godot
   ```

> Das Spiel startet auch **ohne** externe Assets (Platzhalter werden im Code erzeugt).
> Für den finalen Look siehe `assets/README.md` (CC0-Quellen).

## Als ausführbare Datei (`.exe`) exportieren

1. Im Editor: *Editor → Manage Export Templates → Download and Install*.
2. *Project → Export… → Add… → Windows Desktop*.
3. *Export Project…* → `TheBackrooms.exe` (+ `.pck`).

CLI-Variante (Headless/CI):
```bash
godot --headless --export-release "Windows Desktop" ./builds/TheBackrooms.exe
```
Details & weitere Plattformen: `docs/REALIZATION_PLAN.md` (Abschnitt E).

## Projektstruktur

```
project.godot              Godot-Projektkonfig (Eingaben werden im Code registriert)
icon.svg                   Platzhalter-Icon
scenes/    Main · Player · Entity
scripts/   GameManager · Player · RoomGenerator · FlickerLight · Entity · Sanity
assets/    Texturen · Modelle · Audio · Fonts (+ README mit Quellen)
docs/      Game-Design-Wissen · Realisierungsplan
```

## Hinweis zu Rechten

Das Backrooms-Konzept ist Community-/CC-Material; siehe Lizenz-Hinweis in
`docs/BACKROOMS_GAME_DESIGN.md` (Abschnitt 9). Verwende nur lizenzkonforme Assets und
dokumentiere sie in `assets/README.md`.
