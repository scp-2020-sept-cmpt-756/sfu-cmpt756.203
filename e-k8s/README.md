# SFU CMPT 756 main project directory

## Creating a fresh project

To create a fresh system that does not rely on any previous code:

### 1. Create a new cluster

Create a new cluster in the appropriate system (Minikube, AWS, Azure,
GCP, ...).  See the instructions in the appropriate `*.mak` file.

To create a brand new cluster in:

* Minikube:

  ~~~
  $ make -f mk.mak start
  ~~~

* Azure:

  ~~~
  $ make -f az.mak start
  ~~~

  This can take up to 15 minutes.

* AWS:

  ~~~
  $ make -f eks.mak start
  ~~~

  This can take 15--30 minutes.

* GCP:

  ~~~
  $ make -f gcp.mak start
  ~~~

  This can take over 10--15 minutes.

### 2. Instantiate the template files

#### Fill in the required values in the template variable file

Copy the file `cluster/tpl-vars-blank.txt` to `cluster/tpl-vars.txt`
and fill in all the required values in `tpl-vars.txt`.  These include
things like your AWS keys, your GitHub signon, and other identifying
information.  See the comments in that file for details. Note that you
will need to have installed Gatling
(https://gatling.io/open-source/start-testing/) first, because you
will be entering its path in `tpl-vars.txt`.

#### Instantiate the templates

Once you have filled in all the details, run

~~~
$ make -f k8s-tpl.mak templates
~~~

This will check that all the programs you will need have been
installed and are in the search path.  If any program is missing,
install it before proceeding.

The script will then generate makefiles personalized to the data that
you entered in `clusters/tpl-vars.txt`.

**Note:** This is the *only* time you will call `k8s-tpl.mak`
directly. This creates all the non-templated files, such as
`k8s.mak`.  You will use the non-templated makefiles in all the
remaining steps.

### 3. Ensure AWS DynamoDB is running

Regardless of where your cluster will run, it will call AWS DynamoDB
for its backend database. Check that you have the necessary tables
installed by running

~~~
$ aws dynamodb list-tables
~~~

The resulting output should include tables `User` and `Music`.

----

**All the remaining steps can now be accomplished with the single
  command `make -f k8s.mak provision`.**

### 4. Install the Istio service mesh

Your cluster is currently running bare Kubernetes. The next steps will
add tools for controlling and observing applications.

Install the Istio service mesh by running

~~~
$ make -f k8s.mak istio
~~~

### 5. Install the Prometheus and Grafana monitoring tools

Initialize the Helm package manager. If this warns you that it has
already been run, simply proceed to the next section.

~~~
$ make -f obs.mak init-helm
~~~

Install the Prometheus time-series database for gathering metrics and
the Grafana dashboard for monitoring the system:

~~~
$ make -f obs.mak install-prom
~~~

Install the Kiali dashboard for monitoring and controlling your
application and the service mesh:

~~~
$ make -f obs.mak install-kiali
~~~

**Note:** The Kiali Operator is slow and this step can take 5--10
  minutes to complete on Minikube. Wait until the following command
  reports `Running` as the pod status:

~~~
$ make -f obs.mak status-kiali
~~~

### 6. Deploy the sample application

Deploy the sample application for the course:

~~~
$ make -f k8s.mak deploy
~~~

Wait until the following command lists all the pods as `Running` in
the last three lines of output:

~~~
$ make -f k8s.mak ls
~~~

### 7. Connect to the new cluster

Start a connection to your cluster.  This will depend upon where it is
running:

* For Minikube

  ~~~
  $ minikube tunnel
  ~~~

  On macOS and Linux, you may be asked to enter your machine's
  userid. Once the tunnel is running, it will not produce any output.
  Control-C to close the connection when your session is completed.


* For Azure: Nothing to do--the external IPs should already be created.

* For AWS: Nothing to do--the external IPs should already be created.

* For GCP: Nothing to do--the external IPs should already be created.

Locate the external IP address required to access the cluster by running:

~~~
$ kubectl get -n istio-system svc/istio-ingressgateway
~~~

The `EXTERNAL-IP` is the address to use.  For Minikube and Azure, this
will be an IP address like `52.228.115.161`, while for Amazon it will
be a longer string such as 
`a608432bedf3c4f5ae7430d8c3a75ebc-412518752.us-west-2.elb.amazonaws.com`.

### 8. Visualize the cluster graph

First, ensure that all the monitoring infrastructure is running. In
your browser, visit `http://EXTERNALIP/kiali`, where `EXTERNALIP` is the
or external IP address you located in the step above.

You should see the Kiali home page.  If Kiali is not in the `Graph`
pane, click on `Graph` in the top left menu.  You should see a graph
that includes entries for the three services, `cmpt756s1`,
`cmpt756s2`, and `cmpt756db`.  (The structure will vary.)

### 9. Send traffic via Gatling

Now run Gatling to send some requests to the microservices. In the
script `gatling/simulations/proj756/ReadTables.scala`, locate the
line `.baseUrl("http://127.0.0.1")`. Replace `127.0.0.1` with the
cluster's external IP address and save the file.

The Gatling script will make 10 reads to table `User`, followed by 200
requests to table `Music`. Compile and run it with this single command:

~~~
$ make -f k8s.mak -B gatling
~~~

The `-B` option forces `make` to run the script whether or not the
script has been edited.

Once the script is running, return to the Kiali page and watch the
graph be assembled. It will take some time (~5 minutes on Minikube) to
stabilize, as it takes time for the metrics to flow from the
microservices to Prometheus for storage and then to Kiali for
display. The graph should have the same structure as the one in the
[Kiali sample graph](cluster/Kiali-sample-graph.png).

**Note:** Kiali displays the real-time traffic through the
system. Some time after the Gatling script stops generating traffic,
Kiali will disconnect `istio-ingressgateway` from the services because
it is not sending any more requests to the services.

### 10. Delete the cluster

Once you have completed your activities, you will likely want to
delete the cluster.  Minikube consumes a lot of your machine as it
runs, while Azure, AWS, and GCP charge you by the hour.

* Minikube:

  ~~~
  $ make -f mk.mak stop
  ~~~

* Azure:

  ~~~
  $ make -f az.mak stop
  ~~~

* AWS:

  ~~~
  $ make -f eks.mak stop
  ~~~

* GCP:

  ~~~
  $ make -f gcp.mak stop
  ~~~

### 11. (Reference) Querying Prometheus metrics

If you wish to access Prometheus to query its metrics, you will need
to locate its EXTERNAL-IP address. Run

~~~
$ kubectl get -n istio-system svc/prom-ingress
~~~

Enter the URL `http//EXTERNAL-IP:9090/` in your browser to access
Prometheus.

### 12. (Reference) Viewing Grafana dashboards

If you wish to access Grafana to view dashboards, you will need
to locate its EXTERNAL-IP address. Run

~~~
$ kubectl get -n istio-system svc/grafana-ingress
~~~

Enter the URL `http//EXTERNAL-IP:3000/` in your browser to access
Grafana.  You will need to sign in with userid `admin` and password
`prom-operator`.
