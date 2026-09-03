extends Area2D

@export var speed: float = 800.0 
@export var max_range: float = 250.0 # The maximum distance the bullet can travel in pixels

var velocity: Vector2 = Vector2.ZERO
var distance_traveled: float = 0.0 # Keeps track of how far we've gone

# The player will call this function right when the bullet is spawned
func set_direction(dir: int):
	# 'dir' will be 1 (right) or -1 (left)
	velocity = Vector2(dir, 0) * speed
	
	# Flip the bullet sprite so it faces left if we are shooting left
	if dir < 0:
		$Sprite2D.flip_h = true

func _physics_process(delta):
	# Calculate exactly how far we are moving this frame
	var step = velocity * delta
	position += step
	
	# Add that step to our total distance traveled
	# .length() converts the Vector2 step into a simple positive number
	distance_traveled += step.length() 
	
	# If the bullet has traveled past its maximum range, destroy it
	if distance_traveled >= max_range:
		queue_free()

func _on_body_entered(body):
	# Check if the thing we hit is an enemy
	if body.is_in_group("enemies"):
		# Check if the enemy has a health system built in
		if body.has_method("take_damage"):
			body.take_damage(1) # Deal 1 damage
		else:
			# Fallback: if it doesn't have an HP system, just destroy it
			body.queue_free()
			
		queue_free() # Destroy the bullet after it hits the enemy
		
	# Destroy the bullet if it hits a wall/floor
	if body is StaticBody2D:
		queue_free()
