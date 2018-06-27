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