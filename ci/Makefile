PROJECT := dotnet-native
BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
SHA1 := $(shell git rev-parse --verify HEAD)

# General commands
.PHONY: help
BOLD=\e[1m
RESET=\e[0m

help:
	@echo -e "${BOLD}SYNOPSIS${RESET}"
	@echo -e "\tmake <target> [NOCACHE=1]"
	@echo
	@echo -e "${BOLD}DESCRIPTION${RESET}"
	@echo -e "\ttest build inside docker container to have a reproductible build."
	@echo
	@echo -e "${BOLD}MAKE TARGETS${RESET}"
	@echo -e "\t${BOLD}help${RESET}: display this help and exit."
	@echo
	@echo -e "\tBuild using docker and the host platform."
	@echo -e "\t${BOLD}<distro>_<stage>${RESET}: build <stage> docker image for a specific distro."
	@echo -e "\t${BOLD}save_<distro>_<stage>${RESET}: Save the <stage> docker image for a specific distro."
	@echo -e "\t${BOLD}sh_<distro>_<stage>${RESET}: run a container using the <stage> docker image specified (debug purpose)."
	@echo -e "\t${BOLD}clean_<distro>_<stage>${RESET}: Remove cache and docker image."
	@echo -e "\t${BOLD}<stage>${RESET}: build <stage> docker images for ALL DISTROS."
	@echo -e "\t${BOLD}save_<stage>${RESET}: Save <stage> docker images for ALL DISTROS."
	@echo -e "\t${BOLD}clean_<stage>${RESET}: Remove cache and docker image."
	@echo -e "\t${BOLD}clean_native${RESET}: Remove ALL cache and docker image."
	@echo
	@echo -e "\tWith ${BOLD}<distro>${RESET}:"
	@echo -e "\t\t${BOLD}alpine${RESET} (edge)"
	@echo -e "\t\t${BOLD}archlinux${RESET} (latest)"
	@echo -e "\t\t${BOLD}centos${RESET} (latest)"
	@echo -e "\t\t${BOLD}debian${RESET} (latest)"
	@echo -e "\t\t${BOLD}fedora${RESET} (latest)"
	@echo -e "\t\t${BOLD}opensuse${RESET} (tumbleweed)"
	@echo -e "\t\t${BOLD}ubuntu${RESET} (rolling)"
	@echo
	@echo -e "\tWith ${BOLD}<stage>${RESET}:"
	@echo -e "\t\t${BOLD}env${RESET}"
	@echo -e "\t\t${BOLD}devel${RESET}"
	@echo -e "\t\t${BOLD}build${RESET}"
	@echo -e "\t\t${BOLD}test${RESET}"
	@echo -e "\t\t${BOLD}install_env${RESET}"
	@echo -e "\t\t${BOLD}install_devel${RESET}"
	@echo -e "\t\t${BOLD}install_build${RESET}"
	@echo -e "\t\t${BOLD}install_test${RESET}"
	@echo -e "\t\t${BOLD}export${RESET}"
	@echo -e "\te.g. 'make ubuntu_test'"
	@echo
	@echo -e "\tBuild using docker buildx with a platform specified."
	@echo -e "\t${BOLD}<platform>_<stage>${RESET}: build <stage> docker images for ALL DISTROS."
	@echo -e "\t${BOLD}<platform>_<distro>_<stage>${RESET}: build <stage> docker image for a specific distro."
	@echo -e "\t${BOLD}save_<platform>_<stage>${RESET}: Save <stage> docker images for ALL DISTROS."
	@echo -e "\t${BOLD}save_<platform>_<distro>_<stage>${RESET}: Save the <stage> docker image for a specific distro."
	@echo -e "\t${BOLD}sh_<platform>_<distro>_<stage>${RESET}: run a container using the <stage> docker image specified (debug purpose)."
	@echo -e "\t${BOLD}clean_platforms${RESET}: Remove ALL cache and docker image."
	@echo
	@echo -e "\tWith ${BOLD}<platform>${RESET}:"
	@echo -e "\t\t${BOLD}amd64${RESET}: linux/amd64 (x86_64)"
	@echo -e "\t\t${BOLD}386${RESET}: linux/386 (x86)"
	@echo -e "\t\t${BOLD}arm64${RESET}: linux/arm64 (aarch64, arm64v8)"
	@echo -e "\t\t${BOLD}arm${RESET}: linux/arm (armv7)"
	@echo -e "\t\t${BOLD}riscv64${RESET}: linux/riscv64 (RISC-V 64bits)"
	@echo -e "\t\t${BOLD}ppc64le${RESET}: linux/ppc64le (PowerPC 64Bits Little Endian)"
	@echo -e "\te.g. 'make amd64_ubuntu_test'"
	@echo -e "\tDocker image unavailable: arm64_archlinux"
	@echo
	@echo -e "\tGlobal targets."
	@echo -e "\t${BOLD}clean${RESET}: Remove cache and ALL docker images."
	@echo -e "\t${BOLD}distclean${RESET}: Remove everything."
	@echo
	@echo -e "\t${BOLD}NOCACHE=1${RESET}: use 'docker build --no-cache' when building container (default use cache)."
	@echo
	@echo -e "branch: $(BRANCH)"
	@echo -e "sha1: $(SHA1)"

# Need to add cmd_distro to PHONY otherwise target are ignored since they do not
# contain recipe (using FORCE do not work here)
.PHONY: all
all: build

# Delete all implicit rules to speed up makefile
MAKEFLAGS += --no-builtin-rules
.SUFFIXES:
# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES :=
# Keep all intermediate files
# ToDo: try to remove it later
.SECONDARY:

# Docker image name prefix.
IMAGE := ${PROJECT}

ifdef NOCACHE
DOCKER_BUILD_CMD := docker build --no-cache
DOCKER_BUILDX_CMD := docker buildx build --no-cache
else
DOCKER_BUILD_CMD := docker build
DOCKER_BUILDX_CMD := docker buildx build
endif
DOCKER_RUN_CMD := docker run --rm --init --net=host

# $* stem
# $< first prerequist
# $@ target name

export/%:
	-mkdir -pv $@

############
## NATIVE ##
############
# Currently supported distro
DISTROS = alpine archlinux centos debian fedora opensuse ubuntu
STAGES = env devel build test install_env install_devel install_build install_test

define make-stage-target =
#$$(info STAGE: $1)
#$$(info Create targets: $1 $(addsuffix _$1, $(DISTROS)).)
targets_$1 = $(addsuffix _$1, $(DISTROS))
.PHONY: $1 $$(targets_$1)
$1: $$(targets_$1)
$$(targets_$1): %_$1: docker/%/Dockerfile
	#@docker image rm -f ${IMAGE}:$$*_$1 2>/dev/null
	${DOCKER_BUILD_CMD} --target=$1 --tag ${IMAGE}:$$*_$1 -f $$< ..

#$$(info Create targets: save_$1 $(addprefix save_, $(addsuffix _$1, $(DISTROS))) (debug).)
save_targets_$1 = $(addprefix save_, $(addsuffix _$1, $(DISTROS)))
.PHONY: save_$1 $$(save_targets_$1)
save_$1: $$(save_targets_$1)
$$(save_targets_$1): save_%_$1: cache/%/docker_$1.tar
cache/%/docker_$1.tar: %_$1
	@rm -f $$@
	mkdir -p cache/$$*
	docker save ${IMAGE}:$$*_$1 -o $$@

#$$(info Create targets: $(addprefix sh_, $(addsuffix _$1, $(DISTROS))) (debug).)
sh_targets_$1 = $(addprefix sh_, $(addsuffix _$1, $(DISTROS)))
.PHONY: $$(sh_targets_$1)
$$(sh_targets_$1): sh_%_$1: %_$1
	${DOCKER_RUN_CMD} -it --name ${IMAGE}_$$*_$1 ${IMAGE}:$$*_$1

#$$(info Create targets: clean_$1 $(addprefix clean_, $(addsuffix _$1, $(DISTROS))).)
clean_targets_$1 = $(addprefix clean_, $(addsuffix _$1, $(DISTROS)))
.PHONY: clean_$1 $$(clean_targets_$1)
clean_$1: $$(clean_targets_$1)
$$(clean_targets_$1): clean_%_$1:
	docker image rm -f ${IMAGE}:$$*_$1 2>/dev/null
	rm -f cache/$$*/docker_$1.tar
endef

$(foreach stage,$(STAGES),$(eval $(call make-stage-target,$(stage))))

## MERGE ##
.PHONY: clean_native
clean_native: $(addprefix clean_, $(STAGES))
	rm -f $(addprefix cache/, $(DISTROS))

#$(info Create targets: export $(addsuffix _export, $(DISTROS)).)
targets_export = $(addsuffix _export, $(DISTROS))
.PHONY: export $$(targets_export)
export: $$(targets_export)
$(targets_export): %_export: %_build | export/%
	${DOCKER_RUN_CMD} \
    -v `pwd`/export/$*:/export \
		-it ${IMAGE}:$*_build \
		/bin/sh -c "cp build*/python/dist/*.whl /export"

##############
## PLATFORM ##
##############
PLATFORMS = amd64 386 arm64 arm riscv64

define make-platform-stage-target =
#$$(info PLATFORM: $1)
#$$(info STAGE: $2)
#$$(info Create targets: $1_$2 $(addprefix $1_, $(addsuffix _$2, $(DISTROS))).)
targets_$1_$2 = $(addprefix $1_, $(addsuffix _$2, $(DISTROS)))
.PHONY: $1_$2 $$(targets_$1_$2)
$1_$2: $$(targets_$1_$2)
$$(targets_$1_$2): $1_%_$2: docker/%/Dockerfile
	#@docker image rm -f ${IMAGE}:$1_$$*_$2 2>/dev/null
	${DOCKER_BUILDX_CMD} --platform linux/$1 --target=$2 --tag ${IMAGE}:$1_$$*_$2 -f $$< ..

#$$(info Create targets: save_$1_$2 $(addprefix save_$1_, $(addsuffix _$2, $(DISTROS))) (debug).)
save_targets_$1_$2 = $(addprefix save_$1_, $(addsuffix _$2, $(DISTROS)))
.PHONY: save_$1_$2 $$(save_targets_$1_$2)
save_$1_$2: $$(save_targets_$1_$2)
$$(save_targets_$1_$2): save_$1_%_$2: cache/$1/%/docker_$2.tar
cache/$1/%/docker_$2.tar: $1_%_$2
	@rm -f $$@
	mkdir -p cache/$1/$$*
	docker save ${IMAGE}:$1_$$*_$2 -o $$@

#$$(info Create targets: $(addprefix sh_$1_, $(addsuffix _$2, $(DISTROS))) (debug).)
sh_targets_$1_$2 = $(addprefix sh_$1_, $(addsuffix _$2, $(DISTROS)))
.PHONY: $$(sh_targets_$1_$2)
$$(sh_targets_$1_$2): sh_$1_%_$2: $1_%_$2
	${DOCKER_RUN_CMD} --platform linux/$1 -it --name ${IMAGE}_$1_$$*_$2 ${IMAGE}:$1_$$*_$2

#$$(info Create targets: clean_$1_$2 $(addprefix clean_$1_, $(addsuffix _$2, $(DISTROS))).)
clean_targets_$1_$2 = $(addprefix clean_$1_, $(addsuffix _$2, $(DISTROS)))
.PHONY: clean_$1_$2 $$(clean_targets_$1_$2)
clean_$1_$2: $$(clean_targets_$1_$2)
$$(clean_targets_$1_$2): clean_$1_%_$2:
	docker image rm -f ${IMAGE}:$1_$$*_$2 2>/dev/null
	rm -f cache/$1/$$*/docker_$2.tar
endef

define make-platform-target =
#$$(info PLATFORM: $1)
$(foreach stage,$(STAGES),$(eval $(call make-platform-stage-target,$1,$(stage))))

# merge
.PHONY: clean_$1
clean_$1: $(addprefix clean_$1_, $(STAGES))
	-rmdir $(addprefix cache/$1/, $(DISTROS))
	-rmdir cache/$1

#$$(info Create targets: $1_export $(addprefix $1_, $(addsuffix _export, $(DISTROS))).)
targets_$1_export = $(addprefix $1_, $(addsuffix _export, $(DISTROS)))
.PHONY: $1_export $$(targets_$1_export)
$1_export: $$(targets_$1_export)
$$(targets_$1_export): $1_%_export: $1_%_build | export/$1/%
	${DOCKER_RUN_CMD} \
    -v `pwd`/export/$1/$$*:/export \
		-it ${IMAGE}:$1_$$*_build \
		/bin/sh -c "cp build*/python/dist/*.whl /export"
endef

$(foreach platform,$(PLATFORMS),$(eval $(call make-platform-target,$(platform))))

## MERGE ##
.PHONY: clean_platforms
clean_platforms: $(addprefix clean_, $(PLATFORMS))

###########
## CLEAN ##
###########
.PHONY: clean
clean: clean_native clean_platforms
	docker container prune -f
	docker image prune -f
	-rmdir cache

.PHONY: distclean
distclean: clean
	-docker container rm -f $$(docker container ls -aq)
	-docker image rm -f $$(docker image ls -aq)
