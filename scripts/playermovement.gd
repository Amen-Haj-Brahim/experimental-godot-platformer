extends CharacterBody2D


const SPEED = 200.0
const JUMP_VELOCITY = -350.0
var can_double_jump=true
@export_range(0,1) var acceleration=0.1
@export_range(0,1) var deceleration=0.1
@export_range(0,1) var decelerate_jump=0.5
@export var coyote_time=.1
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var jump_buffer_timer=0.0

func jump(delta):
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer=0.2
	jump_buffer_timer-=delta
	
	if (is_on_floor() or is_on_wall())and jump_buffer_timer>0 :
		jump_buffer_timer=0.0
		velocity.y = JUMP_VELOCITY
		
	if (not is_on_floor() and can_double_jump and jump_buffer_timer>0):
		jump_buffer_timer=0.0
		velocity.y = JUMP_VELOCITY
		can_double_jump=false
		
	if Input.is_action_just_released("jump") and velocity.y<0:
		jump_buffer_timer=0.0
		velocity.y*=decelerate_jump

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor(): 
		velocity += get_gravity() * delta
	if is_on_floor():
		can_double_jump=true
	# Handle jump.
	jump(delta)
	
	print(velocity.y)
	
	if velocity.y>400:
		velocity.y=400
		
	if velocity.y>0:
		velocity.y+=2
	# Get the input direction and handle the movement/deceleration.
	var direction  = Input.get_axis("move_left", "move_right")
	if direction>0:
		animated_sprite_2d.flip_h=false
	elif direction<0:
		animated_sprite_2d.flip_h=true
	# Animations
	if is_on_floor():
		if direction==0:
			animated_sprite_2d.play("idle")
		else:
			animated_sprite_2d.play("run")
			
	else:
		animated_sprite_2d.play("jump")
	if direction:
		velocity.x = move_toward(velocity.x, direction*SPEED, SPEED*acceleration)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED*deceleration)

	move_and_slide()
