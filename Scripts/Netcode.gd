extends Node

var GPGS
var PlayerID
var LeaderboardID = "CgkI3Lq17LIQEAIQAA"
var ShouldShowLeaderboard = false
var HasLoggedIn = false


func _ready():
	if Engine.has_singleton("GodotPlayGameServices"):
		GPGS = Engine.get_singleton("GodotPlayGameServices")
		GPGS.init(get_instance_id(), false)


func Login():
	if GPGS == null or not GPGS.isOnline():
		print("sign in failed")
	else:
		GPGS.signInSilent()


func AddScore(score):
	print("Trying to submit score")
	GPGS.submitScore(LeaderboardID, score)


func ShowLoaderboard():
	GPGS.showLeaderboardUI(LeaderboardID)
	Login()
	print("Trying to show leaderboard")
	ShouldShowLeaderboard = true


func CheckFirstLogin():
	if not HasLoggedIn:
		HasLoggedIn = true
		Global.Game.FadeIn()


func _on_play_game_services_sign_in_success(signInType, playerID):
	PlayerID = playerID
	Global.isAutoLogin = true
	print("signed in")
	CheckFirstLogin()
	if ShouldShowLeaderboard:
		ShouldShowLeaderboard = false
		GPGS.showLeaderboardUI(LeaderboardID)


func _on_play_game_services_sign_in_failure(signInType):
	print("sign in failed type: ", signInType)
	CheckFirstLogin()
	if signInType == 0:
		GPGS.signInInteractive()
	else:
		HasLoggedIn = false
		Global.isAutoLogin = false
		print("no auto login")


func _on_play_game_services_player_info_failure(signInType):
	print("sign in failed type: ", signInType)
	CheckFirstLogin()
	if signInType == 0:
		GPGS.signInInteractive()
	else:
		HasLoggedIn = false
		Global.isAutoLogin = false
		print("no auto login info failure")
