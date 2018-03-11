print "TEST!".
SET filename TO "ICBM.ks".
copypath("0:/" + filename, "1:/" + filename).
RUN "ICBM.ks".
