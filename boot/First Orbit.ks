COPYPATH("0:/Util.ks", "1:/Util.ks").
RUN Util.ks.

SET filename TO "orbit.ks".
COPYPATH("0:/" + filename, "1:/" + filename).
RUN "orbit.ks".
