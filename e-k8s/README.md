# SFU CMPT 756 main project directory

## Creating a fresh project

To create a fresh system that does not rely on any previous code:

### 1. Create a new cluster

Create a new cluster in the appropriate system (Minikube, AWS, Azure,
GCP, ...).  See the instructions in the appropriate `*.mak` file.

To create a brand new cluster `newfresh` in Minikube:

Edit `mk.mak`, to set `CTX=newfresh`, then run

~~~
$ make -f mk.mak start
~~~

### 2. Instantiate the template files

You must specify the required values in `cluster/tpl-vars.txt`.  These
include things like your AWS keys, your GitHub signon, and other
identifying information.  See the comments in that file for
details. Note that you will need to have installed Gatling
(https://gatling.io/open-source/start-testing/) first, because you
will be entering its path in `tpl-vars.txt`.

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

### 7. Test the new cluster

Start a connection to your cluster.  This will depend upon where it is
running.  For Minikube, run

~~~
$ minikube tunnel
~~~

On macOS and Linux, you may be asked to enter your machine's
userid. Once the tunnel is running, it will not produce any output.
Control-C to close the connection when your session is completed.

First, ensure that all the monitoring infrastructure is running. In
your browser, visit `http://HOST/kiali`, where `HOST` is the hostname
or IP address of your cluster.  For Minikube, `minikube ip` will
provide the IP address.

You should see the Kiali home page.  If Kiali is not in the `Graph`
pane, click on `Graph` in the top left menu.  You should see a graph
that includes entries for the three services, `cmpt756s1`,
`cmpt756s2`, and `cmpt756db`.  (The structure will vary.)

Now run Gatling to send some requests to the microservices.  This
Gatling script will make 10 reads to table `User`, followed by 200
requests to table `Music`:

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
system. After the Gatling script stops generating traffic, Kiali will
disconnect `istio-ingressgateway` from the services because it is not
sending any more requests to the services.
