class_name GamePhase

enum Phase {
	ROLL,
	ROBBER,
	ACTION,
	PLAYING_CARD,
}

static var phase_to_string_map = {
	Phase.ROLL: "Roll",
	Phase.ROBBER: "Robber",
	Phase.ACTION: "Action",
	Phase.PLAYING_CARD: "Playing Card",
}

static func phase_to_string(phase: Phase) -> String:
	return phase_to_string_map[phase]
