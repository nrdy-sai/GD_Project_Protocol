extends CanvasLayer

@onready var color_rect = $ColorRect

func _ready():
	color_rect.hide()

func change_scene(target_path: String):
	print("[SceneTransition] change_scene called for path: ", target_path)
	
	# 1. Safety Check: Make sure ColorRect and Material exist
	if not color_rect:
		print("[SceneTransition] ERROR: ColorRect node not found!")
		get_tree().change_scene_to_file(target_path)
		return
		
	var shader_mat = color_rect.material as ShaderMaterial
	if not shader_mat:
		print("[SceneTransition] ERROR: ColorRect is missing a ShaderMaterial in the Inspector! Swapping scenes without animation.")
		get_tree().change_scene_to_file(target_path)
		return

	# 2. Show the overlay and reset shader values
	color_rect.show()
	shader_mat.set_shader_parameter("progress", 0.0)
	shader_mat.set_shader_parameter("glitch_amount", 0.0)

	# 3. Animate the Diavolo Shader Effect
	print("[SceneTransition] Playing Diavolo Time Skip animation...")
	var tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property(shader_mat, "shader_parameter/progress", 1.0, 0.9)
	tween.tween_property(shader_mat, "shader_parameter/glitch_amount", 1.0, 0.9)
	
	await tween.finished
	print("[SceneTransition] Animation finished. Changing scene now...")

	# 4. Change Scene
	get_tree().change_scene_to_file(target_path)

	# 5. Reverse / Hide the Transition Overlay
	var fade_tween = get_tree().create_tween().set_parallel(true)
	fade_tween.tween_property(shader_mat, "shader_parameter/progress", 0.0, 0.2)
	fade_tween.tween_property(shader_mat, "shader_parameter/glitch_amount", 0.0, 0.2)
	await fade_tween.finished
	
	color_rect.hide()
	print("[SceneTransition] Transition complete.")
