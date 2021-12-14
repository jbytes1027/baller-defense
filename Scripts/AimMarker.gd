extends Sprite

var ScreenHeight = 160
onready var AimAngleMkr = $AimAngleMarker

func _process(delta):
	get_parent().transform.origin.y = get_viewport().get_size().y - ScreenHeight
	
	if Global.Player.isAiming:
		visible = true
		global_position = Global.Player.StartAimPos
	else:
		visible = false

	AimAngleMkr.visible = true
	
	var line_to_mouse = get_global_mouse_position()-global_position
	if Global.Player.isAllowableJumpAngle:
		AimAngleMkr.visible = true
		AimAngleMkr.position = line_to_mouse.normalized()*4 + Vector2(.30,.30)
	else:
		AimAngleMkr.visible = false
	#draw_texture(Dot,(line_to_mouse.normalized()*6)-Vector2(1,1))
	#for i in range(7,line_to_mouse.length(),7):
		#draw_line(line_to_mouse.normalized()*i, (line_to_mouse.normalized()*(i+1)),Color(0,0,0))