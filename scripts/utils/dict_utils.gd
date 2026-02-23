class_name DictUtils


# Inverts the keys and values for the provided dictionary and returns the inverted dictionary
static func invert_dictionary(dict: Dictionary) -> Dictionary:
	var inverted_dict = {}
	for key in dict:
		var value = dict[key]
		inverted_dict[value] = key
	return inverted_dict
	
