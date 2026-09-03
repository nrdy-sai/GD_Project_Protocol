extends CharacterBody2D

# --- MOVEMENT SETTINGS ---
const MAX_SPEED = 300.0       # Top speed
const RELOAD_SPEED_MULTIPLIER = 0.4 # Slows movement down to 40% while reloading
const ACCELERATION = 3000.0   # Snappy start
const FRICTION = 6000.0       # Stops on a dime
const JUMP_VELOCITY = -550.0  # Stronger jump to fight the gravity

# --- ROLL SETTINGS (NEW) ---
const ROLL_SPEED = 550.0 # Make them slide faster than they run!
const ROLL_DURATION = 0.4 # How long the roll lasts (in seconds)
@export var roll_cooldown: float = 2.0 # NEW: The 2-second cooldown
var is_rolling: bool = false
var can_roll: bool = true # NEW: Tracks if the cooldown is finished
var roll_direction: int = 1

# --- COYOTE TIME SETTINGS ---
const COYOTE_TIME = 0.15 
var coyote_timer = 0.0

# Enhanced gravity setting
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * 1.8

# --- SHOOTING SETTINGS ---
# PRELOAD the bullet scene so it is ready in memory.
const BULLET_SCENE = preload("res://Scenes/bullet.tscn")
@export var fire_anim_duration: float = 0.2 # How long the firing animation takes

# --- AMMO SETTINGS ---
@export var max_ammo: int = 6
var current_ammo: int = 6
var is_reloading: bool = false
var is_firing: bool = false

# --- STATE VARIABLES ---
var is_dead = false
var lives = 3
var spawn_position = Vector2.ZERO

# --- NEW KEYCARD COUNTERS (UPDATED) ---
@export var keys_needed: int = 3 
# This automatically checks if we have enough keys EVERY TIME you pick one up!
var keys_collected: int = 0:
	set(value):
		keys_collected = value
		if keys_needed > 0 and keys_collected == keys_needed:
			show_keycard_warning()

# --- NODE REFERENCES ---
# This links the script to your AnimatedSprite2D node. 
@onready var anim = $AnimatedSprite2D 

# Reference to the Projectiles container in the main scene.
@onready var projectiles_node = get_tree().current_scene.get_node("Projectiles")

# --- UI WARNING LABEL (NEW) ---
@onready var key_warning_label = $UI/KeyWarningLabel

# --- CORE GODOT FUNCTIONS ---

func _ready():
	# Make sure the warning is hidden when the game starts
	if key_warning_label:
		key_warning_label.hide()
		
	# Force stats to reset on level load
	keys_collected = 0
	is_dead = false
	current_ammo = max_ammo # Start with full ammo
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
		
		# Instantly stop the roll if the player falls off a ledge!
		if is_rolling:
			is_rolling = false

	# 2. HANDLE ROLLING (Takes priority over walking/jumping)
	if is_rolling:
		velocity.x = roll_direction * ROLL_SPEED
		move_and_slide()
		return # Skip the normal walking/jumping code while rolling!

	# 3. HANDLE JUMPING (With Coyote Time)
	if Input.is_action_just_pressed("ui_accept") and coyote_timer > 0.0 and not is_firing and not is_reloading:
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0.0 # Drain the timer immediately so you can't double jump
		
	# 3.b. VARIABLE JUMP HEIGHT
	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y *= 0.5 

	# 4. HANDLE ACCELERATION & FRICTION
	var direction = Input.get_axis("ui_left", "ui_right")
	
	# Ignore player input and force them to stop if they are shooting
	if is_firing:
		direction = 0
		
	# Calculate current max speed based on whether we are reloading
	var current_max_speed = MAX_SPEED
	if is_reloading:
		current_max_speed = MAX_SPEED * RELOAD_SPEED_MULTIPLIER
	
	if direction != 0:
		# Smoothly ramp up speed towards our current_max_speed
		velocity.x = move_toward(velocity.x, direction * current_max_speed, ACCELERATION * delta)
	else:
		# Smoothly slide to a stop
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	# Call our custom animation function before moving
	update_animations(direction)
	
	# Apply the movement
	move_and_slide()

# --- INPUT HANDLING ---
func _unhandled_input(event):
	if is_dead:
		return
		
	# Listen for the roll action
	if event.is_action_pressed("roll"):
		# NEW: Check 'can_roll' to make sure the cooldown is finished!
		if is_on_floor() and not is_rolling and can_roll and not is_firing and not is_reloading:
			start_roll()
			
	# Listen for the EXACT moment the button is clicked
	if event.is_action_pressed("shoot"):
		
		# STRICT LOCKOUT: Stop immediately if we are already busy
		if is_firing or is_reloading or is_rolling:
			return 
			
		# Fire if we have bullets, otherwise force a reload
		if current_ammo > 0:
			shoot_projectile()
		else:
			reload()

# --- NEW ROLL SYSTEM ---
func start_roll():
	is_rolling = true
	can_roll = false 
	anim.play("Roll") 
	$RollSFX.play()
	
	# Determine which way the player is facing so they roll forward
	if anim.flip_h:
		roll_direction = -1
	else:
		roll_direction = 1
		
	# Start a timer to stop the roll
	get_tree().create_timer(ROLL_DURATION, false).timeout.connect(_on_roll_finished)

func _on_roll_finished():
	if is_rolling:
		is_rolling = false
		
	# Wait for the 2-second cooldown, then allow them to roll again!
	await get_tree().create_timer(roll_cooldown, false).timeout
	can_roll = true

# --- CUSTOM FUNCTIONS ---
func shoot_projectile():
	current_ammo -= 1
	print("Ammo left: ", current_ammo)
	
	# LOCK the gun so we can't shoot again until the timer finishes
	is_firing = true
	anim.play("Firing") 
	$FiringSFX.play()
	
	# Start the cooldown timer 
	get_tree().create_timer(fire_anim_duration, false).timeout.connect(_on_fire_finished)

	# Spawn Bullet
	if BULLET_SCENE:
		var new_bullet = BULLET_SCENE.instantiate()
		get_parent().add_child(new_bullet)
		new_bullet.global_position = global_position
		var facing_direction = -1 if anim.flip_h else 1
		new_bullet.set_direction(facing_direction)

func _on_fire_finished():
	# UNLOCK the gun
	is_firing = false
	
	# Auto-reload if we just fired the last bullet
	if current_ammo <= 0:
		reload()

# --- RELOAD SYSTEM ---
func reload():
	if is_reloading: 
		return 
		
	# LOCK the gun for reloading
	is_reloading = true
	is_firing = false # Ensure firing is definitely off
	print("Reloading... (Please wait 1 second)")
	
	# Play the reload animation! 
	anim.play("Reloading")
	
	get_tree().create_timer(1.0, false).timeout.connect(_on_reload_finished)

func _on_reload_finished():
	current_ammo = max_ammo
	
	# UNLOCK the gun
	is_reloading = false
	print("Ammo full! Ready to shoot.")

func update_animations(direction):
	# Allow the player to turn left/right even while locked in an action animation
	if direction > 0:
		anim.flip_h = false
	elif direction < 0:
		anim.flip_h = true

	# CRITICAL: If rolling, shooting, OR reloading, DO NOT change the animation!
	if is_rolling or is_firing or is_reloading:
		return 
		
	# Play the correct movement animation
	if not is_on_floor():
		# Check if moving down (falling) or up (jumping)
		if velocity.y > 0:
			anim.play("Fall")
		else:
			anim.play("Jump")
			if $JumpSFX: $JumpSFX.play()
	else:
		if direction != 0:
			anim.play("Run") 
		else:
			anim.play("Idle")

# --- KEYCARD WARNING SYSTEM (NEW) ---
func show_keycard_warning():
	if key_warning_label:
		key_warning_label.show()
		print("Warning Label Shown: YOU HAVE ENOUGH KEYCARD!")
		
		# Keep it on screen for 3 seconds, then hide it
		await get_tree().create_timer(3.0).timeout
		key_warning_label.hide()

# --- LIFE AND DEATH SYSTEM ---
func take_damage():
	# UNTOUCHABLE STATE: Because we check 'is_rolling' right here, 
	# the player takes 0 damage and doesn't flinch if they are hit during a roll!
	if is_dead or is_rolling:
		return
		
	anim.play("Hit")

func player_death():
	# NEW UNTOUCHABLE STATE: Ignore death/damage completely if rolling!
	if is_dead or is_rolling:
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
		if $DeathSFX: $DeathSFX.play()
		await get_tree().create_timer(1.3).timeout
		get_tree().reload_current_scene()

func respawn():
	# Teleport the player back to the saved starting spot
	global_position = spawn_position
	
	# Bring them back to life
	is_dead = false
	current_ammo = max_ammo # Refill ammo on respawn
	anim.play("Idle")


func _on_animated_sprite_2d_frame_changed() -> void:
	if anim.animation == "Run":
		# Check if the animation just reached frame 1 or frame 3 
		# (Change these numbers to whichever frames the foot actually hits the floor!)
		if anim.frame == 1 or anim.frame == 3:
			if $RunSFX: $RunSFX.play()
