LOCK P TO SHIP:BODY:ATM:ALTITUDEPRESSURE(ALTITUDE).
LOCK Q TO 0.5 * P * AIRSPEED.

WAIT 10.0.

SAS OFF.
RCS OFF.
LIGHTS OFF.

LOCK STEERING TO UP.
LOCK THROTTLE TO 1.0.

STAGE.
WAIT 0.5.

CLEARSCREEN.
SET lastThrust TO MAXTHRUST.
print "firing stage one with boosters".

WHEN TRUE then {
	print "Dynamic Pressure: " + Q at(0, 10).
	wait 0.1.
	PRESERVE.
}

UNTIL lastThrust > MAXTHRUST {
	SET lastThrust TO MAXTHRUST.
	WAIT 0.1.
}

STAGE.//Get rid of side boosters
wait 0.5.

SET lastThrust TO MAXTHRUST.
print "firing stage one - no boosters".

UNTIL lastThrust > MAXTHRUST {
	SET lastThrust TO MAXTHRUST.
	WAIT 0.1.
}

LOCK THROTTLE TO 1.0.
STAGE.//Get rid of stage one
wait 0.5.
print "waiting to start turn stage ".

UNTIL ALTITUDE > 38990 {
	WAIT 0.001.
}

print "turning ".
STAGE.//Enable helper motors
RCS ON.
LOCK STEERING TO HEADING(0, -90).

wait 0.5.
UNTIL ALTITUDE > 50750 {
	WAIT 0.1.
}

STAGE.//Start stage two
wait 0.5.
RCS OFF.

SET lastThrust TO MAXTHRUST.

UNTIL lastThrust - 100 > MAXTHRUST {
	SET lastThrust TO MAXTHRUST.
	WAIT 0.01.
}

STAGE.
print "firing stage three ".

until AIRSPEED > 2250 {
	WAIT 0.1.
}

LOCK THROTTLE TO 0.0.
print "lowering throttle for reentry".

until AIRSPEED < 1800 {
	wait 0.1.
}
LOCK STEERING to SRFPROGRADE.

LOCK THROTTLE TO 1.0.

print "Waiting to fire last stages at 4800m".
until ALT:RADAR < 4800 {
	wait 0.1.
}
SET interStageWaitTime TO 0.3.
print "Firing second to last stage".
STAGE.

until MAXTHRUST < 1 {
	wait 0.1.
}

print "Firing last stage! GO GO GO!!!".
STAGE.

WAIT 4.5.
STAGE.

until ALT:RADAR < 100 {
	wait 0.001.
}




