extends CharacterBody2D

const SPEED = 165.0
const JUMP_VELOCITY = -350.0
const DASH_SPEED = 400.0
const MAX_FALL_SPEED=500.0
const MAX_SPEED=400.0
@export_range(0,1) var acceleration=0.1
@export_range(0,1) var deceleration=0.1
@export_range(0,1) var decelerate_jump=0.6
@export var coyote_time=.1
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var jump_buffer_timer=0.0
var can_dash=true
var dash_dir=1
var gravity_disabled=false

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor(): 
		velocity += get_gravity() * delta
	if is_on_floor():
		can_dash=true
	if gravity_disabled==true:
		velocity.y=0	
	# Get the input direction and handle the movement/deceleration.
	var horizontal=Input.get_axis("move_left","move_right")
	var vertical=Input.get_axis("move_up","move_down")
	print(horizontal,vertical)
	#speed up falling speed every tick by 2 until it reaches 400 and keep it constatn at 400
	if velocity.y>0:
		velocity.y+=2
	if velocity.y>MAX_FALL_SPEED:
		velocity.y=MAX_FALL_SPEED
	if velocity.x>MAX_SPEED:
		velocity.x=MAX_SPEED
	# Handle player actions.
	jump(delta)
	dash(horizontal,vertical)
	player_move(horizontal,vertical)
	flip(horizontal)
	animations(horizontal)
	stomp()

	move_and_slide()

func player_move(direction,facing):
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
	#print(can_dash," direction ",direction," velocity ",velocity, "dash dir ",dash_dir)
	if horizontal!=0:
		dash_dir=horizontal
	if Input.is_action_just_pressed("dash") and can_dash:
		if vertical!=0 and horizontal==0:
			velocity.y=-DASH_SPEED
			print("vertical dash")
		elif horizontal!=0 and vertical!=0:
			velocity=(DASH_SPEED*Vector2(horizontal,vertical))
			print("diagonal dash")
		else:
			velocity.x=(DASH_SPEED*1.1)*dash_dir
			disable_gravity()
			#velocity.move_toward(Vector2(velocity.x+DASH_SPEED,velocity.y)*dash_dir,1)
			print("horizontal dash")
		can_dash=false
		$Timer.start()
	print(velocity)

func disable_gravity():
	$GravityTimer.start()
	gravity_disabled=true
	
func flip(direction):
	if direction>0:
		animated_sprite_2d.flip_h=false
	elif direction<0:
		animated_sprite_2d.flip_h=true

func animations(direction):
	# Animations
	if is_on_floor():
		if direction==0:
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


func _on_gravity_timer_timeout() -> void:
	gravity_disabled=false
