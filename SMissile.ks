CLEARSCREEN.
print "KAC " + ADDONS:AVAILABLE("KAC") at(0,2).

if addons:tr:available() = false {
	print "Trajectories mod is not installed or is the wrong version." at(0,8).
	print "Script will fail, but you may press 1 to launch anyway." at(0,9).
} else {
	print "Press 1 to launch." at(0,9).
}

