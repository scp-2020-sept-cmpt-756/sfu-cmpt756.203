#
# Front-end to bring some sanity to the litany of tools and switches
# in setting up, tearing down and validating your EKS cluster.
#
# There is an intentional parallel between this makefile
# and the corresponding file for Minikube (mk.mak). This makefile makes extensive
# use of pseudo-target to automate the error-prone and tedious command-line
# needed to get your environment up. There are some deviations between the
# two due to irreconcilable differences between a private single-node
# cluster (Minikube) and a public cloud-based multi-node cluster (EKS).
#
# The intended approach to working with this makefile is to update select
# elements (body, id, IP, port, etc) as you progress through your workflow.
# Where possible, stodout outputs are tee into .out files for later review.
#

EKS=eksctl
KC=kubectl

# Keep all the logs out of main directory
LOG_DIR=logs

# these might need to change
NS=c756ns
CLUSTER_NAME=aws756
EKS_CTX=aws756


NGROUP=worker-nodes
NTYPE=t3.medium
REGION=ZZ-AWS-REGION
KVER=1.18


start: showcontext
	$(EKS) create cluster --name $(CLUSTER_NAME) --version $(KVER) --region $(REGION) --nodegroup-name $(NGROUP) --node-type $(NTYPE) --nodes 2 --nodes-min 2 --nodes-max 2 --managed | tee $(LOG_DIR)/eks-start.log
	# Use back-ticks for subshell because $(...) notation is used by make
	$(KC) config rename-context `$(KC) config current-context` $(EKS_CTX) | tee -a $(LOG_DIR)/eks-start.log

stop:
	$(EKS) delete cluster --name $(CLUSTER_NAME) --region $(REGION) | tee $(LOG_DIR)/eks-stop.log
	$(KC) config delete-context $(EKS_CTX) | tee -a $(LOG_DIR)/eks-stop.log

up:
	$(EKS) create nodegroup --cluster $(CLUSTER_NAME) --region $(REGION) --name $(NGROUP) --node-type $(NTYPE) --nodes 2 --nodes-min 2 --nodes-min 2 --managed | tee $(LOG_DIR)/eks-up.log

down:
	$(EKS) delete nodegroup --cluster=$(CLUSTER_NAME) --region $(REGION) --name=$(NGROUP) | tee $(LOG_DIR)/eks-down.log

# Show current context and all AWS clusters and nodegroups
# This currently duplicates target "status"
ls: showcontext lsnc

# Show all AWS clusters and nodegroups
lsnc: lscl
	$(EKS) get nodegroup --cluster $(CLUSTER_NAME) --region $(REGION)

# Show all AWS clusters
lscl:
	$(EKS) get cluster --region $(REGION) -v 0

status: showcontext
	$(EKS) get cluster --region $(REGION) | tee $(LOG_DIR)/eks-status.log
	$(EKS) get nodegroup --cluster $(CLUSTER_NAME) --region $(REGION) | tee -a $(LOG_DIR)/eks-status.log

# Only two $(KC) command in a vendor-specific Makefile
# Set context to latest EKS cluster
cd:
	$(KC) config use-context $(EKS_CTX)

# Vendor-agnostic but subtarget of vendor-specific targets such as "start"
showcontext:
	$(KC) config get-contexts

