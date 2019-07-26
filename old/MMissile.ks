WAIT 1.0.

LOCK ACCELERATION TO AIRSPEED.
LOG "Time,Altitude,Acceleration" TO "data.csv".
SET countdownSecs TO 3.
SET profile TO 1.
SET profiles TO list(list(1500, 2500, 5000, 10000, 12000), list(400, 500, 700, 900, 1000)).

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

SET THROTTLE TO 1.0.
print "LAUNCH! - Lock vertical until above 2000m".
STAGE.

when MAXTHRUST = 0 THEN {
	wait 0.25.
	STAGE.
	wait 0.25.
	preserve.
}.

until ALTITUDE > flyheight / 2.0 OR MAXTHRUST = 0 {
	log (TIME:SECONDS + "," + ALTITUDE + "," + ACCELERATION) to "data.csv".
	wait 0.01.
}

//SET targetLatLon TO LATLNG(-20,-146).
//SET targetLatLon TO LATLNG(-1.532,-71.880).
//SET targetLatLon TO LATLNG(6.6357,-68.4229).
//SET targetLatLon TO LATLNG(30.2168,-69.9609).
SET targetLatLon TO LATLNG(0,0).

SET terrainHeight TO targetLatLon:TERRAINHEIGHT.

print terrainHeight.

SET Kpt TO 0.01000.//0.00499
SET Kit TO 0.00008.//0.00025
SET Kdt TO 0.01500.
SET PIDThrottle TO PIDLOOP(Kpt, Kit, Kdt).
SET PIDThrottle:SETPOINT TO targetSpeed.

SET Kpa TO 0.0400.
SET Kia TO 0.0010.
SET Kda TO 0.0000.
SET PIDAngle TO PIDLOOP(Kpa, Kia, Kda).
SET PIDAngle:SETPOINT TO 0.
SET PIDAngle:MINOUTPUT TO -30.
SET PIDAngle:MAXOUTPUT TO -PIDAngle:MINOUTPUT.

SET thrott TO 1.
SET angle TO 0.

until targetLatLon:DISTANCE < flyheight * 2.5 {
	SET thrott TO PIDThrottle:UPDATE(TIME:SECONDS, SHIP:AIRSPEED).
	SET thrott TO max(0.0, min(1.0, thrott)).
	print "Throttle: " + thrott at(0,4).
	SET THROTTLE TO thrott.
	
	SET angle TO PIDAngle:UPDATE(TIME:SECONDS, ALTITUDE - flyheight).
	print "Angle: " + angle at(0,5).
	
	
	SET steer TO HEADING(targetLatLon:HEADING, angle).
	LOCK STEERING TO steer.
	print "Distance from target = "+ROUND(targetLatLon:DISTANCE)+"m" at(0,2).
	print "Mach "+ (ROUND(SHIP:AIRSPEED) / 343) at(0,3).
	log (TIME:SECONDS + "," + ALTITUDE + "," + ACCELERATION) to "data.csv".
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
