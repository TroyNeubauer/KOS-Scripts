
//Calculates the solution to the quadratic equation ax^2+bx+c
//and returns any real anwsers as a list
//If there are two solutions, the smaller one is placed first
function Quadratic { parameter a, b, c.
	SET discrim TO b*b - 4*a*c.
	IF discrim < 0.0 { return LIST(). } //No real solutions

	SET right TO sqrt(discrim).
	
	SET solA TO (-b + right) / (2 * a).
	SET solB TO (-b - right) / (2 * a).
	IF solA = solB {//Both solutions are the same
		return LIST(solA).
	} ELSE {
		IF solA < solB {
			return LIST(solA, solB).
		} ELSE {
			return LIST(solB, solA).
		}
	}
}

//Calculates the solution to the quadratic equation ax^2+bx+c
//Returning only non-negitive anwsers
function QuadraticPos { parameter a, b, c.
	SET quad TO Quadratic(a, b, c).
	SET result TO LIST().
	FOR element IN quad {
		IF element >= 0.0 { result:ADD(element). }
	}
	return result.
}

function GetComponent { parameter vector, axis.
	return vector:MAG * vdot(vector:NORMALIZED, axis:NORMALIZED).
}

//p1 this point...
//p2 to this point...
//radius around a body of this radius.
function circle_distance { parameter p1, p2, radius.
	local A is sin((p1:lat-p2:lat)/2)^2 + cos(p1:lat)*cos(p2:lat)*sin((p1:lng-p2:lng)/2)^2.
	return radius*constant():PI*arctan2(sqrt(A),sqrt(1-A))/90.
}.

// Display a message
FUNCTION Notify { parameter message.
	HUDTEXT(message, 3, 2, 50, YELLOW, false).
}

// Put a file on KSC
FUNCTION Upload { parameter name.
	COPYPATH("1:/" + name, "0:/" + name).
}

FUNCTION Download { parameter name.
	if(NOT EXISTS("0:/" + name)) {
		print "Cannot download non existant file! = " + name.
	}
	COPYPATH("0:/" + name, "1:/" + name).

}


FUNCTION Require { parameter name.
	if(EXISTS("1:/" + name)) {
		print "already downloaded file = " + name.
		return.
	}
	download(name).
	RUNPATH("1:/" + name).
	print "running " + name.
}

FUNCTION lerp { parameter a, b, f.
	RETURN a + f * (b - a).
}


FUNCTION normalize { parameter min, max, value.

	RETURN (value - min) / (max - min).
}


FUNCTION map { parameter sourceMin, sourceMax, value, destMin, destMax.
	
	SET n TO normalize(sourceMin, sourceMax, value).
	RETURN lerp(destMin, destMax, n).
}

FUNCTION distanceFormula { parameter x1, y1, x2, y2.
	RETURN sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1)).
	
}

FUNCTION manhattanDistance { parameter x1, y1, x2, y2.
	RETURN abs(x2 - x1) + abs(y2 - y1).
	
}

FUNCTION clamp {
    parameter min, max, value.
	
    if (value < min)
        SET value TO min.
    else if (value > max)
        SET value TO max.
    
    RETURN value.
}

FUNCTION headingOfVector { // heading_of_vector returns the heading of the vector relative to the ship (number renge   0 to 360)
	parameter vecT.

	LOCAL east IS VCRS(SHIP:UP:VECTOR, SHIP:NORTH:VECTOR).

	LOCAL trig_x IS VDOT(SHIP:NORTH:VECTOR, vecT).
	LOCAL trig_y IS VDOT(east, vecT).

	LOCAL result IS ARCTAN2(trig_y, trig_x).

	IF result < 0 {RETURN 360 + result.} ELSE {RETURN result.}
}

FUNCTION pitchOfVector { // pitch_of_vector returns the pitch of the vector relative to the ship (number range -90 to  90)
	parameter vecT.

	RETURN 90 - VANG(SHIP:UP:VECTOR, vecT).
}
