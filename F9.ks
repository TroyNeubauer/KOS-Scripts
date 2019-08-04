wait until SHIP:UNPACKED AND SHIP:LOADED.
CORE:DOACTION("open terminal", true).

//########## Global Lock Statements

LOCK progradeVec TO ship:velocity:orbit:NORMALIZED.
LOCK normalVec TO vcrs(progradeVec, -body:position):NORMALIZED.
LOCK radialVec TO vcrs(progradeVec, normalVec):NORMALIZED.

LOCK progradeVecSFS TO ship:velocity:surface:NORMALIZED.
LOCK radialVecSFS TO HEADING(0, 90):VECTOR:NORMALIZED.
LOCK gravity TO (BODY:MU / (ALTITUDE + BODY:RADIUS) ^ 2).
LOCK gravityVec TO -radialVecSFS * gravity.
//Accounts for the height of the first stage + landing legs
LOCK groundAlt TO SHIP:ALTITUDE - MAX(0, SHIP:GEOPOSITION:TERRAINHEIGHT) - 50.

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
	IF DEFINED G AND FR <> 0 { return -(F*LN(ABS(FR*t - M)) / FR) - G*t -(-(F*LN(M) / FR)) + SHIP:VERTICALSPEED.}
	ELSE { return SHIP:VERTICALSPEED. }
}

function Y { parameter t.
	SET A TO -(F*(FR*t - M)*LN(ABS(FR*t - M)) )/(FR*FR) - G*t*t/2 + t*(F*(LN(M) + 1) + FR*VERTICALSPEED) / FR.
	SET B TO -(F*(-M)*LN(M) )/(FR*FR).//Same as ^ except t=0
	return A - B + groundAlt.
}

//The equation that calculates height based off of burn time except solved for force needed
function GetForce { parameter t.
	return (FR^2 *(G*t^2 - 2*t*VERTICALSPEED )) / (2*(-FR*t*LN(ABS(FR*t - M)) + M*LN(ABS(FR*t - M)) + FR*t * LN(M) + FR*t)).
}


function fmt { parameter value, digits.
	SET pow TO 10^digits.
	return (round(value * pow)) / pow.
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

SET subUpdates TO 0.
SET mode TO 0.
SET modeName TO "Unknown".

//Set to true the first time a mode runs
SET newMode TO true.
SET lastMode TO -1.

LIST PARTS IN a.
FOR p IN a {
	IF p:NAME:CONTAINS("pad") {
		SET tower TO p.
		BREAK.
	}
}

IF NOT (DEFINED tower) {
	Notify("Failed to locate tower part.").
	wait 5.0.
	Stop().
}

function TowerSeperated {
	return tower:SHIP:NAME:CONTAINS("Debris").
}

SET printDelta TO 0.0.
SET lastMass TO SHIP:MASS.

until false {
	SET now TO MT.
	SET subUpdates TO subUpdates + 1.
	IF newMode {
		SET modeStart TO now.
	}
	SET modeTime TO now - modeStart.

	IF now - lastSpeedTime > 0.1 {
		SET printDelta TO now - lastSpeedTime.
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
	SET estimatedAccel TO SHIP:FACING:VECTOR * (totalThrust / SHIP:MASS) + gravityVec.
	SET maxAccel TO SHIP:FACING:VECTOR * (SHIP:MAXTHRUST / SHIP:MASS) + gravityVec.
	SET drag TO realAccel - estimatedAccel.
	IF realAccel = V(0,0,0) { SET drag TO V(0,0,0). }
	SET verticalDrag TO GetComponent(drag, radialVecSFS).

	IF drag:MAG < 0.1 {
		SET dragVec:SHOW TO false.
	} ELSE {
		SET dragVec:VEC TO verticalDrag * radialVecSFS:NORMALIZED.
		SET dragVec:SHOW TO true.
	}

	SET TTImpactList TO QuadraticPos(0.5*(drag:MAG-gravityVec:MAG), SHIP:VERTICALSPEED, groundAlt).
	IF TTImpactList:EMPTY { SET TTImpact TO 999999.9. }
	ELSE { SET TTImpact TO TTImpactList[0]. }
	SET impactTime TO TTImpact + now.

	SET obsPressure TO (SHIP:SENSORS:PRES / 100000 * CONSTANT:AtmToKPa) * AIRSPEED * AIRSPEED / 2.0.

	SET engineCount TO GetActiveEngineCount(GetFirstStageEngines()).
	SET G TO gravity.
	SET F TO 1000.0 * GetPotentialThrust(GetFirstStageEngines()).//thrust of currently active engines (N)
	SET FR TO NOMINAL_FUEL_FLOW * engineCount.//The rate at which fuel burns (kg/s)
	SET M TO 1000.0 * SHIP:MASS.//THe ship's current mass (kg)

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
		IF TowerSeperated() {
			print "Cannot Launch!".
			print "Tower already seperated".
			Stop().
		}
		IF newMode {
			SelectEngines(3).
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
		if now - ingTime > 7.5 {//Its been 5 seconds since the engines were activated
			Notify("Failed to reach acceptable thrust").
			SET THROTTLE to 0.
			Stop().
		}
		SET thrust TO GetCurrentThrust(GetFirstStageEngines()).//N
		SET weight TO (SHIP:MASS - tower:MASS) * gravity.//kg
		IF thrust > weight {
			Notify("Thrust is nominal").
			SET mode TO 2.//Thrust looks good
		}
	} ELSE IF mode = 2 {
//################################# LAUNCH #################################
		IF newMode {
			STAGE.
			SET modeName TO "Launch".
			SAS OFF. LIGHTS OFF. RCS OFF.
			SET warmupTime TO now - ingTime.
			SET __START_TIME__ TO TIME:SECONDS.
			SET lastSpeedTime TO 0.0.
			SET logfile to archive:CREATE("flight.csv").
			logfile:writeln("Time,Thrust,Altitude,Impact Time,Pressure, Drag").
		}
		IF MT > 55 {
			SET mode TO 3.
			SET THROTTLE to 0.
		} ELSE {
			SET pitch TO 90 - max((MT - 40) / 5, 0).
			SET STEERING TO HEADING(155, pitch).
		}

	} ELSE IF mode = 3 {
//################################# Boostback BURN PREP #################################
		IF newMode {
			SET s TO now.
			SET modeName TO "Boostback Burn Prep".
			RCS ON.
		}
		IF now - s > 60 OR VERTICALSPEED < 0.0 {
			SET mode TO 4.
			STAGE.
		}
	} ELSE IF mode = 4 {
//################################# Boostback BURN #################################
		IF newMode {
			SET modeName TO "Boostback Burn".
		}
		SET mode TO 5.
	} ELSE IF mode = 5 {
//################################# RE-ENTRY BURN PREP #################################
		BRAKES ON.
		IF newMode {
			SET modeName TO "Re-Entry Burn Prep".
			SelectEngines(3).
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
		SET STEERING TO SRFRETROGRADE.

		IF obsPressure < 75 OR AIRSPEED < 350 { SET mode TO 7. }
	} ELSE IF mode = 7 {
//################################# LANDING BURN PREP #################################
		IF newMode {
			SET modeName TO "Landing Burn Prep".
			SET THROTTLE TO 0.0.
			SelectEngines(2).
		}
		SET STEERING TO SRFRETROGRADE.
		SET burnTime TO BinarySearch(Vel@, 0.0, 0.1, 0.0, 15, false).
		SET finalHeight TO Y(burnTime).
		SET finalHeight TO finalHeight + warmupTime * VERTICALSPEED.
		IF finalHeight < 0.0 { SET mode TO 8. }
	} ELSE IF mode = 8 { 
//################################# LANDING THROTTLE UP #################################
		IF newMode {
			SET modeName TO "Landing Burn Throttle Up".
			SET THROTTLE TO 1.0.
		}
		FOR eng IN GetFirstStageEngines() {
			IF IsEngineNominal(eng) {
				SET burnStart TO now.
				Notify("Landing burn started at " + TTImpact).
				SET mode TO 9.
				BREAK.
			}
		}

	} ELSE IF mode = 9 { 
//################################# LANDING BURN #################################
		IF newMode {
			SET modeName TO "Landing Burn".
		}

		//No need to change burn calculation variables since they already account for the single engine thats running
		SET neededForce TO GetForce(burnTime - modeTime).
		SET THROTTLE TO clamp(0.4, 1.0, neededForce / F * 1000.0).

		//Change variables to calculate what time we would need to start the single engine burn 
		SET engineCount TO GetActiveEngineCount(GetFirstStageEngines()).
		SET F TO 1000.0 * GetPotentialThrust(SHIP:PARTSTAGGED("1-5")).//thrust of currently active engines (N)
		SET FR TO NOMINAL_FUEL_FLOW.//The rate at which fuel burns (kg/s)
		
		SET singleBurnTime TO BinarySearch(Vel@, 0.0, 0.1, 0.0, 15, false).
		SET finalHeight TO Y(singleBurnTime).

		SET STEERING TO SRFRETROGRADE.
		IF TTImpact < 3 { GEAR ON. }
		IF finalHeight > 0.0 { SET mode TO 10. }//The single engine burn will get us very close
		
	} ELSE IF mode = 10 {
//################################# SINGLE ENGINE BURN #################################
		IF newMode {
			SET singleEngineStart TO now.
			SelectEngines(1).
			SET modeName TO "Landing Burn Precise".
		}
		SET neededForce TO GetForce(singleBurnTime - modeTime).
		SET THROTTLE TO clamp(0.4, 1.0, neededForce / F * 1000.0).

		IF TTImpact < 3 { GEAR ON. }
		IF groundAlt < 2 OR SHIP:VERTICALSPEED > 0 { SET mode TO 11. }
	} ELSE IF mode = 11 {
//################################# SHUTDOWN #################################
		IF newMode {
			SET modeName TO "Shutdown".
			SET THROTTLE TO 0.0.
			UNLOCK STEERING.
			UNLOCK THROTTLE.
			Notify("The booster has landed").
		}
	} //modes
//################################# GLOBAL CODE (RUNS EVERY LOOP) #################################
	IF DEFINED logfile {
		logfile:writeln(now+","+totalThrust+","+groundAlt+", "+impactTime+", "+obsPressure+", "+drag:MAG).
	}

	SET newMode TO lastMode <> mode.
	SET lastMode TO mode.
	IF printing {
		CLEARSCREEN.
		print "Time: " + fmt(now, 2) + ", mode time: " + fmt(modeTime, 1).
		print "Landing time T-" + fmt(TTImpact, 2).
		print "Pressure " + fmt(obsPressure, 1).
		print "Height " + fmt(groundAlt, 1) + " m".
		print "Drag: " + fmt(drag:MAG, 3) + " m/s^2".
		print "Mode: " + modeName.
		print "================================".
		IF NOT newMode {
			IF mode = 1 {
				print "Thrust: " + fmt(thrust, -1) + " kN".
				print "Weight: " + fmt(weight, -1) + " kN".
			} ELSE IF mode = 7 {
				print "Burntime: " + fmt(burnTime, 2).
				print "Finalheight: " + fmt(finalHeight, 1).
			} ELSE IF mode = 9 {
				print "Single Burntime: " + fmt(burnTime, 2).
				print "Single Finalheight: " + fmt(finalHeight, 1).
			}
		}
		print "".
		print "Sub Updates: " + subUpdates + " delta " + fmt(printDelta, 3).
		SET subUpdates TO 0.
	}
	wait 0.001.
}
