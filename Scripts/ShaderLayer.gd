extends CanvasLayer

var PreScreenSize = Vector2(0, 0)
var ViewHeight = 160
var ViewWidth = 96
var InitialParticleAmount
var PreviousGameState
var BGPrt
var BGTex
var FGTex
var Twn


func _ready():
	BGPrt = $BackgroundTexture/BackgroundParticles
	BGTex = $BackgroundTexture
	FGTex = $ForegroundTexture
	Twn = $Tween

	InitialParticleAmount = BGPrt.amount
	UpdateScreenSize()


func UpdateScreenSize():
	var ScreenSize = get_viewport().get_size()
	$BackgroundTexture.size = get_viewport().get_size()
	BGPrt.process_material.emission_box_extents = Vector3(
		(ScreenSize.x / 2) + 20, (ScreenSize.y / 2) + 20, 1
	)
	BGPrt.position = ScreenSize / 2

	FGTex.size = get_viewport().get_size()
	#$ForegroundTexture/ForegroundParticles.process_material.emission_box_extents = Vector3((ScreenSize.x/2)+20,(ScreenSize.y/2)+20,1)
	#$ForegroundTexture/ForegroundParticles.position = ScreenSize/2

	BGPrt.amount = InitialParticleAmount * ((ScreenSize.x * ScreenSize.y) / (160 * 96))


func SlowBG():
	BGPrt.lifetime = .3


func _process(delta):
	#if Global.isPaused:  BGTex.speed_scale = 0
	#else: BGPrt.speed_scale = 1

	var ScreenSize = get_viewport().get_size()
	if PreScreenSize != ScreenSize:
		UpdateScreenSize()

	if PreviousGameState != Global.GameState:
		if Global.GameState == Global.GAMESTATES.MAINMENU:
			BGPrt.lifetime = .3
		if Global.GameState == Global.GAMESTATES.PLAYING:
			BGPrt.lifetime = .1
			#Twn.interpolate_property(BGPrt, "lifetime", BGPrt.lifetime, .1, .1, Tween.TRANS_SINE, Tween.EASE_OUT)
			#Twn.start()
		if Global.GameState == Global.GAMESTATES.GAMEOVER:
			pass
			#BGPrt.lifetime = .5
			#Twn.interpolate_property(BGPrt, "lifetime", BGPrt.lifetime, .1, .7, Tween.TRANS_SINE, Tween.EASE_OUT)
			#Twn.start()

	PreviousGameState = Global.GameState
	PreScreenSize = ScreenSize
