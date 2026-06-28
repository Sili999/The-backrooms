# Assets

Echte, eingebundene Assets (keine Platzhalter mehr für Texturen & Entity-Sounds).
Die Skripte laden sie defensiv über feste Pfade; fehlt eine Datei, gibt es einen Code-Fallback.

## Struktur

```
textures/backrooms/        # CC0-PBR-Texturen (loafbrr) — Diffuse + Normal + ORM (+ Emission)
  BRW_A/  BRW_A_Diffuse_1K.png · _Normal_1K.png · _ORM_1K.png      -> Wände
  BRF_A/  BRF_A_Diffuse_1K.png · _Normal_1K.png · _ORM_1K.png      -> Boden
  BRC_A/  BRC_A_Diffuse_1K.png · _Normal_1K.png · _ORM_1K.png
          BRC_A_Emission_1K.png                                    -> Decke (leuchtende Paneele)
audio/
  hum_loop.ogg           # Leuchtstoff-Brummen (synthetisiert, GameManager) — ersetzbar
  footstep_01.ogg        # Schritt auf Teppich (synthetisiert, Player)
  entity_ambient.ogg     # Entitäts-Drone, Loop (juanjo_sound, 3D)
  entity_alert.ogg       # Knurren beim Aufnehmen der Verfolgung (juanjo_sound, 3D)
  stinger.ogg            # Tod-Schrei (juanjo_sound)
  prop_impact.ogg        # Aufprall umgestoßener Objekte (synthetisiert, 3D)
  pickup.ogg             # Almond-Water-Aufsammeln (synthetisiert)
models/ , fonts/         # derzeit leer (Geometrie ist prozedural)
```

## Lizenzen der verwendeten Assets

| Asset | Quelle | Lizenz | Autor | Hinweis |
|-------|--------|--------|-------|---------|
| `textures/backrooms/*` | loafbrr „BackroomsLikeAsset2" (itch.io) | **CC0** | loafbrr | frei, Namensnennung erbeten |
| `audio/entity_ambient·alert·stinger.ogg` | juanjo_sound „Backrooms Entity SFX Vol. 1" (itch.io) | frei für Projekte | juanjo_sound | **nicht** als Standalone-Pack weiterverteilen; Namensnennung erbeten |
| `audio/hum_loop·footstep_01·prop_impact·pickup.ogg` | selbst generiert (Synthese) | eigen | — | ersetzbar |

> **Namensnennung (empfohlen):** „Environment textures by loafbrr (CC0)", „Entity sounds by juanjo_sound".
> Es sind nur die tatsächlich genutzten Dateien eingebunden; die übrigen Pack-Inhalte wurden entfernt.

## Noch ersetzbar (optionale Verbesserung)

- `hum_loop.ogg` — synthetisch mit hörbarer Loop-Naht; ein CC0-Leuchtstoff-Brummen von
  *Freesound* (auf CC0 filtern) wäre besser.
- `footstep_01.ogg` — nur eine Variante; ein Schritt-Pack (3–5 Varianten Teppich) verbessert es.
- UI-Schrift (`fonts/`) — optional eine kondensierte Horror-Schrift (Google Fonts).
