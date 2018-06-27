// Display a message
FUNCTION notify {
  PARAMETER message.
  HUDTEXT("kOS: " + message, 3, 2, 50, YELLOW, false).
}

// Put a file on KSC
FUNCTION upload {
	PARAMETER name.
	COPYPATH("1:/" + name, "0:/" + name).
}

FUNCTION download {
	PARAMETER name.
	if(NOT EXISTS("0:/" + name)) {
		print "Cannot download non existant file! = " + name.
	}
	COPYPATH("0:/" + name, "1:/" + name).

}


FUNCTION require {
	PARAMETER name.
	if(EXISTS("1:/" + name)) {
		print "already downloaded file = " + name.
		return.
	}
	download(name).
	RUNPATH("1:/" + name).
	print "running " + name.
}




