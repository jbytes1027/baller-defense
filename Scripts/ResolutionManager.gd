extends Node
# Handles window sizing

onready var base_resolution := Vector2(
	ProjectSettings.get_setting("display/window/size/width"), 
	ProjectSettings.get_setting("display/window/size/height"))

onready var _root: Viewport = get_node("/root")


func _ready():
	# Enforce minimum resolution.
	OS.min_window_size = base_resolution

	# Start tracking resolution changes and scaling the screen.
	update_resolution()

	get_tree().connect("screen_resized", self, "update_resolution")


func update_resolution():

	var video_mode: Vector2 = OS.window_size
	if OS.window_fullscreen: video_mode = OS.get_screen_size()

	# TODO check if mobile with has_feature(mobile)
	print(video_mode)

	# max for when video_mode.x < base_resolution.x
	var ratio = max(video_mode.x / base_resolution.x, 1)
	
	var new_height = int(video_mode.y / ratio)

	# floor to the closest multiple of 16
	new_height -= new_height % 16

	# ensure new_height isn't less than the old height
	new_height = max(new_height, base_resolution.y)


	var new_resolution = Vector2(base_resolution.x, new_height)
	
	print(new_resolution)

	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_VIEWPORT, SceneTree.STRETCH_ASPECT_KEEP, new_resolution, 1)
