extends Area2D

const CREDITS_SCENE_PATH = "res://Scenes/Credits.tscn"

var can_interact = false
var player_ref = null

func _ready():
	print("GameEndTrigger spawned and is ready!")
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func _process(_delta):
	# Wait for the player to press E
	if can_interact and Input.is_action_just_pressed("interact"):
		print("Interact key pressed while inside the GameEndTrigger!")
		
		# Make sure we actually saved the player reference
		if player_ref:
			print("Checking keys... Collected: ", player_ref.keys_collected, " / Needed: ", player_ref.keys_needed)
			
			if player_ref.keys_collected >= player_ref.keys_needed:
				print("SUCCESS! Keys match. Triggering transition to credits...")
				
				if player_ref.has_method("set_movement_locked"):
					player_ref.set_movement_locked(true)
				elif "can_move" in player_ref:
					player_ref.can_move = false
					
				SceneTransition.change_scene(CREDITS_SCENE_PATH)
			else:
				var missing_keys = player_ref.keys_needed - player_ref.keys_collected
				print("LOCKED: Player needs " + str(missing_keys) + " more keycard(s)!")
		else:
			print("ERROR: Interact pressed, but player_ref is null!")

func _on_body_entered(body):
	print("Something just touched the GameEndTrigger: ", body.name)
	
	if body.name == "Player_Main": 
		print("Player_Main has entered the zone! Ready to interact.")
		can_interact = true
		player_ref = body

func _on_body_exited(body):
	if body.name == "Player_Main":
		print("Player_Main has walked away from the zone.")
		can_interact = false
		player_ref = null
