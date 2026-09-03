extends Node2D

const TUTORIAL_LEVEL = preload("res://Scenes/Tutorial_Level.tscn")

var typed_word: String = ""
var is_starting: bool = false 

# Store the default camera position so it always returns to the center!
var base_cam_pos: Vector2

@onready var camera = $AnimatedSprite2D/MenuCam
@onready var play_label = $RichTextLabel
@onready var time_skip_overlay = $TimeSkipLayer/TimeSkipOverlay

func _ready():
	play_label.text = "\"PLAY\""
	time_skip_overlay.hide()
	# Save the exact position the camera starts at
	base_cam_pos = camera.position

func _input(event):
	if is_starting:
		return 
		
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var key_name = OS.get_keycode_string(event.keycode).to_upper()
		
		if key_name.length() == 1:
			typed_word += key_name
			update_visuals()
			
			# Trigger the small shake every time a letter is pressed
			small_camera_shake()
			
			if typed_word.ends_with("PLAY"):
				start_time_skip()

func update_visuals():
	if typed_word.ends_with("PLAY"):
		play_label.text = "[color=green]\"PLAY\"[/color]"
	elif typed_word.ends_with("PLA"):
		play_label.text = "[color=green]\"PLA\"[/color]Y"
	elif typed_word.ends_with("PL"):
		play_label.text = "[color=green]\"PL\"[/color]AY"
	elif typed_word.ends_with("P"):
		play_label.text = "[color=green]\"P\"[/color]LAY"
	else:
		play_label.text = "\"PLAY\""

# New function: A quick, punchy shake for individual letters
func small_camera_shake():
	var shake_tween = get_tree().create_tween()
	
	# Create a random offset (adjust the 5 and -5 to make it stronger or weaker)
	var shake_offset = Vector2(randf_range(-5, 5), randf_range(-5, 5))
	
	# Quickly jerk the camera to the offset, then instantly snap it back to base_cam_pos
	shake_tween.tween_property(camera, "position", base_cam_pos + shake_offset, 0.03)
	shake_tween.tween_property(camera, "position", base_cam_pos, 0.03)

func start_time_skip():
	is_starting = true 
	time_skip_overlay.show()
	
	var shader_mat = time_skip_overlay.material as ShaderMaterial
	
	# --- TWEEN 1: Shader & Zoom (0.9 seconds) ---
	var main_tween = get_tree().create_tween().set_parallel(true)
	
	main_tween.tween_property(shader_mat, "shader_parameter/progress", 1.0, 0.9)
	main_tween.tween_property(shader_mat, "shader_parameter/glitch_amount", 1.0, 0.9)
	main_tween.tween_property(camera, "zoom", Vector2(0.5, 0.5), 0.9)
	
	# --- TWEEN 2: Screen Shake ---
	var shake_tween = get_tree().create_tween()
	
	for i in range(15):
		var shake_offset = Vector2(randf_range(-13, 13), randf_range(-13, 13))
		# Use base_cam_pos here too so the big shake stays centered!
		shake_tween.tween_property(camera, "position", base_cam_pos + shake_offset, 0.05)
	
	shake_tween.tween_property(camera, "position", base_cam_pos, 0.05)
	
	await main_tween.finished
	get_tree().change_scene_to_packed(TUTORIAL_LEVEL)
