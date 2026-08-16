class_name DiceRoller
extends PanelContainer

const ANIMATION_DURATION : float = 1.0
const INITIAL_INTERVAL : float = 0.05
const FINAL_INTERVAL : float = 0.18

signal roll_requested

@onready var die1: Die = %Die1
@onready var die2: Die = %Die2
@onready var roll_button: Button = %RollButton


func set_roll_enabled(val: bool) -> void:
	roll_button.disabled = not val


func _on_roll_button_pressed() -> void:
	roll_button.disabled = true
	roll_requested.emit()


func play_result(d1: DiceFaces.Type, d2: DiceFaces.Type) -> void:
	await _animate_roll()
	die1.show_face(_find_face_index(die1, d1))
	die2.show_face(_find_face_index(die2, d2))


func _find_face_index(die: Die, face_type: DiceFaces.Type) -> int:
	for i in die.dice.sides.size():
		if die.dice.sides[i].dice_face == face_type:
			return i
	return 0


func _animate_roll() -> void:
	var elapsed := 0.0
	var interval := INITIAL_INTERVAL

	while elapsed < ANIMATION_DURATION:
		die1.show_random_face()
		die2.show_random_face()
		await get_tree().create_timer(interval).timeout
		elapsed += interval
		interval = lerpf(INITIAL_INTERVAL, FINAL_INTERVAL, elapsed / ANIMATION_DURATION)
