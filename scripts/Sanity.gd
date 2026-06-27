extends Node
## Verstand-System (Sanity): zermürbt langsam über Zeit, deutlich schneller bei
## Nähe zur Entität. Wird vom GameManager für Vignette/HUD/Game-Over ausgelesen.
## Almond Water (optional) kann den Wert über restore() wieder anheben.

@export var value: float = 100.0
@export var max_value: float = 100.0
@export var base_drain: float = 0.25       # pro Sekunde, Grundzermürbung
@export var proximity_drain: float = 9.0   # zusätzlich, wenn Entität nah
@export var proximity_range: float = 10.0  # ab dieser Distanz beginnt Panik
@export var regen: float = 0.0             # optionale langsame Erholung


func update_sanity(delta: float, entity_distance: float) -> void:
	var drain := base_drain
	if entity_distance < proximity_range:
		# je näher, desto stärker (linear skaliert)
		var t := 1.0 - clampf(entity_distance / proximity_range, 0.0, 1.0)
		drain += proximity_drain * t
	value = clampf(value - drain * delta + regen * delta, 0.0, max_value)


func restore(amount: float) -> void:
	value = clampf(value + amount, 0.0, max_value)
