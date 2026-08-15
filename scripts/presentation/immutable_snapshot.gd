class_name ImmutableSnapshot
extends RefCounted


static func freeze(value: Variant) -> Variant:
	if value is Dictionary:
		var frozen_dictionary := {}
		for key in value:
			frozen_dictionary[freeze(key)] = freeze(value[key])
		frozen_dictionary.make_read_only()
		return frozen_dictionary
	if value is Array:
		var frozen_array := []
		for item in value:
			frozen_array.append(freeze(item))
		frozen_array.make_read_only()
		return frozen_array
	return value


static func is_deeply_read_only(value: Variant) -> bool:
	if value is Dictionary:
		if not value.is_read_only():
			return false
		for key in value:
			if not is_deeply_read_only(key) or not is_deeply_read_only(value[key]):
				return false
	elif value is Array:
		if not value.is_read_only():
			return false
		for item in value:
			if not is_deeply_read_only(item):
				return false
	return true

