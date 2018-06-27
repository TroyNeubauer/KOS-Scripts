FUNCTION greatCircleDistance {
	PARAMETER pos1.
	PARAMETER pos2.
	
	SET R  TO SHIP:BODY:RADIUS. // metres
	SET lat1 TO pos1:LAT.
	SET lat2 TO pos2:LAT.
	SET long1 TO pos1:LNG.
	SET long2 TO pos2:LNG.

	return R * arccos(sin(lat1) * sin(lat2) + cos(lat1) * cos(lat2) * cos(abs(long2 - long1))).
}

FUNCTION headingOfVector { // heading_of_vector returns the heading of the vector relative to the ship (number renge   0 to 360)
	PARAMETER vecT.

	LOCAL east IS VCRS(SHIP:UP:VECTOR, SHIP:NORTH:VECTOR).

	LOCAL trig_x IS VDOT(SHIP:NORTH:VECTOR, vecT).
	LOCAL trig_y IS VDOT(east, vecT).

	LOCAL result IS ARCTAN2(trig_y, trig_x).

	IF result < 0 {RETURN 360 + result.} ELSE {RETURN result.}
}

FUNCTION pitchOfVector { // pitch_of_vector returns the pitch of the vector relative to the ship (number range -90 to  90)
	PARAMETER vecT.

	RETURN 90 - VANG(SHIP:UP:VECTOR, vecT).
}