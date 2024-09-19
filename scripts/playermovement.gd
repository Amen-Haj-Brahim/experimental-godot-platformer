extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -350.0
const DASH_SPEED = 650.0
const MAX_FALL_SPEED=500.0

@export_range(0,1) var acceleration=0.1
@export_range(0,1) var deceleration=0.1
@export_range(0,1) var decelerate_jump=0.5
@export var coyote_time=.1
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var jump_buffer_timer=0.0
var can_dash=true
var dash_dir=1

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor(): 
		velocity += get_gravity() * delta
		
	# Get the input direction and handle the movement/deceleration.
	var direction=Input.get_vector("move_left","move_right","move_up","move_down")
	var facing=Input.get_axis("move_left","move_right")
	# Handle player actions.
	jump(delta)
	dash(direction,facing)
	player_move(direction)
	flip(direction)
	animations(direction)
	stomp()
	#speed up falling speed every tick by 2 until it reaches 400 and keep it constatn at 400
	if velocity.y>0:
		velocity.y+=2
		
	if velocity.y>MAX_FALL_SPEED:
		velocity.y=MAX_FALL_SPEED
	

	move_and_slide()

func player_move(direction):
	#player movement
	if direction[0]:
		velocity.x = move_toward(velocity.x, direction[0]*SPEED, SPEED*acceleration)
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

func dash(direction,facing):
	print("direction ",direction," velocity ",velocity," facing ",facing," dash dir ",dash_dir)
	if facing!=0:
		dash_dir=facing
	if Input.is_action_just_pressed("dash") and can_dash:
		if direction[1]!=0 and direction[0]==0:
			velocity.y=JUMP_VELOCITY
			print("vertical dash")
		elif direction[0]!=0 and direction[1]!=0:
			velocity=(DASH_SPEED*direction)*Vector2.ONE.normalized()
			print("diagonal dash")
		else:
			velocity.x=DASH_SPEED*dash_dir
			print("horizontal dash")
		#velocity.x=DASH_SPEED*dash_dir
		#velocity.y=DASH_SPEED*direction[1]
		can_dash=false
		$Timer.start()

func flip(direction):
	if direction[0]>0:
		animated_sprite_2d.flip_h=false
	elif direction[0]<0:
		animated_sprite_2d.flip_h=true

func animations(direction):
	# Animations
	if is_on_floor():
		if direction[0]==0:
			animated_sprite_2d.play("idle")
		else:
			animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("jump")


func _on_timer_timeout() -> void:
	can_dash=true
func stomp():
	if Input.is_action_just_pressed("stomp") and not is_on_floor():
		velocity.y=MAX_FALL_SPEED
