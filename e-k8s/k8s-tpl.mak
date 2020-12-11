
# Janky front-end to bring some sanity (?) to the litany of tools and switches
# for working with a k8s cluster. Note that this file exercise core k8s
# commands that's independent of where/how you cluster live.
#
# This file addresses APPPLing the Deployment, Service, Gateway, and VirtualService
#
# Be sure to set your context appropriately for the log monitor.
#
# The intended approach to working with this makefile is to update select
# elements (body, id, IP, port, etc) as you progress through your workflow.
# Where possible, stodout outputs are tee into .out files for later review.
#


# specify yor container registry & registry id here
CREG=ghcr.io
REGID=ZZ-REG-ID

KC=kubectl
DK=docker

# these might need to change
NS=cmpt756e4


deploy: gw s1 s2 db
	$(KC) get gw,deploy,svc,pods

gw: cluster/service-gateway.yaml
	$(KC) -n $(NS) apply -f cluster/service-gateway.yaml > gw.log

s1: cluster/s1.yaml
	$(KC) -n $(NS) apply -f cluster/s1.yaml > s1.log

s2: cluster/s2.yaml
	$(KC) -n $(NS) apply -f cluster/s2.yaml > s2.log

db: cluster/db.yaml
	$(KC) -n $(NS) apply -f cluster/db.yaml > db.log

scratch:
	$(KC) delete deploy cmpt756s1 cmpt756s2 cmpt756db
	$(KC) delete svc cmpt756s1 cmpt756s2 cmpt756db
	$(KC) delete gw my-gateway
	$(KC) get gw,deploy,svc,pods
	rm *.log

clean:
	rm {s1,s2,db}.{img,repo,svc}.log gw.svc.log

extern: showcontext
	$(KC) -n istio-system get svc istio-ingressgateway

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

cr:
	$(DK) push $(CREG)/$(REGID)/cmpt756s1:latest | tee s1.repo.log
	$(DK) push $(CREG)/$(REGID)/cmpt756s2:latest | tee s2.repo.log
	$(DK) push $(CREG)/$(REGID)/cmpt756db:latest | tee db.repo.log

image: s1/Dockerfile s2/Dockerfile db/Dockerfile db/app.py
	$(DK) build -t $(CREG)/$(REGID)/cmpt756s1:latest s1 | tee s1.img.log
	$(DK) build -t $(CREG)/$(REGID)/cmpt756s2:latest s2 | tee s2.img.log
	$(DK) build -t $(CREG)/$(REGID)/cmpt756db:latest db | tee db.img.log

# reminder of current context
showcontext:
	$(KC) config get-contexts
