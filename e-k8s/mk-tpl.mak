#
# Front-end to bring some sanity to the litany of tools and switches
# in setting up, tearing down and validating your Minikube cluster.
#
# There is an intentional parallel between this makefile
# and the corresponding file for EKS (eks.mak). This makefile makes extensive
# use of pseudo-target to automate the error-prone and tedious command-line
# needed to get your environment up. There are some deviations between the
# two due to irreconcilable differences between a private single-node
# cluster (Minikube) and a public cloud-based multi-node cluster (EKS).
#
# The intended approach to working with this makefile is to update select
# elements (body, id, IP, port, etc) as you progress through your workflow.
# Where possible, stodout outputs are tee into .out files for later review.
#


MK=minikube
KC=kubectl
IC=istioctl

# Keep all the logs out of main directory
LOG_DIR=logs


# these might need to change
NS=c756ns
MK_CTX=minikube
DRIVER=virtualbox

# developed and tested against 1.19.2
KVER=1.19.4

start:
	$(MK) start -p $(MK_CTX) --kubernetes-version='$(KVER)' driver=$(DRIVER) | tee $(LOG_DIR)/mk-start.log
	$(MK) profile $(MK_CTX) | tee -a $(LOG_DIR)/mk-start.log

stop: showcontext
	$(MK) stop | tee $(LOG_DIR)/mk-stop.log

up:
	@echo "NOT YET IMPLEMENTED"
	exit 1

down:
	@echo "NOT YET IMPLEMENTED"
	exit 1	

# Show all Minikube clusters
# This currently duplicates target "status"
ls: showcontext
	$(MK) status

status: showcontext
	$(MK) status | tee $(LOG_DIR)/mk-status.log


# Special targets specific to Minikube
delete: showcontext
	$(MK) delete | tee $(LOG_DIR)/mk-delete.log

# start up Minikube's nice dashboard
dashboard:
	$(MK) dashboard

# start up a tunnel to allow traffic into your cluster
lb: showcontext
	$(MK) tunnel

# Only two $(KC) command in a vendor-specific Makefile
# Set context to latest GCP cluster
cd:
	$(KC) config use-context $(MK_CTX)

# Vendor-agnostic but subtarget of vendor-specific targets such as "start"
showcontext:
	$(KC) config get-contexts

