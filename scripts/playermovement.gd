extends CharacterBody2D

const SPEED = 210.0
const JUMP_VELOCITY = -375.0
const DASH_SPEED = 400.0
const MAX_FALL_SPEED=500.0
const MAX_SPEED=500.0
const STOMP_MAX_FALL_SPEED=700.0
const MAX_WALL_FALL_SPEED=50.0
@onready var dash_effect: GPUParticles2D = $GPUParticles2D
@onready var run_effect: GPUParticles2D = $GPUParticles2D2
@onready var stomp_effect: GPUParticles2D = $GPUParticles2D3

@export_range(0,1) var acceleration=0.1
@export_range(0,1) var deceleration=0.1
@export_range(0,1) var decelerate_jump=0.6

var buffered_jump_press=false
var jump_buffer_time=0.2
var can_coyote_jump=true
@export var coyote_time=0.3
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var can_dash=true
var dash_dir=1
var gravity_disabled=false
var is_stomping=false
var height_last_tick=0
var height_this_tick=0


func _ready() -> void:
	dash_effect.emitting=false
	stomp_effect.emitting=false

func _physics_process(delta):
	# for detecting the instant the player touches the ground
	height_last_tick=height_this_tick
	height_this_tick=velocity.y
	# when not on ground
	if not is_on_floor():
		coyoteTime()
		#set dash cd to 1 second when on ground
		$Timer.wait_time=1
		# usual gravity stuff
		velocity += get_gravity() * delta
	# when on ground
	if is_on_floor() or is_on_wall():
		# give back ability to jump
		can_coyote_jump=true
		# detect momemnt we contact the ground and give ability to dash
		if height_this_tick==0 and height_last_tick!=0:
			can_dash=true
		# make dash cd shorter to 0.2s
		$Timer.wait_time=0.2
		#stomp stomping if we're stomping
		is_stomping=false
	#disable gravity
	if gravity_disabled==true:
		velocity.y=0	
	# Get the input direction and handle the movement/deceleration.
	var horizontal=Input.get_axis("move_left","move_right")
	var vertical=Input.get_axis("move_up","move_down")
	
	if is_on_wall() and velocity.y>MAX_WALL_FALL_SPEED:
		velocity.y=MAX_WALL_FALL_SPEED
	
	#speed up falling speed every tick by 2 until it reaches 400 and keep it constatn at 400
	if velocity.y>0:
		velocity.y+=20
	if velocity.y>MAX_FALL_SPEED:
		if is_stomping:
			velocity.y=STOMP_MAX_FALL_SPEED
		else:
			velocity.y=MAX_FALL_SPEED
	if abs(velocity.x)>MAX_SPEED:
		velocity.x=MAX_SPEED*horizontal
	# Handle function calls.
	jump()
	dash(horizontal,vertical)
	player_move(horizontal)
	flip(horizontal)
	animations(horizontal)
	stomp()
	emit_stomp()
	emit_run()
	move_and_slide()

func player_move(direction):
	#player movement
	if direction:
		velocity.x = move_toward(velocity.x, direction*SPEED, SPEED*acceleration)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED*deceleration)

func coyoteTime():
	await get_tree().create_timer(coyote_time).timeout
	can_coyote_jump=false

func jump():
	# handle buffered jump
	if buffered_jump_press and is_on_floor():
		velocity.y = JUMP_VELOCITY
		can_coyote_jump=false
	# jump on press and disable coyote time to prevent accidental double jumping
	if Input.is_action_just_pressed("jump"):
		buffered_jump_press=true
		buffer_jump()
		if can_coyote_jump:
			velocity.y = JUMP_VELOCITY
			can_coyote_jump=false
	# decelerate jump gradually
	if Input.is_action_just_released("jump") and velocity.y<0:
		velocity.y*=decelerate_jump

func buffer_jump():
	await get_tree().create_timer(jump_buffer_time).timeout
	buffered_jump_press=false

func wall_jump():
	pass

func dash(horizontal,vertical):
	# dash direction for when player isn't moving
	if horizontal!=0:
		dash_dir=horizontal
	# 3 possible dashes
	if Input.is_action_just_pressed("dash") and can_dash:
		# emit effect regardless of what dash
		dash_effect.emitting=true
		# vertical dash
		if vertical!=0 and horizontal==0:
			velocity.y=DASH_SPEED*vertical
		# diagonal dash
		elif horizontal!=0 and vertical!=0:
			velocity=(DASH_SPEED*Vector2(horizontal,vertical))
		# horizontal dash and disable gravity for a short time
		else:
			velocity.x=DASH_SPEED*1.3*dash_dir
			disable_gravity()
		# set can_dash to false and start cd timer and effect timer
		can_dash=false
		$Timer.start()
		$ghosteffecttimer.start()
		dash_effect.emitting=true

func disable_gravity():
	$GravityTimer.start()
	gravity_disabled=true

func flip(direction):
	if direction>0:
		stomp_effect.scale.x=1
		dash_effect.scale.x=1
		run_effect.scale.x=1
		animated_sprite_2d.flip_h=false
	elif direction<0:
		stomp_effect.scale.x=-1
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

func stomp():
	if Input.is_action_just_pressed("stomp") and not is_on_floor():
		gravity_disabled=false
		velocity.y=MAX_FALL_SPEED
		is_stomping=true

func emit_stomp():
	if is_stomping:
		stomp_effect.emitting=true
	else:
		stomp_effect.emitting=false

func emit_run():
	if velocity.x!=0:
		run_effect.emitting=true
	else:
		run_effect.emitting=false

func _on_timer_timeout() -> void:
	dash_effect.emitting=false
	can_dash=true

func _on_gravity_timer_timeout() -> void:
	gravity_disabled=false

func _on_ghosteffecttimer_timeout() -> void:
	dash_effect.emitting=false
