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


# specify yor GitHub id here
#REGID=your-GitHub-id
REGID=tedkirkpatrick

KC=kubectl
DK=docker
AWS=aws

# these might need to change
NS=cmpt756e4
#NS=istio-system


deploy: gw s1 s2 db
	$(KC) -n $(NS) get gw,deploy,svc,pods

gw: gw.svc.log

s1: s1.svc.log

s2: s2.svc.log

db: db.svc.log

gw.svc.log: misc/service-gateway.yaml
	$(KC) -n $(NS) apply -f $< | tee $@

s1.svc.log: s1/s1.yaml s1.repo.log s1/s1-sm.yaml
	$(KC) -n $(NS) apply -f $< | tee $@
	$(KC) -n $(NS) apply -f s1/s1-sm.yaml

s2.svc.log: s2/s2.yaml s2.repo.log s2/s2-sm.yaml
	$(KC) -n $(NS) apply -f $< | tee $@
	$(KC) -n $(NS) apply -f s2/s2-sm.yaml

db.svc.log: db/db.yaml db.repo.log db/db-sm.yaml
	$(KC) -n $(NS) apply -f $< | tee $@
	$(KC) -n $(NS) apply -f db/db-sm.yaml

scratch:
	$(KC) delete -n $(NS) deploy cmpt756s1 cmpt756s2 cmpt756db --ignore-not-found=true
	$(KC) delete -n $(NS) svc cmpt756s1 cmpt756s2 cmpt756db --ignore-not-found=true
	$(KC) delete -n $(NS) gw my-gateway --ignore-not-found=true
	$(KC) delete -n $(NS) vs cmpt756e4 --ignore-not-found=true
	$(KC) get -n $(NS) gw,vs,deploy,svc,pods
	/bin/rm -f gw.svc.log s1.svc.log s2.svc.log db.svc.log

clean:
	rm {s1,s2,db}.{img,repo,svc}.log gw.svc.log

extern: showcontext
	$(KC) -n istio-system get svc istio-ingressgateway

# show svc across all namespaces
lsa: showcontext
	$(KC) get svc --all-namespaces

# show deploy, pods, vs, and svc of cmpt756e4 ns
ls: showcontext
	$(KC) get -n $(NS) gw,vs,svc,deployments,pods

# show containers across all pods
lsd:
	$(KC) get pods --all-namespaces -o=jsonpath='{range .items[*]}{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}' | sort


# handy bits for the container images... not necessary

image: showcontext
	$(DK) image ls | tee __header | grep $(REGID) > __content
	head -n 1 __header
	cat __content
	rm __content __header
#
# the s1 service
#
s1.repo.log: s1/Dockerfile s1/app.py s1/requirements.txt
	make -f docker.mak $@

#
# the s2 service
#
s2.repo.log: s2/Dockerfile s2/app.py s2/requirements.txt
	make -f docker.mak $@

#
# the db service
#
db.repo.log: db/Dockerfile db/app.py db/requirements.txt
	make -f docker.mak $@

#
# the AWS DynamoDB service
#

dynamodb: misc/cloudformationdynamodb.json
	$(AWS) cloudformation create-stack --stack-name db --template-body file://$<

# reminder of current context
showcontext:
	$(KC) config get-contexts
