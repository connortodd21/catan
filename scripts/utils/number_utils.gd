class_name NumberUtils


# valid catan numbers are [2-12] (the result of rolling a 2-sided dice)
static func is_valid_number(number: int) -> bool:
	return number >= 2 and number <= 12
