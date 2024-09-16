extends CharacterBody2D


const SPEED = 150.0
const JUMP_VELOCITY = -300.0
@export_range(0,1) var acceleration=0.1
@export_range(0,1) var deceleration=0.1
@export_range(0,1) var decelerate_jump=0.5
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor(): 
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and (is_on_floor() or is_on_wall()):
		velocity.y = JUMP_VELOCITY
	if Input.is_action_just_released("jump") and velocity.y<0:
		velocity.y*=decelerate_jump
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction  = Input.get_axis("move_left", "move_right")
	
	if direction>0:
		animated_sprite_2d.flip_h=false
	elif direction<0:
		animated_sprite_2d.flip_h=true
		
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
