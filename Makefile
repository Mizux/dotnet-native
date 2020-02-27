PROJECT := dotnet-native
BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
SHA1 := $(shell git rev-parse --verify HEAD)

# General commands
.PHONY: help
BOLD=\e[1m
RESET=\e[0m

help:
	@echo -e "${BOLD}SYNOPSIS${RESET}"
	@echo -e "\tmake <target>"
	@echo
	@echo -e "${BOLD}DESCRIPTION${RESET}"
	@echo -e "\tRun dotnet cli..."
	@echo
	@echo -e "${BOLD}MAKE TARGETS${RESET}"
	@echo -e "\t${BOLD}help${RESET}: display this help and exit."
	@echo
	@echo -e "\t${BOLD}build_<rid>${RESET}: Build runtime.<rid>.Mizux.Foo."
	@echo -e "\t${BOLD}pack_<rid>${RESET}: Pack runtime.<rid>.Mizux.Foo."
	@echo
	@echo -e "\t${BOLD}build${RESET}: Build Mizux.Foo."
	@echo -e "\t${BOLD}pack${RESET}: Pack Mizux.Foo."
	@echo
	@echo -e "\t${BOLD}test${RESET}: Run Mizux.Foo.Tests."
	@echo
	@echo -e "\t${BOLD}app${RESET}: Run Mizux.FooApp."
	@echo
	@echo -e "\t${BOLD}clean${RESET}: Remove cache."
	@echo -e "\t${BOLD}clean_<rid>${RESET}: Remove cache for runtime.<rid>.Mizux.Foo."
	@echo
	@echo -e "\t${BOLD}<rid>${RESET}:"
	@echo -e "\t\t${BOLD}linux${RESET} (linux-x64)"
	@echo -e "\t\t${BOLD}osx${RESET} (osx-x64)"
	@echo -e "\t\t${BOLD}win${RESET} (win-x64)"
	@echo -e "\te.g. 'make build_win'"
	@echo
	@echo -e "branch: $(BRANCH)"
	@echo -e "sha1: $(SHA1)"

# Need to add cmd_distro to PHONY otherwise target are ignored since they do not
# contain recipe (using FORCE do not work here)
.PHONY: all
all: pack

# Delete all implicit rules to speed up makefile
MAKEFLAGS += --no-builtin-rules
.SUFFIXES:
# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =
# Keep all intermediate files
# ToDo: try to remove it later
.SECONDARY:

# Currently supported rid
RIDS = linux osx win

# $* stem
# $< first prerequist
# $@ target name

# BUILD
targets = $(addprefix build_, $(RIDS))
.PHONY: build $(targets)
build: Mizux.Foo/Mizux.Foo.csproj $(targets)
	dotnet build $<

.SECONDEXPANSION:
$(targets): build_%: runtime.$$*-x64.Mizux.Foo/runtime.$$*-x64.Mizux.Foo.csproj
	dotnet build $<

# PACK
targets = $(addprefix pack_, $(RIDS))
.PHONY: pack $(targets)
pack: Mizux.Foo/Mizux.Foo.csproj build $(targets)
	dotnet pack $<
	@unzip -l packages/Mizux.Foo.1.0.0.nupkg

.SECONDEXPANSION:
$(targets): pack_%: runtime.$$*-x64.Mizux.Foo/runtime.$$*-x64.Mizux.Foo.csproj build_%
	dotnet pack $<
	unzip -l packages/runtime.$*-x64.Mizux.Foo.1.0.0.nupkg

# TEST
.PHONY: test
test: Mizux.Foo.Tests/Mizux.Foo.Tests.csproj pack
	dotnet build Mizux.Foo.Tests
	dotnet test Mizux.Foo.Tests

# APP
.PHONY: app
app: Mizux.FooApp/Mizux.FooApp.csproj pack
	dotnet build Mizux.FooApp
	dotnet run --project Mizux.FooApp

# CLEAN
targets = $(addprefix clean_, $(RIDS))
.PHONY: clean clean_app $(targets)
clean: $(targets)
	-rm -rf Mizux.Foo/bin
	-rm -rf Mizux.Foo/obj
	-rm -rf packages/Mizux.Foo.1.0.0.nupkg
	-rmdir packages
	dotnet nuget locals all --clear

$(targets): clean_%:
	-rm -rf runtime.$*-x64.Mizux.Foo/bin
	-rm -rf runtime.$*-x64.Mizux.Foo/obj
	-rm -rf packages/runtime.$*-x64.Mizux.Foo.1.0.0.nupkg

clean_app:
	-rm -rf Mizux.FooApp/bin
	-rm -rf Mizux.FooApp/obj
