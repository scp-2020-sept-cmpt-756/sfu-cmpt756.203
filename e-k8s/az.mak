#
# Janky front-end to bring some sanity (?) to the litany of tools and switches
# in setting up, tearing down and validating your AKS cluster for working
# with k8s and istio.
#
# There is an intentional parallel between this makefile (aks.m for Azure KS)
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

AKS=az aks
AZ=az
KC=kubectl
IC=istioctl


# Azure specific cuz Azure has no eksctl equivalent
# Thus, resource management (AWS VPC etc) is explicit.
GRP=cmpt756e4

# these might need to change
NS=cmpt756e4
CLUSTERNAME=az756
CTX=az756


#NGROUP=worker-nodes
# Standard_A2_v2: 2 vCore & 4 GiB RAM
NTYPE=Standard_A2_v2
REGION=canadacentral
# use $(AKS) get-versions --location $(REGION) to find available versions
KVER=1.19.0

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
	date | tee az-cluster.log
	$(AZ) group create --name $(GRP) --location $(REGION) | tee -a az-cluster.log
	$(AKS) create --resource-group $(GRP) --name $(CLUSTERNAME) --kubernetes-version $(KVER) --node-count 2 --node-vm-size $(NTYPE) --generate-ssh-keys | tee -a az-cluster.log
	$(AKS) get-credentials --resource-group $(GRP) --name $(CLUSTERNAME) | tee -a az-cluster.log
	cp ~/.ssh/id_rsa az-cluster-public-key
	cat az-cluster-public-key | tee -a az-cluster.log
	cp ~/.ssh/id_rsa.pub az-cluster-private-key
	cat az-cluster-private-key | tee -a az-cluster.log
	$(AKS) list | tee -a az-cluster.log
	date | tee -a az-cluster.log


stop:
	$(AKS) delete --name $(CLUSTERNAME) --resource-group $(GRP) -y --no-wait | tee aks-stop.log

status: showcontext
	$(AKS) list | tee eks-status.log

dashboard: showcontext
	echo Please follow instructions at https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html
	echo Remember to 'pkill kubectl' when you are done!
	$(KC) proxy &
	open http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#!/login


extern: showcontext
	$(KC) -n istio-system get service istio-ingressgateway

cd:
	$(KC) config use-context $(CTX)

# show svc across all namespaces
lsa: showcontext
	$(KC) get svc --all-namespaces

# show deploy and pods in current ns; svc of cmpt756e4 ns
ls: showcontext
	$(KC) get gw,deployments,pods
	$(KC) -n $(NS) get svc

# show containers across all pods
lsd:
	$(KC) get pods --all-namespaces -o=jsonpath='{range .items[*]}{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}' | sort

# reinstate all the pieces of istio on a new cluster
# do this whenever you create/restart your cluster
# NB: You must rename the long context name down to $(CTX) before using this
reinstate:
	$(KC) config use-context $(CTX) | tee -a az-reinstate.log
	$(KC) create ns $(NS) | tee -a az-reinstate.log
	$(KC) config set-context $(CTX) --namespace=$(NS) | tee -a az-reinstate.log
	$(KC) label ns $(NS) istio-injection=enabled | tee -a az-reinstate.log
	$(IC) install --set profile=demo | tee -a az-reinstate.log

#setupdashboard:
#	$(KC) apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml
#	$(KC) get deployment metrics-server -n kube-system
#	$(KC) apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
#	$(KC) apply -f misc/eks-admin-service-account.yaml

showcontext:
	$(KC) config get-contexts
