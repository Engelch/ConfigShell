# Go parameters
GOCMD=go
GOBUILD=godebug
GORELEASE=gorelease
GO_EXEC_DEBUG=goexec-debug
GO_EXEC_RELEASE=goexec-release
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOTOOL=$(GOCMD) tool
GOGET=$(GOCMD) get
GOMOD=$(GOCMD) mod
GOINST=$(GOCMD) install

#Binary Name
APP 			:= $(shell pwd | xargs basename)
ifeq ($(APP), src)
	APP := $(shell pwd | xargs dirname | xargs basename)
endif

d:			build-debug
debug:		build-debug
r: 			build-relaese
release:	build-release
rd: 		run-debug
rr: 		run-release

# Build
build-debug:
	@$(GOBUILD) $(*)
	@echo "📦 Debug Build Done"

build-release:
	@$(GORELEASE) $(*)
	@echo "📦📦📦 RELEASE Build Done"

bpa: bumppatch build-debug

bmi: bumpminor build-debug

bma: bumpmajor build-debug

bumppatch:
	bpa

bumpminor:
	bmi

bumpmajor:
	bma

# Container-Building
container-setup:
	@ if ! test -e /opt/ConfigShell ; then  1>&2 echo ConfigShell not found ; exit 1 ; fi
	@ if ! test -d Container ; then mkdir Container ; echo creating Container/ ; fi
	@ if [ ! -f Container/Containerfile -a  ! -f Container/Containerfile.j2 ] ; then cp /opt/ConfigShell/share/Containerfile.j2 Container/ ; echo copying Containerfile.j2 ; fi
	@ if [ ! -f Container/00-container-containerfile-creator.sh -a ! -f Container/Containerfile ] ; then ln -fvs /opt/ConfigShell/bin/container-file-creator.sh Container/00-container-containerfile-creator.sh ; fi
	@ if [ ! -f Container/10-container-image-build.sh ] ; then ln -fvs /opt/ConfigShell/bin/container-image-build.sh Container/10-container-image-build.sh ; fi
	@ echo container-setup finished, please check Containerfile for required changes,...
	
container-build: container-setup
    # if Containerfile is not to be overwritten, it can be sufficient to remove the s-link 00-container-containerfile-creator.sh
	@ cd Container ; if [ -f 00-container-containerfile-creator.sh ] ; then ./00-container-containerfile-creator.sh ; echo created Containerfile ; fi
	@ cd Container ; ./10-container-image-build.sh ; echo container image built

# Test
test:
	@$(GOTEST) -v ./...
	@echo "🧪 Test Completed"

# Run
run-debug:
	@echo "🚀 Running Debug App"
	@$(GO_EXEC_DEBUG) $(*)

run-release:
	@echo "🚀🚀🚀 Running RELEASE App"
	@$(GO_EXEC_RELEASE) $(*)

clean:
	/bin/rm -fr build vendor
	/bin/rm -fr Container/ContainerBuild*
	find . -name *~ -type f -print -exec /bin/rm -f {} \;
	find . -name .DS_Store -print -type f -exec /bin/rm -f {} \;

