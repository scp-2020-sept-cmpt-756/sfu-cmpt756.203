# First-time use of Kubernetes Google Cloud Platform (GCP)

These steps are best done using the Web Console.  They only need to be
done once to use Google Kubernetes Engine (GKE).

## 1. Sign up for a GCP id

[Google Free Tier](https://cloud.google.com/free) allows you to use
GKE.

## 2. Create a project within your id

All GCP resources are assigned to a project.  You can name your
project anything. A good default is `c756proj`.  Leave the
organization to its default "No Organization".

## 3. Enable the Containers API for your project

Select the project you created.  Then
[enable the Kubernetes Engine API](https://console.cloud.google.com/apis/api/container.googleapis.com/overview)
(confusingly called `container.googleapis.com` in the URLs) for that
project.

## 4. Install the gcloud command-line interface

[Install the `gcloud` command-line interface](https://cloud.google.com/sdk/docs/install),
which will be called from the `.mak` files used in this course.

## 5. Set your GCP defaults on gcloud

Run `gcloud init` to set your GCP defaults.


