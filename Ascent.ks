require("Math").

function executeAscent {
	PARAMETER ascent.
	PARAMETER autoStage.
	PARAMETER desiredHeading.
	
	declare local altutudes TO ascent[0].
	declare local angles TO ascent[1].
	declare local steps TO altutudes:LENGTH.
	declare local stepNum TO 0.//0 = pre first step, 1 = between first step and second step. N indicates after the last step
	
	LIST ENGINES IN elist.

	declare local seperation TO false.
	declare local pitch TO 0.
	UNTIL FALSE {
		SET myAlt TO ALTITUDE.
		
		if(stepNum = 0) {
			SET pitch TO angles[0].
		} else if(stepNum = steps) {
			SET pitch TO angles[steps - 1].
		} else {
			SET pitch TO map(altutudes[stepNum - 1], altutudes[stepNum], myAlt, angles[stepNum - 1], angles[stepNum]).
		}
		print "pitch " + pitch at(0, 8).
		SET STEERING TO HEADING(desiredHeading, pitch).
		until stepNum = steps OR myAlt < altutudes[stepNum] {//Advance to the next step as we ascend
			SET stepNum TO stepNum + 1.
			print "going to next step!".
		}
	
		if(seperation) {
			LIST ENGINES IN elist.
			SET seperation TO false.
		}
		FOR e IN elist {
			if (STAGE:NUMBER = e:STAGE) AND e:FLAMEOUT AND STAGE:READY {
				if(autoStage) STAGE.
				else return.//Were done if we cant stage
				SET seperation TO TRUE.
				BREAK.
			}
		}	
		WAIT 0.01.
	}
}