extends Camera2D

var time: float = 0.0
@export var sway_speed: float = 1.0 # How fast it moves
@export var sway_amount: float = 20.0 # How far left/right it moves
var start_x: float

func _ready():
	start_x = position.x

func _process(delta):
	time += delta
	# sin() goes back and forth smoothly between -1 and 1
	position.x = start_x + (sin(time * sway_speed) * sway_amount)
