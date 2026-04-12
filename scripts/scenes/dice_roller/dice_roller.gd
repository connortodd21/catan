class_name DiceRoller
extends PanelContainer

const ANIMATION_DURATION : float = 1.0
const INITIAL_INTERVAL : float = 0.05
const FINAL_INTERVAL : float = 0.18

@onready var die1: Die = %Die1
@onready var die2: Die = %Die2
@onready var roll_button: Button = %RollButton


func set_roll_enabled(val: bool) -> void:
	roll_button.disabled = not val


func _on_roll_button_pressed() -> void:
	if not die1.dice or not die2.dice:
		return

	var idx1 := randi() % die1.dice.sides.size()
	var idx2 := randi() % die2.dice.sides.size()
	var face1: DiceFace = die1.dice.sides[idx1]
	var face2: DiceFace = die2.dice.sides[idx2]

	roll_button.disabled = true
	await _animate_roll()

	die1.show_face(idx1)
	die2.show_face(idx2)

	var val1 : int = DiceFaces.type_to_int(face1.dice_face)
	var val2 : int = DiceFaces.type_to_int(face2.dice_face)
	var total : int = val1 + val2 if val1 != -1 and val2 != -1 else -1

	roll_button.disabled = false
	total = 7
	GameSignals.roll_dice(face1.dice_face, face2.dice_face, total)


func _animate_roll() -> void:
	var elapsed := 0.0
	var interval := INITIAL_INTERVAL

	while elapsed < ANIMATION_DURATION:
		die1.show_random_face()
		die2.show_random_face()
		await get_tree().create_timer(interval).timeout
		elapsed += interval
		interval = lerpf(INITIAL_INTERVAL, FINAL_INTERVAL, elapsed / ANIMATION_DURATION)
