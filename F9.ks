wait until SHIP:UNPACKED AND SHIP:LOADED.
CORE:DOACTION("open terminal", true).

//########## Global Lock Statements

LOCK progradeVec TO ship:velocity:orbit:NORMALIZED.
LOCK normalVec TO vcrs(progradeVec, -body:position):NORMALIZED.
LOCK radialVec TO vcrs(progradeVec, normalVec):NORMALIZED.

LOCK progradeVecSFS TO ship:velocity:surface:NORMALIZED.
LOCK radialVecSFS TO HEADING(0, 90):VECTOR:NORMALIZED.
LOCK gravity TO -radialVecSFS * (BODY:MU / (ALTITUDE + BODY:RADIUS) ^ 2).
//Accounts for the height of the first stage + landing legs
LOCK groundAlt TO SHIP:ALTITUDE - MAX(0, SHIP:GEOPOSITION:TERRAINHEIGHT) - 51.

SET NOMINAL_FUEL_FLOW TO 236.92823.

//########## Config Options

SET __START_TIME__ TO TIME:SECONDS.
LOCK MT TO TIME:SECONDS - __START_TIME__.


//########## Global Functions

function IsEngineNominal { parameter eng.
	return (eng:THRUST > 650) AND (eng:FUELFLOW > (0.9 * NOMINAL_FUEL_FLOW)).
}

function GetFirstStageEngines {
	return SHIP:PARTSTAGGEDPATTERN("^1-[0-9]+").
}

function GetPotentialThrust { parameter engines.
	SET totalThrust TO 0.
	FOR eng IN engines {
		SET totalThrust TO totalThrust + eng:AVAILABLETHRUST.
	}
	return totalThrust.
}

function GetFuelFlow { parameter engines.
	SET flow TO 0.
	FOR eng IN engines {
		SET flow TO flow + eng:FUELFLOW.
	}
	return flow.
}

function GetCurrentThrust { parameter engines.
	SET totalThrust TO 0.
	FOR eng IN engines {
		SET totalThrust TO totalThrust + eng:THRUST.
	}
	return totalThrust.
}

function GetActiveEngineCount { parameter engines.
	SET count TO 0.
	FOR eng IN engines {
		IF eng:IGNITION { SET count TO count + 1. }
	}
	return count.
}


//Called during flight when the engines are active
//Makes that all engines are present and shuts down the opposite engine if any go offline
function CheckEngines {
	IF THROTTLE = 0.0 { return. }
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

//Turns on the amount of pairs of engines specified by count.
//count | engines used
//0		| 0
//1		| 1
//2		| 3
//3		| 5
function SelectEngines { local parameter count.
	SET count TO clamp(0, 5, count).
	SET firstStage TO GetFirstStageEngines().
	SET statusList TO LIST(false, false, false, false, false, false, false, false, false, false).
	IF count >= 1 {
		SET engList TO SHIP:PARTSTAGGED("1-5").
		IF engList:LENGTH > 0 {
			SET statusList[5] TO true.
			SET count TO count - 1.
		}
		SET engineNum TO 1.
		//Stop when we have the requested number of engines running
		//Or when we run out of engines
		UNTIL count = 0 OR engineNum = 5 {
			SET engListA TO SHIP:PARTSTAGGEDPATTERN("1-" + engineNum).
			IF engListA:LENGTH > 0 {
				SET engListB TO SHIP:PARTSTAGGEDPATTERN("1-" + (10 - engineNum)).
				IF engListB:LENGTH > 0 {//Activate both once we know they exist
					SET statusList[engineNum] TO true.
					SET statusList[10 - engineNum] TO true.
					SET count TO count - 1.
				}
			}
			SET engineNum TO engineNum + 1.
		}
	}
	SET engineNum TO 1.
	UNTIL engineNum = 10 {
		SET engList TO SHIP:PARTSTAGGEDPATTERN("1-" + engineNum).
		IF engList:LENGTH > 0 {
			SET eng TO engList[0].
			IF statusList[engineNum] <> eng:IGNITION {//The state must change
				IF statusList[engineNum] { eng:ACTIVATE. }
				ELSE { eng:SHUTDOWN. }
			}
		}
		SET engineNum TO engineNum + 1.
	}
}

function Stop {
	UNLOCK THROTTLE.
	UNLOCK STEERING.
	Notify("Program forcibly terminated").
	SHUTDOWN.
}

function Vel { parameter t.
	IF DEFINED G AND FR <> 0 { return -(F*LN(ABS(FR*t - M)) / FR) - G*t + SHIP:VERTICALSPEED. }
	ELSE { return SHIP:VERTICALSPEED. }
}

//########## Variables

SET lastSpeed TO V(0,0,0).
SET lastSpeedTime TO MT.

SET dragVec TO VECDRAW(V(6,0,0), V(0, 0, 0), RGB(1,1,1), "Drag", 1.0, true, 0.2).

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

SET lastMass TO SHIP:MASS.
until false {

	SET now TO MT.
	IF now - lastSpeedTime > 0.1 {
		SET deltaT TO now - lastSpeedTime.
		SET massLoss TO (lastMass - SHIP:MASS) / deltaT.
		SET lastMass TO SHIP:MASS.

		SET speed TO ship:velocity:surface.
		SET realAccel TO (speed - lastSpeed) / deltaT.
		SET lastSpeed TO speed.
		SET lastSpeedTime TO now.
		SET printing TO true.
	} ELSE {
		SET printing TO false.
	}
	SET totalThrust TO GetCurrentThrust(GetFirstStageEngines()).
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

	SET TTImpactList TO QuadraticPos(0.5*(drag:MAG-gravity:MAG), SHIP:VERTICALSPEED, groundAlt).
	IF TTImpactList:EMPTY { SET TTImpact TO 999999.9. }
	ELSE { SET TTImpact TO TTImpactList[0]. }
	SET impactTime TO TTImpact + now.

	SET obsPressure TO (SHIP:SENSORS:PRES / 100000 * CONSTANT:AtmToKPa) * AIRSPEED * AIRSPEED / 2.0.

	SET engineCount TO GetActiveEngineCount(GetFirstStageEngines()).
	SET G TO gravity:MAG.
	SET F TO 1000.0 * GetPotentialThrust(GetFirstStageEngines()).//thrust of currently active engines (N)
	SET FR TO NOMINAL_FUEL_FLOW * engineCount.//The rate at which fuel burns (kg/s)
	SET M TO 1000.0 * SHIP:MASS.//THe ship's current mass (kg)

	IF printing {
		CLEARSCREEN.
		print "Time: " + now.
		print "Landing time T-" + TTImpact.
		print "Burntime: " + burnTime.
	}

	IF mode = 0 {
//################################# STARTUP #################################
		SET modeName TO "Startup".
		RCS OFF.
		LIGHTS OFF.
		IF GetFirstStageEngines()[0]:IGNITION {
			SET mode TO 1.
		}
	} ELSE IF mode = 1 {
//################################# VERIFY THRUST #################################
		IF newMode {
			SET steeringmanager:MAXSTOPPINGTIME TO 20.
			SET steeringmanager:PITCHPID:KD TO 2.5.
			SET steeringmanager:PITCHPID:KP TO steeringmanager:PITCHPID:KP * 1.5.
			SET THROTTLE TO 1.0.//Make sure the engines are actually firing
			SET modeName TO "Verify Thrust".
			SET ingTime TO now.
			switch to 0.
			if archive:EXISTS("flight.csv") {
				archive:DELETE("flight.csv").
			}
		}
		if now - ingTime > 5.0 {//Its been 5 seconds since the engines were activated
			Notify("Failed to reach acceptable thrust").
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
			SET mode TO 2.//Thrust looks good
		}
	} ELSE IF mode = 2 {
//################################# LAUNCH #################################
		IF newMode {
			SET modeName TO "Launch".
			SAS OFF. LIGHTS OFF. RCS OFF.
			SET warmupTime TO now - ingTime.
			STAGE.
			SET __START_TIME__ TO TIME:SECONDS.
			SET logfile to archive:CREATE("flight.csv").
			logfile:writeln("Time,Thrust,Altitude,Impact Time,Pressure, Drag").
		}
		IF MT > 140 {
			SET mode TO 3.
			STAGE.
		} ELSE {
			SET pitch TO 90 - max((MT - 100) / 40, 0).
			SET STEERING TO HEADING(95, pitch).
		}

	} ELSE IF mode = 3 {
//################################# Boostback BURN PREP #################################
		SET mode TO 4.

	} ELSE IF mode = 4 {
//################################# Boostback BURN #################################
		SET mode TO 5.

	} ELSE IF mode = 5 {
//################################# RE-ENTRY BURN PREP #################################
		BRAKES ON.
		IF newMode {
			SET modeName TO "Re-Entry Burn Prep".
			SelectEngines(3).
			RCS ON.
		}
		IF SHIP:VERTICALSPEED > 0.0 {
			SET STEERING TO HEADING(0, 90).
		} ELSE {
			SET STEERING TO SRFRETROGRADE.
			IF obsPressure > 100 { SET mode TO 6. }
		}
	} ELSE IF mode = 6 {
//################################# RE-ENTRY BURN #################################
		IF newMode {
			SET modeName TO "Re-Entry Burn".
			SET THROTTLE TO 1.0.
		}

		IF obsPressure < 75 OR AIRSPEED < 350 { SET mode TO 7. }
	} ELSE IF mode = 7 {
//################################# LANDING BURN PREP #################################
		IF newMode {
			SET modeName TO "Landing Burn Prep".
			SET THROTTLE TO 0.0.
			SelectEngines(2).
		}
		IF F = 0 {
			Notify("No thrust for landing burn!").
		}
		IF TTImpact < (burnTime + warmupTime) { SET mode TO 8. }
	} ELSE IF mode = 8 { 
//################################# LANDING BURN #################################
		IF newMode {
			SET modeName TO "Landing Burn".
			//SET THROTTLE TO 1.0.
			SET initalBurnTime TO burnTime.
		}
		IF DEFINED burnStart {
			IF TTImpact < 5 { GEAR ON. }
			IF groundAlt < 1 OR SHIP:VERTICALSPEED > 0 { SET mode TO 9. }
			IF printing {
				print "V(1) = " + Vel(1).
				print "V(2) = " + Vel(2).
				print "V(3) = " + Vel(3).
				print "V(5) = " + Vel(5).
				print "V(8) = " + Vel(8).
				print "V(10) = " + Vel(10).
			}
		} ELSE {
			FOR eng IN GetFirstStageEngines() {
				IF IsEngineNominal(eng) {
					SET burnStart TO now.
					Notify("Landing burn started").
					BREAK.
				}
			}
		}

	} ELSE IF mode = 9 {
//################################# SHUTDOWN #################################
		IF newMode {
			SET modeName TO "Shutdown".
			SET THROTTLE TO 0.0.
			UNLOCK STEERING.
			UNLOCK THROTTLE.
			Notify("THe booster has landed").
		}
	} //modes
//################################# GLOBAL CODE (RUNS EVERY LOOP) #################################
	IF DEFINED logfile {
		logfile:writeln(now+","+totalThrust+","+groundAlt+", "+impactTime+", "+obsPressure+", "+drag:MAG).
	}

	IF printing {
		print "Pressure " + obsPressure.
		print "Height " + groundAlt + " m".
		print "Drag: " + drag:MAG + " m/s^2".
		print "Mode: " + modeName.
	}
	SET newMode TO lastMode <> mode.
	SET lastMode TO mode.
	wait 0.001.
}
