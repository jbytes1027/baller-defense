extends RigidBody2D

var SampleBounce = preload("res://Assets/Audio/bounce_ball.wav")
var SampleHit = preload("res://Assets/Audio/punch_ball.wav")
var ShouldPlayBounceSound = true
var ShouldReset = false
var StartPos
var PrevPos = []


func _ready():
	StartPos = position
	Global.Ball = self
	Global.Player.connect("Hit", self, "_on_Ball_Hit")
	$"/root/Game".connect("GameOver", self, "_on_GameOver")


func _process(delta):
	PrevPos.push_back(position)  #add current position
	if len(PrevPos) > 10:
		PrevPos.pop_front()
	update()  #redraw


func _draw():
	var DrawRadius = 0
	for pos in PrevPos:
		DrawRadius = PrevPos.find(pos) * .5
		if DrawRadius > 3.3:
			draw_circle(pos - position, DrawRadius, Color8(0, 0, 0))


func AnimateHit():
	for Child in get_children():
		if Child.is_in_group("TempTween"):
			Child.playback_speed = 2
	$Tween.interpolate_property(
		$Sprite, "scale", Vector2(1.2, 1.2), Vector2(1, 1), .5, Tween.TRANS_SINE, Tween.EASE_OUT
	)
	$Tween.start()


func HitSoundDelayed():
	yield(get_tree().create_timer(.025), "timeout")
	Global.Game.PlaySample(SampleHit, 8)


func _on_Ball_Hit(Velocity):
	HitSoundDelayed()
	AnimateHit()
	#Freeze ball
	mode = MODE_STATIC
	mode = MODE_CHARACTER
	#hit ball from bottom
	apply_impulse(Vector2(0, 6), Velocity)


func _integrate_forces(state):
	if ShouldReset:
		ShouldReset = false
		state.linear_velocity = Vector2(0, 0)
		state.transform = Transform2D(0, StartPos)
		position = StartPos
		sleeping = true


func _on_GameOver():
	ShouldReset = true
	ShouldPlayBounceSound = true
	Global.Game.Fade(self, $Sprite.texture, 1.5, true, Tween.TRANS_SINE)


func _on_Ball_body_entered(body):
	if ShouldPlayBounceSound:
		Global.Game.PlaySample(SampleBounce, 3)
