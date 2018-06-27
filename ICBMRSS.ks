CLEARSCREEN.
require("Vectors").
require("Ascent").
require("Ascent").

SET DC TO LATLNG(38.9072, -77.0369).
SET SOUTHAMERICA TO LATLNG(-52.513892, -69.472251).
SET RUSSIA TO LATLNG(55.7558,37.6173).
SET NEWYORK TO LATLNG(40.7128, -74.0060).
SET MYHOUSE TO LATLNG(38.885353, -77.358929).

SET countdownSecs TO 7.
//SET targetLatLon TO LATLNG(55.7558,37.6173).//Russia
SET targetLatLon TO SOUTHAMERICA.//South America
SET deployALtitude TO 15000.
SET maxTimeWarp TO 50.
SET apoCorrectTime TO 30.
SET enableTimeWarp TO FALSE.
SET warheadCount TO 9.
SET delta TO LATLNG(100, 100).
SET logFile TO "log.csv".
SWITCH TO 0.
if(EXISTS(logFile)) {
	DELETEPATH(logFile).
}
LOG "Distance,Heading Error"to logFile.

SET THROTTLE TO 0.0.

SET STEERING TO HEADING(HEADING, 90).

SAS OFF.
LIGHTS OFF.
RCS OFF.

FROM {local countdown is countdownSecs.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    PRINT countdown.
	if(countdown = 6) {SET THROTTLE TO 1.0.}
	if(countdown = 5) {
		STAGE.
	}
    WAIT 1.
}

STAGE.
until AIRSPEED > 50.
CLEARSCREEN.

SET ascent TO LIST(LIST(200, 1000, 3000, 5000, 10000, 15000, 25000, 40000, 50000, 55000), LIST(0, 2, 5, 10, 25, 40, 60, 70, 80, 86)).

executeAscent(ascent, TRUE, 90, 5).


LIST ENGINES IN elist.

SET seperation TO false.
SET stagedCount TO 0.

SET lastDistance TO -1.
SET increaseDistanceCount TO 0.
SET increaseDistanceTotal TO 0.
UNTIL(stagedCount = 2){
	if(seperation){
		LIST ENGINES IN elist.
		SET seperation TO false.
	}
	FOR e IN elist {
		if (STAGE:NUMBER = e:STAGE) AND e:FLAMEOUT AND STAGE:READY {
			STAGE.
			SET stagedCount TO stagedCount + 1.
			SET seperation TO true.
			BREAK.
		}
	}
	print "Current Position:   " + SHIP:LATITUDE + ", " + SHIP:LONGITUDE at (0, 3).
	if(ADDONS:TR:hasImpact) {
		SET dist to greatCircleDistance(ADDONS:TR:IMPACTPOS, targetLatLon).
	} else {
		SET dist TO -1.
	}
	if(stagedCount = 1) {
		print "Distance:           " + dist at (0, 2).
		if(lastDistance = -1) {
			WAIT 5.0.
		} else {
			if(lastDistance < dist) {
				SET increaseDistanceCount TO increaseDistanceCount + 1.
				SET increaseDistanceTotal TO increaseDistanceTotal + 1.
			} else {
				SET increaseDistanceCount TO 0.
			}
		}
		SET lastDistance TO dist.
	}
	print "Bad Distance Count: " + increaseDistanceCount at (0, 5).
	print "Bad Distance ever: " + increaseDistanceTotal at (0, 6).
	wait 0.03.
	SET pitch TO max(5, 90 * (1 - ALTITUDE / 65000)).
	SET progradeHeading TO headingOfVector(SHIP:PROGRADE:FOREVECTOR).
	SET progradePitch TO pitchOfVector(SHIP:PROGRADE:FOREVECTOR).
	SET destHeading TO targetLatLon:HEADING.
	SET deltaHeading TO destHeading - progradeHeading.
	SET newHeading TO destHeading + deltaHeading.
	print "Heading Error:      " + deltaHeading at (0, 4).
	LOG dist + "," + deltaHeading to logFile.
	if(ALTITUDE > 30000) {
		if(abs(dist) < 1.0) {
			SET pitch to 0.
		}
		SET STEERING TO HEADING(newHeading, pitch).
		RCS OFF.
		print "Standard steering mode active" at(0,0).
	} else {
		if(AIRSPEED > 500) {
			RCS ON.
			SET STEERING TO SRFPROGRADE.
			print "Safe steering mode active" at(0,0).
		} else {
			SET STEERING TO HEADING(targetLatLon:HEADING, pitch).
			RCS OFF.
			print "Ascent steering mode active" at(0,0).
		}
	}
}
print "Done autostaging!" at(0,0).


SET THROTTLE TO 0.0.
WAIT 5.
CLEARSCREEN.
SET lastAlt TO ALTITUDE.
until ALTITUDE > 140000.
	WAIT 0.1.

until ETA:APOAPSIS < apoCorrectTime {
	print "Waiting for apoapsis t-" + round(ETA:APOAPSIS - apoCorrectTime) at (0,0).
	if enableTimeWarp {
		if (lastAlt < 70000) AND (lastAlt >= 70000) {
			set kuniverse:timewarp:rate to 1.
			WAIT 0.5.
		}
		
		if(ETA:APOAPSIS < apoCorrectTime + 10)
			set kuniverse:timewarp:rate to 1.
		else if kuniverse:timewarp:MODE = "Physics"
			set kuniverse:timewarp:rate to MIN(maxTimeWarp, 4).
		else 
			set kuniverse:timewarp:rate to maxTimeWarp.
			
		SET lastAlt TO ALTITUDE.
	}
	
	wait 0.1.
}
CLEARSCREEN.

print "Getting forward direction..." at (0,0).

LOCK shipBearing TO SHIP:BEARING.

print "Correcting trajectory" at (0,0).
//COrrect
print "DONE" at(0,8).

wait 5.0.

CLEARSCREEN.
until ALTITUDE < 140000 {
	print "Waiting for rentry" at (0,0).
	if enableTimeWarp {
		if(ALTITUDE < 150000)
			set kuniverse:timewarp:rate to 1.
		else
			set kuniverse:timewarp:rate to maxTimeWarp.
	}
}
LOCK STEERING TO RETROGRADE.
CLEARSCREEN.
print "Steering..." at (0,0).
Wait 3.0.

CLEARSCREEN.
print "Correcting trajectory" at (0,0).
RCS ON.
//FIXME: Correct trajectory code here
wait 5.0.
RCS OFF.

LOCK STEERING TO SRFRETROGRADE.

CLEARSCREEN.
until ALTITUDE < deployALtitude {
	print "Waitig to get close to the ground. Will deploy at " + deployALtitude + "m" at (0,0).
}
CLEARSCREEN.
print "Deploying warheads " at (0,0).
Stage.//Deploy fering
Wait 1.5.
SET i TO 1.
until i > warheadCount {
	print "Deploying warhead #" + (i) at(0, 1).
	WAIT 1.2.
	STAGE.
	SET i TO i + 1.
}

CLEARSCREEN.
print "ICBM Script Done" at(0,1).
