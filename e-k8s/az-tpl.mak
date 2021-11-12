#
# Front-end to bring some sanity to the litany of tools and switches
# in setting up, tearing down and validating your Azure cluster.
#
# There is an intentional parallel between this makefile
# and the corresponding file for Minikube or EKS. This makefile makes extensive
# use of pseudo-target to automate the error-prone and tedious command-line
# needed to get your environment up. There are some deviations between the
# two due to irreconcilable differences between a private single-node
# cluster (Minikube) and a public cloud-based multi-node cluster (EKS).
#
# The intended approach to working with this makefile is to update select
# elements (body, id, IP, port, etc) as you progress through your workflow.
# Where possible, stodout outputs are tee into .out files for later review.
#

AZ=az
AKS=$(AZ) aks
KC=kubectl

# Keep all the logs out of main directory
LOG_DIR=logs

# these might need to change
GRP=c756ns
NS=c756ns
CLUSTER_NAME=az756
AZ_CTX=az756


# Standard_A2_v2: 2 vCore & 4 GiB RAM
NTYPE=Standard_A2_v2
NUM_NODES=3
REGION=canadacentral
# use $(AKS) get-versions --location $(REGION) to find available versions
# This version is supported for canadacentral
KVER=1.21.1

#
# Note that get-credentials fetches the access credentials for the managed Kubernetes cluster and inserts it
# into your kubeconfig (~/.kube/config)
#
# It might be a good idea to lock this down if the cluster is long-lived.
# Ref: https://docs.microsoft.com/en-us/azure/aks/control-kubeconfig-access
#
# Virtual nodes look like a great idea to save cost:
# Ref: https://docs.microsoft.com/en-us/azure/aks/virtual-nodes-cli
# But they're not available in the canadacentral region as of Oct 2020
#
start: showcontext
	date | tee  $(LOG_DIR)/az-start.log
	$(AZ) group create -o table --name $(GRP) --location $(REGION) | tee -a $(LOG_DIR)/az-start.log
	$(AKS) create -o table --resource-group $(GRP) --name $(CLUSTER_NAME) --kubernetes-version $(KVER) --node-count $(NUM_NODES) --node-vm-size $(NTYPE) --generate-ssh-keys | tee -a $(LOG_DIR)/az-start.log
	$(AKS) get-credentials --resource-group $(GRP) --name $(CLUSTER_NAME) --context $(AZ_CTX) --overwrite-existing | tee -a $(LOG_DIR)/az-start.log
	$(AKS) list -o table | tee -a $(LOG_DIR)/az-start.log
	date | tee -a $(LOG_DIR)/az-start.log


stop:
	$(AKS) delete --name $(CLUSTER_NAME) --resource-group $(GRP) -y | tee $(LOG_DIR)/az-stop.log
	$(KC) config delete-context $(AZ_CTX) | tee -a $(LOG_DIR)/az-stop.log

up:
	@echo "NOT YET IMPLEMENTED"
	exit 1

down:
	@echo "NOT YET IMPLEMENTED"
	exit 1	

# Show current context and all Azure clusters
# This currently duplicates target "status"
ls: showcontext lsnc

# Show all Azure clusters
lsnc:
	$(AKS) list -o table || true

status: showcontext
	$(AKS) list -o table | tee $(LOG_DIR)/az-status.log

# Only two $(KC) command in a vendor-specific Makefile
# Set context to latest Azure cluster
cd:
	$(KC) config use-context $(AZ_CTX)

# Vendor-agnostic but subtarget of vendor-specific targets such as "start"
showcontext:
	$(KC) config get-contexts
