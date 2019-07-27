LOCK progradeVec TO ship:velocity:orbit:NORMALIZED.
LOCK normalVec TO vcrs(progradeVec, -body:position):NORMALIZED.
LOCK radialVec TO vcrs(progradeVec, normalVec):NORMALIZED.

LOCK progradeVecSFS TO ship:velocity:surface:NORMALIZED.
LOCK radialVecSFS TO HEADING(0, 90):VECTOR:NORMALIZED.
LOCK gravity TO -radialVecSFS * (BODY:MU / (ALTITUDE + BODY:RADIUS) ^ 2).
LOCK groundAlt TO SHIP:ALTITUDE - MAX(0, SHIP:GEOPOSITION:TERRAINHEIGHT).


declare function Land {
	WAIT 2.0.
	STAGE.
	RCS ON.
	LOCK STEERING TO HEADING(HEADING, 90).


	SET lastSpeed TO V(0,0,0).
	SET lastSpeedTime TO MISSIONTIME.

	SET dragVec TO VECDRAW(V(6,0,0), V(0, 0, 0), RGB(1,1,1), "Drag", 1.0, true, 0.5).

	SET realAccel TO V(0,0,0).
	SET lastImpactTime TO 0.
	SET lastTime TO MISSIONTIME.
	SET lastImpactTimeMET TO MISSIONTIME.
	SET lastDeltaImpactTime TO 0.

	until false {

		SET now TO MISSIONTIME.
		IF now - lastSpeedTime > 0.2 {
			SET speed TO ship:velocity:surface.
			SET realAccel TO (speed - lastSpeed) / (now - lastSpeedTime).
			SET lastSpeed TO speed.
			SET lastSpeedTime TO now.
		}
		SET estimatedAccel TO SHIP:FACING:VECTOR * (THROTTLE * SHIP:AVAILABLETHRUST / SHIP:MASS) + gravity.
		SET maxAccel TO SHIP:FACING:VECTOR * (SHIP:MAXTHRUST / SHIP:MASS) + gravity.		
		SET drag TO realAccel - estimatedAccel.
		IF drag:MAG < 0.1 {
			SET dragVec:SHOW TO false.
		} ELSE {
			SET dragVec:VEC TO drag.
			SET dragVec:SHOW TO true.
		}
		SET obsPressure TO SHIP:Q * AIRSPEED * AIRSPEED / 2.0.

		SET TTImpact TO groundAlt / -SHIP:VERTICALSPEED.
		IF TTImpact > 0 AND TTImpact < 5 {
			GEAR ON.
		}
		IF SHIP:VERTICALSPEED < 0.0 {
			BRAKES ON.
		}
		SET impactTime TO TTImpact + MISSIONTIME.

		CLEARSCREEN.
		print "Predicted Accel " + estimatedAccel:MAG + " m/s^2".
		print "Measured Accel " + realAccel:MAG + " m/s^2".
		print "Drag: " + drag:MAG + " m/s^2".
		print "Time to impact " + TTImpact.
		if now - lastImpactTimeMET > 0.2 {
			SET lastDeltaImpactTime TO ((impactTime - lastImpactTime) / (now - lastImpactTimeMET)).
			SET lastImpactTimeMET TO now.
		}
		print "delta impact time " + lastDeltaImpactTime + " s error /s".
		SET lastImpactTime TO impactTime.
		SET lastTime TO now.
		WAIT 0.1.
	}
}

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

WAIT 10.0.
LOCK STEERING TO HEADING(180, 90).
WAIT 15.0.
LOCK STEERING TO HEADING(180, 88).

WAIT 25.0.
SET THROTTLE TO 0.0.
Land().

