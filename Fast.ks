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
	print "firing stage one stage: " + STAGE:NUMBER at(0, 0).
	SET lastThrust TO MAXTHRUST.
	WAIT 0.1.
}

CLEARSCREEN.
wait 0.5.
STAGE.//Get rid of side boosters

SET lastThrust TO MAXTHRUST.
wait 0.5.

UNTIL lastThrust > MAXTHRUST {
	print "firing stage one stage: " + STAGE:NUMBER at(0, 0).
	SET lastThrust TO MAXTHRUST.
	WAIT 0.1.
}

CLEARSCREEN.
wait 0.5.//Get rid of stage one
STAGE.

UNTIL ALTITUDE > 43000 {
	print "waiting to start turn stage " + STAGE:NUMBER at(0, 0).
	WAIT 0.1.
}

CLEARSCREEN.
print "turning " at(0, 0).
STAGE.//Enable helper motors
RCS ON.
LOCK STEERING TO HEADING(0, -89.9).

UNTIL ALTITUDE > 55000 {
	print "turning..." at(0, 0).
	WAIT 0.1.
}

STAGE.
RCS OFF.

SET lastThrust TO MAXTHRUST.

UNTIL lastThrust > MAXTHRUST {
	print "firing stage two " + MAXTHRUST at(0, 0).
	SET lastThrust TO MAXTHRUST.
	WAIT 0.1.
}
