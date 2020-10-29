#
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


# specify yor DockerHub id here
REGID=your-DockerHub-id

KC=kubectl
DK=docker

# these might need to change
NS=cmpt756e4


deploy: gw s1 s2 db
	$(KC) get gw,deploy,svc,pods

gw: gw.svc.log

s1: s1.svc.log

s2: s2.svc.log

db: db.svc.log

gw.svc.log:
	$(KC) -n $(NS) apply -f misc/service-gateway.yaml | tee gw.svc.log

s1.svc.log:
	$(KC) -n $(NS) apply -f s1/s1.yaml | tee s1.svc.log

s2.svc.log:
	$(KC) -n $(NS) apply -f s2/s2.yaml | tee s2.svc.log

db.svc.log:
	$(KC) -n $(NS) apply -f db/db.yaml | tee db.svc.log

scratch:
	$(KC) delete deploy cmpt756s1 cmpt756s2 cmpt756db
	$(KC) delete svc cmpt756s1 cmpt756s2 cmpt756db
	$(KC) delete gw my-gateway
	$(KC) get gw,deploy,svc,pods

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


# handy bits for the container images... not necessary

image: showcontext
	$(DK) image ls | tee __header | grep overcoil > __content
	head -n 1 __header
	cat __content
	rm __content __header



#
# the s1 service
#
s1.repo.log: s1.img.log
	$(DK) push $(REGID)/cmpt756s1:latest | tee s1.repo.log

s1.img.log: e-aws/s1/Dockerfile e-aws/s1/app.py
	$(DK) build -t $(REGID)/cmpt756s1:latest e-aws/s1 | tee s1.img.log

#
# the s2 service
#
s2.repo.log: s2.img.log
	$(DK) push $(REGID)/cmpt756s2:latest | tee s2.repo.log

s2.img.log: e-aws/s2/Dockerfile e-aws/s2/app.py
	$(DK) build -t $(REGID)/cmpt756s2:latest e-aws/s2 | tee s2.img.log

#
# the db service
#
db.repo.log: db.img.log
	$(DK) push $(REGID)/cmpt756db:latest | tee db.repo.log

db.img.log: e-aws/db/Dockerfile e-aws/db/app.py
	$(DK) build -t $(REGID)/cmpt756db:latest e-aws/db | tee db.img.log


# reminder of current context
showcontext:
	$(KC) config get-contexts
