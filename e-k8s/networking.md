## The base installation

We install Prometheus and Grafana using the
[`kube-prometheus-stack` Helm chart collection](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack).
The [Helm package manager](https://helm.sh/) manages templated
Kubernetes manifests, called *charts*.

A closely-related collection, which we are not currently using, is
[`kube-prometheus`](https://github.com/prometheus-operator/kube-prometheus).
This collection is written in [jsonnet](jsonnet.org), which is used to
generate the `.yaml` manifests that would actually be installed.  The
tools in this collection tend to be more sophisticated than required
for the simple clusters defined in this class.

Both of these collections are based upon [the Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator).

## Exploring the underlying mechanisms of the minikube node

In the minikube node (via `minikube ssh`) execute the following
commands to see how Kubernetes entitis are implemented in a single
Linux system.

Prompt: `docker@minikube:~$`

### How services are implemented

As [iptable rules](https://linux.die.net/man/8/iptables):

`sudo iptables -L -t filter`

`sudo iptables -L -t nat`

[`kube-proxy`](https://kubernetes.io/docs/concepts/services-networking/service/#virtual-ips-and-service-proxies)

[IPVS: The Linux Load Balancer (Deep Dive)](https://pasztor.at/blog/ipvs-the-linux-load-balancer/)

See ConfigMap `kube-system/kube-proxy`:

~~~
	iptables:
		  masqueradeAll: false
		  masqueradeBit: null
		  minSyncPeriod: 0s
		  syncPeriod: 0s
		ipvs:
		  excludeCIDRs: null
		  minSyncPeriod: 0s
		  scheduler: \"\"
		  strictARP: false
		  syncPeriod: 0s
		  tcpFinTimeout: 0s
		  tcpTimeout: 0s
		  udpTimeout: 0s
~~~

To look up a service on the cluster DNS:

`dig @<IP> <SERVICE>.<NAMESPACE>.svc.cluster.local`

Where

* `<IP>` is the IP address of either the service
  `kube-system/kube-dns` or the pod `kube-system/coredns-<HASH1>-<HASH2>`.
* `<SERVICE>` is the service name
* `<NAMESPACE>` is the namespace of the service

Example: `dig @10.96.0.10 kiali.istio-system.svc.cluster.local`

[Comparing `kube-proxy` modes: iptables or IPVS?](https://www.projectcalico.org/comparing-kube-proxy-modes-iptables-or-ipvs/)

### How nodes and pods are implemented

As Linux processes:

`ps -eaf`

As Docker containers:

`docker container ls`

## Opening ports to the minikube node

`minikube tunnel`:  Uses `ssh` tunneling to open one or more ports to
`127.0.0.1`. To any services listed as type `LoadBalancer`.  In our
system, that is the single service,
`istio-system/istio-ingressgateway`. Uses an `sshd docker [priv]`
command for each LoadBalancer service.

`kubectl port-forward`: Uses Kubernete-specific tunneling to open one
or more ports to `127.0.0.1`.  To one specific service on one specific
pod.  Uses `/usr/bin/socat - TCP4:localhost:20001` on node.

In both cases, the command must continue running on the Host OS to
complete the tunnel and keep the port open.

`minikube dashboard`

## Istio configuration

From `mk.mak`, target `reinstate`:

`istioctl install --set profile=demo`

To get profile data:

`istioctl profile dump demo`

[Istio Operator configuration](https://istio.io/v1.7/docs/reference/config/istio.operator.v1alpha1/)

Specifically, the ingress gateway
[`spec.components.ingressGateways`](https://istio.io/v1.7/docs/reference/config/istio.operator.v1alpha1/#GatewaySpec)

The
[`.k8s.service`](https://istio.io/v1.7/docs/reference/config/istio.operator.v1alpha1/#ServiceSpec)
defines a Kubernetes Service, mapping host OS ports (visible to curl
and your browser running in your host OS) to target ports in the cluster.
This mapping is enabled whenever `minikube tunnel` is running.

[Integrating Istio 1.7 with Prometheus](https://istio.io/v1.7/docs/ops/integrations/prometheus/).

## A pod in the service mesh

Init container: Istio Proxy called to update iptables to establish Istio networking in
the pod.  View the container logs to see the rules it adds.

Sidecar: Istio proxy running concurrently with main container(s),
rerouting their traffic to run between Istio proxies.

## Istio components

Istiod: [`pilot`](https://github.com/istio/istio/tree/master/pilot)

[Proxy (Extended version of Envoy)](https://github.com/istio/proxy)


## Starting a load balancer

Starting a LoadBalancer while `minikube tunnel` is already running
and that LoadBalancer requests a privileged port (< 1024) will require
you to enter a password into the tunneling instance of minikube.

## Kiali configuration

[Documentation of Kiali configuration file](https://github.com/kiali/kiali-operator/blob/master/deploy/kiali/kiali_cr.yaml)

File for this cluster: `kiali-cr.yaml`

[Kiali v1.27 documentation](https://kiali.io/documentation/v1.27/)

## Prometheus configuration

[Architecture of Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator/blob/master/Documentation/user-guides/getting-started.md)

Under the default configuration of
[kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
(the configuration used in this course),

> By default, Prometheus discovers ... ServiceMonitors within its namespace, that are labeled with the same release tag as the prometheus-operator release. 
> --- [prometheus-community / helm-charts, section "prometheus.io/scrape"](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack#user-content-prometheusioscrape)

To start Prometheus monitoring a new service, create a new
ServiceMonitor and apply it. The ServiceMonitor must

* Be added to the namespace in which Prometheus runs (currently
  `istio-system`)
* Specify a `metadata.labels.release` tag set to the release of the
  system (currently `komplete-prometheus`, but likely to change)
* Specify a `spec.namespaceSelector.matchNames` array with the single
  value of the namespace in which the service runs (typically
  `cmpt756e4`)
* Specify a `spec.selector.matchLabels.app` tag with the same label
  given to the application (`cmpt756db`, `cmpt756s1`, ...)
* Specify a `spec.endpoints` array of elements with
  * `port` tag specifying the port name used by the service to be
     monitored
  * `path` tag set to `/metrics` (the path that Prometheus uses to
    request metrics)

Example: A ServiceMonitor for the `cmpt756db` service

~~~
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: cmpt756db
  labels:
    app: cmpt756db
    release: komplete-prometheus
spec:
  namespaceSelector:
    matchNames:
    - cmpt756e4
[adapter Prometheus stats -> Kubernetes stats for input to HorizontalAutoscaler](https://github.com/DirectXMan12/k8s-prometheus-adapter)
The `kube-prometheus-stack` does *not* install this.

  selector:
    matchLabels:
      app: cmpt756db
  endpoints:
  - port: http
    path: /metrics
~~~

This ServiceMonitor would be added by the command, specifying the
Prometheus namespace as `istio-system`:

~~~
$ kubectl apply -n istio-system -f sm-db.yaml
~~~

[ServiceMonitor resource specification](https://docs.openshift.com/container-platform/4.4/rest_api/monitoring_apis/servicemonitor-monitoring-coreos-com-v1.html)

[Prometheus `relabel_config` specification](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#relabel_config).

StackOverflow answer about
[adding custom pod metrics to Prometheus](https://stackoverflow.com/questions/53365191/monitor-custom-kubernetes-pod-metrics-using-prometheus)

[Istio standard metrics](https://istio.io/v1.7/docs/reference/config/metrics/)

[Standard Promethus configuration](https://github.com/helm/charts/blob/master/stable/prometheus/values.yaml)

[Prometheus Operator API](https://github.com/prometheus-operator/prometheus-operator/blob/master/Documentation/api.md)

## Docker Hub mitigations

[Setting Istio to use Google Container Registry](https://istio.io/latest/blog/2020/docker-rate-limit/)

## Scraping Prometheus data from the Python Flask applications

The `debug=True` option to `app.run()` stops the Prometheus `/metrics` requests from
being recognized.  No idea why.  On the other hand, the
`threaded=True` option to `app.run()` and `BluePrint` view are
compatible with Prometheus metrics.

## Minikube pods and purposes

### `kube-state-metrics`

This sevice is installed as part of `kube-prometheus-stack`. It returns Kubernetes metrics in Prometheus format. To
directly query, first forwart the port

~~~
$ kubectl port-forward svc/komplete-prometheus-kube-state-metrics -n istio-system 8080
~~~

and then in the browser, enter `127.0.0.1:8080/metrics`

This will return *many* metrics.  It is really only useful to test
that the pod is correctly running.

[`kube-state-metrics` README and source code](https://github.com/kubernetes/kube-state-metrics)

### Potentially useful but not currently installed

[adapter Prometheus stats -> Kubernetes stats for input to HorizontalAutoscaler](https://github.com/DirectXMan12/k8s-prometheus-adapter)
The `kube-prometheus-stack` does *not* install this.

## Istio ingress gateway

Envoy proxy.  To debug routing problems, inspect the proxy logs for
the service endpoint.  [Format of Envoy access logs](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage)

## Grafana dependency of kube-prometheus-stack

If you want to override the defaults of Grafana, you cannot simply
specify something at the top level `values.yaml` of the Helm chart. In
particular, you might want to specify that Grafana is pulled from a
different hub than Docker Hub, which throttles accesses.

The
[`Chart.yaml`](https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/Chart.yaml)
for `kube-prometheus-stack` specifies Grafana as a dependency at
[`https://grafana.github.io/helm-charts`](https://grafana.github.io/helm-charts).

The [`README.md`] of the Grafana repo lists `image.repository` as specifying
the source of the image to be pulled, the Docker Hub image
`grafana/grafana`.  However, the `image.pullPolicy` is `IfNotPresent`,
so the pull will only be done the first time a cluster is started.

## Loading Grafana dashboards

To load a Grafana dashboard into the cluster, create a `ConfigMap`
with a label `grafana_dashboard` that has any value (typically `"1"`,
though that is not required).  See the example at
`clusters/grafana-flask-configmap.yaml`.

### How locally-installed dashboards are discovered and loaded

The Grafana installation includes a pod sidecar,
`kiwigrid/k8s-sidecar`. This sidecar regularly scans every `ConfigMap`
in the system. If a `ConfigMap` has the label `grafana_dashboard`, it
is loaded.

## Other tools

[Fortio load tester](https://github.com/fortio/fortio) Developed as
part of Istio.

[Flask-OpenTracing](https://github.com/opentracing-contrib/python-flask)
library for producing OpenTracing data (used by tools such as Jaeger).
