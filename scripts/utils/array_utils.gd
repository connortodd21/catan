class_name ArrayUtils


static func sum_array(numbers_array: Array) -> Variant:
	var total_sum: int = 0
	for number in numbers_array:
		total_sum += number
	return total_sum
