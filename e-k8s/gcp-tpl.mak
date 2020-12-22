#
# Janky front-end to bring some sanity (?) to the litany of tools and switches
# in setting up, tearing down and validating your AKS cluster for working
# with k8s and istio.
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

# these might need to change
NS=c756ns
CLUSTER_NAME=gcp756
ZONE=us-west1-c
SUBNET_NAME=c756subnet

# Small machines to stay in free tier
MACHINE_TYPE="g1-small"
IMAGE_TYPE="COS"
DISK_TYPE="pd-standard"
DISK_SIZE="32"


# Keep all the logs out of main directory
LOG_DIR=logs

# This version is supported for us-west2
KVER=1.19.3

start:
	date | tee  $(LOG_DIR)/gcp-cluster.log
	# This long list of options is the recommendation produced by Google's "My First Cluster"
	# The lines up to and including "metadata" are required for 756.
	# The lines after that may or may not be necessary
	$(GC) container clusters create $(CLUSTER_NAME) --zone $(ZONE) --num-nodes "3" \
	      --cluster-version "1.18.12-gke.1200" --release-channel "rapid" \
	      --machine-type $(MACHINE_TYPE) --image-type $(IMAGE_TYPE) --disk-type $(DISK_TYPE) --disk-size $(DISK_SIZE) \
	      --metadata disable-legacy-endpoints=true \
	      --no-enable-basic-auth \
	      --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
	      --no-enable-stackdriver-kubernetes \
	      --addons HorizontalPodAutoscaling,HttpLoadBalancing \
	      --enable-ip-alias --no-enable-master-authorized-networks --enable-shielded-nodes | tee -a $(LOG_DIR)/gcp-cluster.log
	      # These options were in original Google version but do not seem necessary for this project
	      #--network "projects/c756proj/global/networks/default" --subnetwork "projects/c756proj/regions/us-west1/subnetworks/default" --default-max-pods-per-node "110" --enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0


get-credentials:
	$(GC) container clusters get-credentials $(CLUSTER_NAME) --zone $(ZONE)

#
# Note that get-credentials fetches the access credentials for the managed Kubernetes cluster and inserts it
# into your kubeconfig (~/.kube/config)
#


stop:
	$(GC)  container clusters delete $(CLUSTER_NAME) --zone $(ZONE) --async --quiet | tee $(LOG_DIR)/gcp-stop.log

status: showcontext
	$(GC) container clusters --zone $(ZONE) list | tee $(LOG_DIR)/gcp-status.log

# dashboard: Haven't bothered to find Google dashboard

extern: showcontext
	$(KC) -n istio-system get service istio-ingressgateway

# cd: GCP context names are long and vary with zone, project, and other things

# show svc across all namespaces
lsa: showcontext
	$(KC) get svc --all-namespaces

# show deploy and pods in current ns; svc of cmpt756 ns
ls: showcontext
	$(KC) get gw,deployments,pods
	$(KC) -n $(NS) get svc

# show containers across all pods
lsd:
	$(KC) get pods --all-namespaces -o=jsonpath='{range .items[*]}{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}' | sort

# reinstate:  Not necessary (all the updates are retained until cluster is deleted)

showcontext:
	$(KC) config get-contexts
