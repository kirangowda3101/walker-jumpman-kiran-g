extends SceneTree
## Walkthrough capture driver — walker-jumpman-kiran-g
##
## Drives the REAL main-scene session through the REAL input path:
##   * held movement / jump  -> Input.parse_input_event()  (updates action state
##                              that player.gd polls via Input.get_axis /
##                              Input.is_action_just_pressed)
##   * discrete UI keys      -> SubViewport.push_input()   (delivered to
##                              session.gd::_unhandled_input)
##
## It never teleports the player, never writes velocity/position/state, never
## sets completion, never touches collision layers, and never uses the
## test_control / test_axis / test_jump_pressed hooks that tests/route_driver.gd
## relies on. It may READ player.position and game.state to decide when to press
## a key — that is observation, not a gameplay shortcut.
##
## Rendering: the session runs inside a 3840x2160 SubViewport. Camera2D zoom 6
## and a 6x CanvasLayer transform reproduce the project's own `canvas_items`
## stretch from its 640x360 logical canvas, so the framing is identical to a
## normal run and every pixel is rendered natively at 4K (all art is vector
## draw_* calls, so this is real resolution, not an upscale).
##
## Usage:
##   Godot --path <capture-project> --script res://capture_driver.gd \
##         --fixed-fps 60 --resolution 1280x720 -- <run-id> <out-dir>

const Game = preload("res://game/session.gd")

const OUT_W := 3840
const OUT_H := 2160
const STRETCH := 6.0
const PHYS_HZ := 60.0

var sub: SubViewport
var game: Node2D
var run_id := "probe"
var out_dir := ""
var frames_dir := ""
var log_path := ""
var log_buf: PackedStringArray = PackedStringArray()
var tick := 0
var frame_no := 0
var capturing := false
var failures: PackedStringArray = PackedStringArray()
var last_ground_tick := -1000

# ---------------------------------------------------------------- lifecycle

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		run_id = args[0]
	if args.size() > 1:
		out_dir = args[1]
	else:
		out_dir = ProjectSettings.globalize_path("user://capture")
	call_deferred("main")

func main() -> void:
	frames_dir = out_dir + "/" + run_id + "-frames"
	DirAccess.make_dir_recursive_absolute(frames_dir)
	log_path = out_dir + "/" + run_id + "-inputs.jsonl"
	_boot()
	match run_id:
		"probe": await run_probe()
		"run-01": await run_01()
		"run-02": await run_02()
		"run-03": await run_03()
		"run-04": await run_04()
		"run-05": await run_05()
		_:
			failures.append("unknown run id: " + run_id)
	_flush_log()
	print("CAPTURE %s: ticks=%d frames=%d" % [run_id, tick, frame_no])
	if failures.is_empty():
		print("CAPTURE OK")
		quit(0)
	else:
		for f in failures:
			printerr("CAPTURE FAILURE: " + f)
		quit(3)

func _boot() -> void:
	sub = SubViewport.new()
	sub.size = Vector2i(OUT_W, OUT_H)
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub.handle_input_locally = true
	sub.transparent_bg = false
	sub.disable_3d = true
	root.add_child(sub)
	game = Game.new()
	sub.add_child(game)
	# Unattended capture: an OS focus change must not silently pause a take.
	# run-05 re-enables the real behaviour and demonstrates it on camera.
	game.test_mode = (run_id != "run-05")
	game.camera.zoom = Vector2(STRETCH, STRETCH)
	var layer := game.hud.get_parent() as CanvasLayer
	layer.transform = Transform2D().scaled(Vector2(STRETCH, STRETCH))
	print("BOOT viewport=%dx%d camera_zoom=%s level_width=%d finish=%s" % [
		sub.size.x, sub.size.y, str(game.camera.zoom), int(game.level.width),
		str(game.level.finish)])

# ---------------------------------------------------------------- frame loop

func step() -> void:
	await physics_frame
	await process_frame
	tick += 1
	if game != null and game.player.is_on_floor():
		last_ground_tick = tick
	if capturing and tick % 2 == 0:
		await RenderingServer.frame_post_draw
		var image := sub.get_texture().get_image()
		var err := image.save_png("%s/%06d.png" % [frames_dir, frame_no])
		if err != OK:
			failures.append("png save failed at frame %d" % frame_no)
		frame_no += 1

func roll() -> void:
	capturing = true
	log_event("capture_start", "", "")

func cut() -> void:
	capturing = false
	log_event("capture_stop", "", "")

func wait(ticks: int) -> void:
	for i in range(ticks):
		await step()

## Run until `test` returns true. Returns false (and records a failure) on timeout.
func until(test: Callable, limit: int, label: String) -> bool:
	if not failures.is_empty():
		return false  # first timeout aborts the take; don't burn frames after it
	for i in range(limit):
		if test.call():
			return true
		await step()
	failures.append("timeout waiting for %s (x=%.1f y=%.1f state=%d)" % [
		label, game.player.position.x, game.player.position.y, game.state])
	return false

# ---------------------------------------------------------------- input

func _key(code: int, pressed: bool) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.pressed = pressed
	return ev

## Held gameplay keys: drive the polled action state player.gd reads.
func down(code: int, action: String) -> void:
	Input.parse_input_event(_key(code, true))
	Input.flush_buffered_events()
	log_event("key_down", action, OS.get_keycode_string(code))

func up(code: int, action: String) -> void:
	Input.parse_input_event(_key(code, false))
	Input.flush_buffered_events()
	log_event("key_up", action, OS.get_keycode_string(code))

## Discrete UI keys: delivered as events to session.gd::_unhandled_input.
func tap_ui(code: int, action: String) -> void:
	sub.push_input(_key(code, true))
	sub.push_input(_key(code, false))
	log_event("key_tap", action, OS.get_keycode_string(code))

func jump() -> void:
	down(KEY_SPACE, "jump")
	await step()
	await step()
	up(KEY_SPACE, "jump")

## Jump the moment the player is grounded at or past `x` (observation only).
## `is_on_floor()` flickers off for single frames while running along a flat
## slab, so "grounded" here means "touched the floor within the last 3 ticks" —
## the same tolerance the game's own coyote window applies to the player.
func jump_at(x: float, limit: int = 600) -> void:
	var ok := await until(
		func(): return game.player.position.x >= x and tick - last_ground_tick <= 3,
		limit, "grounded at x>=%.0f" % x)
	if ok:
		await jump()

## Forward-integrate the player's fall exactly as player.gd does, to answer
## "how many ticks until the feet reach target_y?". Observation only — it
## chooses when to press a key, it never writes player state.
func predicted_ticks_to_y(target_y: float) -> int:
	var y: float = game.player.position.y
	var vy: float = game.player.velocity.y
	var dt := 1.0 / PHYS_HZ
	for n in range(1, 120):
		vy = minf(vy + game.player.tuning.gravity * dt, game.player.tuning.terminal_velocity)
		y += vy * dt
		if y >= target_y:
			return n
	return 999

func click_start() -> void:
	var at := Vector2(320.0, 232.0) * STRETCH
	var motion := InputEventMouseMotion.new()
	motion.position = at
	sub.push_input(motion)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = at
	press.pressed = true
	sub.push_input(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = at
	release.pressed = false
	sub.push_input(release)
	log_event("mouse_click", "start_button", "LMB @ hud(320,232)")

# ---------------------------------------------------------------- logging

const STATE_NAMES := ["MENU", "PLAYING", "PAUSED", "DYING", "COMPLETE"]

func log_event(kind: String, action: String, key: String) -> void:
	var row := {
		"run": run_id,
		"tick": tick,
		"t_s": snappedf(float(tick) / PHYS_HZ, 0.0001),
		"video_s": snappedf(float(frame_no) / 30.0, 0.0001) if capturing else null,
		"event": kind,
		"action": action,
		"key": key,
		"state": STATE_NAMES[game.state] if game != null else "",
		"player_x": snappedf(game.player.position.x, 0.01) if game != null else null,
		"player_y": snappedf(game.player.position.y, 0.01) if game != null else null,
		"on_floor": game.player.is_on_floor() if game != null else null,
		"axis": snappedf(Input.get_axis("move_left", "move_right"), 0.01),
		"vx": snappedf(game.player.velocity.x, 0.1) if game != null else null,
		"deaths": game.deaths if game != null else null,
		"elapsed_s": snappedf(game.elapsed, 0.01) if game != null else null,
	}
	log_buf.append(JSON.stringify(row))

func note(text: String) -> void:
	log_event("note", text, "")

func _flush_log() -> void:
	var f := FileAccess.open(log_path, FileAccess.WRITE)
	if f == null:
		failures.append("cannot write input log: " + log_path)
		return
	for line in log_buf:
		f.store_line(line)
	f.close()

func expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

# ---------------------------------------------------------------- routes

func run_probe() -> void:
	roll()
	await wait(40)
	note("menu visible")
	tap_ui(KEY_ENTER, "confirm")
	await wait(4)
	expect(game.state == Game.State.PLAYING, "ENTER did not start the session")
	note("session started via ENTER")
	down(KEY_D, "move_right")
	await wait(50)
	await jump()
	await wait(40)
	up(KEY_D, "move_right")
	await wait(20)
	tap_ui(KEY_ESCAPE, "pause")
	await wait(6)
	expect(game.state == Game.State.PAUSED, "ESC did not pause (state=%d) — check for double delivery" % game.state)
	note("paused")
	tap_ui(KEY_ENTER, "confirm")
	await wait(6)
	expect(game.state == Game.State.PLAYING, "ENTER did not resume (state=%d)" % game.state)
	note("resumed")
	cut()

## run-01 — the high route, start to completion to replay.
func run_01() -> void:
	roll()
	await wait(75)
	note("title card / menu")
	tap_ui(KEY_ENTER, "confirm")
	await wait(6)
	expect(game.state == Game.State.PLAYING, "ENTER did not start the session")
	note("zone 01 — walk, then stop")
	# short burst: stop well clear of the step at x=160 so what the viewer
	# sees is deceleration, not a body jammed against a wall
	down(KEY_D, "move_right")
	await wait(28)
	up(KEY_D, "move_right")
	await wait(24)
	note("released the key: decelerates to a stop, running pose drops to standing")
	# face left to show the whole figure mirror: sword and headband swap sides.
	# The west-boundary clamp is demonstrated in run-04, not here — walking to
	# x=10 shifts every downstream jump mark and makes this take nondeterministic.
	down(KEY_A, "move_left")
	await wait(20)
	up(KEY_A, "move_left")
	await wait(20)
	note("faced left: the canvas mirror flips sword, headband and pupil")
	down(KEY_D, "move_right")
	# the starter's five marks, then the five added for the extension
	for mark in [138.0, 292.0, 424.0, 548.0, 712.0, 900.0, 1010.0, 1085.0, 1175.0, 1450.0]:
		await jump_at(mark)
	var done := await until(func(): return game.state == Game.State.COMPLETE, 600, "completion")
	up(KEY_D, "move_right")
	expect(done, "high route did not complete")
	expect(game.deaths == 0, "high route took %d deaths" % game.deaths)
	note("course complete in %.1fs with %d retries" % [game.last_finish_time, game.deaths])
	await wait(120)
	tap_ui(KEY_ENTER, "confirm")
	await wait(6)
	expect(game.state == Game.State.PLAYING, "ENTER did not replay")
	note("replay: timer and progress reset")
	await wait(60)
	cut()

## run-02 — failure and recovery: spike death, fall death, manual restart,
## pause/resume, main menu, and the mouse start button.
func run_02() -> void:
	roll()
	await wait(54)
	click_start()
	await wait(8)
	expect(game.state == Game.State.PLAYING, "mouse click on START did not begin the session")
	note("started with the mouse button, not the keyboard")
	# --- spike death: clear the 16px step at x=160, then walk into the
	#     zone-01 spike cluster at x=320 without jumping over it
	down(KEY_D, "move_right")
	await jump_at(138.0)
	var died := await until(func(): return game.state == Game.State.DYING, 400, "spike death")
	up(KEY_D, "move_right")
	expect(died, "did not reach the spike cluster")
	note("spike death: '%s', retries now %d" % [game.death_reason, game.deaths])
	await wait(50)
	var back := await until(func(): return game.state == Game.State.PLAYING, 120, "auto respawn")
	expect(back, "did not respawn automatically")
	note("auto respawn at spawn after 0.55s")
	await wait(30)
	# --- fall death: clear the step and the spikes, then run off the edge of
	#     the first slab at x=448 without jumping the 64px gap
	down(KEY_D, "move_right")
	await jump_at(138.0)
	await jump_at(292.0)
	var fell := await until(
		func(): return game.state == Game.State.DYING and game.death_reason == "Missed the landing",
		400, "fall death")
	up(KEY_D, "move_right")
	expect(fell, "did not fall past fall_y")
	note("fall death: '%s', retries now %d" % [game.death_reason, game.deaths])
	var back2 := await until(func(): return game.state == Game.State.PLAYING, 120, "auto respawn 2")
	expect(back2, "did not respawn after the fall")
	await wait(40)
	# --- manual restart: R does NOT increment the retry counter
	down(KEY_D, "move_right")
	await jump_at(138.0)
	await wait(40)
	up(KEY_D, "move_right")
	await wait(15)
	var before: int = game.deaths
	note("about to press R with %d retries on the counter" % before)
	tap_ui(KEY_R, "restart")
	await wait(20)
	expect(game.deaths == before, "R incremented the retry counter (%d -> %d)" % [before, game.deaths])
	expect(is_equal_approx(game.player.position.x, float(game.level.spawn[0])),
		"R did not return the player to spawn")
	note("R returned to spawn; retry counter unchanged at %d" % game.deaths)
	await wait(30)
	# --- pause, read the panel, resume
	down(KEY_D, "move_right")
	await jump_at(138.0)
	await wait(30)
	up(KEY_D, "move_right")
	tap_ui(KEY_ESCAPE, "pause")
	await wait(6)
	expect(game.state == Game.State.PAUSED, "ESC did not pause")
	note("paused: 'Take a breath.'")
	await wait(90)
	tap_ui(KEY_ENTER, "confirm")
	await wait(6)
	expect(game.state == Game.State.PLAYING, "ENTER did not resume")
	note("resumed")
	await wait(40)
	# --- pause again, then M back to the main menu
	tap_ui(KEY_P, "pause")
	await wait(6)
	expect(game.state == Game.State.PAUSED, "P did not pause")
	note("P pauses too, not just ESC")
	await wait(40)
	tap_ui(KEY_M, "menu")
	await wait(8)
	expect(game.state == Game.State.MENU, "M did not return to the main menu")
	note("M returned to the main menu")
	await wait(60)
	cut()

## run-03 — the ground route: see the flag, fail to reach it, climb at the far
## east end, and backtrack west to the finish.
## Waypoints taken from a breadth-first search over the project's own
## simulator (scripts/sim.py), then executed here through the real input path.
func run_03() -> void:
	roll()
	await wait(45)
	tap_ui(KEY_ENTER, "confirm")
	await wait(6)
	down(KEY_D, "move_right")
	# zones 01-02, identical to the high route up to the third gap
	for mark in [138.0, 292.0, 424.0, 548.0, 712.0]:
		await jump_at(mark)
	# cross the 40px gap onto the long ground slab and simply keep walking:
	# skipping the climb at x=1060 is what makes this the ground route
	await jump_at(900.0)
	var landed := await until(func(): return game.player.is_on_floor() and game.player.position.x > 1000.0,
		200, "landing on the long ground slab")
	expect(landed, "did not land on the long ground slab")
	note("stayed low: walked under the climb at x=1060 with 32px of headroom")
	# Clear four spike clusters while running under the high route's runway.
	# The runway leaves 80px of sky over the ground slab and a full jump needs
	# ~84, so each of these takeoffs bumps its head — the marks are pulled
	# early to buy arc, and every one is verified against +/-3px of jitter.
	for mark in [1180.0, 1311.0, 1439.0, 1559.0]:
		await jump_at(mark)
	note("under the shelf: the flag is overhead and there is no way up from here")
	await wait(45)
	# the only climb is past the far east end
	await jump_at(1724.0)
	var up1 := await until(func(): return game.player.is_on_floor() and game.player.position.y <= 280.0,
		240, "the step at x=1790")
	expect(up1, "did not land on the step at x=1790")
	note("landed on the step at x=1790, past the east end of the level")
	up(KEY_D, "move_right")
	await wait(8)
	# turn around and climb west onto the stepping stone, then the shelf
	down(KEY_A, "move_left")
	await wait(4)
	await jump()
	var up2 := await until(func(): return game.player.is_on_floor() and game.player.position.y <= 230.0,
		240, "the stepping stone at x=1700")
	expect(up2, "did not reach the stepping stone")
	note("climbed, then turned back west — the backtrack the level forces")
	await wait(15)
	await jump()
	var done := await until(func(): return game.state == Game.State.COMPLETE, 400, "ground completion")
	up(KEY_A, "move_left")
	expect(done, "ground route did not complete")
	note("ground route complete in %.1fs with %d retries" % [game.last_finish_time, game.deaths])
	await wait(110)
	cut()

## run-04 — the two timing features: coyote time and the input buffer.
## Both are 6-tick windows; a still frame cannot establish either, so the input
## log records the exact tick of every press against the ground contact.
func run_04() -> void:
	roll()
	await wait(48)
	tap_ui(KEY_ENTER, "confirm")
	await wait(6)
	# ---- the west boundary: player.gd clamps position.x to 10, it does not
	#      stop the body. Hold left into it and the figure stops while
	#      velocity.x stays pinned at -160.
	down(KEY_A, "move_left")
	var walled := await until(func(): return game.player.position.x <= 10.5, 180, "the west boundary")
	expect(walled, "did not reach the west boundary")
	await wait(26)
	expect(game.player.position.x >= 9.9 and game.player.position.x <= 10.1,
		"west clamp did not hold at x=10 (x=%.2f)" % game.player.position.x)
	note("held against the west boundary: x clamped at %.0f while velocity.x is still %.0f"
		% [game.player.position.x, game.player.velocity.x])
	up(KEY_A, "move_left")
	await wait(16)
	# ---- coyote: run off the edge of the first slab, press jump AFTER leaving it
	down(KEY_D, "move_right")
	await jump_at(138.0)
	await jump_at(292.0)
	var airborne := await until(
		func(): return (not game.player.is_on_floor() and game.player.position.x > 455.0
			and game.player.velocity.y > 0.0),
		600, "left the slab edge at x=448")
	expect(airborne, "never left the first slab")
	var left_at := last_ground_tick
	note("ran off the edge at tick %d with no jump pressed" % left_at)
	await wait(2)
	note("pressing jump %d ticks after the last ground contact — inside the 6-tick coyote window"
		% (tick - left_at))
	await jump()
	await wait(2)
	expect(game.player.velocity.y < 0.0,
		"coyote jump did not fire (vy=%.1f)" % game.player.velocity.y)
	note("coyote jump fired: the player is rising from mid-air")
	# ---- no double jump: press again at the apex, far outside the 6-tick
	#      buffer window, and nothing happens. The jump is spent.
	var apex := await until(func(): return game.player.velocity.y >= 0.0, 120, "the apex")
	expect(apex, "never reached the apex")
	down(KEY_SPACE, "jump")
	var vy_before: float = game.player.velocity.y
	await step()
	await step()
	up(KEY_SPACE, "jump")
	expect(game.player.velocity.y > vy_before,
		"a second mid-air jump fired (vy %.1f -> %.1f)" % [vy_before, game.player.velocity.y])
	note("pressed jump again at the apex: no second jump, still falling (vy=%.0f)"
		% game.player.velocity.y)
	var landed := await until(func(): return game.player.is_on_floor(), 200, "landing after coyote jump")
	expect(landed, "never landed after the coyote jump")
	note("landed on the far side of the gap, flush against the 32-high block")
	await wait(30)
	# A late coyote jump carries further than a normal one, so the landing is
	# pinned against the block's left face. Back off west for a clean run-up —
	# otherwise whether the next jump clears the block is a one-frame coin flip.
	up(KEY_D, "move_right")
	down(KEY_A, "move_left")
	var backed := await until(func(): return game.player.position.x <= 524.0, 120, "room for a run-up")
	up(KEY_A, "move_left")
	expect(backed, "could not back off for a run-up")
	await wait(12)
	note("backed off to x=%.0f for a full-speed run-up at the block" % game.player.position.x)
	down(KEY_D, "move_right")
	# ---- buffer: press jump in mid-air, inside the 6-tick window before the
	#      feet reach the block at x=576 (top y=288). The press is early; the
	#      engine holds it and spends it on the frame of contact.
	await jump_at(548.0)
	var about_to_land := await until(
		func(): return (not game.player.is_on_floor() and game.player.velocity.y > 0.0
			and predicted_ticks_to_y(288.0) <= 5),
		200, "5 ticks from landing on the block at x=576")
	expect(about_to_land, "never lined up a descent onto the block")
	down(KEY_SPACE, "jump")
	var press_tick := tick
	note("jump pressed at tick %d, still airborne, %d ticks from contact" % [
		press_tick, predicted_ticks_to_y(288.0)])
	var touched := await until(func(): return game.player.is_on_floor(), 40, "ground contact")
	expect(touched, "never touched the ground while the jump was buffered")
	note("ground contact at tick %d, %d ticks after the press" % [tick, tick - press_tick])
	await step()
	up(KEY_SPACE, "jump")
	expect(game.player.velocity.y < 0.0,
		"the buffered jump did not fire on contact (vy=%.1f)" % game.player.velocity.y)
	note("buffered jump fired on the contact frame: vy=%.0f" % game.player.velocity.y)
	await wait(22)
	up(KEY_D, "move_right")
	await wait(85)
	cut()

## run-05 — focus-loss auto-pause, with the real engine focus change.
## test_mode stays false here so session.gd::_on_focus_lost is live.
func run_05() -> void:
	roll()
	await wait(48)
	tap_ui(KEY_ENTER, "confirm")
	await wait(6)
	down(KEY_D, "move_right")
	await wait(60)
	expect(game.state == Game.State.PLAYING, "not playing before the focus test")
	note("playing, moving right, window focused")
	var thief := Window.new()
	thief.title = "focus"
	thief.size = Vector2i(320, 200)
	thief.position = Vector2i(40, 40)
	root.add_child(thief)
	thief.grab_focus()
	thief.move_to_foreground()
	log_event("focus_steal", "second window grabs focus", "")
	await wait(30)
	expect(game.state == Game.State.PAUSED,
		"window focus loss did not pause the game (state=%d)" % game.state)
	note("focus lost -> the game paused itself")
	await wait(200)
	up(KEY_D, "move_right")
	thief.queue_free()
	await wait(20)
	cut()
