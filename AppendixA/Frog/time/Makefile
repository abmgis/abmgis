ifeq ($(origin JAVA_HOME), undefined)
  JAVA_HOME=/usr
endif

ifeq ($(origin NETLOGO), undefined)
  NETLOGO=../..
endif

ifneq (,$(findstring CYGWIN,$(shell uname -s)))
  COLON=\;
  JAVA_HOME := `cygpath -up "$(JAVA_HOME)"`
else
  COLON=:
endif

SRCS=$(wildcard src/*.java)

time.jar time.jar.pack.gz: $(SRCS) manifest.txt
	mkdir -p classes
	$(JAVA_HOME)/bin/javac -g -encoding us-ascii -source 1.6 -target 1.6 -classpath $(NETLOGO)/NetLogo.jar:joda-time-2.2.jar -d classes $(SRCS)
	jar cmf manifest.txt time.jar -C classes .
	pack200 --modification-time=latest --effort=9 --strip-debug --no-keep-file-order --unknown-attribute=strip time.jar.pack.gz time.jar

time.zip: time.jar
	rm -rf time
	mkdir time
	cp -rp time.jar time.jar.pack.gz README.md Makefile src manifest.txt time
	zip -rv time time
	rm -rf time
