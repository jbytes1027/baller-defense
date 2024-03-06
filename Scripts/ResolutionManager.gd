extends Node

onready var base_resolution := Vector2(
	ProjectSettings.get_setting("display/window/size/width"), 
	ProjectSettings.get_setting("display/window/size/height"))

onready var _root: Viewport = get_node("/root")


func _ready():
	# Don't use workaround when on desktop
	if (OS.has_feature("pc")): return

	# Enforce minimum resolution.
	OS.min_window_size = base_resolution

	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED, SceneTree.STRETCH_ASPECT_IGNORE, base_resolution, 1)

	# Start tracking resolution changes and scaling the screen.
	update_resolution()
	get_tree().connect("screen_resized", self, "update_resolution")


func update_resolution():
	var video_mode: Vector2 = OS.window_size
	if OS.window_fullscreen: video_mode = OS.get_screen_size()

	# max() is for when video_mode.x < base_resolution.x
	var ratio = max(video_mode.x / base_resolution.x, 1)
	
	var new_height = int(video_mode.y / ratio)

	# floor to the closest multiple of 16
	new_height -= new_height % 16

	# ensure new_height isn't less than the old height
	new_height = max(new_height, base_resolution.y)

	var new_internal_resolution = Vector2(base_resolution.x, new_height)

	var scale := max(min(video_mode.x / base_resolution.x, video_mode.y / base_resolution.y), 1)
	var viewport_size: Vector2 = new_internal_resolution * scale
	var margin: Vector2
	var margin2: Vector2

	viewport_size = new_internal_resolution * scale
	margin = (video_mode - viewport_size) / 2
	margin2 = margin.ceil()
	margin = margin.floor()

	# Add all y margin to the bottom
	margin2.y += margin.y
	margin.y = 0

	viewport_size.x = floor(viewport_size.x)
	viewport_size.y = floor(viewport_size.y)

	_root.set_size(new_internal_resolution)
	_root.set_attach_to_screen_rect(Rect2(margin, viewport_size))
	_root.set_size_override_stretch(false)
	_root.set_size_override(false)

	VisualServer.black_bars_set_margins(int(margin.x), int(margin.y), int(margin2.x), int(margin2.y))
