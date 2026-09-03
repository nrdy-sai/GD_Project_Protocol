extends CanvasLayer

# 1. Connect to our Text Labels
@onready var health_text = $HealthText
@onready var ammo_text = $AmmoText
@onready var key_text = $KeyText

# 2. Get the player reference
@onready var player = get_parent()

func _process(_delta):
	# 3. Update the text to show the counters
	
	# Displays like: "x 3"
	health_text.text = "x " + str(player.lives)
	
	# Displays like: "6 / 6"
	ammo_text.text = str(player.current_ammo) + " / " + str(player.max_ammo)
	
	# Displays like: "0 / 3" (Updates as you collect them)
	key_text.text = str(player.keys_collected) + " / " + str(player.keys_needed)
	
	# Optional: Turn the key text green when you have enough!
	if player.keys_collected >= player.keys_needed:
		key_text.add_theme_color_override("font_color", Color.GREEN)
	else:
		key_text.add_theme_color_override("font_color", Color.WHITE)
