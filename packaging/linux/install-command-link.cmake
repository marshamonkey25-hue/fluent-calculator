# CPACK_SET_DESTDIR preserves this private /opt install and the public launcher.
file(MAKE_DIRECTORY "$ENV{DESTDIR}/usr/bin")
file(CREATE_LINK "/opt/fluent-calculator/bin/fluent-calculator"
    "$ENV{DESTDIR}/usr/bin/fluent-calculator" SYMBOLIC)
