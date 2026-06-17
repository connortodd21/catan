class_name Port
extends Node2D

@onready var _trade_rate_label: Label = $TradeRateLabel
@onready var _resource: Sprite2D = $Resource


func setup(trade_rate: int, resource_texture: Texture2D, rotation_deg: float) -> void:
	_trade_rate_label.text = "%d:1" % trade_rate
	_resource.texture = resource_texture
	_resource.visible = resource_texture != null
	rotation_degrees = rotation_deg
