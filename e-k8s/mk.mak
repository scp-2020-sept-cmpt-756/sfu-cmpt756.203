#
# Janky front-end to bring some sanity (?) to the litany of tools and switches
# in setting up, tearing down and validating your Minikube cluster for working
# with k8s and istio.
#
# There is an intentional parallel between this makefile (mk.m for Minkube)
# and the corresponding file for EKS (eks.m). This makefile makes extensive
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


# these might need to change
NS=cmpt756e4
CLUSTER=minikube
CTX=minikube
DRIVER=virtualbox

# developed and tested again 1.19.2
KVER=1.19.2

# output: mk-cluster.log
start:
	echo $(MK) start --kubernetes-version='$(KVER)' driver=$(DRIVER)> tee mk-cluster.log
	$(MK) start --kubernetes-version='$(KVER)' driver=$(DRIVER)| tee -a mk-cluster.log

stop: showcontext
	$(MK) stop | tee mk-stop.log

delete: showcontext
	$(MK) delete | tee mk-delete.log

# output: mk-status.log
status: showcontext
	$(MK) status | tee mk-status.log

# start up Minikube's nice dashboard
dashboard:
	$(MK) dashboard

# show svc inside istsio's ingressgateway
extern: showcontext
	$(KC) -n istio-system get svc istio-ingressgateway

# start up a tunnel to allow traffic into your cluster
lb: showcontext
	$(MK) tunnel

# switch to the cmpt756e4 context quickly
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
# output mk-pods.txt
lsd:
	$(KC) get pods --all-namespaces -o=jsonpath='{range .items[*]}{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}' | sort | tee mk-pods.txt

# reinstate all the pieces of istio on a new cluster
# do this whenever you restart your cluster
# output: mk-reinstate.log
reinstate:
	$(KC) config use-context $(CTX) | tee mk-reinstate.log
	$(KC) create ns $(NS) | tee -a mk-reinstate.log
	$(KC) config set-context $(CTX) --namespace=$(NS) | tee -a mk-reinstate.log
	$(KC) label ns $(NS) istio-injection=enabled | tee -a mk-reinstate.log
	$(IC) install --set profile=demo | tee -a mk-reinstate.log

# show contexts available
showcontext:
	$(KC) config get-contexts
