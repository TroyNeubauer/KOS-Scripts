CLEARSCREEN.
WAIT 1.0. print "8".
WAIT 1.0. print "7". SAS OFF. LIGHTS OFF. RCS OFF.
WAIT 1.0. print "6".
WAIT 1.0. print "5". SET THROTTLE TO 1.0.
WAIT 1.0. print "4". STAGE.
WAIT 1.0. print "3". LOCK STEERING TO HEADING(HEADING, 90).
WAIT 1.0. print "2".
WAIT 1.0. print "1".
WAIT 0.8.
STAGE.

declare function InitList { declare parameter size. 


}

LOCK progradeVec TO ship:velocity:orbit:NORMALIZED.
LOCK normalVec TO vcrs(progradeVec, -body:position):NORMALIZED.
LOCK radialVec TO vcrs(progradeVec, normalVec):NORMALIZED.

LOCK progradeVecSFS TO ship:velocity:surface:NORMALIZED.
LOCK radialVecSFS TO HEADING(0, 90):VECTOR:NORMALIZED.

SET lastSpeed TO V(0,0,0).
SET lastSpeedTime TO MISSIONTIME.

SET dragVec TO VECDRAW(V(6,0,0), V(0, 0, 0), RGB(1,1,1), "Drag", 1.0, true, 0.5).

SET realAccel TO V(0,0,0).

until false {
	CLEARSCREEN.
	SET now TO MISSIONTIME.
	IF now - lastSpeedTime > 0.2 {
		SET speed TO ship:velocity:orbit.
		SET realAccel TO (speed - lastSpeed) / (now - lastSpeedTime).
		SET lastSpeed TO speed.
		SET lastSpeedTime TO now. 
	}
	SET gravity TO radialVecSFS * (BODY:MU / (ALTITUDE + BODY:RADIUS) ^ 2).
	SET estimatedAccel TO SHIP:FACING:VECTOR * (SHIP:MAXTHRUST / SHIP:MASS) - gravity.
	SET engineAccelMag TO (SHIP:AVAILABLETHRUST / SHIP:MASS).
	
	SET drag TO realAccel - estimatedAccel.
	IF drag:MAG < 0.1 {
		SET dragVec:SHOW TO false.
	} ELSE {
		SET dragVec:VEC TO drag.
		SET dragVec:SHOW TO true.
	}
	SET obsPressure TO SHIP:Q * AIRSPEED * AIRSPEED / 2.0.

	print "Predicted Accel " + estimatedAccel:MAG + " m/s^2".
	print "Gravity " + gravity:MAG + " m/s^2".
	print "Measured Accel " + realAccel:MAG + " m/s^2".
	print "Drag: " + drag:MAG + " m/s^2".
	print "Pressure: " + obsPressure.

	WAIT 0.01.
	
}
