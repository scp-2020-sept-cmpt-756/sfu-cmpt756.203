
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
AWS=aws

JDK_15_HOME=/Users/ted/Documents/Career/Facilities/openjdk/jdk-15.0.1.jdk/Contents/Home
GAT_DIR=/Users/ted/Documents/Teaching/756-20-3/gatling-charts-highcharts-bundle-3.4.2
GAT=$(GAT_DIR)/bin/gatling.sh

SIM_DIR=gatling/simulations
SIM_PACKAGE=proj756
SIM_PACKAGE_DIR=$(SIM_DIR)/$(SIM_PACKAGE)
SIM_FILE=ReadTables.scala
SIM_NAME=$(SIM_PACKAGE).ReadTablesSim

# these might need to change
APP_NS=cmpt756e4
ISTIO_NS=istio-system


deploy: gw s1 s2 db monitoring
	$(KC) -n $(APP_NS) get gw,vs,deploy,svc,pods

monitoring: monvs
	$(KC) -n $(ISTIO_NS) get vs

gw: gw.svc.log

monvs: monvs.svc.log

s1: s1.svc.log

s2: s2.svc.log

db: db.svc.log

gw: cluster/service-gateway.yaml
	$(KC) -n $(APP_NS) apply -f $< > gw.log

monvs: cluster/monitoring-virtualservice.yaml
	$(KC) -n $(ISTIO_NS) apply -f $< > monvs.log

s1: cluster/s1.yaml s1.repo.log cluster/s1-sm.yaml
	$(KC) -n $(APP_NS) apply -f $< > s1.log
	$(KC) -n $(APP_NS) apply -f cluster/s1-sm.yaml >> s1.log

s2: cluster/s2.yaml s2.repo.log cluster/s2-sm.yaml
	$(KC) -n $(APP_NS) apply -f $< > s2.log
	$(KC) -n $(APP_NS) apply -f cluster/s2-sm.yaml >> s2.log

db: cluster/db.yaml db.repo.log cluster/db-sm.yaml
	$(KC) -n $(APP_NS) apply -f $< > db.log
	$(KC) -n $(APP_NS) apply -f cluster/db-sm.yaml >> db.log

scratch:
	$(KC) delete -n $(APP_NS) deploy cmpt756s1 cmpt756s2 cmpt756db --ignore-not-found=true
	$(KC) delete -n $(APP_NS) svc cmpt756s1 cmpt756s2 cmpt756db --ignore-not-found=true
	$(KC) delete -n $(APP_NS) gw my-gateway --ignore-not-found=true
	$(KC) delete -n $(APP_NS) vs cmpt756e4 --ignore-not-found=true
	$(KC) delete -n $(ISTIO_NS) vs monitoring --ignore-not-found=true
	$(KC) get -n $(APP_NS) deploy,svc,pods,gw,vs
	$(KC) get -n $(ISTIO_NS) vs
	/bin/rm -f gw.log monvs.log s1.log s2.log db.log

clean:
	rm {s1,s2,db}.{img,repo,svc}.log {gw,monvs}.svc.log

extern: showcontext
	$(KC) -n istio-system get svc istio-ingressgateway

# show svc across all namespaces
lsa: showcontext
	$(KC) get svc --all-namespaces

# show deploy, pods, vs, and svc of application ns
ls: showcontext
	$(KC) get -n $(APP_NS) gw,vs,svc,deployments,pods

# show containers across all pods
lsd:
	$(KC) get pods --all-namespaces -o=jsonpath='{range .items[*]}{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}' | sort

cr:
	$(DK) push $(CREG)/$(REGID)/cmpt756s1:latest | tee s1.repo.log
	$(DK) push $(CREG)/$(REGID)/cmpt756s2:latest | tee s2.repo.log
	$(DK) push $(CREG)/$(REGID)/cmpt756db:latest | tee db.repo.log

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

# reminder of current context
showcontext:
	$(KC) config get-contexts

#
# Start the AWS DynamoDB service
#
dynamodb: misc/cloudformationdynamodb.json
	$(AWS) cloudformation create-stack --stack-name db --template-body file://$<

#
# Gatling
#
gatling: $(SIM_PACKAGE_DIR)/$(SIM_FILE)
	JAVA_HOME=$(JDK_15_HOME) $(GAT) -rsf gatling/resources -sf $(SIM_DIR) -bf $(GAT_DIR)/target/test-classes -s $(SIM_NAME) -rd 'Run command'