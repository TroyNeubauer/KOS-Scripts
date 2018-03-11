SET countdownSecs TO 3.
SET targetLatLon TO LATLNG(90,0).
SET deployALtitude TO 3500.
SET maxTimeWarp TO 50.
SET apoCorrectTime TO 30.
SET enableTimeWarp TO TRUE.
SET warheadCount TO 3.

//clear output window
CLEARSCREEN.
SET THROTTLE TO 0.0.
//This is our countdown loop, which cycles from 10 to 0
PRINT "Counting down:".
PRINT "TEST".
//FROM {local countdown is countdownSecs.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
//    PRINT countdown.
//    WAIT 1. // pauses the script here for 1 second.
//}


CLEARSCREEN.

LOCK STEERING TO HEADING(HEADING, 90).

SAS OFF.
LIGHTS OFF.
RCS OFF.
SET THROTTLE TO 1.0.
print "LAUNCH!" at(0,0).

STAGE.
SET firstStageLiquidFuel TO STAGE:LIQUIDFUEL.
WAIT 5.0.

SET STEERING TO HEADING(targetLatLon:HEADING, 90).

until AIRSPEED > 80.0 { 
	print "Waiting to get above 80 m/s" at (0,0).
	WAIT 0.1.
}

CLEARSCREEN.
until AIRSPEED > 120.0 { 
	LOCK STEERING TO HEADING(targetLatLon:HEADING, 80).
	print "Turning over 10 degrees" at (0,0).
	WAIT 0.1.
}

CLEARSCREEN.
until STAGE:LIQUIDFUEL < 1.0 {
	LOCK STEERING TO SRFPROGRADE.
	print "Waiting for stage burnout. " + (100 - round(STAGE:LIQUIDFUEL / firstStageLiquidFuel * 100)) + "% done with burn" at (0,0).
	wait 0.01.
}

SET THROTTLE TO 0.0.
LOCK STEERING TO PROGRADE.
WAIT 0.5.
Stage.//Ditch first stage
WAIT 1.0.
CLEARSCREEN.
SET lastMode TO kuniverse:timewarp:MODE.
until ETA:APOAPSIS < apoCorrectTime {
	print "Waiting for apoapsis t-" + round(ETA:APOAPSIS - apoCorrectTime) + " Mode: " + kuniverse:timewarp:MODE at (0,0).
	if enableTimeWarp {
		if (lastMode = "Physics") AND (kuniverse:timewarp:MODE = "RAILS") {
			set kuniverse:timewarp:rate to 1.
			WAIT 3.0.
		}
		
		if(ETA:APOAPSIS < apoCorrectTime + 10)
			set kuniverse:timewarp:rate to 1.
		else if kuniverse:timewarp:MODE = "Physics"
			set kuniverse:timewarp:rate to MIN(maxTimeWarp, 4).
		else 
			set kuniverse:timewarp:rate to maxTimeWarp.
			
		SET lastMode TO kuniverse:timewarp:MODE.
	}
	
	wait 0.1.

}
CLEARSCREEN.

print "Correcting trajectory" at (0,0).
//FIXME: Correct trajectory code here
wait 5.0.

CLEARSCREEN.
until ALTITUDE < 70000 {
	print "Waiting for rentry" at (0,0).
	if enableTimeWarp {
		if(ALTITUDE < 80000)
			set kuniverse:timewarp:rate to 1.
		else
			set kuniverse:timewarp:rate to maxTimeWarp.
	}
}
LOCK STEERING TO RETROGRADE.
CLEARSCREEN.
print "Steering..." at (0,0).
Wait 3.0.
Stage.//Ditch second stage
CLEARSCREEN.
print "Releasing second stage" at (0,0).
WAIT 1.0.

CLEARSCREEN.
print "Correcting trajectory" at (0,0).
RCS ON.
//FIXME: Correct trajectory code here
wait 5.0.
RCS OFF.

LOCK STEERING TO SRFRETROGRADE.

CLEARSCREEN.
until ALT:RADAR < deployALtitude {
	print "Waitig to get close to the ground. Will deploy at " + deployALtitude + "m" at (0,0).
}
CLEARSCREEN.
print "Deploying warheads " at (0,0).
Stage.//Deploy fering
Wait 0.5.
SET i TO 0.
until i >= warheadCount {
	LOCK STEERING TO HEADING(360 / warheadCount * i, 60).
	print "Deploying warhead #" + (i + 1) at(0, 1).
	WAIT 1.0.
	STAGE.
	SET i TO i + 1.
	WAIT 0.5.
}

CLEARSCREEN.
print "ICBM Script Done" at(0,1).


