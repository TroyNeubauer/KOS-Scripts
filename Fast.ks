WAIT 3.0.

SAS OFF.
RCS OFF.
LIGHTS OFF.

LOCK STEERING TO UP.

STAGE.
WAIT 0.5.

CLEARSCREEN.
SET lastThrust TO MAXTHRUST.

UNTIL lastThrust > MAXTHRUST {
	print "THRUST: " + MAXTHRUST at(0, 0).
	SET lastThrust TO MAXTHRUST.
	WAIT 0.1.
}

STAGE.
CLEARSCREEN.

UNTIL ALTITUDE > 55000 {
	print "WAITNIG: " at(0, 0).
	WAIT 0.1.
}

CLEARSCREEN.
print "turning " at(0, 0).

RCS ON.
LOCK STEERING TO SHIP:UP:INVERSE.
WAIT 3.0.

STAGE.
RCS OFF.

SET lastThrust TO MAXTHRUST.

UNTIL lastThrust > MAXTHRUST {
	print "THRUST: " + MAXTHRUST at(0, 0).
	SET lastThrust TO MAXTHRUST.
	WAIT 0.1.
}
