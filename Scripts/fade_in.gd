extends ColorRect

func _ready():
	# 1. Make sure it starts completely solid black
	modulate.a = 1.0 
	
	# 2. Create a Tween (a tool that smoothly transitions numbers)
	var tween = get_tree().create_tween()
	
	# 3. Tell it to fade the 'alpha' (transparency) to 0.0 over 1 second
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
