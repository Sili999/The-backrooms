# Assets

In `textures/` und `audio/` liegen bereits **generierte Platzhalter** — das Spiel sieht und
klingt sofort nach Backrooms. Zum Aufwerten ersetzt du sie durch hochwertige (CC0-)Assets mit
**gleichem Dateinamen** — kein Code-Eingriff nötig. Fehlt eine Datei, fällt das Spiel auf
prozedurale Platzhalter im Code zurück.

➡️ **Fertige Einkaufsliste mit Links & Zuordnung: [`../docs/ASSETS.md`](../docs/ASSETS.md)**

## Erwartete Dateien

```
textures/
  wallpaper_yellow.png   # kachelbare gelbe Tapete  (RoomGenerator -> Wände)
  carpet.png             # kachelbarer feuchter Teppich (Boden)
  ceiling.png            # Akustik-/Deckenplatten (Decke)
models/
  ceiling_light.glb      # optionales Lampen-Panel (derzeit prozedural)
audio/
  hum_loop.ogg           # nahtloses Leuchtstoff-Brummen (GameManager)
  footstep_01.ogg        # Schritt auf Teppich (Player)
  entity_ambient.ogg     # ferne Bedrohungsgeräusche (Entity, 3D-Sound)
  stinger.ogg            # Tod-/Schreck-Stinger (optional)
  prop_impact.ogg        # Aufprall/Klappern umgestoßener Objekte (KnockableProp, 3D)
fonts/
  ui.ttf                 # UI-Schrift (optional)
```

## Empfohlene CC0-/lizenzfreie Quellen

- **Texturen:** ambientCG (ambientcg.com), Poly Haven (polyhaven.com), Kenney (kenney.nl)
- **3D-Modelle:** Kenney, Poly Haven, selbst in Blender erstellt
- **Audio:** Freesound (freesound.org — auf CC0 filtern!), Kenney Audio
- **Fonts:** Google Fonts (fonts.google.com — Lizenz beachten)

## Lizenz-Dokumentation

Trage hier jede verwendete Datei mit Quelle + Lizenz ein, bevor das Projekt veröffentlicht wird:

| Datei | Quelle (URL) | Lizenz | Autor |
|-------|--------------|--------|-------|
| _z. B. carpet.png_ | _ambientcg.com/..._ | CC0 | _ambientCG_ |
