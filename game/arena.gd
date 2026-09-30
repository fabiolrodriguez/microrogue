class_name VigilArena
extends Node2D

signal changed
signal reward_requested(options: Array)
signal run_ended(won: bool)

const Room = preload("res://game/room.gd")
const Sound = preload("res://game/sound.gd")
const Content = preload("res://game/content.gd")
const View = preload("res://game/arena_view.gd")
const SEAL_DURATION := 65.0
const SPAWN_END := 55.0
var room := Room.new()
var rng := RandomNumberGenerator.new()
var player := Vector2(192, 116)
var facing := Vector2.RIGHT
var hp := 6
var max_hp := 6
var stage := 0
var stage_time := 0.0
var elapsed := 0.0
var kills := 0
var relics: Array[String] = []
var enemies: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var zones: Array[Dictionary] = []
var motes: Array[Dictionary] = []
var hearts: Array[Vector2] = []
var state := "intro"
var state_time := 3.0
var attack_cd := 0.0
var swing := 0.0
var swing_direction := Vector2.RIGHT
var roll_cd := 0.0
var rolling := 0.0
var invincible := 0.0
var shake := 0.0
var hurt_flash := 0.0
var freeze := 0.0
var pulse := 0.0
var trap_clock := 5.0
var next_spawn := 1.0
var spawn_index := 0
var boss_phase := 1
var boss_attack := 0
var boss_hp := 0
var boss_max_hp := 210
var banner := "intro"
var banner_time := 6.0
var view: Node2D
var decorative := false
var input_enabled := true
var hit_ids: Array[int] = []
var next_id := 0
var last_damage := ""

func _ready() -> void:
	rng.randomize()
	if GameSession.active:
		rng.seed = GameSession.get_value("seed", rng.seed)
	view = View.new()
	view.arena = self
	add_child(view)
	if decorative:
		state = "display"
		return
	GameSession.set_value("relics", [])
	changed.emit()

func _physics_process(delta: float) -> void:
	if SceneManager.is_transitioning:
		return
	if decorative:
		pulse += delta
		view.queue_redraw()
		return
	if state in ["reward", "won", "lost"]:
		return
	step(delta)

func step(delta: float) -> void:
	pulse += delta
	shake = maxf(0, shake - delta * 20)
	hurt_flash = maxf(0, hurt_flash - delta)
	banner_time = maxf(0, banner_time - delta)
	if freeze > 0:
		freeze -= delta
		view.queue_redraw()
		return
	elapsed += delta
	attack_cd = maxf(0, attack_cd - delta)
	swing = maxf(0, swing - delta)
	roll_cd = maxf(0, roll_cd - delta)
	rolling = maxf(0, rolling - delta)
	invincible = maxf(0, invincible - delta)
	if input_enabled:
		move_player(delta)
	update_motes(delta)
	if state == "intro":
		state_time -= delta
		if state_time <= 0:
			begin_stage()
	elif state == "combat":
		stage_time += delta
		next_spawn -= delta
		if next_spawn <= 0 and stage_time < SPAWN_END:
			spawn_wave()
			next_spawn = 9.0 if stage < 2 else 8.0
		if stage >= 1:
			update_traps(delta)
		if stage_time >= SEAL_DURATION and enemies.is_empty():
			state = "chest"
			shots.clear()
			zones.clear()
			banner = "chest"
			banner_time = 60
			Sound.play("reward")
	elif state == "chest":
		if player.distance_to(Room.CENTER) < 18:
			open_chest()
	elif state == "boss_intro":
		state_time -= delta
		if state_time <= 0:
			state = "boss"
			spawn_enemy("warden", Vector2(192, 60))
			boss_hp = boss_max_hp
			Sound.play("boss")
	elif state == "boss":
		stage_time += delta
		update_traps(delta)
	if state in ["combat", "boss"]:
		update_enemies(delta)
		update_shots(delta)
		update_zones(delta)
	for i in range(hearts.size() - 1, -1, -1):
		if player.distance_to(hearts[i]) < 12 and hp < max_hp:
			hp += 1
			hearts.remove_at(i)
			Sound.play("heal")
	view.queue_redraw()
	changed.emit()

func move_player(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if rolling > 0:
		player = room.move(player, facing * 205 * delta)
		if int(pulse * 60) % 3 == 0:
			burst(player, Color("87c6c0"), 1)
	else:
		if direction.length() > 0.1:
			facing = direction.normalized()
		var speed := 72.0 * (1.15 if "boots" in relics else 1.0)
		player = room.move(player, direction * speed * delta)
		if Input.is_action_just_pressed("roll") and roll_cd <= 0:
			rolling = 0.20
			invincible = maxf(invincible, 0.25)
			roll_cd = 0.8 if "boots" in relics else 1.6
			Sound.play("roll")
		if Input.is_action_pressed("attack") and attack_cd <= 0:
			attack()

func attack() -> void:
	if state in ["reward", "won", "lost", "boss_intro"]:
		return
	var nearest := 85.0
	for enemy in enemies:
		var distance: float = player.distance_to(enemy.p)
		if distance < nearest and enemy.spawn <= 0 and room.clear_line(player, enemy.p):
			nearest = distance
			facing = player.direction_to(enemy.p)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		facing = player.direction_to(get_global_mouse_position())
	if facing.is_zero_approx():
		facing = Vector2.RIGHT
	attack_cd = 0.30 if "haste" in relics else 0.5
	swing = 0.18
	swing_direction = facing
	Sound.play("swing")
	var reach := 37.0 if "edge" in relics else 25.0
	var damage := 3 + (1 if "edge" in relics else 0)
	if "fury" in relics:
		damage += 4 if hp <= max_hp / 2 else 2
	for enemy in enemies.duplicate():
		var offset: Vector2 = enemy.p - player
		if enemy.spawn <= 0 and offset.length() < reach + enemy.radius and (offset.normalized().dot(facing) > -0.25 or offset.length() < 12) and room.clear_line(player, enemy.p):
			hit_enemy(enemy, damage, facing * 6)
			if state in ["won", "lost"]:
				return
	if "echo" in relics:
		make_shot(player + facing * 10, facing * 145, true, damage, 1.4)
	if "mirror" in relics:
		for shot in shots:
			if not shot.friendly and player.distance_to(shot.p) < reach + 8:
				shot.friendly = true
				shot.v = -shot.v * 1.5
				shot.damage = 7

func hurt(source: String, damage := 1) -> void:
	if invincible > 0 or state not in ["combat", "boss"]:
		return
	hp = maxi(0, hp - damage)
	last_damage = source
	invincible = 1.1
	hurt_flash = 0.22
	shake = 3.5
	Sound.play("hurt")
	burst(player, Color("e66c70"), 10)
	if hp <= 0:
		finish(false)

func begin_stage() -> void:
	state = "combat"
	stage_time = 0
	next_spawn = 1.5
	spawn_index = 0
	trap_clock = 7
	banner = "stage_%d" % (stage + 1)
	banner_time = 3.5
	GameSession.set_value("seal", stage + 1)

func spawn_wave() -> void:
	var count := mini(3 + stage, 11 - enemies.size())
	var roster: Array = [["rat", "rat", "goblin"], ["rat", "goblin", "skeleton"], ["goblin", "skeleton", "slime", "rat"], ["goblin", "skeleton", "slime"]][stage]
	for i in range(count):
		var gate: Vector2 = Room.GATES[(spawn_index + i) % 4]
		# Try another entrance if the player is standing at this one.
		if player.distance_to(gate) < 55:
			gate = Room.GATES[(spawn_index + i + 2) % 4]
		var at := room.move(gate, Vector2(rng.randf_range(-9,9), rng.randf_range(-6,6)))
		spawn_enemy(roster[rng.randi_range(0,roster.size()-1)], at)
	spawn_index += 1

func spawn_enemy(kind: String, at: Vector2) -> Dictionary:
	var health: int = {"rat": 5, "goblin": 10, "skeleton": 8, "slime": 14, "warden": boss_max_hp}[kind]
	next_id += 1
	var enemy := {"id":next_id, "kind":kind, "p":at, "hp":health, "max_hp":health, "spawn":1.25,
		"timer":rng.randf_range(0.5,1.5), "mode":"walk", "dir":Vector2.DOWN,
		"flash":0.0, "path_cd":0.0, "nav":Vector2.ZERO, "radius":10.0 if kind == "warden" else 6.0,
		"flip":false}
	enemies.append(enemy)
	return enemy

func update_enemies(delta: float) -> void:
	for enemy in enemies.duplicate():
		if not enemies.has(enemy):
			continue
		enemy.flash = maxf(0, enemy.flash - delta)
		if enemy.spawn > 0:
			enemy.spawn -= delta
			continue
		enemy.timer -= delta
		enemy.path_cd -= delta
		if enemy.path_cd <= 0:
			enemy.nav = room.direction(enemy.p, player)
			enemy.path_cd = 0.35 + rng.randf() * 0.1
		var direction: Vector2 = enemy.nav
		var speed := 0.0
		var distance: float = enemy.p.distance_to(player)
		match enemy.kind:
			"rat":
				speed = 32
			"slime":
				speed = 19
			"goblin":
				if enemy.mode == "walk":
					speed = 27
					if distance < 90 and enemy.timer <= 0 and room.clear_line(enemy.p, player):
						enemy.mode = "windup"
						enemy.timer = 0.8
						enemy.dir = enemy.p.direction_to(player)
				elif enemy.mode == "windup" and enemy.timer <= 0:
					enemy.mode = "charge"
					enemy.timer = 0.5
				elif enemy.mode == "charge":
					speed = 150
					direction = enemy.dir
					if enemy.timer <= 0:
						enemy.mode = "rest"
						enemy.timer = 0.9
				elif enemy.mode == "rest" and enemy.timer <= 0:
					enemy.mode = "walk"
					enemy.timer = 1.4
			"skeleton":
				if enemy.mode == "walk":
					speed = 23 if distance > 92 else (-15 if distance < 58 else 0)
					if enemy.timer <= 0 and room.clear_line(enemy.p, player):
						enemy.mode = "windup"
						enemy.dir = enemy.p.direction_to(player)
						enemy.timer = 0.9
				elif enemy.timer <= 0:
					make_shot(enemy.p, enemy.dir * 78)
					enemy.mode = "walk"
					enemy.timer = 2.0
			"warden":
				update_boss(enemy)
				speed = 13 if enemy.mode == "walk" else 0
		# Mild separation prevents unreadable stacks. Charges keep their locked heading.
		var separation := Vector2.ZERO
		if enemy.mode != "charge":
			for other in enemies:
				if other.id != enemy.id:
					var offset: Vector2 = enemy.p - other.p
					if offset.length() < 13 and offset.length() > 0.01:
						separation += offset.normalized() * 16
		enemy.p = room.move(enemy.p, (direction * speed + separation) * delta, enemy.radius * 0.7)
		if absf(direction.x) > 0.1:
			enemy.flip = direction.x < 0
		if distance < enemy.radius + 5:
			hurt(enemy.kind)
		if state == "lost":
			break

func update_boss(enemy: Dictionary) -> void:
	boss_hp = enemy.hp
	if enemy.hp <= boss_max_hp / 2 and boss_phase == 1:
		boss_phase = 2
		banner = "enrage"
		banner_time = 3
		Sound.play("boss")
	if enemy.timer > 0:
		return
	if enemy.mode == "walk":
		enemy.mode = "windup"
		enemy.dir = enemy.p.direction_to(player)
		enemy.timer = 1.15 if boss_phase == 1 else 0.9
		if boss_attack % 3 == 2:
			for offset in [Vector2.ZERO, Vector2(-30,0), Vector2(30,0)]:
				zones.append({"p":player + offset, "radius":15.0, "warm":1.3, "life":2.6, "kind":"curse"})
	else:
		if boss_attack % 3 == 0:
			for i in range(-2,3):
				make_shot(enemy.p, enemy.dir.rotated(i * 0.22) * (65 + boss_phase * 7))
		elif boss_attack % 3 == 1:
			# A rotating, wide safe wedge keeps the radial pattern dodgeable.
			for i in range(12):
				if i in [0,1,2]:
					continue
				make_shot(enemy.p, Vector2.RIGHT.rotated(i * TAU / 12 + boss_attack * 0.4) * 57)
		elif enemies.size() < 5:
			for i in range(boss_phase):
				var gate: Vector2 = Room.GATES[(boss_attack+i)%4]
				if player.distance_to(gate) < 50:
					gate = Room.GATES[(boss_attack+i+2)%4]
				spawn_enemy("rat", gate)
		Sound.play("cast")
		boss_attack += 1
		enemy.mode = "walk"
		enemy.timer = 1.6 if boss_phase == 1 else 1.0

func hit_enemy(enemy: Dictionary, damage: int, knock: Vector2) -> void:
	if not enemies.has(enemy):
		return
	enemy.hp -= damage
	enemy.flash = 0.13
	enemy.p = room.move(enemy.p, knock * (0.15 if enemy.kind == "warden" else 1.0))
	burst(enemy.p, Color("eec98b"), 5)
	freeze = 0.035
	shake = maxf(shake, 0.7)
	Sound.play("hit")
	if enemy.kind == "warden":
		boss_hp = maxi(0,enemy.hp)
	if enemy.hp <= 0:
		kills += 1
		burst(enemy.p, Color("a4c47a"), 12)
		if enemy.kind == "slime":
			zones.append({"p":enemy.p, "radius":13.0,"warm":0.6,"life":4.0,"kind":"poison"})
		if kills % 10 == 0:
			hearts.append(enemy.p)
		if "hunger" in relics and kills % 8 == 0:
			hp = mini(max_hp, hp + 1)
		enemies.erase(enemy)
		Sound.play("death")
		if enemy.kind == "warden":
			finish(true)

func make_shot(at: Vector2, velocity: Vector2, friendly := false, damage := 1, life := 5.0) -> void:
	shots.append({"p":at,"v":velocity,"friendly":friendly,"damage":damage,"life":life,"hit":[]})

func update_shots(delta: float) -> void:
	for i in range(shots.size()-1,-1,-1):
		var shot := shots[i]
		var old: Vector2 = shot.p
		shot.p += shot.v * delta
		shot.life -= delta
		if shot.life <= 0 or not room.clear_line(old, shot.p):
			shots.remove_at(i)
			continue
		if shot.friendly:
			for enemy in enemies.duplicate():
				if enemy.spawn <= 0 and enemy.id not in shot.hit and enemy.p.distance_to(shot.p) < enemy.radius + 4:
					shot.hit.append(enemy.id)
					hit_enemy(enemy, shot.damage, shot.v.normalized() * 3)
					if state == "won":
						return
		elif shot.p.distance_to(player) < 7:
			hurt("bolt")
			if state == "lost":
				return
			shots.remove_at(i)

func update_traps(delta: float) -> void:
	trap_clock -= delta
	if trap_clock > 0:
		return
	trap_clock = 9.0 if stage < 3 else 7.5
	var horizontal := int(stage_time / trap_clock) % 2 == 0
	var points: Array[Vector2] = []
	if horizontal:
		for x in [64,80,96,128,144,240,256,288,304,320]:
			points.append(Vector2(x,104))
	else:
		for y in [48,64,80,128,144,160]:
			points.append(Vector2(192,y))
	for at in points:
		zones.append({"p":at,"radius":8.0,"warm":1.5,"life":3.0,"kind":"spike"})
	if stage == 1 and stage_time < 10:
		banner = "warning"
		banner_time = 4

func update_zones(delta: float) -> void:
	for i in range(zones.size()-1,-1,-1):
		var zone := zones[i]
		zone.warm -= delta
		zone.life -= delta
		if zone.life <= 0:
			zones.remove_at(i)
		elif zone.warm <= 0 and player.distance_to(zone.p) < zone.radius + 3:
			hurt(zone.kind)
			if state == "lost":
				return

func open_chest() -> void:
	state = "reward"
	hp = mini(max_hp, hp + 1)
	banner_time = 0
	var available: Array = []
	for id in Content.RELICS:
		if id not in relics:
			available.append(id)
	var options: Array = []
	for i in range(3):
		var index := rng.randi_range(0, available.size()-1)
		options.append(available[index])
		available.remove_at(index)
	Sound.play("reward")
	reward_requested.emit(options)

func choose_relic(id: String) -> void:
	if state != "reward" or id in relics or id not in Content.RELICS:
		return
	relics.append(id)
	if id == "heart":
		max_hp += 2
		hp = max_hp
	GameSession.set_value("relics", relics.duplicate())
	invincible = 1.5
	attack_cd = 0.3
	stage += 1
	if stage < 4:
		begin_stage()
	else:
		state = "boss_intro"
		state_time = 3.5
		stage_time = 0
		trap_clock = 9
		banner = "boss_intro"
		banner_time = 3.5
	Sound.play("heal")
	changed.emit()

func finish(won: bool) -> void:
	if state in ["won","lost"]:
		return
	state = "won" if won else "lost"
	shots.clear()
	zones.clear()
	banner_time = 0
	GameSession.set_value("result", state)
	GameSession.set_value("kills", kills)
	GameSession.set_value("time", elapsed)
	Sound.play("victory" if won else "loss")
	view.queue_redraw()
	changed.emit()
	run_ended.emit(won)

func burst(at: Vector2, color: Color, count: int) -> void:
	for i in range(count):
		motes.append({"p":at, "v":Vector2.RIGHT.rotated(rng.randf()*TAU)*rng.randf_range(12,45),"life":rng.randf_range(0.15,0.45),"color":color})

func update_motes(delta: float) -> void:
	for i in range(motes.size()-1,-1,-1):
		motes[i].life -= delta
		motes[i].p += motes[i].v * delta
		if motes[i].life <= 0:
			motes.remove_at(i)
