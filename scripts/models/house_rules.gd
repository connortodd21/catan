class_name HouseRules
extends Resource

@export var friendly_robber: bool = false
@export var no_robber: bool = false
@export var re_roll_7_first_round: bool = false
@export var stampede : bool = false
@export var futures_trading : bool = false

enum RULE_NAMES {
	FRIENDLY_ROBBER,
	NO_ROBBER,
	RE_ROLL_7_FIRST_ROUND,
	STAMPEDE,
	FUTURES_TRADING
}

const DISPLAY_NAMES: Dictionary = {
	RULE_NAMES.FRIENDLY_ROBBER: "Friendly robber (can't target players with starting VP",
	RULE_NAMES.NO_ROBBER: "No robber in game. Period",
	RULE_NAMES.RE_ROLL_7_FIRST_ROUND: "Re-roll all 7s during the first round",
	RULE_NAMES.STAMPEDE: "Pay 15 Sheep to eliminate another player's city or settlement",
	RULE_NAMES.FUTURES_TRADING: "Allow trading of future resource gains"
}
