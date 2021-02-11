#
# Front-end to bring some sanity to the litany of tools and switches
# in setting up, tearing down and validating your GCP cluster.
#
# There is an intentional parallel between this makefile
# and the corresponding file for Minikube or AWS. This makefile makes extensive
# use of pseudo-target to automate the error-prone and tedious command-line
# needed to get your environment up. There are some deviations between the
# two due to irreconcilable differences between a private single-node
# cluster (Minikube) and a public cloud-based multi-node cluster (EKS).
#
# The intended approach to working with this makefile is to update select
# elements (body, id, IP, port, etc) as you progress through your workflow.
# Where possible, stodout outputs are tee into .out files for later review.
#

GC=gcloud
KC=kubectl

# Keep all the logs out of main directory
LOG_DIR=logs

# these might need to change
NS=c756ns
CLUSTER_NAME=gcp756
GCP_CTX=gcp756
SUBNET_NAME=c756subnet

# Small machines to stay in free tier
MACHINE_TYPE="g1-small"
IMAGE_TYPE="COS"
DISK_TYPE="pd-standard"
DISK_SIZE="32"
NUM_NODES=3 # This was default for Google's "My First Cluster"
# The CMPT 756 stack will run with 2 `g1-small` nodes but has almost
# no memory to spare
#NUM_NODES=2

# Refer https://cloud.google.com/kubernetes-engine/versioning#available_versions
#   for details on version and zones.
#
# Pay attention to the release channel chosen and the versions available within it.
# The available channels are: rapid, regular, & stable.
# As of 2021-02-04, the rapid channel for us-west1-c supports 1.18.12-gke.1205
#
# Also see the lskver target below.
#
ZONE=us-west1-c
REL_CHAN=rapid
KVER=1.19.3

start:	showcontext
	date | tee  $(LOG_DIR)/gcp-start.log
	# This long list of options is the recommendation produced by Google's "My First Cluster"
	# The lines up to and including "metadata" are required for 756.
	# The lines after that may or may not be necessary
	$(GC) container clusters create $(CLUSTER_NAME) --zone $(ZONE) --num-nodes $(NUM_NODES) \
	      --cluster-version "$(KVER)" --release-channel "$(REL_CHAN)" \
	      --machine-type $(MACHINE_TYPE) --image-type $(IMAGE_TYPE) --disk-type $(DISK_TYPE) --disk-size $(DISK_SIZE) \
	      --metadata disable-legacy-endpoints=true \
	      --no-enable-basic-auth \
	      --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
	      --no-enable-stackdriver-kubernetes \
	      --addons HorizontalPodAutoscaling,HttpLoadBalancing \
	      --enable-ip-alias --no-enable-master-authorized-networks --enable-shielded-nodes \
	      --default-max-pods-per-node "110" --enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0 | tee -a $(LOG_DIR)/gcp-start.log
	      # These options were in original Google version but do not seem necessary for this project
	      #--network "projects/c756proj/global/networks/default" --subnetwork "projects/c756proj/regions/us-west1/subnetworks/default"
	$(GC) container clusters get-credentials $(CLUSTER_NAME) --zone $(ZONE) | tee -a $(LOG_DIR)/gcp-start.log
	# Use back-ticks for subshell because $(...) notation is used by make
	$(KC) config rename-context `$(KC) config current-context` $(GCP_CTX) | tee -a $(LOG_DIR)/gcp-start.log

stop:
	$(GC) container clusters delete $(CLUSTER_NAME) --zone $(ZONE) --quiet | tee $(LOG_DIR)/gcp-stop.log
	$(KC) config delete-context $(GCP_CTX) | tee -a $(LOG_DIR)/gcp-stop.log

up:
	@echo "NOT YET IMPLEMENTED"
	exit 1

down:
	@echo "NOT YET IMPLEMENTED"
	exit 1	

# Show current context and all GCP clusters
# This currently duplicates target "status"
ls: showcontext lsnc

# use this to show versions available for your ZONE
# refer: https://cloud.google.com/kubernetes-engine/versioning#available_versions
lskver:
	$(GC) container get-server-config --zone $(ZONE)

# Show all GCP clusters
lsnc:
	$(GC) container clusters --zone $(ZONE) list

status: showcontext
	$(GC) container clusters --zone $(ZONE) list | tee $(LOG_DIR)/gcp-status.log

# Only two $(KC) command in a vendor-specific Makefile
# Set context to latest GCP cluster
cd:
	$(KC) config use-context $(GCP_CTX)

# Vendor-agnostic but subtarget of vendor-specific targets such as "start"
showcontext:
	$(KC) config get-contexts
