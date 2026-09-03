extends Area2D

func _on_body_entered(body):
	if body.name == "Player_Main":
		if body.has_method("player_death"):
			body.player_death()
			
			
func _on_death_timer_timeout():
	# When the timer finishes, restart the current map
	get_tree().reload_current_scene()
