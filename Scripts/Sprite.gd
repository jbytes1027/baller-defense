extends Sprite

func _process(delta):
	update()

func _draw():
	draw_line(Vector2(-96,Global.Player.FloorPosY - Global.Player.position.y - 10),Vector2(96,Global.Player.FloorPosY - Global.Player.position.y - 10),ColorN("Black"),1)