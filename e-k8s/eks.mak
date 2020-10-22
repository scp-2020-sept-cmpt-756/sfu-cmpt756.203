#
# Janky front-end to bring some sanity (?) to the litany of tools and switches
# in setting up, tearing down and validating your EKS cluster for working
# with k8s and istio.
#
# There is an intentional parallel between this makefile (eks.m for Minkube)
# and the corresponding file for Minikube (mk.m). This makefile makes extensive
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
IC=istioctl

# these might need to change
NS=cmpt756e4
CLUSTERNAME=aws756
CTX=aws756


NGROUP=worker-nodes
NTYPE=t2.medium
REGION=us-east-1
KVER=1.17


start: showcontext
	$(EKS) create cluster --name $(CLUSTERNAME) --version $(KVER) --region $(REGION) --nodegroup-name $(NGROUP) --node-type $(NTYPE) --nodes 2 --nodes-min 2 --nodes-max 2 --managed | tee eks-cluster.log


stop:
	$(EKS) delete cluster --name $(CLUSTERNAME) --region $(REGION) | tee eks-delete.log

up:
	$(EKS) create nodegroup --cluster $(CLUSTERNAME) --region $(REGION) --name $(NGROUP) --node-type $(NTYPE) --nodes 2 --nodes-min 2 --nodes-min 2 --managed | tee repl-nodes.log

down:
	$(EKS) delete nodegroup --cluster=$(CLUSTERNAME) --region $(REGION) --name=$(NGROUP)
	rm repl-nodes.log

status: showcontext
	$(EKS) get cluster --region $(REGION) | tee eks-status.log
	$(EKS) get nodegroup --cluster $(CLUSTERNAME) --region $(REGION) | tee -a eks-status.log

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
	$(KC) config use-context $(CTX) | tee -a eks-reinstate.log
	$(KC) create ns $(NS) | tee -a eks-reinstate.log
	$(KC) config set-context $(CTX) --namespace=$(NS) | tee -a eks-reinstate.log
	$(KC) label ns $(NS) istio-injection=enabled | tee -a eks-reinstate.log
	$(IC) install --set profile=demo | tee -a eks-reinstate.log

setupdashboard:
	echo TODO
	
showcontext:
	$(KC) config get-contexts
