extends Area2D

@export var next_level: PackedScene
var can_interact = false

# We use this to remember exactly which player is standing at the door
var player_ref = null 

func _process(_delta):
	# Listen for the interact key (E)
	if can_interact and Input.is_action_just_pressed("interact"):
		
		# CHECK THE LOCK: Does the player have enough keys for this specific level?
		if player_ref.keys_collected >= player_ref.keys_needed:
			if next_level != null:
				print("Door Unlocked! Loading next level...")
				get_tree().change_scene_to_packed(next_level)
			else:
				print("You forgot to assign the next level in the Inspector!")
		else:
			# If they don't have enough keys, deny entry and tell them how many they are missing!
			var missing_keys = player_ref.keys_needed - player_ref.keys_collected
			print("Locked: You need " + str(missing_keys) + " more keycard(s) to open this door!")

func _on_body_entered(body):
	if body.name == "Player_Main": 
		can_interact = true
		player_ref = body # Save a reference to the player

func _on_body_exited(body):
	if body.name == "Player_Main":
		can_interact = false
		player_ref = null # Clear the reference when they walk away
