# Realisierungsplan — Backrooms Level 0 (kurzes 3D-Horror-Spiel)

> Wie aus dem Konzept ein **lauffähiges, kurzes** Spiel (~10–20 Min) wird: Tech-Stack,
> Architektur, benötigte Assets, ehrliche Selbsteinschätzung meiner Asset-Erstellung und
> der Weg zur **ausführbaren `.exe`-Datei**.

---

## A) Technischer Stack — Programmiersprachen & Tools

| Bereich | Wahl | Begründung |
|---|---|---|
| **Engine** | **Godot 4.x** | Kostenlos, Open Source, schlank (~100 MB), eingebauter 1-Klick-`.exe`-Export. Szenen (`.tscn`) & Skripte (`.gd`) sind **reine Textdateien** → vollständig per Code/KI erzeugbar. |
| **Sprache** | **GDScript** | Python-ähnlich, eng in die Engine integriert, schnellste Iteration für ein Solo-/Kurzprojekt. (C# wäre möglich, ist hier aber Overhead.) |
| **3D-Modellierung** (optional) | Blender (CC0) | Falls eigene Props (Lampe, Stuhl, Tür) nötig; exportiert nach `.glb`. |
| **Texturen/Bild** (optional) | GIMP / Krita | Nachbearbeitung von CC0-/KI-Texturen, Kachelung. |
| **Audio** (optional) | Audacity | Schneiden/Loopen von CC0-Sounds (nahtlose Brummen-Loops). |
| **Versionierung** | Git | Bereits vorhanden; `.gitignore` schließt `.godot/` & Builds aus. |

> **Warum Godot statt Unity/Unreal?** Für einen KI-Agenten ist Godot optimal: Ich kann komplette,
> gültige Szenen und Spiellogik **direkt als Textdateien** schreiben. Bei Unity (Binär-/GUID-Meta)
> und Unreal (Binär-Assets) ginge nur Code-Stückwerk ohne fertige Szenen.

---

## B) Spielarchitektur (MVP Level 0)

Umgesetzt im mitgelieferten Projektgerüst (`scenes/`, `scripts/`):

- **First-Person-Controller** (`Player.gd`): Maus-Look, WASD, Sprint mit **Stamina**, Headbob,
  (optionale) Schrittgeräusche, Schwerkraft/Kollision.
- **Prozeduraler Raum-Generator** (`RoomGenerator.gd`): Grid/Chunk-basiert, generiert modulare
  Boden-, Decken-, Wand- und Pfeiler-Segmente **um den Spieler herum** und gibt entfernte wieder
  frei → endlose, nie exakt wiederkehrende gelbe Räume. Deterministisch geseedet.
- **Atmosphäre** (`GameManager.gd`, `FlickerLight.gd`): WorldEnvironment mit **gelblichem Nebel**,
  niedriges Ambient, **flackernde Leuchtstoffröhren** (OmniLight + emissive Panels), Glow/Bloom,
  begrenzte Sichtweite.
- **Sanity-System** (`Sanity.gd`): zermürbt langsam, schneller bei Nähe zur Entität; speist
  Tunnelblick-Vignette & Audio.
- **Eine Bedrohung** (`Entity.gd`): wandert zufällig, **verfolgt bei Entdeckung**, Game-Over bei
  Kontakt. Kein Kampf — nur Weglaufen/Distanz halten.
- **UI** (in `GameManager.gd` erzeugt): Startbildschirm, HUD (Stamina/Sanity), Tod-/Neustart-Screen,
  Pause (Esc), Maus-Capture.
- **Optional/erweiterbar**: Almond Water als Sanity-Restore-Pickup.

> Bewusste Entscheidung: Viel wird **prozedural in GDScript** gebaut (Meshes, Materialien, Lichter,
> UI), damit die `.tscn`-Dateien klein und robust bleiben und das Projekt sofort startet.

---

## C) Benötigte Game-Assets — deine „Einkaufsliste"

Das Projekt läuft auch **ohne** externe Assets (Platzhalter-Materialien/-Geometrie werden im Code
erzeugt). Für den finalen Look ersetzt/ergänzt du folgende Dateien (Ablage gemäß `assets/README.md`):

### Texturen (CC0 — empfohlene Quellen: ambientCG, Poly Haven, Kenney)
- **Gelbe Tapete** (kachelbar, ~2K) → `assets/textures/wallpaper_yellow.png`
- **Feuchter Teppichboden** (kachelbar) → `assets/textures/carpet.png`
- **Deckenplatten/Akustikdecke** → `assets/textures/ceiling.png`
- *(optional)* Normal-/Roughness-Maps der obigen für PBR-Tiefe

### 3D-Modelle (modular, low-poly — Quellen: Kenney, Poly Haven, selbst in Blender)
- **Leuchtstofflampen-Panel** → `assets/models/ceiling_light.glb`
- *(optional)* Türrahmen, Steckdose, Rohr, Stuhl als Detail-Props

### Audio (CC0 — Quellen: Freesound, Kenney Audio)
- **Leuchtstoffröhren-Brummen** (nahtloser Loop) → `assets/audio/hum_loop.ogg`
- **Schritte auf Teppich** (mehrere Varianten) → `assets/audio/footstep_*.ogg`
- **Atem/Herzschlag** → `assets/audio/breath.ogg`
- **Ferne Bedrohungsgeräusche / Schaben** → `assets/audio/entity_*.ogg`
- **Jumpscare-/Tod-Stinger** → `assets/audio/stinger.ogg`

### Fonts (offene Lizenz — z. B. Google Fonts)
- Schlichte Sans-Serif → `assets/fonts/ui.ttf`

> Die Skripte laden Assets **defensiv** (`ResourceLoader.exists(...)`): fehlt eine Datei, fällt das
> Spiel automatisch auf Platzhalter zurück und startet trotzdem.

---

## D) Kritische Selbstanalyse — wie gut kann **ich** Assets erstellen?

Ehrliche Einschätzung, damit du Aufwand realistisch planst:

| Asset-Typ | Meine Eignung | Begründung & Empfehlung |
|---|---|---|
| **Code / Szenen / Spiellogik** | 🟢 **Sehr gut** | Vollständige GDScript-Logik, gültige `.tscn`-Szenen und Projektkonfig erzeuge ich direkt und zuverlässig. Das ist der Kern dessen, was ich liefere. |
| **Prozedurale Geometrie/Materialien** | 🟢 **Sehr gut** | Box-/Wand-/Decken-Meshes und Standard-Materialien im Code zu generieren ist robust und für Level 0 völlig ausreichend. |
| **2D-Texturen (KI)** | 🟡 **Gut, mit Einschränkungen** | Über KI-Bildtools (z. B. `generate_image`) kann ich gelbe-Tapeten-/Teppich-Optik erzeugen — **aber** nahtlos **kachelbare** PBR-Texturen sind nicht garantiert (Kanten-Artefakte). Kuratierte CC0-Texturen sind hier oft verlässlicher. KI = guter Platzhalter. |
| **3D-Modelle (KI)** | 🟠 **Eingeschränkt** | Bild→3D-Tools (`generate_3d`) liefern meist **organische Einzel-Meshes**, nicht saubere, modulare, kachelbare Architektur-Kits. Für Räume ist **prozedurale Geometrie** besser; KI-3D nur für isolierte Detail-Props (Lampe, Stuhl) sinnvoll, dann oft nachbearbeitungsbedürftig. |
| **Audio (KI)** | 🟡 **Mittel** | KI-Audio (`generate_audio`) taugt für Ambient/Stinger; ein wirklich **nahtlos loopendes** Brummen ist mit kuratierten Freesound-CC0-Clips meist sauberer. |
| **Musik/Komposition** | 🟠 **Eingeschränkt** | Möglich, aber Qualität/Lizenzkontrolle schwankt. Für Backrooms ohnehin eher **kein** Score, sondern Ambient. |

**Fazit / klare Arbeitsteilung:**
- **Ich liefere zuverlässig:** das gesamte **lauffähige Code-/Szenen-Gerüst** inkl. prozeduraler
  Räume, Atmosphäre, Entität, UI und Build-Anleitung.
- **KI als Platzhalter:** erste Texturen/Props/Stinger lassen sich generieren, um schnell etwas
  Sichtbares zu haben.
- **Du ersetzt das Kritische:** nahtlose Texturen, gut loopendes Brummen und finalen Feinschliff
  am besten durch **kuratierte CC0-Assets** (Liste in Abschnitt C) — das hebt die Qualität spürbar
  bei geringem Aufwand.

---

## E) Weg zur ausführbaren Datei (`.exe`)

Godot erzeugt **eigenständige** Executables — beim Endnutzer ist **keine** Runtime-Installation nötig.

### Einmalige Vorbereitung
1. **Godot 4.x** herunterladen (godotengine.org) — „Standard"-Version reicht für GDScript.
2. Projekt öffnen: Godot starten → *Import* → `project.godot` aus diesem Repo wählen.
3. **Export-Templates installieren:** im Editor *Editor → Manage Export Templates → Download and Install*.

### Variante 1 — Export über die GUI (empfohlen)
1. *Project → Export…*
2. *Add… → Windows Desktop* (ggf. *Linux/X11* oder *macOS* zusätzlich).
3. Optional: Icon, Produktname, Version setzen.
4. *Export Project…* → Zielordner → `TheBackrooms.exe` (+ `.pck`) wird erzeugt.
5. **`.exe` und `.pck` zusammen** weitergeben (oder „Embed PCK" aktivieren → einzelne `.exe`).

### Variante 2 — Export über die Kommandozeile (Headless/CI)
```bash
# Beispiel (Pfade/Preset-Name anpassen):
godot --headless --export-release "Windows Desktop" ./builds/TheBackrooms.exe
```
> Hinweis: Auch der CLI-Export benötigt **installierte Export-Templates** und die Godot-Binary.
> In dieser Remote-Umgebung läuft kein Godot-Editor — den `.exe`-Build führst du **lokal** aus.
> Die `builds/`-Ausgabe ist in `.gitignore` ausgeschlossen.

### Distribution
- Windows: `.exe` (+ ggf. `.pck`) zippen. Optional Installer (z. B. Inno Setup).
- Cross-Platform: separate Presets für Linux (`.x86_64`) und macOS (`.app`) im selben Export-Dialog.

---

## F) Mitgeliefertes Projekt-Gerüst (Überblick)

```
project.godot              # Godot-4-Projektkonfig (Main-Szene, Fenster, Rendering)
icon.svg                   # Platzhalter-Icon
scenes/
  Main.tscn                # Einstiegsszene (GameManager)
  Player.tscn              # First-Person-Controller (Kamera, Kollision, Audio)
  Entity.tscn              # Die Bedrohung
scripts/
  GameManager.gd           # Spielzustand, Environment, UI, Orchestrierung
  Player.gd                # Bewegung, Maus-Look, Stamina, Headbob
  RoomGenerator.gd         # Prozedurale, endlose Räume (Chunks)
  FlickerLight.gd          # Flackernde Leuchtstoffröhren
  Entity.gd                # Wandern + Verfolgen + Game-Over
  Sanity.gd                # Geisteszustands-System
assets/                    # Asset-Ordner + README (CC0-Quellen/Lizenzen)
docs/                      # Diese Dokumente
README.md                  # Setup, Steuerung, Build
```

---

## G) Umsetzungs-Roadmap (Iterationen)

1. **MVP (dieses Gerüst):** begehbare, endlose gelbe Räume, Atmosphäre, eine Bedrohung, Stamina/Sanity, UI.
2. **Asset-Pass:** CC0-Texturen/Sounds einsetzen, Brummen-Loop, Schritte, Stinger.
3. **Feinschliff:** Vignette/VHS-Post-Processing, Sound-Mix, Entitäts-Balancing, Almond Water.
4. **Polish & Build:** Menü/Optionen, Maus-Sensitivität, Lautstärke; `.exe`-Export & Test.
5. *(optional)* Level 1/2, weitere Entitäten, Save-System.

## H) Verifikation / Test

- **Lokal starten:** `godot project.godot` (oder Projekt im Editor öffnen, ▶ drücken).
- **Erwartung:** Startbildschirm → Enter → First-Person in gelben, neblig-flackernden Räumen;
  Sprint zehrt Stamina; eine Entität wandert/verfolgt; Kontakt → Tod-Screen → Neustart.
- **Build-Test:** `.exe` exportieren und auf einem sauberen Windows ohne Godot starten.
