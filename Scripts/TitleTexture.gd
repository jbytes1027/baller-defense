extends TextureRect


func _ready():
	# Puts the title below a mobile notch
	# Gets the ratio between the device resolution and the game resolution
	var ratio = max(OS.window_size.x / ProjectSettings.get_setting("display/window/size/width"), 1)
	# Use the ratio to convert the display resolution notch offset to the game resolution
	var offset = int(OS.get_window_safe_area().position.y / ratio)
	self.rect_position.y += offset
