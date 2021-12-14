extends Node

signal MainMenu
signal Play
signal GameOver

var SampleScript = load("res://Scripts/TempASL.gd")

var DissolveShaderMaterial = preload("res://Shaders/Dissolve.material")
var SampleGameOver = preload("res://Assets/Audio/fail1.wav")
var SampleTransReset = preload("res://Assets/Audio/trans_reset.wav")
var SampleTransBoot = preload("res://Assets/Audio/trans_bootup.wav")

var PlayerStartPos
var BallStartPos
var ScreenHeight = 160
var PreViewSize
var WasColored
var ASLTransReset

func _ready():
	#Assign global vars
	Global.Game = self
	Global.TransitionPlayer = $TransitionPlayer
	Global.CurrentScore = 0
	Global.HighScore = 0
	Global.isColored = true
	Global.isMuted = false
	Global.ShowTutorial = true
	Global.SavePath = 'user://Game.data'
	Global.Player.connect("Hit", self, "_on_Ball_hit")
	Global.isAutoLogin = true
	Global.Volume = -10
	
	WasColored = true
	PlayerStartPos = Global.Player.position
	BallStartPos = Global.Ball.position
	randomize()
	
	get_tree().paused = true
	UpdateColor()
	LoadData()
	if Netcode.GPGS != null and Global.isAutoLogin: Netcode.Login()
	else: FadeIn()
	UpdateScreenSize()
	UpdateColor()
	MainMenu()
	

func FadeIn():
	get_tree().paused = false
	PlaySample(SampleTransBoot, -5)
	Fade($SplashLayer/SplashRect, null, 1)

func _process(delta):
	if PreViewSize != get_viewport().get_size(): UpdateScreenSize()
	PreViewSize = get_viewport().get_size()

func _input(ev):
	if ev is InputEventKey and ev.scancode == KEY_C and ev.is_pressed(): UpdateColor()

func KillSample(ASP):
	yield(ASP, "finished")
	ASP.queue_free()
	
func PlaySample(Stream, Decibels=0):
	if Global.isMuted: return
	var ASP = AudioStreamPlayer.new()
	ASP.set_script(SampleScript)
	Global.Game.add_child(ASP)
	ASP.stream = Stream
	ASP.volume_db = Global.Volume + Decibels
	ASP.play()
#	KillSample(ASP)
	return ASP

func DelaySet(node, sec, variable, value):
	yield(get_tree().create_timer(sec), "timeout")
	node.set(variable, value)

func HideForSec(node,sec):
	node.visible = false
	yield(get_tree().create_timer(sec), "timeout")
	node.visible = true

func Fade(node, texture, duration, fade_in = false, Trans = Tween.TRANS_LINEAR, Ease = Tween.EASE_OUT, delay = 0):
	yield(get_tree().create_timer(delay), "timeout")
	#ADD SHADER w/ paramaters
	var initial_amount
	if node.material == null:
		node.material = DissolveShaderMaterial.duplicate(true)
		var NoiseTex = node.material.get_shader_param("noise_tex")
		if texture != null:
			NoiseTex.width = texture.get_size().x
			NoiseTex.height = texture.get_size().y
		elif node.rect_size != null:
			NoiseTex.width = node.rect_size.x
			NoiseTex.height = node.rect_size.y
		NoiseTex.height /= 2
		NoiseTex.width /= 2
		NoiseTex.noise.seed = randi()
		node.material.set_shader_param("noise_tex",NoiseTex)
		initial_amount = 0
	else:
		initial_amount = node.material.get_shader_param("burn_position")
	#ANIMATE
	var FadeTween
	for Child in node.get_children():
		if Child.is_in_group("TempTween"):
			Child.stop_all()
			Child.queue_free()
	
	if FadeTween == null or is_instance_valid(FadeTween):
		FadeTween = Tween.new()
		FadeTween.add_to_group("TempTween")
		node.add_child(FadeTween)
	
	if fade_in:
		node.material.set_shader_param("burn_position",1)
		FadeTween.interpolate_property(node.material,"shader_param/burn_position",1,0,duration,Trans,Ease)
	else:
		node.material.set_shader_param("burn_position",0)
		FadeTween.interpolate_property(node.material,"shader_param/burn_position",0,1,duration,Trans,Ease)
	
	FadeTween.start()
	yield(FadeTween, "tween_started")
	node.visible = true
	yield(FadeTween, "tween_completed")
	#yield(get_tree().create_timer(duration), "timeout")
	node.material = null
	FadeTween.stop_all()
	FadeTween.queue_free()
	if not fade_in: node.visible = false

func UpdateScreenSize():
	var ViewHeight = get_viewport().get_size().y
	get_viewport().set_canvas_transform(Transform2D(0,Vector2(0,ViewHeight-ScreenHeight)))
	
	$MouseLayer/AimMarker.material.set_shader_param("screen_height",float(ViewHeight))
	Global.Player.FloorPosY = ViewHeight-48

func GetRelLum(C):
	var RGB = {"R":C.r, "G":C.g, "B":C.b}
	for i in RGB:
		if RGB[i] <= 0.03928: RGB[i] /= 12.96
		else: RGB[i] = pow(((RGB[i] + 0.055) / 1.055), 2.4)
	
	return (0.2126 * RGB["R"] + 0.7152 * RGB["G"] + 0.0722 * RGB["B"])

func GetContrastRatio(C1,C2):
	var L1 = GetRelLum(C1)
	var L2 = GetRelLum(C2)
	if L1 < L2:
		return (L1 + 0.05) / (L2 + 0.05)
	else:
		return (L2 + 0.05) / (L1 + 0.05)

func UpdateColor():
	var FBGColorHueVariance = .15
	var BGColorHueVariance = .1
	var BgColorHueRange = .1
	var HueCoolMin = .45
	var HueCoolMax = .80
	var MaxContrast = .65
	
	var BGPrt = $ShaderLayer/BackgroundTexture/BackgroundParticles
	var BGTex = $ShaderLayer/BackgroundTexture/BackgroundColor
	
	var Twn = Tween.new()
	var RNG = RandomNumberGenerator.new()
	RNG.randomize()
	
	var isHighContrast
	while(Global.isColored == WasColored and not isHighContrast): # find another color
		var NewFBGColor = BGPrt.process_material.color
		
		NewFBGColor.h += RNG.randf_range(FBGColorHueVariance, (HueCoolMax-HueCoolMin)-FBGColorHueVariance)
		if NewFBGColor.h > HueCoolMax: NewFBGColor.h -= (HueCoolMax-HueCoolMin)
		if NewFBGColor.h < HueCoolMin: NewFBGColor.h += (HueCoolMax-HueCoolMin)
		
		var NewBGColor = NewFBGColor
		var PrevBGColor = BGTex.color
		var isDifferentColor
		while(not isDifferentColor):
			NewBGColor.h = (NewFBGColor.h + .5) + RNG.randf_range(-BgColorHueRange,BgColorHueRange)
			isDifferentColor =  abs(PrevBGColor.h - NewBGColor.h) > BGColorHueVariance and abs(PrevBGColor.h - NewBGColor.h) < 1-BGColorHueVariance
#			if not isDifferentColor:print(abs(PrevBGColor.h - NewBGColor.h), " > ",BGColorHueVariance)
#		print(str(GetContrastRatio(NewBGColor, NewFBGColor))+" - "+str(NewFBGColor.h)+"/"+str(NewBGColor.h))
		
		isHighContrast = GetContrastRatio(NewBGColor, NewFBGColor) < MaxContrast
		
		if (isHighContrast):# Apply Hues
			BGPrt.process_material.color.h = NewFBGColor.h
			BGTex.color.h = NewBGColor.h
	
	if Global.isColored != WasColored: # CHANGE MODE
		BGPrt.emitting = Global.isColored # determine to show particles
		BGPrt.lifetime = .1
		if Global.isColored: WaitToResetParticles(BGPrt)
	
	WasColored = Global.isColored

func WaitToResetParticles(BGPrt):
	yield(get_tree().create_timer(.1), "timeout")
	if Global.GameState != Global.GAMESTATES.PLAYING: BGPrt.lifetime = .3

func MainMenu():
	Global.GameState = Global.GAMESTATES.MAINMENU
	emit_signal("MainMenu")

func GameOver():
	Global.GameState = Global.GAMESTATES.GAMEOVER
	if Global.ShowTutorial: Global.ShowTutorial = false
	if Global.CurrentScore > Global.HighScore:
		#new high score
		Global.HighScore = Global.CurrentScore
		$UI.NewHighscore()
	else:
		$UI.OldHighscore()
	if Netcode.GPGS != null: Netcode.AddScore(Global.CurrentScore)
	SaveData()
	
	ASLTransReset = PlaySample(SampleTransReset)
	emit_signal("GameOver")

func Play():
	Global.GameState = Global.GAMESTATES.PLAYING
	Global.CurrentScore = 0
	
	if ASLTransReset != null and is_instance_valid(ASLTransReset):
		var TweenAudioFade = Tween.new()
		ASLTransReset.add_child(TweenAudioFade)
		TweenAudioFade.interpolate_property(ASLTransReset, "volume_db", ASLTransReset.volume_db, -100, .5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		TweenAudioFade.start()
	
	emit_signal("Play")

func SaveData():
	#CUSTOM SAVE VARS
	var Data = {
		"HighScore" : Global.HighScore,
		"isMuted" : Global.isMuted,
		"ShowTutorial" : Global.ShowTutorial,
		"isColored" : Global.isColored,
		"isAutoLogin" : Global.isAutoLogin
	}###
	
	var DataFile = File.new()
	
	DataFile.open(Global.SavePath, File.WRITE)
	DataFile.store_line(to_json(Data))
	DataFile.close()

func LoadData():
	var DataFile = File.new()
	if not DataFile.file_exists(Global.SavePath): return
	
	DataFile.open(Global.SavePath, File.READ)
	var Data = parse_json(DataFile.get_as_text())
	DataFile.close()
	
	#CUSTOM LOAD VARS
	if Data.has("HighScore"): Global.HighScore = Data["HighScore"]
	if Data.has("isMuted"): Global.isMuted = Data["isMuted"]
	if Data.has("ShowTutorial"): Global.ShowTutorial = Data["ShowTutorial"]
	if Data.has("isColored"): Global.isColored = Data["isColored"]
	if Data.has("isAutoLogin"): Global.isAutoLogin = Data["isAutoLogin"]

func _on_Ball_hit(data):
	if Global.GameState != Global.GAMESTATES.PLAYING: Play()
	Global.isPaused = false
	$Tween.interpolate_property(Engine,"time_scale",1.5,Engine.time_scale,.1,Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.start()
	$ShaderLayer/BackgroundTexture/BackgroundParticles.speed_scale = 0
	yield(get_tree().create_timer(.1),"timeout")
	$ShaderLayer/BackgroundTexture/BackgroundParticles.speed_scale = 1

func _on_GameOverArea_body_entered(body):
	if Global.GameState == Global.GAMESTATES.PLAYING:
		UpdateColor()
		$ShaderLayer.SlowBG()
		Fade((Global.Ball), $Ball/Sprite.texture, 1, false, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		$Player/HitArea.monitoring = false
		$Player/HitArea/WindupArea.monitoring = false
		$Ball.ShouldPlayBounceSound = false
		PlaySample(SampleGameOver,-3)
		yield(get_tree().create_timer(1.5), "timeout")
		GameOver()
