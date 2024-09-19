extends CharacterBody2D

const SPEED = 210.0
const JUMP_VELOCITY = -350.0
const DASH_SPEED = 400.0
const MAX_FALL_SPEED=500.0
const MAX_SPEED=500.0
@onready var dash_effect: GPUParticles2D = $GPUParticles2D
@onready var run_effect: GPUParticles2D = $GPUParticles2D2
@export_range(0,1) var acceleration=0.1
@export_range(0,1) var deceleration=0.1
@export_range(0,1) var decelerate_jump=0.6
@export var coyote_time=.1
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var jump_buffer_timer=0.0
var can_dash=true
var dash_dir=1
var gravity_disabled=false
var is_stomping=false

func _ready() -> void:
	dash_effect.emitting=false

func _physics_process(delta):
	if velocity.x!=0:
		run_effect.emitting=true
	else:
		run_effect.emitting=false
	# Add the gravity.
	if not is_on_floor(): 
		velocity += get_gravity() * delta
	if is_on_floor():
		can_dash=true
		is_stomping=false
	if gravity_disabled==true:
		velocity.y=0	
	# Get the input direction and handle the movement/deceleration.
	var horizontal=Input.get_axis("move_left","move_right")
	var vertical=Input.get_axis("move_up","move_down")
	print(horizontal,vertical)
	#speed up falling speed every tick by 2 until it reaches 400 and keep it constatn at 400
	if velocity.y>0:
		velocity.y+=20
	if velocity.y>MAX_FALL_SPEED:
		velocity.y=MAX_FALL_SPEED
	if abs(velocity.x)>MAX_SPEED:
		velocity.x=MAX_SPEED*horizontal
	# Handle player actions.
	jump(delta)
	dash(horizontal,vertical)
	player_move(horizontal)
	flip(horizontal)
	animations(horizontal)
	stomp()

	move_and_slide()

func player_move(direction):
	#player movement
	if direction:
		velocity.x = move_toward(velocity.x, direction*SPEED, SPEED*acceleration)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED*deceleration)

func jump(delta):
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer=0.2
	jump_buffer_timer-=delta
	
	if (is_on_floor() or is_on_wall())and jump_buffer_timer>0 :
		jump_buffer_timer=0.0
		velocity.y = JUMP_VELOCITY
		
	if Input.is_action_just_released("jump") and velocity.y<0:
		jump_buffer_timer=0.0
		velocity.y*=decelerate_jump

func dash(horizontal,vertical):
	if horizontal!=0:
		dash_dir=horizontal
	if Input.is_action_just_pressed("dash") and can_dash:
		dash_effect.emitting=true
		if vertical!=0 and horizontal==0:
			
			velocity.y=-DASH_SPEED
		elif horizontal!=0 and vertical!=0:
			print("here2")
			velocity=(DASH_SPEED*Vector2(horizontal,vertical))
		else:
			velocity.x=DASH_SPEED*1.3*dash_dir
			disable_gravity()
		can_dash=false
		$Timer.start()
	#print(velocity,is_stomping)

func disable_gravity():
	$GravityTimer.start()
	gravity_disabled=true

func flip(direction):
	if direction>0:
		dash_effect.scale.x=1
		run_effect.scale.x=1
		animated_sprite_2d.flip_h=false
	elif direction<0:
		run_effect.scale.x=-1
		dash_effect.scale.x=-1
		animated_sprite_2d.flip_h=true

func animations(direction):
	# Animations
	if is_on_floor():
		if direction==0:
			animated_sprite_2d.play("idle")
		else:
			animated_sprite_2d.play("run")
	if !is_on_floor():
		if is_stomping:
			animated_sprite_2d.play("stomp")
		else:
			animated_sprite_2d.play("jump")

func _on_timer_timeout() -> void:
	dash_effect.emitting=false
	can_dash=true

func stomp():
	print(is_stomping)
	if Input.is_action_just_pressed("stomp") and not is_on_floor():
		gravity_disabled=false
		velocity.y=MAX_FALL_SPEED
		is_stomping=true

func _on_gravity_timer_timeout() -> void:
	gravity_disabled=false
