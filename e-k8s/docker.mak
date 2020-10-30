#
# Janky front-end to bring some sanity (?) to the litany of tools and switches
# in setting up, tearing down and validating your Minikube cluster for working
# with k8s and istio.
#
# This file covers off driving the API independent of where the cluster is
# running.
# Be sure to set your context appropriately for the log monitor.
#
# The intended approach to working with this makefile is to update select
# elements (body, id, IP, port, etc) as you progress through your workflow.
# Where possible, stodout outputs are tee into .out files for later review.
#

REGID=your-DockerHub-id

DK=docker
PORTFAMILY=5

all: svc

svc: s1.svc.log s2.svc.log db.svc.log

repo: s1.repo.log s2.repo.log db.repo.log

clean:
	rm {s1,s2,db}.{img,repo,svc}.log

s1.svc.log: s1.repo.log
	$(DK) run -t --publish 5000:5000 --detach --name s1 $(REGID)/cmpt756s1:latest | tee s1.svc.log

s1.repo.log: s1.img.log
	$(DK) push $(REGID)/cmpt756s1:latest | tee s1.repo.log

s1.img.log: s1/Dockerfile s1/app.py
	$(DK) build -t $(REGID)/cmpt756s1:latest s1 | tee s1.img.log


s2.svc.log: s2.repo.log
	$(DK) run -t --publish 5001:5001 --detach --name s2 $(REGID)/cmpt756s2:latest | tee s2.svc.log

s2.repo.log: s2.img.log
	$(DK) push $(REGID)/cmpt756s2:latest | tee s2.repo.log

s2.img.log: s2/Dockerfile s2/app.py
	$(DK) build -t $(REGID)/cmpt756s2:latest s2 | tee s2.img.log


db.svc.log: db.repo.log
	$(DK) run -t --publish 5002:5002 --detach --name db $(REGID)/cmpt756db:latest | tee db.svc.log

db.repo.log: db.img.log
	$(DK) push $(REGID)/cmpt756db:latest | tee db.repo.log

db.img.log: db/Dockerfile db/app.py
	$(DK) build -t $(REGID)/cmpt756db:latest db | tee db.img.log

godocker:
	cp s1/Dockerfile.d s1/Dockerfile
	cp s2/Dockerfile.d s2/Dockerfile
	cp db/Dockerfile.d db/Dockerfile
	cp s1/appd.py s1/app.py
	cp s2/appd.py s2/app.py

gok8s:
	cp s1/Dockerfile.k s1/Dockerfile
	cp s2/Dockerfile.k s2/Dockerfile
	cp db/Dockerfile.k db/Dockerfile
	cp s1/appk.py s1/app.py
	cp s2/appk.py s2/app.py
	touch s1/Dockerfile s2/Dockerfile db/Dockerfile s1/app.py s2/app.py
