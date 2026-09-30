extends Control
const Content = preload("res://game/content.gd")
var arena: Node2D
var health: Label
var phase: Label
var clock_label: Label
var roll: Label
var goal: Label
var banner: Label
var relic_row: HBoxContainer
var progress: ProgressBar
var boss_bar: ProgressBar
var boss_label: Label
var overlay: Panel
var card: PanelContainer
var current_options: Array = []
var result: Variant = null
signal relic_chosen(id: String)
signal restart_requested
signal menu_requested

func _ready() -> void:
	style_bars()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	health = label_at(Vector2(64,18),Vector2(390,32),"", "WarningLabel")
	health.add_theme_font_size_override("font_size",24)
	phase = label_at(Vector2(500,18),Vector2(280,32),"", "Eyebrow")
	phase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock_label = label_at(Vector2(1040,18),Vector2(176,32),"", "MutedLabel")
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	progress = ProgressBar.new()
	progress.add_theme_font_size_override("font_size", 1)
	progress.position = Vector2(64,61)
	progress.size = Vector2(1152,4)
	progress.show_percentage = false
	add_child(progress)
	goal = label_at(Vector2(64,70),Vector2(880,24),"", "MutedLabel")
	roll = label_at(Vector2(950,70),Vector2(266,24),"", "Eyebrow")
	roll.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label_at(Vector2(64,684),Vector2(1152,24),Content.text("hint"),"MutedLabel").name = "Hint"
	get_node("Hint").add_theme_font_size_override("font_size",14)
	relic_row = HBoxContainer.new()
	relic_row.position = Vector2(1036,680)
	relic_row.size = Vector2(180,28)
	add_child(relic_row)
	banner = label_at(Vector2(180,106),Vector2(920,35),"", "WarningLabel")
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_color_override("font_shadow_color",get_theme_color("background","Palette"))
	banner.add_theme_constant_override("shadow_offset_x",2)
	banner.add_theme_constant_override("shadow_offset_y",2)
	boss_label = label_at(Vector2(470,612),Vector2(340,22),"", "DangerLabel")
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_bar = ProgressBar.new()
	boss_bar.add_theme_font_size_override("font_size", 1)
	boss_bar.position = Vector2(430,641)
	boss_bar.size = Vector2(420,8)
	boss_bar.show_percentage = false
	boss_bar.theme_type_variation = "BossBar"
	add_child(boss_bar)
	overlay = Panel.new()
	overlay.theme_type_variation = "PauseOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	overlay.hide()
	LocalizationManager.language_changed.connect(refresh_language)
	refresh()
	progress.set_deferred("size", Vector2(1152,4))
	boss_bar.set_deferred("size", Vector2(420,8))

func label_at(at: Vector2, extent: Vector2, text: String, variation := "Label") -> Label:
	var label := Label.new()
	label.position = at
	label.size = extent
	label.text = text
	label.theme_type_variation = variation
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func refresh() -> void:
	if not is_instance_valid(arena):
		return
	health.text = "♥ ".repeat(arena.hp) + "· ".repeat(arena.max_hp-arena.hp)
	phase.text = Content.text("seal") % mini(arena.stage+1,4) if arena.stage < 4 else Content.text("boss")
	clock_label.text = "%02d:%02d" % [int(arena.elapsed)/60,int(arena.elapsed)%60]
	var fraction: float = minf(1, arena.stage_time/arena.SEAL_DURATION)
	if arena.stage == 4:
		fraction = 1.0 - float(arena.boss_hp)/arena.boss_max_hp if arena.state == "boss" else 0.0
	progress.value = 100.0 if arena.state == "won" else 100.0 * (arena.stage + fraction) / 5
	goal.text = Content.text("chest" if arena.state == "chest" else ("cleanup" if arena.stage_time >= arena.SPAWN_END and arena.stage < 4 else "survive"))
	if arena.stage == 4:
		goal.text = Content.text("boss_intro" if arena.state == "boss_intro" else "boss")
	roll.text = Content.text("ready") if arena.roll_cd <= 0 else Content.text("cooldown") % arena.roll_cd
	banner.text = Content.text(arena.banner) if arena.banner_time > 0 else ""
	boss_bar.visible = arena.state == "boss"
	boss_label.visible = boss_bar.visible
	boss_label.text = Content.text("boss")
	boss_bar.value = 100.0 * arena.boss_hp / arena.boss_max_hp
	get_node("Hint").text = Content.text("pad_hint" if not Input.get_connected_joypads().is_empty() else "hint")
	if relic_row.get_child_count() != arena.relics.size():
		for child in relic_row.get_children():
			relic_row.remove_child(child)
			child.queue_free()
		for id in arena.relics:
			var icon := TextureRect.new()
			icon.texture = Content.icon(Content.ICONS[id])
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.custom_minimum_size = Vector2(32,32)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.tooltip_text = Content.text(id+"_name")
			relic_row.add_child(icon)

func refresh_language() -> void:
	refresh()
	if not current_options.is_empty():
		show_reward(current_options)
	elif result != null:
		show_result(result)

func modal(width: float) -> VBoxContainer:
	if is_instance_valid(card):
		overlay.remove_child(card)
		card.queue_free()
	overlay.show()
	card = PanelContainer.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	card.offset_left = -width/2
	card.offset_right = width/2
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	overlay.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",20)
	card.add_child(box)
	return box

func heading(box: VBoxContainer, text: String, variation := "Title") -> void:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)

func show_reward(options: Array) -> void:
	current_options = options.duplicate()
	var box := modal(1030)
	heading(box,Content.text("choose"))
	heading(box,Content.text("choice_hint"),"MutedLabel")
	var row := HBoxContainer.new()
	box.add_child(row)
	var buttons: Array[Button] = []
	for id in options:
		var button := Button.new()
		button.custom_minimum_size = Vector2(308,225)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = ""
		var margin := MarginContainer.new()
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for side in ["left","right","top","bottom"]:
			margin.add_theme_constant_override("margin_"+side,20)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(margin)
		var inner := VBoxContainer.new()
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(inner)
		var icon := TextureRect.new()
		icon.texture = Content.icon(Content.ICONS[id])
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.custom_minimum_size = Vector2(48,48)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(icon)
		heading(inner,Content.text(id+"_name"),"WarningLabel")
		var description := Label.new()
		description.text = Content.text(id+"_desc")
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		description.custom_minimum_size = Vector2(250,84)
		description.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(description)
		button.pressed.connect(func():
			current_options.clear()
			overlay.hide()
			AudioManager.play_click()
			relic_chosen.emit(id))
		button.focus_entered.connect(AudioManager.play_hover)
		button.mouse_entered.connect(AudioManager.play_hover)
		row.add_child(button)
		buttons.append(button)
	for i in range(buttons.size()):
		buttons[i].focus_neighbor_left = buttons[(i+2)%3].get_path()
		buttons[i].focus_neighbor_right = buttons[(i+1)%3].get_path()
	buttons[0].grab_focus()

func show_result(won: bool) -> void:
	result = won
	var box := modal(870)
	heading(box,"IV / IV" if won else "%d / IV" % mini(arena.stage+1,4),"Eyebrow")
	heading(box,Content.text("victory" if won else "defeat"))
	heading(box,Content.text("win_text" if won else "lose_text"),"MutedLabel")
	var time := "%02d:%02d" % [int(arena.elapsed)/60,int(arena.elapsed)%60]
	heading(box,Content.text("stats") % [arena.kills,time,arena.relics.size()],"MutedLabel")
	var retry := Button.new()
	retry.text = Content.text("retry")
	retry.theme_type_variation = "PrimaryButton"
	retry.custom_minimum_size.y = 52
	retry.pressed.connect(func(): restart_requested.emit())
	box.add_child(retry)
	var menu := Button.new()
	menu.text = Content.text("menu")
	menu.custom_minimum_size.y = 48
	menu.pressed.connect(func(): menu_requested.emit())
	box.add_child(menu)
	retry.grab_focus()

func style_bars() -> void:
	# Extend the shared theme only for game-specific progress bars.
	theme = Theme.new()
	for variant in ["ProgressBar", "BossBar"]:
		if variant == "BossBar":
			theme.set_type_variation(variant, "ProgressBar")
		var background := StyleBoxFlat.new()
		background.bg_color = get_theme_color("surface_alt", "Palette")
		var fill := StyleBoxFlat.new()
		fill.bg_color = get_theme_color("danger" if variant == "BossBar" else "primary", "Palette")
		theme.set_stylebox("background", variant, background)
		theme.set_stylebox("fill", variant, fill)
