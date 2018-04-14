set countdownsecs to 3.
set targetlatlon to latlng(32.5195,11.25).
set deployaltitude to 3500.
set maxtimewarp to 50.
set apocorrecttime to 30.
set enabletimewarp to true.
set warheadcount to 8.

function printlandinginfo {
	

}
//clear output window
set throttle to 0.0.
//this is our countdown loop, which cycles from 10 to 0
print "counting down:".
from {local countdown is countdownsecs.} until countdown = 0 step {set countdown to countdown - 1.} do {
    print countdown.
    wait 1. // pauses the script here for 1 second.
}

clearscreen.

lock steering to heading(heading, 90).

sas off.
lights off.
rcs off.
set throttle to 1.0.
print "launch!" at(0,0).

stage.
set firststageliquidfuel to stage:liquidfuel.
wait 5.0.


set steering to heading(targetlatlon:heading, 90).

until airspeed > 80.0 { 
	print "waiting to get above 80 m/s" at (0,0).
	wait 0.1.
}

clearscreen.
until airspeed > 120.0 { 
	lock steering to heading(targetlatlon:heading, 80).
	print "turning over 10 degrees" at (0,0).
	wait 0.1.
}

clearscreen.
until stage:liquidfuel < 1.0 {
	lock steering to srfprograde.
	print "waiting for stage burnout. " + (100 - round(stage:liquidfuel / firststageliquidfuel * 100)) + "% done with burn" at (0,0).
	wait 0.01.
}

set throttle to 0.0.
lock steering to prograde.
wait 0.5.
stage.//ditch first stage
wait 1.0.
clearscreen.
set lastalt to altitude.
until altitude > 70000.
	wait 0.1.

until eta:apoapsis < apocorrecttime {
	print "waiting for apoapsis t-" + round(eta:apoapsis - apocorrecttime) at (0,0).
	if enabletimewarp {
		if (lastalt < 70000) and (lastalt >= 70000) {
			set kuniverse:timewarp:rate to 1.
			wait 0.5.
		}
		
		if(eta:apoapsis < apocorrecttime + 10)
			set kuniverse:timewarp:rate to 1.
		else if kuniverse:timewarp:mode = "physics"
			set kuniverse:timewarp:rate to min(maxtimewarp, 4).
		else 
			set kuniverse:timewarp:rate to maxtimewarp.
			
		set lastalt to altitude.
	}
	
	wait 0.1.

}
clearscreen.

print "getting forward direction..." at (0,0).

lock shipbearing to ship:bearing.

print "correcting trajectory" at (0,0).

set throttle to 0.1.
until 0 {
	if not addons:tr:hasimpact {
		print "error: no impact!".
		break.
    }
	set impact to addons:tr:impactpos.
	set delta to latlng(impact:lat - targetlatlon:lat, impact:lng - targetlatlon:lng).
	set delta to latlng(cos(delta:lat * shipbearing) - sin(delta:lng * shipbearing), sin(delta:lat * shipbearing) + cos(delta:lng * shipbearing)).
	print "delta: " + delta at (0,4).
	set finalangle to arctan2(delta:lat, delta:lng).
	print "ship angle  " + shipbearing at (0,5).
	print "final angle!!!: " + finalangle at (0,6).
	wait 0.1.
}


wait 5.0.

clearscreen.
until altitude < 70000 {
	print "waiting for rentry" at (0,0).
	if enabletimewarp {
		if(altitude < 80000)
			set kuniverse:timewarp:rate to 1.
		else
			set kuniverse:timewarp:rate to maxtimewarp.
	}
}
lock steering to retrograde.
clearscreen.
print "steering..." at (0,0).
wait 3.0.
stage.//ditch second stage
clearscreen.
print "releasing second stage" at (0,0).
wait 1.0.

clearscreen.
print "correcting trajectory" at (0,0).
rcs on.
//fixme: correct trajectory code here
wait 5.0.
rcs off.

lock steering to srfretrograde.

clearscreen.
until alt:radar < deployaltitude {
	print "waitig to get close to the ground. will deploy at " + deployaltitude + "m" at (0,0).
}
clearscreen.
print "deploying warheads " at (0,0).
stage.//deploy fering
wait 0.5.
set i to 1.
until i > warheadcount {
	//lock steering to heading(360 / warheadcount * i, 60).
	print "deploying warhead #" + (i + 1) at(0, 1).
	wait 0.5.
	stage.
	set i to i + 1.
}

clearscreen.
print "icbm script done" at(0,1).


