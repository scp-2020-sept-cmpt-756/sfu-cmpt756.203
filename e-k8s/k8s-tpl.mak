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


# These will be filled in by template processor
CREG=ZZ-CR-ID
REGID=ZZ-REG-ID
JAVA_HOME=ZZ-JAVA-HOME
GAT_DIR=ZZ-GAT-DIR

KC=kubectl
DK=docker
AWS=aws

# Gatling parameters---you should not have to change these
GAT=$(GAT_DIR)/bin/gatling.sh
SIM_DIR=gatling/simulations
SIM_PACKAGE=proj756
SIM_PACKAGE_DIR=$(SIM_DIR)/$(SIM_PACKAGE)
SIM_FILE=ReadTables.scala
SIM_NAME=$(SIM_PACKAGE).ReadTablesSim

# these might need to change
APP_NS=c756ns
ISTIO_NS=istio-system


deploy: gw s1 s2 db monitoring
	$(KC) -n $(APP_NS) get gw,vs,deploy,svc,pods

monitoring: monvs
	$(KC) -n $(ISTIO_NS) get vs

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

db: cluster/db.yaml db.repo.log cluster/db-sm.yaml cluster/awscred.yaml
    	$(KC) -n $(APP_NS) apply -f cluster/awscred.yaml > db.log
	$(KC) -n $(APP_NS) apply -f $< >> db.log
	$(KC) -n $(APP_NS) apply -f cluster/db-sm.yaml >> db.log

scratch: clean
	$(KC) delete -n $(APP_NS) deploy cmpt756s1 cmpt756s2 cmpt756db --ignore-not-found=true
	$(KC) delete -n $(APP_NS) svc cmpt756s1 cmpt756s2 cmpt756db --ignore-not-found=true
	$(KC) delete -n $(APP_NS) gw c756-gateway --ignore-not-found=true
	$(KC) delete -n $(APP_NS) vs c756vs --ignore-not-found=true
	$(KC) delete -n $(ISTIO_NS) vs monitoring --ignore-not-found=true
	$(KC) get -n $(APP_NS) deploy,svc,pods,gw,vs
	$(KC) get -n $(ISTIO_NS) vs

clean:
	/bin/rm -f {s1,s2,db,gw,monvs}.log

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
s1: s1/Dockerfile s1/app.py s1/requirements.txt
	$(DK) build -t $(CREG)/$(REGID)/cmpt756s1:latest s1 | tee s1.img.log
	$(DK) push $(CREG)/$(REGID)/cmpt756s1:latest | tee s1.repo.log

#
# the s2 service
#
s2: s2/Dockerfile s2/app.py s2/requirements.txt
	$(DK) build -t $(CREG)/$(REGID)/cmpt756s2:latest s2 | tee s2.img.log
	$(DK) push $(CREG)/$(REGID)/cmpt756s2:latest | tee s2.repo.log

#
# the db service
#
db: db/Dockerfile db/app.py db/requirements.txt
	$(DK) build -t $(CREG)/$(REGID)/cmpt756db:latest db | tee db.img.log
	$(DK) push $(CREG)/$(REGID)/cmpt756db:latest | tee db.repo.log

# reminder of current context
showcontext:
	$(KC) config get-contexts

#
# Start the AWS DynamoDB service
#
dynamodb: cluster/cloudformationdynamodb.json
	$(AWS) cloudformation create-stack --stack-name db --template-body file://$<

#
# Gatling
#
gatling: $(SIM_PACKAGE_DIR)/$(SIM_FILE)
	JAVA_HOME=$(JAVA_HOME) $(GAT) -rsf gatling/resources -sf $(SIM_DIR) -bf $(GAT_DIR)/target/test-classes -s $(SIM_NAME) -rd 'Run command'