extends Control

@onready var credits_text = $CreditsText

func _ready():
	var screen_height = get_viewport_rect().size.y
	
	# Start position: just below the bottom of the screen
	credits_text.position.y = screen_height
	
	# Calculate total distance to travel until it clears the top
	var target_y = -credits_text.size.y - 100
	
	# Smoothly scroll the text up over 12 seconds (adjust time to speed up/slow down)
	var tween = create_tween()
	tween.tween_property(credits_text, "position:y", target_y, 12.0)
	
	# When the scrolling finishes, head back to the main menu
	await get_tree().create_timer(30.0).timeout
	return_to_main_menu()

func _input(event):
	# Allow player to skip by pressing Space, Enter, or Esc
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		return_to_main_menu()

func return_to_main_menu():
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
