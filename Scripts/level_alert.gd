extends CanvasLayer

@export var alert_text: String = "LEVEL 1"
@export var display_duration: float = 2.0

@onready var dark_overlay = $DarkOverlay
@onready var alert_label = $CenterContainer/AlertLabel

func _ready():
	# 1. Set the text
	alert_label.text = alert_text
	
	# 2. Ensure screen is pitch black instantly, label starts invisible
	dark_overlay.modulate.a = 1.0
	alert_label.modulate.a = 0.0
	show()
	
	# 3. Freeze the player immediately
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_movement_locked"):
		player.set_movement_locked(true)
	elif player and "can_move" in player:
		player.can_move = false
		
	# --- FADE IN LABEL ONLY (Screen is already black) ---
	var fade_in = get_tree().create_tween()
	fade_in.tween_property(alert_label, "modulate:a", 1.0, 0.3)
	await fade_in.finished
	
	# 4. Stay on screen for the chosen duration
	await get_tree().create_timer(display_duration).timeout
	
	# --- FADE OUT EVERYTHING ---
	var fade_out = get_tree().create_tween().set_parallel(true)
	fade_out.tween_property(dark_overlay, "modulate:a", 0.0, 0.5)
	fade_out.tween_property(alert_label, "modulate:a", 0.0, 0.5)
	await fade_out.finished
	
	# 5. Unfreeze the player and clear the alert node
	if player and player.has_method("set_movement_locked"):
		player.set_movement_locked(false)
	elif player and "can_move" in player:
		player.can_move = true
		
	queue_free()
