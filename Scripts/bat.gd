extends CharacterBody2D

# --- BAT STATS ---
@export var max_hp: int = 3
var current_hp: int = 0
var is_dead: bool = false
var is_flinching: bool = false 

# --- TETHER SETTINGS ---
@export var max_chase_distance: float = 230.0 
var spawn_position: Vector2 = Vector2.ZERO

# --- CHASE & ATTACK SETTINGS ---
const SPEED = 120.0 
var player = null
enum State { IDLE, CHASE, ATTACK }
var current_state = State.IDLE

# --- SETTINGS ---
@export var flinch_duration: float = 0.3 
@export var start_facing_left: bool = false 

# --- NODE REFERENCES ---
@onready var anim = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	current_hp = max_hp
	anim.play("Fly") 
	
	if start_facing_left:
		anim.flip_h = true
		
	# FIX 1: Moved this OUTSIDE the 'if' statement! Now it always remembers home.
	spawn_position = global_position 

func _physics_process(_delta):
	if is_dead:
		return
		
	if is_flinching:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	# --- STATE MACHINE (IDLE, CHASE, ATTACK) ---
	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
			anim.play("Fly") 
			
		State.CHASE:
			if player:
				# Check if we went too far from home
				if global_position.distance_to(spawn_position) > max_chase_distance:
					teleport_home()
				else:
					var direction = global_position.direction_to(player.global_position)
					
					# FIX 2: Proper flying movement
					velocity = direction * SPEED 
					
					# FIX 3: Proper flying animation
					anim.play("Fly") 
					
					if velocity.x > 0:
						anim.flip_h = false
					elif velocity.x < 0:
						anim.flip_h = true
			else:
				current_state = State.IDLE
				
		State.ATTACK:
			velocity = Vector2.ZERO
			anim.play("Attack") 

	move_and_slide()

# --- HEALTH SYSTEM ---
func take_damage(amount: int):
	if is_dead or current_hp <= 0:
		return
		
	current_hp -= amount
	print("Bat hit! HP left: ", current_hp)
	
	if current_hp <= 0:
		die()
		return 

	is_flinching = true 
	anim.play("Hit") 
	get_tree().create_timer(flinch_duration, false).timeout.connect(_on_flinch_finished)

func _on_flinch_finished():
	if not is_dead:
		is_flinching = false

func die():
	is_dead = true
	collision_shape.set_deferred("disabled", true) 
	anim.play("Death")
	await anim.animation_finished
	queue_free()
	
# --- NEW TETHER FUNCTION ---
func teleport_home():
	global_position = spawn_position 
	current_state = State.IDLE       
	player = null                    
	velocity = Vector2.ZERO
	# FIX 4: Proper reset animation
	anim.play("Fly") 

# --- DETECTION & ATTACK SIGNALS ---
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		if current_state != State.ATTACK:
			current_state = State.CHASE

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		current_state = State.IDLE

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		current_state = State.ATTACK
		
		# NEW: Tell the player to take damage/die!
		if body.has_method("player_death"):
			body.player_death()

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body == player:
		current_state = State.CHASE
