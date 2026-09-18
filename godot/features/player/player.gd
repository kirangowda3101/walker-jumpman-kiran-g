extends CharacterBody2D

const Tuning = preload("res://features/player/tuning.gd")
var tuning = Tuning.new()
var enabled: bool = false
var tick: int = 0
var last_floor_tick: int = -1000
var jump_request_tick: int = -1000
var opportunity_consumed: bool = false
var require_jump_release: bool = true
var facing: float = 1.0
var jumps: int = 0
var test_control: bool = false
var test_axis: float = 0.0
var test_jump_pressed: bool = false
var test_jump_held: bool = false

func _ready() -> void:
	name = "Player"
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 1.0
	var shape := RectangleShape2D.new()
	shape.size = Vector2(18, 28)
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = Vector2(0, -14)
	add_child(collider)

func reset_at(spawn: Vector2) -> void:
	position = spawn
	velocity = Vector2.ZERO
	last_floor_tick = -1000
	jump_request_tick = -1000
	opportunity_consumed = false
	require_jump_release = true
	test_jump_pressed = false
	jumps = 0
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	tick += 1
	var axis := test_axis if test_control else Input.get_axis("move_left", "move_right")
	var held := test_jump_held if test_control else Input.is_action_pressed("jump")
	var pressed := test_jump_pressed if test_control else Input.is_action_just_pressed("jump")
	test_jump_pressed = false
	if not held:
		require_jump_release = false
	if is_on_floor() and velocity.y >= 0.0:
		last_floor_tick = tick
		opportunity_consumed = false
	if pressed and not require_jump_release:
		jump_request_tick = tick
	var rate: float = tuning.acceleration if not is_zero_approx(axis) else tuning.deceleration
	velocity.x = move_toward(velocity.x, axis * tuning.speed, rate * delta)
	if not is_zero_approx(axis):
		facing = signf(axis)
	velocity.y = minf(velocity.y + tuning.gravity * delta, tuning.terminal_velocity)
	if not opportunity_consumed and tick - last_floor_tick <= tuning.coyote_ticks and tick - jump_request_tick <= tuning.buffer_ticks:
		velocity.y = tuning.jump_velocity
		opportunity_consumed = true
		jump_request_tick = -1000
		jumps += 1
	move_and_slide()
	position.x = maxf(position.x, 10.0)
	queue_redraw()

func _draw() -> void:
	var ink := Color("161d28")
	var cloth := Color("33405a")
	var sash := Color("c0453c")
	var steel := Color("c9d2da")
	var glow := Color("fff3d0")
	var airborne := not is_on_floor()
	var moving := is_on_floor() and absf(velocity.x) > 8
	var stride := sin(float(tick) * 0.7) * 2.0 if moving else 0.0
	var sway := sin(float(tick) * 0.3) * 1.2

	# mirror everything below when facing left
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(signf(facing), 1.0))

	# sword across the back, drawn first so the torso covers its middle
	draw_line(Vector2(-10, -7), Vector2(-3, -27), ink, 3.0)
	draw_line(Vector2(-4, -26), Vector2(-2, -29), steel, 2.0)

	# headband tail, trailing behind and waving
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5, -25), Vector2(-10, -23 + sway),
		Vector2(-11, -21 + sway), Vector2(-5, -22)
	]), sash)

	# hood: narrow crown flaring out to the shoulders
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4, -28), Vector2(4, -28), Vector2(7, -23),
		Vector2(6, -17), Vector2(-6, -17), Vector2(-7, -23)
	]), ink)

	# eye slit
	draw_rect(Rect2(0, -24, 6, 3), glow)
	draw_rect(Rect2(3, -24, 2, 3), ink)

	# torso
	draw_rect(Rect2(-9, -17, 18, 11), ink)
	draw_rect(Rect2(-7, -15, 14, 7), cloth)

	# lead arm, swinging opposite the legs
	draw_rect(Rect2(4, -15 - stride * 0.5, 4, 7), ink)

	# sash and its hanging knot
	draw_rect(Rect2(-10, -12, 20, 3), sash)
	draw_rect(Rect2(-8, -9, 2, 4 + sway * 0.5), sash)

	# legs, with a tucked pose in the air
	if airborne:
		draw_rect(Rect2(1, -7, 5, 4), ink)
		draw_rect(Rect2(-6, -6, 5, 6), ink)
		draw_rect(Rect2(1, -3, 6, 2), cloth)
		draw_rect(Rect2(-6, -2, 6, 2), cloth)
	else:
		draw_rect(Rect2(-6, -6, 5, 6 + stride), ink)
		draw_rect(Rect2(2, -6, 5, 6 - stride), ink)
		draw_rect(Rect2(-6, -2 + stride, 6, 2), cloth)
		draw_rect(Rect2(2, -2 - stride, 6, 2), cloth)
