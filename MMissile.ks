//Variables
SET countdownSecs TO 3.
SET profile TO 0.
SET profiles TO list(list(1000, 2000, 5000, 10000, 12000), list(300, 500, 700, 900, 1000)).

SET flyheight TO profiles[0][profile].
SET targetSpeed TO profiles[1][profile].

//clear output window
CLEARSCREEN.
SET THROTTLE TO 0.0.
//This is our countdown loop, which cycles from 10 to 0
PRINT "Counting down:".
FROM {local countdown is countdownSecs.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    PRINT countdown.
    WAIT 1. // pauses the script here for 1 second.
}
STAGE.

CLEARSCREEN.

//Make rocket keep adjusting automatically to point vertical.
LOCK STEERING TO UP.
LOCK SAS TO OFF.
LIGHTS OFF.
RCS OFF.

SET THROTTLE TO 1.0.
print "LAUNCH! - Lock vertical until above 2000m".
when MAXTHRUST = 0 THEN {
	wait 0.1.
	STAGE.
	preserve.
}.

until ALT:RADAR > flyheight / 3.0.

//SET targetLatLon TO LATLNG(-20,-146).
//SET targetLatLon TO LATLNG(-1.532,-71.880).
//SET targetLatLon TO LATLNG(6.6357,-68.4229).
SET targetLatLon TO LATLNG(30.2168,-69.9609).

SET terrainHeight TO targetLatLon:TERRAINHEIGHT.

print terrainHeight.

SET Kpt TO 0.00499.
SET Kit TO 0.00025.
SET Kdt TO 0.00000.
SET PIDThrottle TO PIDLOOP(Kpt, Kit, Kdt).
SET PIDThrottle:SETPOINT TO targetSpeed.

SET Kpa TO 0.020.
SET Kia TO 0.000.
SET Kda TO 0.500.
SET PIDAngle TO PIDLOOP(Kpa, Kia, Kda).
SET PIDAngle:SETPOINT TO 0.

SET thrott TO 1.
SET lastt TO 0.
SET angle TO 0.

until targetLatLon:DISTANCE < flyheight * 2.5 {
	SET t TO PIDThrottle:UPDATE(TIME:SECONDS, SHIP:AIRSPEED).
	SET delta TO t - lastt.
	SET thrott TO thrott + delta.
	SET thrott TO max(0.0, min(1.0, thrott)).
	print "Throttle: " + thrott at(0,4).
	SET THROTTLE TO thrott.
	
	SET angle TO PIDAngle:UPDATE(TIME:SECONDS, ALT:RADAR - flyheight).
	print "Angle: " + angle at(0,5).
	
	
	SET steer TO HEADING(targetLatLon:HEADING, angle).
	LOCK STEERING TO steer.
	print "Distance from target = "+ROUND(targetLatLon:DISTANCE)+"m" at(0,2).
	print "Mach "+ (ROUND(SHIP:AIRSPEED) / 343) at(0,3).
	wait 0.03.
	SET lastt TO t.
}.

CLEARSCREEN.

SET THROTTLE TO 1.0.
until targetLatLon:DISTANCE<-1{
	LOCK STEERING TO targetLatLon:ALTITUDEPOSITION(terrainHeight).
	print "DESTROY!!!" at(0,1).	
	wait 0.1.
}.

//copypath("0:/Missile.ks", "1:/")
