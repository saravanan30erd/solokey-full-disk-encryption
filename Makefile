install: reinstall
	install -v -b -Dm644 src/skfde.conf "$(DESTDIR)/etc/skfde.conf"

reinstall:
	install -Dm644 src/hooks/skfde "$(DESTDIR)/usr/lib/initcpio/hooks/skfde"
	install -Dm644 src/install/skfde "$(DESTDIR)/usr/lib/initcpio/install/skfde"
	install -Dm755 src/skfde-enroll "$(DESTDIR)/usr/bin/skfde-enroll"
	install -Dm755 src/skfde-format "$(DESTDIR)/usr/bin/skfde-format"
	install -Dm755 src/skfde-open "$(DESTDIR)/usr/bin/skfde-open"
	install -Dm755 src/skfde-load "$(DESTDIR)/usr/bin/skfde-load"
	install -Dm755 src/skfde-cred "$(DESTDIR)/usr/bin/skfde-cred"
	install -Dm644 README.md "$(DESTDIR)/usr/share/doc/skfde/README.md"

all: install
