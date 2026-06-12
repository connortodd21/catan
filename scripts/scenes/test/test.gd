extends Node2D

@onready var port: Port = $Port
@export var wood_icon: Texture2D

func _ready() -> void:
	port.setup(2, wood_icon, 0)
