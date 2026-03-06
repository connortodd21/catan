class_name HouseRules
extends Resource


enum RULE_NAMES {
	FRIENDLY_ROBBER,
	NO_ROBBER,
	RE_ROLL_7_FIRST_ROUND,
	STAMPEDE,
	FUTURES_TRADING
}

const DISPLAY_NAMES: Dictionary = {
	RULE_NAMES.FRIENDLY_ROBBER: "Friendly Robber: can't target players with starting VP).",
	RULE_NAMES.NO_ROBBER: "No Robber in game. Period.",
	RULE_NAMES.RE_ROLL_7_FIRST_ROUND: "Re-roll all 7s during the first round.",
	RULE_NAMES.STAMPEDE: "Stampede: Pay 15 Sheep to eliminate another player's city or settlement.",
	RULE_NAMES.FUTURES_TRADING: "Futures Trading: Allow trading of future resource gains."
}
