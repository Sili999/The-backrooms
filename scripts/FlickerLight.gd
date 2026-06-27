extends OmniLight3D
## Flackernde Leuchtstoffröhre — der typische "hum-buzz"-Look von Level 0.
## Variiert die Lichtenergie unregelmäßig; selten ein kurzes Aussetzen.

@export var base_energy: float = 1.8
var _timer: float = 0.0


func _ready() -> void:
	# Versatz, damit nicht alle Lampen synchron flackern
	_timer = randf_range(0.0, 0.5)


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = randf_range(0.04, 0.7)
	if randf() < 0.12:
		# kurzes Aussetzen / starkes Abdunkeln
		light_energy = base_energy * randf_range(0.0, 0.25)
	else:
		light_energy = base_energy * randf_range(0.82, 1.0)
