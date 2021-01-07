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
ZONE=us-west1-c
SUBNET_NAME=c756subnet

# Small machines to stay in free tier
MACHINE_TYPE="g1-small"
IMAGE_TYPE="COS"
DISK_TYPE="pd-standard"
DISK_SIZE="32"
NUM_NODES=3 # This was default for Google's "My First Cluster"

# This version is supported for us-west2
KVER=1.19.3

start:	showcontext
	date | tee  $(LOG_DIR)/gcp-cluster.log
	# This long list of options is the recommendation produced by Google's "My First Cluster"
	# The lines up to and including "metadata" are required for 756.
	# The lines after that may or may not be necessary
	$(GC) container clusters create $(CLUSTER_NAME) --zone $(ZONE) --num-nodes $(NUM_NODES) \
	      --cluster-version "1.18.12-gke.1200" --release-channel "rapid" \
	      --machine-type $(MACHINE_TYPE) --image-type $(IMAGE_TYPE) --disk-type $(DISK_TYPE) --disk-size $(DISK_SIZE) \
	      --metadata disable-legacy-endpoints=true \
	      --no-enable-basic-auth \
	      --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
	      --no-enable-stackdriver-kubernetes \
	      --addons HorizontalPodAutoscaling,HttpLoadBalancing \
	      --enable-ip-alias --no-enable-master-authorized-networks --enable-shielded-nodes \
	      --default-max-pods-per-node "110" --enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0 | tee -a $(LOG_DIR)/gcp-cluster.log
	      # These options were in original Google version but do not seem necessary for this project
	      #--network "projects/c756proj/global/networks/default" --subnetwork "projects/c756proj/regions/us-west1/subnetworks/default"
	$(GC) container clusters get-credentials $(CLUSTER_NAME) --zone $(ZONE) | tee -a $(LOG_DIR)/gcp-cluster.log
	# Use back-ticks for subshell because $(...) notation is used by make
	$(KC) config rename-context `$(KC) config current-context` $(GCP_CTX) | tee -a $(LOG_DIR)/GCP-cluster.log

stop:
	$(GC) container clusters delete $(CLUSTER_NAME) --zone $(ZONE) --async --quiet | tee $(LOG_DIR)/gcp-stop.log

up:
	@echo "NOT YET IMPLEMENTED"
	exit 1

down:
	@echo "NOT YET IMPLEMENTED"
	exit 1	

# Show all GCP clusters
# This currently duplicates target "status"
ls: showcontext
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
