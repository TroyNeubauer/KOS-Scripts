
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

//Standard XOR function
function XOR { parameter a, b.
	IF NOT a AND NOT b { return false. }
	IF NOT a AND     b { return true.  }
	IF     a AND NOT b { return true.  }
	IF     a AND     b { return false. }
}


function BinarySearch { parameter func, startX, deltaX, goal, iterations, printing.
	SET last TO func:call(startX).
	SET x TO startX + deltaX.
	SET reverse TO x < 0.0.
	until false {
		SET now TO func:call(x).
		IF (last > 0 AND now < 0) OR (last < 0 AND now > 0) {
			SET left TO x - deltaX.
			SET right TO x.
			IF printing {
				print "left: func(" + left + ") = " + last.
				print "right: func(" + right + ") = " + now.
			}
			BREAK.
		}
		SET last TO now.
		SET x TO x + deltaX.
	}

	until iterations <= 0 {

		SET center TO (right + left) / 2.
		SET new TO func:call(center).
		
		IF XOR(new > 0.0, reverse) { SET left TO center. }//The function is decreasing and the center is still too early
		ELSE { SET right TO center. }
		IF printing {
			print "func(" + center + ") = " + new.
			print "new Left: " + left.
			print "new Right: " + right.
		}
		SET iterations TO iterations - 1.
    } 
}
//p1 this point...
//p2 to this point...
//radius around a body of this radius.
function circle_distance { parameter p1, p2, radius.
	local A is sin((p1:lat-p2:lat)/2)^2 + cos(p1:lat)*cos(p2:lat)*sin((p1:lng-p2:lng)/2)^2.
	return radius*constant():PI*arctan2(sqrt(A),sqrt(1-A))/90.
}.

// Display a message
function Notify { parameter message.
	HUDTEXT(message, 3, 2, 50, YELLOW, false).
}

// Put a file on KSC
function Upload { parameter name.
	COPYPATH("1:/" + name, "0:/" + name).
}

function Download { parameter name.
	if(NOT EXISTS("0:/" + name)) {
		print "Cannot download non existant file! = " + name.
	}
	COPYPATH("0:/" + name, "1:/" + name).

}


function Require { parameter name.
	if(EXISTS("1:/" + name)) {
		print "already downloaded file = " + name.
		return.
	}
	download(name).
	RUNPATH("1:/" + name).
	print "running " + name.
}

function Lerp { parameter a, b, f.
	RETURN a + f * (b - a).
}


function Normalize { parameter min, max, value.

	RETURN (value - min) / (max - min).
}


function Map { parameter sourceMin, sourceMax, value, destMin, destMax.
	
	SET n TO normalize(sourceMin, sourceMax, value).
	RETURN lerp(destMin, destMax, n).
}

function DistanceFormula { parameter x1, y1, x2, y2.
	RETURN sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1)).
	
}

function ManhattanDistance { parameter x1, y1, x2, y2.
	RETURN abs(x2 - x1) + abs(y2 - y1).
	
}

function Clamp {
    parameter min, max, value.
	
    if (value < min)
        SET value TO min.
    else if (value > max)
        SET value TO max.
    
    RETURN value.
}

function HeadingOfVector { // heading_of_vector returns the heading of the vector relative to the ship (number renge   0 to 360)
	parameter vecT.

	LOCAL east IS VCRS(SHIP:UP:VECTOR, SHIP:NORTH:VECTOR).

	LOCAL trig_x IS VDOT(SHIP:NORTH:VECTOR, vecT).
	LOCAL trig_y IS VDOT(east, vecT).

	LOCAL result IS ARCTAN2(trig_y, trig_x).

	IF result < 0 {RETURN 360 + result.} ELSE {RETURN result.}
}

function PitchOfVector { // pitch_of_vector returns the pitch of the vector relative to the ship (number range -90 to  90)
	parameter vecT.

	RETURN 90 - VANG(SHIP:UP:VECTOR, vecT).
}
