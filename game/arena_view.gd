extends Node2D
## All art is sampled at its original pixel resolution inside the game viewport.
const PACK := "res://assets/Bitcrawl_Free_Roguelike_v1/"
const TILES = preload(PACK + "Tileset/Tileset.png")
const TORCH = preload(PACK + "Tileset/Single_Decoration_Animation/Sheets/Animated_Torch_Wall.png")
const CHEST = preload(PACK + "Tileset/Single_Decoration_Animation/Sheets/Animated_Chest_Open.png")
const ITEMS = preload(PACK + "Items/Items_Normal_Outline.png")
const SPRITES := {
	"knight":preload(PACK + "Characters/Normal_Outline_Sheet/Animation_Normal_Outline_Knight.png"),
	"rat":preload(PACK + "Characters/Normal_Outline_Sheet/Animation_Normal_Outline_Rat.png"),
	"goblin":preload(PACK + "Characters/Normal_Outline_Sheet/Animation_Normal_Outline_Goblin.png"),
	"skeleton":preload(PACK + "Characters/Normal_Outline_Sheet/Animation_Normal_Outline_Skeleton.png"),
	"slime":preload(PACK + "Characters/Normal_Outline_Sheet/Animation_Normal_Outline_Slime.png"),
	"warden":preload(PACK + "Characters/Normal_Outline_Sheet/Animation_Normal_Outline_Wraith.png")}
var arena: Node2D
var floor_tiles: Array[Vector2i] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var rng := RandomNumberGenerator.new()
	rng.seed = 7412
	for i in range(24*12):
		floor_tiles.append([Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)][rng.randi()%4])

func tile(cell: Vector2i, at: Vector2, color := Color.WHITE) -> void:
	draw_texture_rect_region(TILES, Rect2(at,Vector2(16,16)),Rect2(Vector2(cell)*16,Vector2(16,16)),color)

func _draw() -> void:
	if not is_instance_valid(arena):
		return
	var a = arena
	var t: float = a.pulse
	var frame := int(t*7) % 4
	position = Vector2(sin(t*151),cos(t*173)) * a.shake
	draw_rect(Rect2(0,0,384,192),Color("101019"))
	# Recessed walls, broken stone, and a deliberately symmetrical arena.
	for y in range(2,11):
		for x in range(1,23):
			tile(floor_tiles[y*24+x],Vector2(x*16,y*16))
	for x in range(1,23):
		tile(Vector2i(3 + x%2,0),Vector2(x*16,8))
		tile(Vector2i(3 + x%2,1),Vector2(x*16,24))
		tile(Vector2i(3 + x%2,2),Vector2(x*16,176))
	for y in range(2,11):
		tile(Vector2i(2,1),Vector2(8,y*16))
		tile(Vector2i(5,1),Vector2(360,y*16))
	# Central aisle and inlaid ritual circle stay visually quieter than walls.
	for y in range(3,11):
		for x in [11,12]:
			tile(Vector2i(1,0),Vector2(x*16,y*16),Color(1.10,1.03,1.06))
	draw_arc(Vector2(192,104),27,0,TAU,48,Color("63514d"),1)
	draw_arc(Vector2(192,104),30,0,TAU,48,Color("332d3c"),1)
	for i in range(4):
		var at := Vector2(192,104) + Vector2.RIGHT.rotated(PI/4+i*PI/2)*27
		var lit: bool = a.stage > i
		draw_rect(Rect2(at-Vector2(2,2),Vector2(4,4)),Color("efbd6b") if lit else Color("5c5260"))
	# Four entrances; no additional rooms exist behind them.
	tile(Vector2i(6,4),Vector2(176,18))
	tile(Vector2i(7,4),Vector2(192,18))
	tile(Vector2i(11,4),Vector2(16,88))
	tile(Vector2i(11,4),Vector2(352,88))
	tile(Vector2i(11,4),Vector2(184,170))
	for at in [Vector2(40,42),Vector2(328,42),Vector2(40,151),Vector2(328,151)]:
		tile(Vector2i(0,4),at)
	for at in [Vector2(64,41),Vector2(304,151)]:
		tile(Vector2i(5,4),at)
	for at in [Vector2(72,151),Vector2(312,42),Vector2(145,54),Vector2(225,145)]:
		tile(Vector2i(7,3),at)
	for at in [Vector2(85,46),Vector2(292,157),Vector2(152,151)]:
		tile(Vector2i(7,1),at,Color(1,1,1,0.6))
	# Warm torch halos use restrained translucent rings, keeping silhouettes crisp.
	for at in [Vector2(64,25),Vector2(144,25),Vector2(224,25),Vector2(304,25),Vector2(16,57),Vector2(352,137)]:
		for radius in [18,12,7]:
			draw_circle(at+Vector2(8,6),radius+sin(t*5+at.x),Color(0.96,0.56,0.20,0.022))
		draw_texture_rect_region(TORCH,Rect2(at,Vector2(16,16)),Rect2(frame*16,0,16,16))
	for zone in a.zones:
		var color := Color("e66c70") if zone.kind != "poison" else Color("9ac45b")
		if zone.warm > 0:
			color.a = 0.55 + sin(t*16)*0.2
			draw_arc(zone.p,zone.radius,0,TAU,24,color,1)
			draw_line(zone.p-Vector2(3,0),zone.p+Vector2(3,0),color)
			draw_line(zone.p-Vector2(0,3),zone.p+Vector2(0,3),color)
		else:
			draw_circle(zone.p,zone.radius,Color(color,0.2))
			draw_arc(zone.p,zone.radius,0,TAU,24,color,1)
			if zone.kind == "spike":
				tile(Vector2i(12,3),zone.p-Vector2(8,8))
			elif zone.kind == "curse":
				for i in range(4):
					var end: Vector2 = zone.p+Vector2.UP.rotated(t+i*PI/2)*zone.radius
					draw_line(zone.p,end,color,1)
	if a.state in ["chest","reward"]:
		draw_circle(Vector2(192,104),18,Color(0.93,0.70,0.36,0.10))
		draw_arc(Vector2(192,104),18+sin(t*3)*2,0,TAU,32,Color("efbd6b"),1)
		draw_texture_rect_region(CHEST,Rect2(184,93,16,16),Rect2((3 if a.state == "reward" else 0)*16,0,16,16))
	elif a.state == "boss_intro":
		draw_arc(Vector2(192,65),20+sin(t*9)*4,0,TAU,40,Color("e66c70"),2)
	for heart in a.hearts:
		draw_texture_rect_region(ITEMS,Rect2(heart-Vector2(8,10+sin(t*4)*2),Vector2(16,16)),Rect2(64,0,16,16))
	# Sort architecture and actors together for correct top-down occlusion.
	var objects: Array = []
	for pillar in a.room.PILLARS:
		objects.append({"p":pillar,"kind":"pillar"})
	for enemy in a.enemies:
		objects.append(enemy)
	objects.append({"p":a.player,"kind":"knight"})
	objects.sort_custom(func(left,right): return left.p.y < right.p.y)
	for object in objects:
		if object.kind == "pillar":
			draw_circle(object.p+Vector2(3,1),11,Color(0,0,0,0.25))
			tile(Vector2i(6,2),object.p-Vector2(8,13))
			tile(Vector2i(6,1),object.p-Vector2(8,29))
			continue
		if object.kind == "knight":
			var opacity := 0.45 if a.invincible > 0 and int(t*18)%2 == 0 else 1.0
			if a.state == "lost":
				opacity = 0.35
			draw_arc(a.player,7,0,TAU,20,Color(0.94,0.77,0.45,0.65),1)
			# The knight's source sprite faces left.
			actor("knight",a.player,frame,a.facing.x>0,Color(1,1,1,opacity))
			continue
		if object.spawn > 0:
			draw_arc(object.p,8+object.spawn*6,0,TAU,24,Color("de9770"),1)
			draw_line(object.p-Vector2(3,0),object.p+Vector2(3,0),Color("de9770"))
			actor(object.kind,object.p,frame,object.flip,Color(1,1,1,0.25))
			continue
		if object.mode == "windup":
			var end: Vector2 = object.p+object.dir*(70 if object.kind == "goblin" else 35)
			draw_line(object.p,end,Color(0.97,0.52,0.4,0.65),1)
			draw_arc(object.p,10,0,TAU,20,Color("efbd6b"),1)
		var tint := Color(2.5,2.2,1.7) if object.flash > 0 else Color.WHITE
		actor(object.kind,object.p,frame,object.flip,tint)
		if object.hp < object.max_hp and object.kind != "warden":
			draw_rect(Rect2(object.p-Vector2(7,18),Vector2(14,2)),Color("292332"))
			draw_rect(Rect2(object.p-Vector2(7,18),Vector2(14.0*object.hp/object.max_hp,2)),Color("c89478"))
	for shot in a.shots:
		var color := Color("8bd0ca") if shot.friendly else Color("f18b78")
		draw_line(shot.p,shot.p-shot.v.normalized()*7,color,2)
		draw_circle(shot.p,2,Color("f8e7b1"))
	if a.swing > 0:
		var reach := 37.0 if "edge" in a.relics else 25.0
		var angle: float = a.swing_direction.angle()
		var progress: float = 1.0-a.swing/0.18
		draw_arc(a.player,reach-3,angle-1.4+progress,angle+0.9+progress,18,Color(0.98,0.88,0.62,a.swing/0.18),2)
		draw_arc(a.player,reach-7,angle-1.1+progress,angle+0.7+progress,18,Color(0.98,0.88,0.62,a.swing/0.3),1)
		var sword_at: Vector2 = a.player+Vector2.RIGHT.rotated(angle-1.1+progress*2.5)*(reach-8)
		draw_set_transform(sword_at,angle+progress*2.5-0.4)
		draw_texture_rect_region(ITEMS,Rect2(-8,-8,16,16),Rect2(48,48,16,16))
		draw_set_transform(Vector2.ZERO)
	for mote in a.motes:
		draw_rect(Rect2(mote.p,Vector2(1,1)),mote.color)
	# Soft edge framing and the boss' changing atmosphere.
	for i in range(8):
		draw_rect(Rect2(i,i,384-i*2,192-i*2),Color(0.03,0.02,0.06,0.06),false,1)
	if a.boss_phase == 2:
		draw_rect(Rect2(0,0,384,192),Color(0.5,0.07,0.12,0.04))
	if a.hurt_flash > 0:
		draw_rect(Rect2(0,0,384,192),Color(0.9,0.2,0.2,a.hurt_flash*0.35))

func actor(kind: String, at: Vector2, frame: int, flip: bool, tint: Color) -> void:
	var scale_factor := 2 if kind == "warden" else 1
	var size := Vector2(16,16)*scale_factor
	draw_set_transform(at.round())
	draw_set_transform(at.round(),0,Vector2(-1 if flip else 1,1))
	draw_texture_rect_region(SPRITES[kind],Rect2(Vector2(-size.x/2,-size.y+5),size),Rect2(frame*16,0,16,16),tint)
	draw_set_transform(Vector2.ZERO)
