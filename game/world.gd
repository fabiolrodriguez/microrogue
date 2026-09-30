extends Node
const Content = preload("res://game/content.gd")
const Arena = preload("res://game/arena.gd")
const Interface = preload("res://game/ui/game_ui.gd")
var arena: Node2D
var hud: Control
var pause_menu: CanvasLayer

func _enter_tree() -> void:
	Content.install()

func _ready() -> void:
	get_tree().auto_accept_quit = false
	if not GameSession.active:
		GameSession.start({"seed":randi()})
	var container := SubViewportContainer.new()
	container.position = Vector2(64,100)
	container.scale = Vector2(3,3)
	container.size = Vector2(384,192)
	container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(container)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(384,192)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.handle_input_locally = false
	container.add_child(viewport)
	arena = Arena.new()
	viewport.add_child(arena)
	var layer := CanvasLayer.new()
	layer.layer = 3
	add_child(layer)
	hud = Interface.new()
	hud.arena = arena
	layer.add_child(hud)
	pause_menu = preload("res://scenes/pause_menu/pause_menu.tscn").instantiate()
	pause_menu.layer = 10
	add_child(pause_menu)
	pause_menu.quit_requested.connect(return_to_menu)
	arena.changed.connect(hud.refresh)
	arena.reward_requested.connect(func(options):
		pause_menu.handle_pause_input = false
		hud.show_reward(options))
	arena.run_ended.connect(func(won):
		pause_menu.handle_pause_input = false
		hud.show_result(won))
	hud.relic_chosen.connect(func(id):
		arena.choose_relic(id)
		pause_menu.handle_pause_input = true
		hud.get_viewport().gui_release_focus())
	hud.restart_requested.connect(restart)
	hud.menu_requested.connect(return_to_menu)
	preload("res://game/sound.gd").music()

func restart() -> void:
	if SceneManager.is_transitioning:
		return
	GameSession.start({"seed":randi()})
	SceneManager.change_scene("res://game/world.tscn")

func return_to_menu() -> void:
	if SceneManager.is_transitioning:
		return
	GameSession.finish()
	SceneManager.change_scene("res://game/entry.tscn")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		preload("res://game/sound.gd").stop_all()
		await get_tree().create_timer(0.2, true, false, true).timeout
		get_tree().quit()
