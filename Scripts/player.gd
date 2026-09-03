extends CharacterBody2D

# --- MOVEMENT SETTINGS ---
const MAX_SPEED = 800.0       # Top speed
const ACCELERATION = 8000.0   # Snappy start
const FRICTION = 6000.0       # Stops on a dime
const JUMP_VELOCITY = -550.0  # Stronger jump to fight the gravity

# --- COYOTE TIME SETTINGS ---
const COYOTE_TIME = 0.15 
var coyote_timer = 0.0

# Enhanced gravity settings
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * 1.8

# --- SHOOTING SETTINGS ---
# PRELOAD the bullet scene so it is ready in memory.
const BULLET_SCENE = preload("res://Scenes//bullet.tscn")

# --- STATE VARIABLES ---
var is_dead = false
var lives = 3
var spawn_position = Vector2.ZERO
var has_key = false

# --- NODE REFERENCES ---
# This links the script to your AnimatedSprite2D node. 
@onready var anim = $AnimatedSprite2D 

# Reference to the Projectiles container in the main scene.
@onready var projectiles_node = get_tree().current_scene.get_node("Projectiles")

# --- CORE GODOT FUNCTIONS ---

func _ready():
	# Save the exact spot the player is standing when the scene loads
	spawn_position = global_position 

func _physics_process(delta):
	# Stop all movement and physics calculations if the player is dead
	if is_dead:
		return 
		
	# 1. HANDLE GRAVITY & COYOTE TIMER
	if is_on_floor():
		coyote_timer = COYOTE_TIME # Reset the timer when touching the ground
	else:
		velocity.y += gravity * delta
		coyote_timer -= delta # Count down the timer when falling

	# 2. HANDLE JUMPING (With Coyote Time)
	if Input.is_action_just_pressed("ui_accept") and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0.0 # Drain the timer immediately so you can't double jump
		
	# 2.b. VARIABLE JUMP HEIGHT (Bonus for better game feel)
	# If you let go of the spacebar early while moving up, cut the jump short
	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y *= 0.5 

	# 3. HANDLE ACCELERATION & FRICTION
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction != 0:
		# Smoothly ramp up speed towards MAX_SPEED
		velocity.x = move_toward(velocity.x, direction * MAX_SPEED, ACCELERATION * delta)
	else:
		# Smoothly slide to a stop
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	# Call our custom animation function before moving
	update_animations(direction)
	
	# Apply the movement
	move_and_slide()

# --- INPUT HANDLING ---

func _unhandled_input(event):
	# We use _unhandled_input for discrete "just pressed" actions like shooting.
	
	# 1. We don't allow shooting if the player is dead
	if is_dead:
		return
		
	# 2. Check if the 'shoot' input action (e.g., Left Mouse Button) was pressed
	if event.is_action_pressed("shoot"):
		shoot_projectile()

# --- CUSTOM FUNCTIONS ---

func shoot_projectile():
	# PHASE 3 steps from the guide:
	
	# 1. Instantiate (create) a new copy of the preloaded bullet scene
	var new_bullet = BULLET_SCENE.instantiate()
	
	# 2. Add it to the tree as a child of the 'Projectiles' container node.
	# Adding it to that node keeps it separate from the Player so it doesn't move with them.
	projectiles_node.add_child(new_bullet)
	
	# 3. Position the new bullet at the player's current global position.
	new_bullet.global_position = global_position

func update_animations(direction):
	# Flip the sprite left or right based on movement direction
	if direction > 0:
		anim.flip_h = false
	elif direction < 0:
		anim.flip_h = true
		
	# Play the correct animation from your list
	if not is_on_floor():
		anim.play("Jump")
	else:
		if direction != 0:
			anim.play("Run") 
		else:
			anim.play("Idle")

# Placeholder function
func take_damage():
	anim.play("Hit")

# Placeholder function for a potential dodge roll
func dodge_roll():
	anim.play("Roll")

# --- LIFE AND DEATH SYSTEM ---

func player_death():
	# Prevent the KillZone from hitting the player 60 times a second
	if is_dead:
		return 
		
	is_dead = true
	velocity = Vector2.ZERO # Stop moving instantly
	anim.play("Hit")
	
	lives -= 1 # Subtract 1 life
	print("Ouch! Lives remaining: ", lives)
	
	if lives > 0:
		# Wait for 1 second, then trigger the respawn
		await get_tree().create_timer(1.0).timeout
		respawn()
	else:
		# Out of lives! Wait 1 second, then reload the whole level
		print("Game Over!")
		anim.play("Death")
		await get_tree().create_timer(1.3).timeout
		get_tree().reload_current_scene()

func respawn():
	# Teleport the player back to the saved starting spot
	global_position = spawn_position
	
	# Bring them back to life
	is_dead = false
	anim.play("Idle")
