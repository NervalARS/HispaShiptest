///Calculate the angle between two movables and the west|east coordinate
/proc/get_angle(atom/movable/start, atom/movable/end)//For beams.
	if(!start || !end)
		return 0
	var/dy =(32 * end.y + end.pixel_y) - (32 * start.y + start.pixel_y)
	var/dx =(32 * end.x + end.pixel_x) - (32 * start.x + start.pixel_x)
	if(!dy)
		return (dx >= 0) ? 90 : 270
	. = arctan(dx/dy)
	if(dy < 0)
		. += 180
	else if(dx < 0)
		. += 360

/proc/invert_hex(hex)
	var/length = length(hex)

	var/num = hex2num(hex)

	return num2hex((16 ** length) - 1 - num, length)

/proc/cubic_random(min, max)
	// Ensure we're in a valid range
	if(max <= min)
		return min

	var/span = max - min

	// Center-biased cubic curve: closer to average
	var/curve = ((rand() - 0.5) ** 3) * 4 + 0.5
	curve = clamp(curve, 0, 1)

	var/result = min + round(curve * span)

	return result
