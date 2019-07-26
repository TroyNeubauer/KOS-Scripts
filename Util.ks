

function circle_distance {
	parameter
	p1,     //...this point...
	p2,     //...to this point...
	radius. //...around a body of this radius.
	local A is sin((p1:lat-p2:lat)/2)^2 + cos(p1:lat)*cos(p2:lat)*sin((p1:lng-p2:lng)/2)^2.
	return radius*constant():PI*arctan2(sqrt(A),sqrt(1-A))/90.
}.

// Display a message
FUNCTION notify {
  PARAMETER message.
  HUDTEXT("kOS: " + message, 3, 2, 50, YELLOW, false).
}

// Put a file on KSC
FUNCTION upload {
	PARAMETER name.
	COPYPATH("1:/" + name, "0:/" + name).
}

FUNCTION download {
	PARAMETER name.
	if(NOT EXISTS("0:/" + name)) {
		print "Cannot download non existant file! = " + name.
	}
	COPYPATH("0:/" + name, "1:/" + name).

}


FUNCTION require {
	PARAMETER name.
	if(EXISTS("1:/" + name)) {
		print "already downloaded file = " + name.
		return.
	}
	download(name).
	RUNPATH("1:/" + name).
	print "running " + name.
}

FUNCTION ish {
	PARAMETER center.
	PARAMETER offset.
	PARAMETER value.
	RETURN value > center - offset AND value < center + offset.
}

FUNCTION lerp {
	PARAMETER a.
	PARAMETER b.
	PARAMETER f.
	RETURN a + f * (b - a).
}


FUNCTION normalize {
	PARAMETER min.
	PARAMETER max.
	PARAMETER value.

	RETURN (value - min) / (max - min).
}


FUNCTION map {
	PARAMETER sourceMin.
	PARAMETER sourceMax.
	PARAMETER value.
	PARAMETER destMin.
	PARAMETER destMax.
	
	SET n TO normalize(sourceMin, sourceMax, value).
	RETURN lerp(destMin, destMax, n).
}

FUNCTION distanceFormula {
	PARAMETER x1.
	PARAMETER y1.
	PARAMETER x2.
	PARAMETER y2.
	RETURN sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1)).
	
}

FUNCTION manhattanDistance {
	PARAMETER x1.
	PARAMETER y1.
	PARAMETER x2.
	PARAMETER y2.
	RETURN abs(x2 - x1) + abs(y2 - y1).
	
}

FUNCTION clamp {
    PARAMETER min.
	PARAMETER max.
	PARAMETER value.
	
    if (value < min)
        SET value TO min.
    else if (value > max)
        SET value TO max.
    
    RETURN value.
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
