extends Node
## Exercise the game entry and its actual graceful quit policy, not forced engine exit.
func _ready() -> void:
	if not ProjectSettings.get_setting("starter_kit/testing",false):
		get_tree().quit(1)
		return
	get_tree().current_scene = null
	call_deferred("run")

func run() -> void:
	SceneManager.change_scene("res://game/entry.tscn")
	await SceneManager.transition_finished
	for frame in range(120):
		await get_tree().process_frame
	get_tree().current_scene.quit_game()
