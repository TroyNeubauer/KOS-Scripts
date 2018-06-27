COPYPATH("0:/Util.ks", "1:/Util.ks").
RUN Util.ks.

SET filename TO "Fast 2.0.ks".
COPYPATH("0:/" + filename, "1:/" + filename).
RUN "Fast 2.0.ks".
