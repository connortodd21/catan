extends Node

signal steam_initialized(steam_id: int)
signal steam_failed(reason: String)

var local_steam_id: int = 0


func _ready() -> void:
	if not Steam.isSteamRunning():
		print("[NetworkManager] Steam is not running")
		steam_failed.emit("Steam is not running")
		return
	local_steam_id = Steam.getSteamID()
	print("[NetworkManager] Steam ready — ID: %d, Name: %s" % [local_steam_id, Steam.getPersonaName()])
	steam_initialized.emit(local_steam_id)
