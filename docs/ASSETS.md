# 🎨 Asset-Einkaufsliste

> **Update:** Die wichtigsten Assets sind inzwischen durch **echte CC0-/lizenzfreie Dateien** ersetzt:
> PBR-Wand/-Boden/-Decken-Texturen (Normal + ORM + Emission) von **loafbrr** und die Entitäts-Sounds
> (Ambient, Alarm-Knurren, Tod-Schrei) von **juanjo_sound**. Aktuelle Lizenz-/Quellenübersicht:
> [`../assets/README.md`](../assets/README.md). Die Liste unten dient für weitere optionale Upgrades.

Diese Liste sagt dir **genau**, welche Asset-Dateien das Spiel erwartet und **wo du hochwertigen
Ersatz** für die noch synthetischen Sounds (hum_loop, footstep, prop_impact, pickup) bekommst.

> **So funktioniert der Austausch:** Lade ein passendes Asset herunter, benenne es exakt wie in
> Spalte „Zieldatei" und lege es in den angegebenen Ordner. **Kein Code-Änderung nötig** — die
> Skripte laden Assets automatisch über diese Pfade. Fehlt eine Datei, nutzt das Spiel einen
> Platzhalter.

---

## ✅ Bereits vorhanden — generierte Platzhalter

Diese habe ich für dich erzeugt (schlicht, aber stimmig). Du kannst sofort spielen und sie
später ersetzen:

| Zieldatei | Typ | Beschreibung des Platzhalters |
|---|---|---|
| `assets/textures/wallpaper_yellow.png` | Textur 512² | Gelbe Streifentapete (kachelbar) |
| `assets/textures/carpet.png` | Textur 512² | Feuchter gelb-grauer Teppich (kachelbar) |
| `assets/textures/ceiling.png` | Textur 512² | Akustik-Deckenplatten mit Raster (kachelbar) |
| `assets/audio/hum_loop.ogg` | Audio-Loop | Leuchtstoffröhren-Brummen (120 Hz) |
| `assets/audio/footstep_01.ogg` | Audio | Weicher Schritt auf Teppich |
| `assets/audio/entity_ambient.ogg` | Audio-Loop | Tiefer, bedrohlicher Drone (3D-Sound der Entität) |
| `assets/audio/stinger.ogg` | Audio | Tod-/Schreck-Stinger (one-shot) |
| `assets/audio/prop_impact.ogg` | Audio | Aufprall/Klappern eines umgestoßenen Objekts (3D) |
| `assets/audio/pickup.ogg` | Audio | Aufsammel-Chime (Almond Water) |

> ⚠️ **Hinweis zur Internet-Recherche:** Ich sollte deine drei itch.io-Links eigenständig
> abrufen/herunterladen. Die **Netzwerk-Richtlinie dieser Cloud-Umgebung blockiert `itch.io`
> jedoch (Egress-Proxy: 403)**, daher konnte ich die Packs weder lesen noch herunterladen.
> Unten findest du sie dennoch als konkrete Empfehlung mit Zuordnung — der Download erfolgt
> von dir lokal (kostenlos, meist 1–2 Klicks).

---

## ⭐ Empfohlene Packs (deine drei Tipps)

Bitte auf der jeweiligen Seite die **Lizenz** prüfen (CC0 / „free to use" / Attribution?) und
sie anschließend in `assets/README.md` eintragen.

### 1. „Backrooms-like" Environment-Pack — von **loafbrr**
🔗 <https://loafbrr.itch.io/backrooms-like-asset-re>
- **Wofür:** Wände-/Boden-/Decken-**Texturen** (und ggf. 3D-Geometrie) im Backrooms-Look.
- **Zuordnung:** passende Texturen → `assets/textures/wallpaper_yellow.png`, `carpet.png`, `ceiling.png`.

### 2. „Backrooms Entity Sound Effects" — von **juanjosound**
🔗 <https://juanjosound.itch.io/backrooms-entity-sound-effects>
- **Wofür:** Bedrohungs-/Entitäts-**Geräusche** (Knurren, Schaben, Schreie, Atmen).
- **Zuordnung:** bestes Loop-/Ambient-Geräusch → `assets/audio/entity_ambient.ogg`;
  ein Schock-Geräusch → `assets/audio/stinger.ogg`.

### 3. „CC0 Backrooms Asset Pack" — von **naivegoblin**
🔗 <https://naivegoblin.itch.io/cc0-backrooms-asset-pack>
- **Wofür:** **CC0** (gemeinfrei, ohne Namensnennungspflicht) — Texturen/Modelle/Sounds.
- **Zuordnung:** universell für Texturen **und** Audio. Wegen CC0 die **sicherste** Wahl.

> 💡 Empfehlung: Starte mit **Pack 3 (CC0)** für Texturen, ergänze **Pack 2** für die
> Entitäts-Sounds. Pack 1 als Alternative/Erweiterung.

---

## 🌐 Weitere hochwertige, lizenzfreie Quellen (CC0)

Falls du mehr Auswahl willst — alle frei nutzbar:

### Texturen (kachelbare PBR)
- **ambientCG** — <https://ambientcg.com> (CC0) → Suche: „Carpet", „Wallpaper", „Plaster",
  „Office Ceiling".
- **Poly Haven** — <https://polyhaven.com/textures> (CC0).
- **Kenney** — <https://kenney.nl/assets?q=texture> (CC0).

### Sounds & Ambient
- **Freesound** — <https://freesound.org> (Filter auf **CC0** stellen!) → Suche:
  „fluorescent hum", „footstep carpet", „horror drone", „jumpscare".
- **Kenney Audio** — <https://kenney.nl/assets?q=audio> (CC0).

### 3D-Modelle (optional, Detail-Props)
- **Kenney** & **Poly Haven Models** (CC0); oder selbst in **Blender** modellieren
  (Export als `.glb` → `assets/models/`).

### Fonts (UI, optional)
- **Google Fonts** — <https://fonts.google.com> (Lizenz beachten) → `assets/fonts/ui.ttf`.

---

## 📋 Vollständige Ziel-Dateiliste (Referenz)

```
assets/
├── textures/
│   ├── wallpaper_yellow.png   ✅ Platzhalter vorhanden  · gelbe Tapete (kachelbar)
│   ├── carpet.png             ✅ Platzhalter vorhanden  · Teppich (kachelbar)
│   └── ceiling.png            ✅ Platzhalter vorhanden  · Deckenplatten (kachelbar)
├── audio/
│   ├── hum_loop.ogg           ✅ Platzhalter vorhanden  · Lampen-Brummen (Loop)
│   ├── footstep_01.ogg        ✅ Platzhalter vorhanden  · Schritt (Teppich)
│   ├── entity_ambient.ogg     ✅ Platzhalter vorhanden  · Entitäts-Drone (Loop, 3D)
│   ├── stinger.ogg            ✅ Platzhalter vorhanden  · Tod-Stinger (one-shot)
│   ├── prop_impact.ogg        ✅ Platzhalter vorhanden  · Objekt-Aufprall (3D)
│   └── pickup.ogg             ✅ Platzhalter vorhanden  · Almond-Water-Aufsammeln
├── models/
│   └── ceiling_light.glb      ⬜ optional · Lampen-Panel (aktuell prozedural erzeugt)
└── fonts/
    └── ui.ttf                 ⬜ optional · UI-Schrift
```

**Empfohlene Texturgrößen:** 512² bis 2048², **kachelbar/seamless** (sonst sichtbare Kanten
an den Raumübergängen).

---

## ⚖️ Lizenz-Pflicht (wichtig vor Veröffentlichung)

- **CC0**: frei nutzbar, keine Namensnennung nötig — trotzdem Quelle dokumentieren.
- **„Free / CC-BY"**: oft **Namensnennung** des Autors erforderlich.
- Trage **jede** verwendete Datei mit Quelle + Lizenz in **`assets/README.md`** ein,
  bevor du das Spiel veröffentlichst.
