extends Node
## Zentrales Geräusch-System ("Ohr der Welt").
## Als Autoload-Singleton unter dem Namen NoiseSystem registriert
## (NICHT "Noise" — das ist eine eingebaute Godot-Klasse).
##
## Props und Spieler melden Lärm über emit_noise(). Der Pegel baut sich über
## Zeit wieder ab. Überschreitet er die Schwelle, wird einmalig (mit Cooldown)
## das Signal alarm_triggered ausgelöst — die Entität reagiert darauf.

signal alarm_triggered(position: Vector3, loudness: float)

@export var max_level: float = 100.0
@export var alarm_threshold: float = 60.0
@export var decay_per_sec: float = 25.0
@export var alarm_cooldown: float = 2.5
@export var grace_time: float = 1.5   # Karenz nach Start: kein Lärm zählt (Pegel bleibt 0)

var level: float = 0.0
var last_noise_pos: Vector3 = Vector3.ZERO
var _cooldown: float = 0.0
var _grace: float = 0.0


func _ready() -> void:
	# Auffindbar per Gruppe — unabhängig davon, ob als Autoload oder zur Laufzeit erzeugt
	add_to_group("noise_system")


func emit_noise(pos: Vector3, amount: float) -> void:
	if _grace > 0.0:
		return   # Karenzzeit nach Spielstart: Spawn-Geräusche werden ignoriert
	level = minf(max_level, level + amount)
	last_noise_pos = pos
	if level >= alarm_threshold and _cooldown <= 0.0:
		_cooldown = alarm_cooldown
		alarm_triggered.emit(pos, level)


func reset() -> void:
	level = 0.0
	_cooldown = 0.0
	last_noise_pos = Vector3.ZERO
	_grace = grace_time   # Pegel startet garantiert bei 0


func _process(delta: float) -> void:
	if _grace > 0.0:
		_grace -= delta
	if level > 0.0:
		level = maxf(0.0, level - decay_per_sec * delta)
	if _cooldown > 0.0:
		_cooldown -= delta
