

//#################### Function Library Complete. Begin Missile Code ####################

WAIT 1.0.

LOCK ACCELERATION TO AIRSPEED.
SET countdownSecs TO 3.
SET profile TO 1.
SET profiles TO list(list(1500, 2500, 5000, 10000, 20000), list(400, 500, 700, 900, 1500)).

SET flyheight TO profiles[0][profile].
SET targetSpeed TO profiles[1][profile].

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

//Make rocket keep adjusting automatically to point vertical.
LOCK STEERING TO UP.
LOCK SAS TO OFF.
LIGHTS OFF.
RCS OFF.

LOCK THROTTLE TO 0.0.
print "LAUNCH! - Lock vertical until above 2000m".
STAGE.

when MAXTHRUST = 0 THEN {
	wait 0.25.
	STAGE.
	wait 0.25.
	preserve.
}.

until ALTITUDE > flyheight / 2.0 OR MAXTHRUST = 0 {
	wait 0.01.
}

//SET targetLatLon TO LATLNG(-20,-146).
SET targetLatLon TO LATLNG(-1.532,-71.880).
//SET targetLatLon TO LATLNG(6.6357,-68.4229).
//SET targetLatLon TO LATLNG(30.2168,-69.9609).
//SET targetLatLon TO LATLNG(-47.8125,-129.37).//To the south west

//SET targetLatLon TO LATLNG(9.0308,-187.6245).//West bank of wierd circle thing

SET terrainHeight TO targetLatLon:TERRAINHEIGHT.
SET startLoc TO SHIP:GEOPOSITION.
SET startDist TO circle_distance(startLoc, targetLatLon, Kerbin:radius + flyheight).

print terrainHeight.
//2058 2193 2290 2293 

SET Kpt TO 0.01000.//0.00499
SET Kit TO 0.00008.//0.00025
SET Kdt TO 0.08500.
SET PIDThrottle TO PIDLOOP(Kpt, Kit, Kdt).
SET PIDThrottle:SETPOINT TO targetSpeed.

SET Kpa TO 0.0400.
SET Kia TO 0.0010.
SET Kda TO 0.8000.
SET PIDAngle TO PIDLOOP(Kpa, Kia, Kda).
SET PIDAngle:SETPOINT TO 0.
SET PIDAngle:MINOUTPUT TO -30.
SET PIDAngle:MAXOUTPUT TO -PIDAngle:MINOUTPUT.

SET thrott TO 1.
SET angle TO 0.

until targetLatLon:DISTANCE < flyheight * 3 {
	SET thrott TO PIDThrottle:UPDATE(TIME:SECONDS, SHIP:AIRSPEED).
	SET thrott TO max(0.0, min(1.0, thrott)).
	print "Throttle: " + thrott at(0,0).
	SET THROTTLE TO thrott.
	
	SET angle TO PIDAngle:UPDATE(TIME:SECONDS, ALTITUDE - flyheight).
	print "Angle: " + angle at(0,1).
	SET targetDist TO circle_distance(targetLatLon, SHIP:GEOPOSITION, Kerbin:radius + flyheight).
	SET distTravled TO circle_distance(startLoc, SHIP:GEOPOSITION, Kerbin:radius + flyheight).
	SET timeToDist TO targetDist / targetSpeed.
	
	SET steer TO HEADING(targetLatLon:HEADING, angle).
	LOCK STEERING TO steer.
	print "Distance to Target =   " + ROUND(targetDist) + "m" at(0,2).
	print "Time to Impact     = T-" + ROUND(timeToDist) + "s" at(0,3).
	print "Percent Done       =   " + ROUND(distTravled / startDist * 100.0) + "%" at (0,4).
	print "Distance Traveled  =   " + ROUND(distTravled) + "m" at(0,5).
	wait 0.01.
}.

CLEARSCREEN.

SET THROTTLE TO 1.0.
until targetLatLon:DISTANCE<-1{
	LOCK STEERING TO targetLatLon:ALTITUDEPOSITION(terrainHeight).
	print "DESTROY!!!" at(0,1).	
	wait 0.1.
}.

//copypath("0:/Missile.ks", "1:/")
