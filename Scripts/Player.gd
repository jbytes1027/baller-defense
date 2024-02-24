extends KinematicBody2D

signal Hit

export var VerticalDampening = .1
export var HorizontalDampening = .1
export var GravityDampening = 0.0
export var Gravity = 280
export var JumpForce = 150
export var HitStrength = 70

export var ExtraHitAngle = 20#degrees
export var MinHitAngle = 40#degrees
export var MinDragAngle = 33#degrees
export var MinDragLength = 10

var SampleWindup
var SampleJump = preload("res://Assets/Audio/jump_player.wav")
var SampleHit = preload("res://Assets/Audio/punch_player.wav")
var SampleMiss = preload("res://Assets/Audio/woosh1.ogg")
var SampleBounce = preload("res://Assets/Audio/bounce_player.wav")
var SampleLand = preload("res://Assets/Audio/land_player.wav")

var isWaitingToFlip = false
var isWaitingToHit = true
var isWaitingToAim = false
var isWaitingToSwing = false
var isWaitingToJump
var isAllowableJumpAngle = false
var isInHitArea = false
var isInWindupArea = false
var isAiming = false
var isSwinging = false
var isGrounded = true
var isAlmostGrounded = false
var Velocity = Vector2()
var StartAimPos = Vector2()
var StartPos = Vector2()
var FloorPosY = 160-48

var SwingAnimAngle = 30
var SwingDir = "Up" #Up, Front, Back

onready var AnimSpr = $AnimatedSprite
onready var BlinkTimer = $BlinkRect/BlinkTimer

#for tracking
var PrevFrame
var ASPMiss
#var DrawPos

func _ready():
	Global.Player = self
	StartPos = position
	$"/root/Game".connect("GameOver",self,"_on_GameOver")
	AnimSpr.playing = true
	AnimSpr.animation = "Idle"

func isAnyButtonPressed():
	var GroupMember = get_tree().get_nodes_in_group("Buttons")
	for Member in GroupMember:
		if Member.is_pressed():
			return true
	return false

func _input(event):
	var DragOffset = StartAimPos - get_global_mouse_position()
	var DragAngle = -rad2deg(DragOffset.angle())

	if isAiming and isGrounded:
		if DragOffset.length() >= MinDragLength and not (DragAngle <= -ExtraHitAngle and DragAngle >= ExtraHitAngle-180):#Fuzzies allowable drag angle
			if not isAllowableJumpAngle: #start allowing release to jump
				AnimSpr.play("Charge")
				isAllowableJumpAngle = true
		else:
			if true: #stop allowing release to jump
				AnimSpr.play("Charge",true)
				isAllowableJumpAngle = false

	if event is InputEventMouseButton:
		#Starting JUMP
		if isAlmostGrounded:
			if event.is_pressed() and not isAiming:#try to start aiming
				isWaitingToAim = true
			
			if not event.is_pressed() and isAiming:#stopped aiming
				isAiming = false
				_on_AnimatedSprite_animation_finished()
				if isAllowableJumpAngle:#Fuzzies allowable drag angle
					isAllowableJumpAngle = false
					DragAngle = deg2rad(-clamp(abs(DragAngle), MinDragAngle, 180-MinDragAngle))#Converts fuzzied angle to allowable angle
					#JUMP
					var JumpDir = Vector2(cos(DragAngle),sin(DragAngle)).normalized()
					Velocity = JumpDir * JumpForce
					isGrounded = false
					AnimSpr.play("Release")
					Global.Game.PlaySample(SampleJump,-10)
		
		if not isAlmostGrounded and event.is_pressed() and (not isSwinging or CanFuzzSwingAgainBufferTime()): #fuzzies allowable swing time
			isWaitingToSwing = true #send signal to swing next frame
			ASPMiss = Global.Game.PlaySample(SampleMiss,3)

func Animate():
	##BLINK
	if AnimSpr.animation == "Idle" or AnimSpr.animation == "Charge":
		if BlinkTimer.is_stopped(): BlinkTimer.start()
		
		# Move blink position with player sprite
		if AnimSpr.animation == "Idle":
			$BlinkRect.rect_position.y = -5
		elif AnimSpr.animation == "Charge":
			$BlinkRect.rect_position.y = -3
	else:
		BlinkTimer.stop()
		$BlinkRect.visible = false
	
	if AnimSpr.flip_h:
		$BlinkRect.rect_position.x = -2
	else:
		$BlinkRect.rect_position.x = -1
	
	###SPRITE
	#calc swing dir
	var DirToBall = rad2deg(abs(position.angle_to_point(Global.Ball.position)))-90
	if DirToBall < -SwingAnimAngle:#right of ball
		if not AnimSpr.flip_h: SwingDir="Front"
		else: SwingDir="Back"
	elif DirToBall > SwingAnimAngle:#left of ball
		if AnimSpr.flip_h: SwingDir="Front"
		else: SwingDir="Back"
	else:
		SwingDir="Up"
	#direction
	if Velocity.x > 0 and not AnimSpr.flip_h and not isSwinging:
		AnimSpr.flip_h = true
	elif Velocity.x < 0 and AnimSpr.flip_h and not isSwinging:
		AnimSpr.flip_h = false
	
	if not "Hit" in AnimSpr.animation and isSwinging:
		isWaitingToHit = false
		isSwinging = false #can now swing again

func _process(delta):
	if isWaitingToAim and not isAnyButtonPressed() and isAlmostGrounded:
		if not isAiming:#just started aiming
			StartAimPos = get_global_mouse_position()
			isAiming = true
	isWaitingToAim = false
	
	if isWaitingToSwing and (not isSwinging or CanFuzzSwingAgainTime()) and not isAnyButtonPressed() and not isAlmostGrounded and not JustJumped():
		AnimSpr.play("Hit"+SwingDir)
		AnimSpr.frame = 0
		isSwinging = true
		isWaitingToHit = true
		isWaitingToSwing = false
	if not JustJumped() and not isSwinging: isWaitingToSwing = false
	
	if isWaitingToHit and isSwinging and "Hit" in AnimSpr.animation and AnimSpr.frame < 1:
		if isInHitArea: #Should hit
			if ASPMiss != null or is_instance_valid(ASPMiss):
				ASPMiss.stop()
				ASPMiss.queue_free()
			
			Global.Game.PlaySample(SampleHit, -1)
			isWaitingToHit = false
			var HitDirection = (Global.Ball.position - position).normalized()#get dir in vector2
			HitDirection.y = -abs(HitDirection.y)#only hit up
			var HitAngle = (-rad2deg(HitDirection.angle()))#convert vector2 dir to deg
			HitAngle = deg2rad(-clamp(HitAngle, MinHitAngle, 180-MinHitAngle))#clamp angle
			HitDirection = Vector2(cos(HitAngle),sin(HitAngle)).normalized()#convert back to vector2
		
			emit_signal("Hit", HitDirection * HitStrength)
			Global.CurrentScore += 1
	if AnimSpr.frame == 1 and isWaitingToHit and AnimSpr.frame != PrevFrame:
		isWaitingToHit = false
	PrevFrame = AnimSpr.frame
	
	if not Input.is_mouse_button_pressed(1) and isAiming:
		isAiming = false #stops aiming sticking
	
	Animate()
	update()

func CanFuzzSwingAgainBufferTime():
	return "Hit" in AnimSpr.animation and AnimSpr.frame >= 3

func CanFuzzSwingAgainTime():
	return "Hit" in AnimSpr.animation and AnimSpr.frame >= 6

func JustJumped():
	return AnimSpr.animation == "Release"

func _physics_process(delta):
	if Global.isPaused: return
#	DrawPos = Velocity.y * delta * 10
	isAlmostGrounded = (FloorPosY - position.y - 10) < (Velocity.y * delta * 10) or isGrounded
	
	var Collision = move_and_collide(Velocity*delta)
	
	if Collision:
		if Collision.collider.is_in_group("Floors"):#hit the floor
			Velocity=Vector2(0,0)
			if not isGrounded:#just landed
				AnimSpr.play("Land")
				Global.Game.PlaySample(SampleLand, -5)
				isGrounded = true
				isWaitingToSwing = false
				isWaitingToHit = false
		else:
			Global.Game.PlaySample(SampleBounce, -10)
			Velocity = Velocity.bounce(Collision.normal)#bounce off wall
	
	if not isGrounded:
		if Velocity.y > 0:
			Velocity.y += Gravity * delta * (1+GravityDampening)
		else:
			Velocity.y += Gravity * delta * (1-GravityDampening)
		Velocity.y -= Velocity.y * VerticalDampening * delta#DAMPEN VERTICALY
		Velocity.x -= Velocity.x * HorizontalDampening * delta#DAMPEN VERTICALY

func _on_GameOver():
	$HitArea/WindupArea.monitoring = true
	$HitArea.monitoring = true

func _on_AnimatedSprite_animation_finished():
	var CurrAnim = AnimSpr.animation
	if isGrounded:
		if not isAiming: AnimSpr.play("Idle")
	else:
		if not isInHitArea and isInWindupArea:
			AnimSpr.play("Windup"+SwingDir)
			AnimSpr.frame = 0
			AnimSpr.stop()
		if not isInWindupArea:
			if not isAlmostGrounded:
				AnimSpr.play("Rise")
			else:
				AnimSpr.play("AlmostLand")
			

func _on_HitArea_body_entered(body):
	isInHitArea = true
	if not isSwinging and not isAlmostGrounded:
		AnimSpr.play("Windup"+SwingDir)
		AnimSpr.frame = 1
		AnimSpr.stop()

func _on_HitArea_body_exited(body):
	isInHitArea = false
	if "Windup" in AnimSpr.animation: _on_AnimatedSprite_animation_finished()

func _on_WindupArea_body_entered(body):
	isInWindupArea = true
	if not isSwinging and not isAlmostGrounded:
		AnimSpr.play("Windup"+SwingDir)
		AnimSpr.frame = 0
		AnimSpr.stop()

func _on_WindupArea_body_exited(body):
	isInWindupArea = false
	if "Windup" in AnimSpr.animation: _on_AnimatedSprite_animation_finished()


func _on_BlinkTimer_timeout():
	randomize()
	if $BlinkRect.visible:
		$BlinkRect.visible = false
		BlinkTimer.wait_time = rand_range(2,7)
		BlinkTimer.start()
	else:
		$BlinkRect.visible = true
		BlinkTimer.wait_time = .2
		BlinkTimer.start()
