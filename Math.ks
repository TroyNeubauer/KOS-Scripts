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