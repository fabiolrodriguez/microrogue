class_name VigilRoom
extends RefCounted

const SIZE := Vector2i(384, 192)
const CENTER := Vector2(192, 104)
const BOUNDS := Rect2(24, 32, 336, 144)
const PILLARS := [Vector2(112, 72), Vector2(272, 72), Vector2(112, 136), Vector2(272, 136)]
const GATES := [Vector2(32, 104), Vector2(352, 104), Vector2(192, 40), Vector2(192, 168)]
var grid := AStarGrid2D.new()

func _init() -> void:
	grid.region = Rect2i(0, 0, 48, 24)
	grid.cell_size = Vector2(8, 8)
	grid.offset = Vector2(4, 4)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for y in range(24):
		for x in range(48):
			grid.set_point_solid(Vector2i(x, y), blocked(Vector2(x * 8 + 4, y * 8 + 4), 6))

func blocked(p: Vector2, radius := 5.0) -> bool:
	if not BOUNDS.grow(-radius).has_point(p):
		return true
	for pillar in PILLARS:
		if Rect2(pillar - Vector2(8, 6), Vector2(16, 12)).grow(radius).has_point(p):
			return true
	return false

func move(p: Vector2, motion: Vector2, radius := 5.0) -> Vector2:
	# Small substeps keep high-speed rolls and charges from tunnelling through pillars.
	var steps := maxi(1, ceili(motion.length() / 3.0))
	var step := motion / steps
	for i in range(steps):
		if not blocked(p + Vector2(step.x, 0), radius):
			p.x += step.x
		if not blocked(p + Vector2(0, step.y), radius):
			p.y += step.y
	return p

func clear_line(a: Vector2, b: Vector2) -> bool:
	var steps := maxi(1, ceili(a.distance_to(b) / 4.0))
	for i in range(1, steps + 1):
		if blocked(a.lerp(b, float(i) / steps), 1):
			return false
	return true

func direction(a: Vector2, b: Vector2) -> Vector2:
	if clear_line(a, b):
		return a.direction_to(b)
	var start := Vector2i(a / 8).clamp(Vector2i(0,0),Vector2i(47,23))
	var goal := Vector2i(b / 8).clamp(Vector2i(0,0),Vector2i(47,23))
	# Characters can stand close to obstacles; find a nearby navigable cell.
	start = nearest_cell(start)
	goal = nearest_cell(goal)
	var path := grid.get_point_path(start, goal)
	if path.size() > 1:
		return a.direction_to(path[1])
	return Vector2.ZERO

func nearest_cell(cell: Vector2i) -> Vector2i:
	if not grid.is_point_solid(cell):
		return cell
	for r in range(1, 4):
		for y in range(-r,r+1):
			for x in range(-r,r+1):
				var candidate := cell + Vector2i(x,y)
				if grid.is_in_boundsv(candidate) and not grid.is_point_solid(candidate):
					return candidate
	return cell
