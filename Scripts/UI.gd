extends Node

export(Texture) var MainMenuTitleTexture
export(Texture) var GameOverTitleTexture
var PreviousGameState
var PreviousScore
var PreviousTutAnim
var isUpdatingScoreText
var InitialPos

var SampleBtn = preload("res://Assets/Audio/btn1.wav")
onready var DissolveShaderMaterial = load("res://Shaders/Dissolve.material")
onready var BallRingTex = $BallRing
onready var RingTimer = $BallRing/RingTimer
onready var RingTween = $BallRing/RingTween
onready var TitleTex = $TitleTexture
onready var ColorBtn = $Buttons/ColorButton
onready var SoundBtn = $Buttons/SoundButton
onready var TutSpr = $FloorArea/TutSprite
onready var ScoreLbl = $FloorArea/ScoreLabel
onready var ScoreIcn = $FloorArea/ScoreIcon
onready var ScoreIcnTimer = $FloorArea/ScoreIcon/Timer
onready var ScoreDiv = $FloorArea/ScoreDivider
onready var HighScoreLbl = $FloorArea/HighScoreLabel
onready var HighScoreIcn = $FloorArea/HighScoreLabel/HighScoreIcon
export(Texture) var NewScoreIcnTex
export(Texture) var ScoreIcnTex
export(Texture) var ScoreIcnBlankTex

func _ready():
	$"/root/Game".connect("MainMenu",self,"_on_MainMenu")
	$"/root/Game".connect("Play",self,"_on_Play")
	$"/root/Game".connect("GameOver",self,"_on_GameOver")
	
	InitialPos = {
		"ColorBtn":ColorBtn.position,
		"SoundBtn":SoundBtn.position,
		"TitleTex":TitleTex.rect_position,
		"ScoreLbl":ScoreLbl.rect_position,
		"ScoreIcn":ScoreIcn.rect_position,
		"ScoreDiv":ScoreDiv.rect_position
	}
	isUpdatingScoreText = true
	if Global.isMuted: SoundBtn.normal = load("res://Assets/UI/BtnMuted.png")
	else: SoundBtn.normal = load("res://Assets/UI/BtnUnmuted.png")
	
	CreateRing()

func _process(delta):
	#TUTORIAL
	if Global.GameState == Global.GAMESTATES.MAINMENU and Global.ShowTutorial:
		UpdateTutorial()
	
	if isUpdatingScoreText:
		UpdateScoreLabel()
	
	$FPS.text = str(int(Engine.get_frames_per_second()))
	HighScoreLbl.text = str(Global.HighScore)
	HighScoreIcn.margin_left = (len(HighScoreLbl.text)*6)-4 #position highscore icon
	PreviousGameState = Global.GameState
	PreviousScore = Global.CurrentScore

func OnGameStateChange():
	Global.TransitionPlayer.remove_all()
	ChangeRing()

func _on_MainMenu():
	OnGameStateChange()
	ScoreLbl.visible = false
	ScoreIcn.visible = false
	ScoreDiv.visible = false
	BallRingTex.visible = true
	TitleTex.texture = MainMenuTitleTexture
	TitleTex.visible = true
	if Global.ShowTutorial:
		TutSpr.visible = true
		HighScoreLbl.visible = false
		ColorBtn.visible = false
		SoundBtn.visible = false
	else:
		TutSpr.visible = false
		HighScoreLbl.visible = true
	
	UpdateSoundButton()
	HighScoreLbl.rect_position.y = 12
	ScoreLbl.rect_position.x = 2
#	for c in get_children():
#		c.visible = false
#		Global.Ball.visible=false
#		Global.Player.visible=false

func _on_Play():
	OnGameStateChange()
	#Buttons
	Global.TransitionPlayer.interpolate_property(ColorBtn,"position:x",ColorBtn.position.x,InitialPos["ColorBtn"].x-48, .3,Tween.TRANS_LINEAR,Tween.EASE_OUT)
	Global.TransitionPlayer.interpolate_property(SoundBtn,"position:x",SoundBtn.position.x,InitialPos["SoundBtn"].x+48, .3,Tween.TRANS_LINEAR,Tween.EASE_OUT)
	#Title
	Global.TransitionPlayer.interpolate_property(TitleTex,"rect_position:y",TitleTex.rect_position.y,-InitialPos["TitleTex"].y-48, .2,Tween.TRANS_LINEAR,Tween.EASE_OUT)
	#Ballring
	#Global.Game.Fade(BallRingTex, BallRingTex.texture, 0.1,false)
	Global.TransitionPlayer.interpolate_property(BallRingTex.material, "shader_param/burn_position", BallRingTex.material.get_shader_param("burn_position"),1, .1, Tween.TRANS_LINEAR,Tween.EASE_OUT)
	
	TutSpr.visible = false
	
	#$ScoreLabel.rect_position.x = 2
	
	if PreviousGameState == Global.GAMESTATES.GAMEOVER:
		Global.TransitionPlayer.interpolate_property(ScoreIcn,"rect_position:y",ScoreIcn.rect_position.y, InitialPos["ScoreIcn"].y+48, .2,Tween.TRANS_LINEAR,Tween.EASE_OUT,.1)
		Global.TransitionPlayer.interpolate_property(ScoreLbl,"rect_position:y",ScoreLbl.rect_position.y, InitialPos["ScoreLbl"].y+48, .2,Tween.TRANS_LINEAR,Tween.EASE_OUT,.1)
		Global.TransitionPlayer.interpolate_property(ScoreDiv,"rect_position:y", ScoreDiv.rect_position.y,InitialPos["ScoreDiv"].y+24, .1,Tween.TRANS_LINEAR,Tween.EASE_OUT,.05)
		Global.TransitionPlayer.interpolate_property(HighScoreLbl,"rect_position:y",HighScoreLbl.rect_position.y,30+24, .1,Tween.TRANS_LINEAR,Tween.EASE_OUT)
		
		isUpdatingScoreText = false
	else:
		Global.Game.Fade($FloorArea, null, .3, false, Tween.TRANS_SINE)
		Global.Game.DelaySet(HighScoreLbl, .3, "visible", false)
		Global.Game.DelaySet(ScoreLbl, .4, "visible", true)
		Global.Game.Fade($FloorArea, null, .3, true, Tween.TRANS_SINE, Tween.EASE_OUT, .3)
	
	Global.TransitionPlayer.start()

func _on_GameOver():
	OnGameStateChange()
	#for Btn in $Buttons.get_children():
	#	Global.Game.Fade(Btn,Btn.normal,.1,true)
	#Buttons
	var BtnTime = 1.3
	var BtnTrans = Tween.TRANS_SINE
	Global.TransitionPlayer.interpolate_property(ColorBtn,"position:x",InitialPos["ColorBtn"].x-48,InitialPos["ColorBtn"].x, BtnTime,BtnTrans,Tween.EASE_OUT)
	Global.TransitionPlayer.interpolate_property(SoundBtn,"position:x",InitialPos["SoundBtn"].x+48,InitialPos["SoundBtn"].x, BtnTime,BtnTrans,Tween.EASE_OUT)
	
	#Title
	TitleTex.texture = GameOverTitleTexture
	Global.Game.Fade(TitleTex,$TitleTexture.texture,1,true, Tween.TRANS_SINE)
	Global.TransitionPlayer.interpolate_property(TitleTex,"rect_position:y",InitialPos["TitleTex"].y+8,InitialPos["TitleTex"].y, 1,Tween.TRANS_SINE,Tween.EASE_OUT)
	#Ballring
	#Global.Game.Fade(BallRingTex, BallRingTex.texture, 1.5, true, Tween.TRANS_LINEAR, Tween.EASE_OUT, .3)
	Global.TransitionPlayer.interpolate_property(BallRingTex.material, "shader_param/burn_position", BallRingTex.material.get_shader_param("burn_position"), .3, .3, Tween.TRANS_LINEAR,Tween.EASE_OUT)
	#floor ui
	ScoreDiv.margin_left  = -((len(ScoreLbl.text)+1)*8) +48
	ScoreDiv.margin_right =  ((len(ScoreLbl.text)+1)*8) -48
	#$HighScoreLabel.rect_position.y = get_viewport().get_size().y-18
	#$ScoreLabel.rect_position.x = -8 +2
	#$ScoreIcon.rect_position.x =  ((len($ScoreLabel.text)-1)*8) +48 -5 +2
	
	var Timer1 = 0.4
	Global.TransitionPlayer.interpolate_property(ScoreIcn,"rect_position:x",96,((len(ScoreLbl.text)-1)*8) +48 -5 +2, Timer1,BtnTrans,Tween.EASE_OUT)
	Global.TransitionPlayer.interpolate_property(ScoreLbl,"rect_position:x",ScoreLbl.rect_position.x, -8 +2, Timer1,BtnTrans,Tween.EASE_OUT)
	Global.TransitionPlayer.interpolate_property(ScoreDiv,"rect_position:y",InitialPos["ScoreDiv"].y+24, InitialPos["ScoreDiv"].y, .6,BtnTrans,Tween.EASE_OUT, Timer1)
	Global.TransitionPlayer.interpolate_property(HighScoreLbl,"rect_position:y",30+24, 30, .6,BtnTrans,Tween.EASE_OUT, Timer1+.2)
	
	Global.TransitionPlayer.start()
	yield(Global.TransitionPlayer, "tween_started")
	ScoreIcn.rect_position.y = InitialPos["ScoreIcn"].y
	Global.Game.HideForSec(ScoreDiv, Timer1)
	Global.Game.HideForSec(HighScoreLbl, Timer1+.2)
	Global.Game.HideForSec(HighScoreIcn, Timer1+.2)
	Global.Game.HideForSec(ColorBtn,.1)
	SoundBtn.visible = true
	TitleTex.visible = true
	ScoreLbl.visible = true
	ScoreIcn.visible = true

func ChangeRing():
	randomize()
	var NoiseTex = BallRingTex.material.get_shader_param("noise_tex")
	NoiseTex.noise.seed = randi()

func CreateRing():
	#ADD SHADER w/ paramaters
	BallRingTex.material = DissolveShaderMaterial.duplicate(true)
	var NoiseTex = BallRingTex.material.get_shader_param("noise_tex")
	NoiseTex.width = BallRingTex.rect_size.x
	NoiseTex.height = BallRingTex.rect_size.y
	randomize()
	NoiseTex.noise.seed = randi()
	BallRingTex.material.set_shader_param("noise_tex",NoiseTex)
	NoiseTex.noise.period = 3
	NoiseTex.seamless = false
	BallRingTex.material.set_shader_param("burn_position",0.3)
	
	#Setup and start tween
	NoiseTex = BallRingTex.material.get_shader_param("noise_tex")
	RingTween.interpolate_property(BallRingTex.material, "shader_param/y_offset", 1, 0, 1, Tween.TRANS_LINEAR,Tween.EASE_OUT)
	RingTween.repeat = true
	if not RingTween.is_active(): RingTween.start()

func UpdateTutorial():
	var TutAnim = TutSpr.animation
	if Global.Player.isGrounded:
		TutAnim = "Drag"
	elif Global.Player.isInHitArea and not Global.Player.isSwinging:
		TutAnim = "Tap"
		Global.isPaused = true
	else:
		TutAnim = ""
	
	if PreviousTutAnim != TutAnim:
		if PreviousTutAnim != TutAnim:
			if TutAnim != "":
				Global.Game.Fade($FloorArea, null, .3, true, Tween.TRANS_SINE)
				TutSpr.frame = 0
			else:
				Global.Game.Fade($FloorArea, null, .3, false, Tween.TRANS_SINE)
	PreviousTutAnim = TutAnim
	if TutAnim != "":
		TutSpr.animation = TutAnim

func UpdateScoreLabel():
	#Global.Game.Fade($ScoreLabel, null, 3, false)
	#yield(get_tree().create_timer(.33), "timeout")
	#Global.Game.Fade($ScoreLabel, null, .3, true)
	ScoreLbl.text = str(Global.CurrentScore)

func UpdateSoundButton():
	if not Global.isMuted:
		SoundBtn.normal = load("res://Assets/UI/BtnUnmuted.png")
	else:
		SoundBtn.normal = load("res://Assets/UI/BtnMuted.png")

func NewHighscore():
	ScoreIcn.texture = NewScoreIcnTex
	var BlinkSpeed = .25
	yield(get_tree().create_timer(0.7+BlinkSpeed*2), "timeout")
	for i in range(3):
		yield(get_tree().create_timer(BlinkSpeed), "timeout")
		ScoreIcn.texture = ScoreIcnBlankTex
		yield(get_tree().create_timer(BlinkSpeed), "timeout")
		ScoreIcn.texture = NewScoreIcnTex

func OldHighscore():
	ScoreIcn.texture = ScoreIcnTex

func _on_TransitionPlayer_tween_completed(object, key):
	if object == ScoreLbl and Global.GameState == Global.GAMESTATES.PLAYING:
		isUpdatingScoreText = true
		ScoreLbl.rect_position.y = InitialPos["ScoreLbl"].y
		ScoreLbl.rect_position.x = 2
		#Global.Game.Fade(ScoreLbl, null, 0.7, true, Tween.TRANS_SINE)
		Global.Game.Fade($FloorArea, null, 0.7, true, Tween.TRANS_SINE)

func _on_ColorButton_released():
	Global.Game.PlaySample(SampleBtn, -3)
	if Global.isColored: Global.isColored = false
	else: Global.isColored = true
	Global.Game.UpdateColor()
	Global.Game.SaveData()

func _on_SoundButton_released():
	if Global.isMuted:
		Global.isMuted = false
	else:
		Global.isMuted = true
	UpdateSoundButton()
	Global.Game.SaveData()
	Global.Game.PlaySample(SampleBtn, -3)
