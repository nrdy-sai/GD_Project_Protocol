extends Area2D

func _on_body_entered(body):
	# Make sure it's the player that touched it
	if body.name == "Player_Main": 
		
		# Add 1 to the player's new key counter!
		body.keys_collected += 1 
		
		# Optional: Play a sound here!
		
		# Delete the keycard from the world
		queue_free()


func _on_game_end_trigger_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
