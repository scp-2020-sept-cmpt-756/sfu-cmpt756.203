# Makefile for Gatling container
REG_ID=tedkirkpatrick
CREG=ghcr.io

GATLING_VER=3.4.2
IMAGE_NAME=$(CREG)/scp-2021-jan-cmpt-756/gatling:$(GATLING_VER)

DIR=../../gatling

# Convert relative pathname to absolute
ABS_DIR=$(realpath $(DIR))

CLUSTER_IP=NONE
USERS=1
SIM_NAME=ReadUserSim
SIM_PROJECT=proj756
SIM_FULL_NAME=$(SIM_PROJECT).$(SIM_NAME)

TMP_FILE=/tmp/123

build:
	docker image build -t $(IMAGE_NAME) .

run:
	docker container run --detach --rm -v $(ABS_DIR)/results:/opt/gatling/results -v $(ABS_DIR):/opt/gatling/user-files -v $(ABS_DIR)/target:/opt/gatling/target -e CLUSTER_IP=$(CLUSTER_IP) -e USERS=$(USERS) -e SIM_NAME=$(SIM_NAME) --label gatling $(IMAGE_NAME) -s $(SIM_FULL_NAME) > $(TMP_FILE)
	@echo
	@echo "*** Control-C out of the following when you've seen enough ***"
	@echo
	docker container logs `cat $(TMP_FILE)` --follow
