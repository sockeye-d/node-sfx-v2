class_name Math


static func get_lsd_place(n: float, zero_threshold: float = 0.001) -> int:
	var i := 0
	var zero_check := false
	while n != 0.0:
		if n >= 1.0:
			zero_check = true
		if zero_check and n < zero_threshold:
			break
		n = fmod(10 * n, 1)
		i += 1
	return i
