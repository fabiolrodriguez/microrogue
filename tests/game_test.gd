extends Node
## Runs only in the disposable test project created by run_tests.py.
const Arena = preload("res://game/arena.gd")
const Content = preload("res://game/content.gd")
var checks := 0
var failures := 0
var capture_dir := ""

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ",message)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not ProjectSettings.get_setting("starter_kit/testing",false):
		push_error("Use tests/run_tests.py so settings and saves are isolated.")
		get_tree().quit(1)
		return
	capture_dir = ProjectSettings.get_setting("starter_kit/capture_dir", "")
	# Keep the driver alive while the real scene manager replaces scenes.
	get_tree().current_scene = null
	call_deferred("run")

func scene(path: String) -> Node:
	var err := SceneManager.change_scene(path)
	check(err == OK,"Scene request accepted: "+path)
	await SceneManager.transition_finished
	return get_tree().current_scene

func capture(name: String) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name() == "headless":
		return
	var current = get_tree().current_scene
	if current and current.get_script() == load("res://game/world.gd"):
		current.arena.view.queue_redraw()
		current.hud.refresh()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(capture_dir.path_join("game_"+name+".png"))

func input_action(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await get_tree().process_frame
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	await get_tree().process_frame

func run() -> void:
	Content.install()
	var entry = await scene("res://game/entry.tscn")
	check(not entry.menu.load_button.visible,"No unsupported continue/save flow")
	await capture("menu_en")
	entry.menu.settings_button.pressed.emit()
	check(entry.menu.settings_panel.visible,"Settings open through supplied menu")
	await capture("settings")
	SettingsManager.set_language("pt_BR")
	entry.menu.back_button.pressed.emit()
	check(entry.title.text == Content.text("title"),"Menu responds to language change")
	await capture("menu_pt")
	entry.menu.controls_button.pressed.emit()
	check(entry.menu.controls_panel.visible,"Controls open")
	check(ControlsManager.get_controls_data().size() == 6,"Game controls registered with foundation")
	await capture("controls")
	entry.menu.controls_back_button.pressed.emit()
	# Real menu signal, session start, real scene fade and actual world composition.
	entry.menu.start_button.pressed.emit()
	await SceneManager.transition_finished
	var world = get_tree().current_scene
	var a = world.arena
	check(GameSession.active,"New run creates a session")
	check(a.hp == 6 and a.relics.is_empty(),"Fresh run state")
	await capture("intro")
	await get_tree().process_frame
	check(world.hud.progress.size.y <= 5, "Compact HUD progress height: %s" % world.hud.progress.size)
	await input_action("pause")
	check(PauseManager.is_paused() and world.pause_menu.visible,"Escape action opens shared pause")
	var before: float = a.elapsed
	await get_tree().create_timer(0.05).timeout
	check(a.elapsed == before,"Simulation stops while paused")
	await capture("pause")
	world.pause_menu.resume_button.pressed.emit()
	check(not PauseManager.is_paused(),"Resume unpauses without reloading")
	check(world.arena == a,"Resume preserves world instance")
	a.set_physics_process(false)
	a.input_enabled = false
	a.begin_stage()
	# High-speed collision, line-of-sight, hurt immunity, real sword attack.
	check(a.room.move(Vector2(90,72),Vector2(50,0)).x < 100,"Roll cannot tunnel through pillar")
	check(not a.room.clear_line(Vector2(90,72),Vector2(140,72)),"Pillar blocks bolts")
	a.hurt("test")
	var health_after: int = a.hp
	a.hurt("test")
	check(a.hp == health_after,"Damage grants invulnerability")
	a.hp = a.max_hp
	a.player = Vector2(190,110)
	var rat = a.spawn_enemy("rat",Vector2(206,110))
	rat.spawn = 0
	a.attack()
	check(rat.hp == 2,"Sword hits nearby target")
	a.attack_cd = 0
	a.attack()
	check(a.enemies.is_empty() and a.kills == 1,"Sword kills and removes enemy")
	var safe_spawn = a.spawn_enemy("rat",a.player)
	a.invincible = 0
	a.update_enemies(0.1)
	check(a.hp == a.max_hp,"Arriving enemy cannot damage before telegraph ends")
	a.enemies.clear()
	a.relics.append("mirror")
	a.make_shot(a.player+Vector2(12,0),Vector2(-40,0))
	a.attack()
	check(a.shots[0].friendly,"Mirror relic reflects hostile projectile")
	a.shots.clear()
	a.relics.clear()
	a.stage = 2
	a.stage_time = 15
	a.trap_clock = 0
	a.update_traps(0.1)
	check(not a.zones.is_empty() and a.zones[0].warm > 1,"Traps telegraph before activating")
	for kind in ["rat","goblin","skeleton","slime"]:
		var enemy = a.spawn_enemy(kind,Vector2(65+40*a.enemies.size(),80))
		enemy.spawn = 0
	await capture("combat")
	a.enemies.clear()
	a.zones.clear()
	a.state = "chest"
	a.open_chest()
	check(a.state == "reward" and world.hud.overlay.visible,"Reward safely suspends combat")
	check(world.hud.current_options.size() == 3,"Reward offers three relics")
	var options: Array = world.hud.current_options.duplicate()
	check(options[0] != options[1] and options[1] != options[2] and options[0] != options[2],"Reward options unique")
	check(get_viewport().gui_get_focus_owner() is Button,"Reward acquires keyboard focus")
	await capture("reward_pt")
	SettingsManager.set_language("en_US")
	await capture("reward_en")
	var focused: Control = get_viewport().gui_get_focus_owner()
	await input_action("ui_right")
	check(get_viewport().gui_get_focus_owner() != focused,"Keyboard can navigate reward cards")
	# Synthetic controller events exercise native GUI navigation without a device.
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_A
	pad.pressed = true
	Input.parse_input_event(pad)
	await get_tree().process_frame
	pad = InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_A
	pad.pressed = false
	Input.parse_input_event(pad)
	await get_tree().process_frame
	check(a.relics.size() == 1 and a.state == "combat","Gamepad confirm selects relic and resumes")
	# Mouse confirmation exercises the same native reward buttons.
	a.state = "chest"
	a.open_chest()
	await get_tree().process_frame
	# Nested containers finish sorting over successive frames, including headless runs.
	await get_tree().process_frame
	var reward_button: Button = world.hud.card.find_children("*", "Button", true, false)[0]
	var mouse := InputEventMouseButton.new()
	mouse.position = reward_button.get_global_rect().get_center()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	# Send local GUI coordinates directly; headless has no native mouse window.
	get_viewport().push_input(mouse, true)
	await get_tree().process_frame
	mouse = mouse.duplicate()
	mouse.pressed = false
	get_viewport().push_input(mouse, true)
	await get_tree().process_frame
	check(a.relics.size() == 2 and not world.hud.overlay.visible, "Mouse selects a relic and closes modal")
	# Explicit end states and repeated real scene transitions verify lifecycle/UI.
	a.stage = 4
	a.state = "boss"
	a.enemies.clear()
	var warden = a.spawn_enemy("warden",Vector2(192,64))
	warden.spawn = 0
	warden.hp = 100
	a.boss_hp = 100
	a.boss_phase = 2
	await capture("boss")
	a.hit_enemy(warden,1000,Vector2.ZERO)
	check(a.state == "won" and world.hud.result == true,"Boss death opens victory result")
	await capture("victory")
	world.restart()
	await SceneManager.transition_finished
	world = get_tree().current_scene
	a = world.arena
	check(a.hp == 6 and a.relics.is_empty() and a.kills == 0 and a.boss_phase == 1,"Restart clears all run state")
	a.begin_stage()
	a.hp = 1
	a.invincible = 0
	a.hurt("rat")
	check(a.state == "lost" and world.hud.result == false,"Death opens defeat result")
	await capture("defeat")
	world.restart()
	await SceneManager.transition_finished
	world = get_tree().current_scene
	check(world.arena.state == "intro","Second restart starts normally")
	world.return_to_menu()
	await SceneManager.transition_finished
	check(not GameSession.active,"Return to menu ends session")
	check(not PauseManager.is_paused(),"No stale pause after scenes change")
	# Full, unshortened runs through actual world/HUD composition. No health/damage cheats.
	for seed_value in [7412, 1907, 9921]:
		await simulated_run(seed_value)
	preload("res://game/sound.gd").stop_all()
	await get_tree().create_timer(0.2).timeout
	print("Game: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)

func simulated_run(seed_value: int) -> void:
	GameSession.start({"seed":seed_value})
	var world = await scene("res://game/world.tscn")
	var a = world.arena
	a.set_physics_process(false)
	a.input_enabled = false
	var dt := 1.0 / 60.0
	var simulated := 0.0
	var choose_order: Array = ["echo","edge","haste","heart","fury","hunger","boots","mirror"]
	var offered: Array = []
	a.reward_requested.connect(func(options): offered.assign(options))
	while a.state not in ["won","lost"] and simulated < 600:
		simulated += dt
		if a.state == "reward":
			for id in choose_order:
				if id in offered:
					var buttons = world.hud.card.find_children("*", "Button", true, false)
					buttons[offered.find(id)].pressed.emit()
					break
		elif a.state == "chest":
			a.player = a.room.move(a.player,a.room.direction(a.player,a.room.CENTER)*72*dt)
		else:
			var nearest = null
			var distance := INF
			for enemy in a.enemies:
				if enemy.spawn <= 0 and a.player.distance_to(enemy.p) < distance:
					nearest = enemy
					distance = a.player.distance_to(enemy.p)
			var direction := Vector2.ZERO
			if nearest:
				var toward: Vector2 = a.room.direction(a.player,nearest.p)
				var reach := 34 if "edge" in a.relics else 23
				if distance > reach:
					direction = toward
				elif distance < 17 or (a.attack_cd > 0.2 and distance < 27):
					direction = -toward
				else:
					direction = toward.orthogonal()*0.5
				if a.attack_cd <= 0 and distance < reach+6:
					a.attack()
			var threat := Vector2.ZERO
			for shot in a.shots:
				if not shot.friendly and a.player.distance_to(shot.p) < 22:
					threat += shot.p.direction_to(a.player)
			for zone in a.zones:
				if a.player.distance_to(zone.p) < zone.radius+10:
					threat += zone.p.direction_to(a.player)
			if threat.length() > 0:
				direction = threat.normalized()
				if a.roll_cd <= 0:
					a.rolling = .20
					a.invincible = maxf(a.invincible,.25)
					a.roll_cd = .8 if "boots" in a.relics else 1.6
			var speed := 205 if a.rolling > 0 else 72
			a.player = a.room.move(a.player,direction*speed*dt)
			a.facing = direction if direction != Vector2.ZERO else a.facing
		a.step(dt)
		if int(simulated*60)%1200 == 0:
			await get_tree().process_frame
	print("Simulation seed=%d result=%s time=%.1f kills=%d health=%d relics=%s" % [seed_value,a.state,a.elapsed,a.kills,a.hp,str(a.relics)])
	check(a.state in ["won","lost"],"Simulation reaches a terminal state without stalling")
	# Not a win-rate assertion: this bot is deliberately fallible, and death is valid.
	check(a.shots.is_empty() and a.zones.is_empty(),"Terminal state clears hazards")
	await capture("run_%d_%s" % [seed_value,a.state])
	world.return_to_menu()
	await SceneManager.transition_finished
