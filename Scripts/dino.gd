extends CharacterBody2D

# --- DINO STATS ---
@export var max_hp: int = 5
var current_hp: int = 0
var is_dead: bool = false
var is_flinching: bool = false

# --- TETHER SETTINGS ---
@export var max_chase_distance: float = 230.0 
var spawn_position: Vector2 = Vector2.ZERO

# --- CHASE & ATTACK SETTINGS ---
const SPEED = 100.0
var player = null
enum State { IDLE, CHASE, ATTACK }
var current_state = State.IDLE

# --- SETTINGS ---
@export var flinch_duration: float = 0.3 
@export var start_facing_left: bool = false 

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var anim = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	current_hp = max_hp
	anim.play("Idle") 
	
	if start_facing_left:
		anim.flip_h = true
		
	# FIX 1: Moved this OUTSIDE the 'if' statement! Now it always remembers home.
	spawn_position = global_position 

func _physics_process(delta):
	if is_dead:
		return
		
	if not is_on_floor():
		velocity.y += gravity * delta
		
	if is_flinching:
		velocity.x = 0
		move_and_slide()
		return
		
	# --- STATE MACHINE (IDLE, CHASE, ATTACK) ---
	match current_state:
		State.IDLE:
			velocity.x = 0
			anim.play("Idle")
			
		State.CHASE:
			if player:
				# Check if we went too far from home!
				if global_position.distance_to(spawn_position) > max_chase_distance:
					teleport_home()
				else:
					var direction = global_position.direction_to(player.global_position)
					velocity.x = sign(direction.x) * SPEED 
					
					anim.play("Walk") 
					
					if velocity.x > 0:
						anim.flip_h = false
					elif velocity.x < 0:
						anim.flip_h = true
			else:
				current_state = State.IDLE
				
		State.ATTACK:
			velocity.x = 0
			anim.play("Attack") 

	move_and_slide()

# --- HEALTH SYSTEM ---
func take_damage(amount: int):
	if is_dead or current_hp <= 0:
		return
		
	current_hp -= amount
	print("Dino hit! HP left: ", current_hp)
	
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
	anim.play("Idle") 

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
		
		# FIX 2: Added this so the Dino actually hurts the player when it bites!
		if body.has_method("player_death"):
			body.player_death()

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body == player:
		current_state = State.CHASE
