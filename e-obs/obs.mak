
# Janky front-end to bring some sanity (?) to the litany of tools and switches
# for working with a k8s cluster. This file adds a set of monitoring and
# observability tool including: Prometheus, Grafana and Kiali by way of installing
# them using Helm. Note the Helm repo is up-to-date as of mid-Nov 2020. 
#
# Prometheus, Grafana and Kiali are installed into the same namespace (istio-system)
# to make them work out-of-the-box (install). It may be possible to separate each of
# them out into their own namespace but I didn't have time to validate/explore this.
#
# The intended approach to working with this makefile is to update select
# elements (body, id, IP, port, etc) as you progress through your workflow.
# Where possible, stodout outputs are tee into .out files for later review.
#


KC=kubectl
DK=docker
HELM=helm
TARGNS=istio-system

# these might need to change
NS=cmpt756e4

# this name is derived/dependent on the choice of "komplete-prometheus" specified during install
# this might also change in step with Prometheus' evolution
PROMETHEUSPOD=prometheus-komplete-prometheus-kube-p-prometheus-0

all: install-prom install-kiali


# add the latest active repo for Prometheus
init-helm:
	$(HELM) repo add prometheus-community https://prometheus-community.github.io/helm-charts

# note that the name komplete-prometheus is discretionary; it is used to reference the install 
# Grafana is included within this Prometheus package
install-prom:
	echo $(HELM) install komplete-prometheus --namespace $(TARGNS) prometheus-community/kube-prometheus-stack > obs-install-prometheus.log
	$(HELM) install komplete-prometheus --namespace $(TARGNS) prometheus-community/kube-prometheus-stack | tee -a obs-install-prometheus.log

uninstall-prom:
	echo $(HELM) uninstall komplete-prometheus --namespace $(TARGNS) > obs-uninstall-prometheus.log
	$(HELM) uninstall komplete-prometheus --namespace $(TARGNS) | tee -a obs-uninstall-prometheus.log

install-kiali:
	echo $(HELM) install --namespace $(TARGNS) --set auth.strategy="anonymous" --repo https://kiali.org/helm-charts kiali-server kiali-server > obs-kiali.log
	$(HELM) install --namespace $(TARGNS) --set auth.strategy="anonymous" --repo https://kiali.org/helm-charts kiali-server kiali-server | tee -a obs-kiali.log

uninstall-kiali:
	echo $(HELM) uninstall kiali-server --namespace $(TARGNS) > obs-uninstall-kiali.log
	$(HELM) uninstall kiali-server --namespace $(TARGNS) | tee -a obs-uninstall-kiali.log

promport:
	$(KC) describe pods $(PROMETHEUSPOD) -n $(TARGNS)

extern: showcontext
	$(KC) -n istio-system get svc istio-ingressgateway

# show deploy and pods in current ns; svc of cmpt756e4 ns
ls: showcontext
	$(KC) get gw,deployments,pods
	$(KC) -n $(NS) get svc
	$(HELM) list -n $(TARGNS)


# reminder of current context
showcontext:
	$(KC) config get-contexts
