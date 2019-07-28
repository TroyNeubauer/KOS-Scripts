
//########## Global Lock Statements

LOCK progradeVec TO ship:velocity:orbit:NORMALIZED.
LOCK normalVec TO vcrs(progradeVec, -body:position):NORMALIZED.
LOCK radialVec TO vcrs(progradeVec, normalVec):NORMALIZED.

LOCK progradeVecSFS TO ship:velocity:surface:NORMALIZED.
LOCK radialVecSFS TO HEADING(0, 90):VECTOR:NORMALIZED.
LOCK gravity TO -radialVecSFS * (BODY:MU / (ALTITUDE + BODY:RADIUS) ^ 2).
LOCK groundAlt TO SHIP:ALTITUDE - MAX(0, SHIP:GEOPOSITION:TERRAINHEIGHT) - 25.


//########## Config Options

SET __START_TIME__ TO TIME:SECONDS.
LOCK MT TO TIME:SECONDS - __START_TIME__.


//########## Global Functions

function IsEngineNominal { parameter eng.
	return (eng:THRUST > 650) AND (eng:FUELFLOW > 230).
}

function GetFirstStageEngines {
	return SHIP:PARTSTAGGEDPATTERN("^1-[0-9]+").
}

function GetTotalThrust { parameter engines.
	SET totalThrust TO 0.
	FOR eng IN engines {
		SET totalThrust TO totalThrust + eng:THRUST.
	}
	return totalThrust.
}

//Called during flight when the engines are active
//Makes that all engines are present and shuts down the opposite engine if any go offline
function CheckEngines {
	if THROTTLE = 0.0 { return. }
	SET firstStage TO GetFirstStageEngines().
	IF firstStage:EMPTY { return. }//The first stage has been seperated
	SET unSeenEngines TO UNIQUESET(1,2,3,4,6,7,8,9).//1-4, 6-9 for all the engines on the oustide
	FOR eng IN firstStage {
	    SET engNum TO eng:TAG:SUBSTRING(2, 1):TONUMBER(0.0).
		if engNum <> 0.0 {
			IF unSeenEngines:CONTAINS(engNum) AND IsEngineNominal(eng)
			{ unSeenEngines:REMOVE(engNum). }
		}
	}.
	IF NOT unSeenEngines:EMPTY {
		FOR engNum IN unSeenEngines {
			SET otherNum TO 10 - engNum.
			if NOT unSeenEngines:CONTAINS(otherNum) {//The other engine is still active
				SET opposite TO SHIP:PARTSTAGGED("1-" + otherNum).
				if NOT opposite:EMPTY {
					opposite[0]:SHUTDOWN.
					Notify("ENGINE FAILURE: Shtting down engine " + otherNum).
				}
			}
		}
	}
}

function Stop {
	UNLOCK THROTTLE.
	UNLOCK STEERING.
	print "Program forcibly terminated".
	SHUTDOWN.
}

//########## Variables
RCS ON.
LOCK STEERING TO SRFRETROGRADE.

SET lastSpeed TO V(0,0,0).
SET lastSpeedTime TO MT.

SET dragVec TO VECDRAW(V(6,0,0), V(0, 0, 0), RGB(1,1,1), "Drag", 1.0, true, 0.5).

SET realAccel TO V(0,0,0).
SET lastImpactTime TO 0.
SET lastTime TO MT.
SET lastImpactTimeMET TO MT.
SET lastDeltaImpactTime TO 0.

SET mode TO 0.
SET modeName TO "Unknown".

//Set to true the first time a mode runs
SET newMode TO true.
SET lastMode TO -1.


until false {
	CLEARSCREEN.
	SET now TO MT.
	print "Time: " + now.
	IF mode = 0 {
//################################# STARTUP #################################
		SET modeName TO "Startup".
		IF GetFirstStageEngines()[0]:IGNITION {
			mode++.
		}
	} ELSE IF mode = 1 {
//################################# VERIFY THRUST #################################
		IF newMode {
			SET modeName TO "Verify Thrust".
			SET ingTime TO MT.
			switch to 0.
			if archive:EXISTS("flight.csv") {
				archive:DELETE("flight.csv").
			}
			set logfile to archive:CREATE("flight.csv").
			logfile:writeln("Time,Altitude,Impact Time,Pressure, Drag").
		}
		if MT - ingTime > 5.0 {//Its been 5 seconds since the engines were activated
			print "Failed to reach acceptable thrust".
			SET THROTTLE to 0.
			Stop().
		}
		SET allGood TO true.
		FOR eng IN GetFirstStageEngines() {
			IF NOT IsEngineNominal(eng) {
				SET allGood TO false.
				break.
			}
		}
		IF allGood {
			mode++.//Thrust looks good
		}
	} ELSE IF mode = 2 {
//################################# LAUNCH #################################
		IF newMode {
			SET modeName TO "Launch".
			SAS OFF. LIGHTS OFF. RCS OFF.
			LOCK STEERING TO HEADING(SHIP:HEADING, 90).
			SET warmupTime TO MT - ingTime.
		}
		IF MISSIONTIME > 110 {
			LOCK STEERING TO HEADING(100, 89).
			Notify("Steering Activated").
		} ELSE IF MISSIONTIME > 5 {
			LOCK STEERING TO HEADING(100, 90).
		} 

	} ELSE IF mode = 3 {//Wait for re-entry burn
//################################# RE-ENTRY BURN PREP #################################
		SET modeName TO "Re-Entry Burn Prep".

	} ELSE IF mode = 4 {//Re-entry burn
//################################# RE-ENTRY BURN #################################
		SET modeName TO "Re-Entry Burn".

	} ELSE IF mode = 5 {
//################################# LANDING BURN PREP #################################
		IF newMode {
			SET modeName TO "Landing Burn Prep".

		}
		CheckEngines().

		SET TTImpactList TO QuadraticPos(0.5*(drag:MAG-gravity:MAG), SHIP:VERTICALSPEED, groundAlt).
		IF TTImpactList:EMPTY { SET TTImpact TO 999999.9. }
		ELSE IF TTImpactList:LENGTH = 1 { SET TTImpact TO TTImpactList[0]. }
		ELSE {SET TTImpact TO TTImpactList[0]. }

		SET impactTime TO TTImpact + MT.
		IF TTImpact < 5 { GEAR ON. }
		IF SHIP:VERTICALSPEED < 0.0 AND groundAlt < 60000 { BRAKES ON. }

		print "Time to impact " + TTImpact.
		if now - lastImpactTimeMET > 0.2 {
			SET lastDeltaImpactTime TO ((impactTime - lastImpactTime) / (now - lastImpactTimeMET)).
			SET lastImpactTimeMET TO now.
		}
		print "delta impact time " + lastDeltaImpactTime + " s error /s".
		SET lastImpactTime TO impactTime.
		SET lastTime TO now.
		ShowStatus().
		logfile:writeln(MT+","+groundAlt+", "+impactTime+", "+obsPressure+", "+drag:MAG).
	} //modes
//################################# GLOBAL CODE (RUNS EVERY LOOP) #################################

	IF now - lastSpeedTime > 0.2 {
		SET speed TO ship:velocity:surface.
		SET realAccel TO (speed - lastSpeed) / (now - lastSpeedTime).
		SET lastSpeed TO speed.
		SET lastSpeedTime TO now.
	}
	SET totalThrust TO GetTotalThrust(GetFirstStageEngines()).
	SET estimatedAccel TO SHIP:FACING:VECTOR * (totalThrust / SHIP:MASS) + gravity.
	SET maxAccel TO SHIP:FACING:VECTOR * (SHIP:MAXTHRUST / SHIP:MASS) + gravity.
	SET drag TO realAccel - estimatedAccel.
	IF realAccel = V(0,0,0) { SET drag TO V(0,0,0). }
	SET verticalDrag TO GetComponent(drag, radialVecSFS).

	IF drag:MAG < 0.1 {
		SET dragVec:SHOW TO false.
	} ELSE {
		SET dragVec:VEC TO verticalDrag * radialVecSFS:NORMALIZED.
		SET dragVec:SHOW TO true.
	}
	SET obsPressure TO SHIP:Q * AIRSPEED * AIRSPEED / 2.0.

	print "ATM " + SHIP:Q + " atm".
	print "Total thrust " + totalThrust + " kN".
	print "Pressure " + obsPressure.
	print "Height " + groundAlt + " m".
	print "Drag: " + drag:MAG + " m/s^2".
	print "Mode: " + modeName.
	SET newMode TO lastMode <> mode.
	wait 0.1
}
