extends Node
const Content = preload("res://game/content.gd")
var menu: Node2D
var title: Label
var subtitle: Label
var footer: Label

func _enter_tree() -> void:
	Content.install()

func _ready() -> void:
	get_tree().auto_accept_quit = false
	var container := SubViewportContainer.new()
	container.position = Vector2(434,210)
	container.scale = Vector2(2,2)
	container.size = Vector2(384,192)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(container)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(384,192)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)
	var arena = preload("res://game/arena.gd").new()
	arena.decorative = true
	arena.stage = 3
	viewport.add_child(arena)
	arena.spawn_enemy("warden",Vector2(192,64)).spawn = 0
	arena.spawn_enemy("skeleton",Vector2(300,100)).spawn = 0
	arena.spawn_enemy("goblin",Vector2(76,124)).spawn = 0
	menu = preload("res://scenes/main_menu/main_menu.tscn").instantiate()
	add_child(menu)
	menu.get_node("Background").hide()
	menu.load_button.hide()
	menu.quit_button.pressed.disconnect(menu._on_quit_pressed)
	menu.quit_button.pressed.connect(quit_game)
	menu.pause_menu.handle_pause_input = false
	menu.menu_panel.anchor_left = 0
	menu.menu_panel.anchor_right = 0
	menu.menu_panel.offset_left = 54
	menu.menu_panel.offset_right = 404
	menu.start_requested.connect(start)
	menu.get_node("menu/MainPanel/MarginContainer/VBoxContainer/Eyebrow").text = "MICRO ROGUELIKE"
	menu.get_node("menu/MainPanel/MarginContainer/VBoxContainer/Title").text = "VIGIL"
	var layer := CanvasLayer.new()
	add_child(layer)
	title = make_label(layer,Vector2(454,55),Vector2(730,118),"Title")
	title.add_theme_font_size_override("font_size",38)
	subtitle = make_label(layer,Vector2(434,176),Vector2(768,28),"MutedLabel")
	footer = make_label(layer,Vector2(434,613),Vector2(768,64),"Eyebrow")
	LocalizationManager.language_changed.connect(update_text)
	update_text()
	preload("res://game/sound.gd").music()
	# Settings and controls retain their native centered layout and focus handling.
	menu.settings_button.pressed.connect(func(): container.hide(); title.hide(); subtitle.hide(); footer.hide())
	menu.controls_button.pressed.connect(func(): container.hide(); title.hide(); subtitle.hide(); footer.hide())
	menu.back_button.pressed.connect(func(): container.show(); title.show(); subtitle.show(); footer.show())
	menu.controls_back_button.pressed.connect(func(): container.show(); title.show(); subtitle.show(); footer.show())
	menu.menu_panel.visibility_changed.connect(func():
		var show_art: bool = menu.menu_panel.visible
		container.visible = show_art
		title.visible = show_art
		subtitle.visible = show_art
		footer.visible = show_art
		menu.pause_menu.handle_pause_input = false)

func make_label(layer: CanvasLayer, at: Vector2, extent: Vector2, variation: String) -> Label:
	var label := Label.new()
	label.position = at
	label.size = extent
	label.theme_type_variation = variation
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(label)
	return label

func update_text() -> void:
	title.text = Content.text("title")
	subtitle.text = Content.text("subtitle")
	footer.text = Content.text("tagline") + "\n\n" + Content.text("about")

func start() -> void:
	GameSession.start({"seed":randi()})
	SceneManager.change_scene("res://game/world.tscn")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()

func quit_game() -> void:
	preload("res://game/sound.gd").stop_all()
	# Let the audio server retire its playback references before engine shutdown.
	await get_tree().create_timer(0.2, true, false, true).timeout
	get_tree().quit()
