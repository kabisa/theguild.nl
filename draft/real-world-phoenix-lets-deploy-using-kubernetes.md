# Real World Phoenix |> Let's D4Y |> __using__ K8S

As promised in my [last post](https://www.theguild.nl/real-world-phoenix-lets-d4y/) here is step 3 in my deployment adventure. The one
where I use Kubernetes!

In the last post we explored a very straightforward and simple
way to deploy a Phoenix application using the built-in Elixir releases on render.com. 

Today I want to discuss a much more complicated setup, using Kubernetes. I know for
most applications you will surely not need a setup using Kubernetes, but I've
been having an urge to try it out for a while now and wanted to see if it is
really that complicated as I seem to be hearing through the grapevine. Who
knows, maybe it turns out it's actually not that hard at all. 
Also I really like the fact that I can have a cluster to spin up nodes (ie.
applications) of all the experiments / ideas / apps that I'm currently playing
with, so I can actually expose those into the Real World with a reproducable and
easy deployment workflow. Let's see if we can make that dream come true! 

## The Kubernetes Cluster

If you are not aware of what Kubernetes is, head over to [their website](https://kubernetes.io/docs/tutorials/kubernetes-basics/), as they have great documentation to get started on the basics.

To use Kubernetes for our deployment the first thing we'll need is a Kubernetes
cluster. This is the part where you see most tutorials and guides grab for a
local setup with minikube. While I like that it's possible to do this, it still
seems a bit too far from real life for me, so I wanted to have a bit more of a
production-like environment, like... for instance... a production environment :) 

The beauty is that these days there are more and more managed Kubernetes
services that do all the hard work like setting up the cluster, managing
upgrades etc etc. I'll be using the service DigitalOcean is offering, because I
already have a lot of content running at DigitalOcean, so it is known territory
for me and they make it really easy to get started with Kubernetes.
If you haven't used DigitalOcean before, you can use this [referral
link](https://m.do.co/c/78020d21b236) to create an account and get $100 credit
to spend in the first 60 days. So more than enough to follow along with this tutorial.

## Terraform + Helm

We are going to need to use 2 more tools to get this setup up and running. [Terraform](https://www.terraform.io/) and [Helm](https://helm.sh/). We'll use terraform to setup most of the infrastructure. In this way I don't have to remember all the tweaks and install steps I took to get everything up and running. I can just automate the whole setup declaratively and put the whole thing under version control. 
This is often referred to these days as an infrastructure-as-code setup.
I wanted to use terraform for everything, but ran into some trouble setting up a 
few of the tools needed, so reverted to Helm (the Kubernetes package manager) to
install Traefik and our Gitlab Runner. 

Our Terraform setup will include:
1. Setting up a DigitalOcean Kubernetes Cluster with 2 worker nodes
2. Connecting a gitlab project to the kubernetes cluster
3. Creating a kubernetes_secret to be able to pull images from our private gitlab
   registry.
4. Setup a managed database cluster service @ digitalocean

And we'll use Helm to:
1. Install Traefik as an ingress controller
2. Create a Gitlab Runner in our cluster 

So let's get crackin'!

### Install doctl to talk to your DigitalOcean account

If we want to automate any of this stuff we'll have to be able to talk to
DigitalOcean programmatically, so installing doctl is step one. Please refer to
this guide to get that setup: [doctl up and running
guide](https://blog.digitalocean.com/introducing-doctl/)

After you have `doctl` installed, make sure you create a [personal access token](https://www.digitalocean.com/docs/api/create-personal-access-token/) in DigitalOcean and add that in an environment variable and also initialize your
account.

```bash
export DIGITALOCEAN_TOKEN=[token]
doctl auth init -t $DIGITALOCEAN_TOKEN
doctl account get
```

### Install Terraform

Of course there is a handy install guide for terraform also. Actually just an
executable, as it is written in go, so they have a handy packaged binary you can use.
See: [terraform install](https://www.terraform.io/downloads.html) 

### Setup our project

If you want to follow along with this guide, create a folder that will hold your
terraform configs and create a `main.tf` file that will hold the terraform declarations.

```bash
mkdir kube-terra
cd kube-terra
touch main.tf
```

### Setup the DigitalOcean Kubernetes cluster

Terraform works in a declaritive manner, which means that we state what we want
the world to be like and terraform figures out how to get to that state. In
terraform you describe an item you want to exist as a resource. A Kubernetes
cluster is a form of a resource that is provided by one of the many providers
that exist in terraform. So let's create a DigitalOcean kubernetes cluster:

Creating a resource is always in the format: `resource [kind] [reference] {}`
We can use the reference we provide later on to refer back to this resource.

```hcl
resource "digitalocean_tag" "kubernetes-cl01" {
  name = "kubernetes-cl01"
}

data "digitalocean_kubernetes_versions" "versions" {}

resource "digitalocean_kubernetes_cluster" "cl01" {
  name    = "cl01"
  region  = "ams3"
  version = data.digitalocean_kubernetes_versions.versions.latest_version

  node_pool {
    name       = "default"
    size       = "s-1vcpu-2gb"
    node_count = 2
    tags       = ["${digitalocean_tag.kubernetes-cl01.id}"]
  }
}
```

Now you can get your cluster setup by issuing the following commands in the folder you
created:

```bash
tarraform init
terraform apply
```

This will take about 5 minutes and then you'll have a fresh kubernetes cluster
up and running. Now that was easy!

### Install Traefik

Kubernetes needs an ingress controller to route traffic from the outside world
to the services that are running inside the cluster as these services are not
exposed to the outside world, which is a good thing! Nginx is often used, but I went with Traefik, a very nice alternative that has a lot of nice functinality out of the box, like automatic ssl certificates using Let's Encrypt
and auto discovery of services running in the cluster. This setup also takes advantage of a DigitalOcean load balancer, which will automatically be created by the serviceType set below to `LoadBalancer`.

Create a file called `traefik-values.yml` in the root of your kubernetes config directory and add the following content. If you manage dns settings with DigitalOcean, you can comment out those parts as well. This will provide automatic ssl certificate generation. Very cool! If not you can just leave it like this. It'll work, but without ssl enabled. A benefit of using the dns-challenge as opposed to the more standard acme-challenge is that you can also get a valid certificate if your production system is behind a firewall.

```yaml

image: traefik
dashboard:
  enabled: true
  domain: domain.example.com                     # put a (sub)domain here where you want to access the traefik dashboard
serviceType: LoadBalancer
rbac:
  enabled: true
# ssl:
#   enabled: true                                # Enables SSL
#   enforced: true                               # Redirects HTTP to HTTPS
# acme:
#   enabled: true                                # Enables Let's Encrypt certificates
#   staging: false                               # Use Lets Encrypt staging area for this example. For production purposes set this to false
#   email: info@drumusician.com                  # Email address that Let's Encrypt uses to notify about certificate expiry etc.
#   challengeType: "dns-01"
#   dnsProvider:
#     name:  digitalocean                        # This is why you need your domain to be under Digital Ocean control
#     digitalocean:
#       DO_AUTH_TOKEN: $DIGITALOCEAN_TOKEN
#   domains:
#     enabled: true
#     domainsList:
#       - main: domain.example.com               # domain that belongs to this certificate
```

Now we can go ahead and install traefik in our cluster:

Install helm:
```bash
brew install kubernetes-helm
```

Pull in our fresh cluster configuration locally (otherwise helm will
fail):
```bash
doctl kubernetes cluster kubeconfig save cl01
```

And install traefik:

```bash
# get the helm/stable charts
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
# install Traefik
helm install traefik --values traefik-values.yml stable/traefik
```

After Traefik is installed we have enough running to be able to deploy our application
to the cluster. We are going to use gitlab-ci to deploy so we'll need to
install a gitlab-runner in our cluster first so we can use that in our project.

### Creating a kubernetes secret to access our registry

If we install the Gitlab runner in the next step, we'll need a kubernetes secret
to be able to pull from our private registry in gitlab.
Go to https://gitlab.com/profile/personal_access_tokens and create an access
token to access the gitlab registry. Scopes: api, read_registry.

Then create a file at `~/.docker/docker-registry.json` with the credentials for
the access token:
```json
{
  "registry.gitlab.com": {
    "username": "",            # access-token-name
    "password": "",            # token
    "email": ""                # email of the gitlab account
  }
}
```

And then in our main.tf we can create the kubernetes secret.
```hcl
resource "kubernetes_secret" "docker_pull_secret" {
  metadata {
    name = "gitlab.com"
  }

  data = {
    ".dockercfg" = file("~/.docker/docker-registry.json")
  }

  type = "kubernetes.io/dockercfg"
}
```

With that in place, we'll have to initialize the new provider and then we can add the secret:
```bash
terraform init
terraform apply
```

### Install Gitlab Runner

To be able to deploy into our cluster from Gitlab CI we will need our runner to run inside of our cluster and have enough access rights to actually spin-up pods and services in our cluster. So we'll install that using helm as well. Gitlab has an install script from their interface, but that doesn't provide you with customisation options that we'll need for our use case.

Create the following file in your kubernetes dir: `gitlab-runner-values.yml` and
add this content:

```yaml
gitlabUrl: https://gitlab.com/
runnerRegistrationToken: "" # copy this from your gitlab project settings: 
rbac:
  create: true
  clusterWideAccess: true
runners:
  privileged: true
imagePullSecrets: ["gitlab.com"]
```

Now let's install the runner:

```bash
helm install --namespace default gitlab-runner  -f gitlab-runner-values.yml gitlab/gitlab-runner
```

### Connect a gitlab project to the cluster

This is something you can do through the Gitlab interface, but I like automating
it here as well. We need to provide the Gitlab project in terraform like this.
If you don't have a project yet, you should create it on `gitlab.com` and add the
ID here.

```
data "gitlab_project" "project-x" {
  id = [your-project-id]
}
```

Then we can use this reference to create the settings in our project:

```
resource "gitlab_project_cluster" "gitlab-kubernetes" {
  project                       = data.gitlab_project.project-x.id
  name                          = "my-awesome-cluster"
  domain                        = "[mydomain.com]"
  enabled                       = true
  kubernetes_api_url            = digitalocean_kubernetes_cluster.cl01.endpoint
  kubernetes_token              = digitalocean_kubernetes_cluster.cl01.kube_config[0].token
  kubernetes_ca_cert            = base64decode(digitalocean_kubernetes_cluster.cl01.kube_config[0].cluster_ca_certificate)
  kubernetes_namespace          = ""
  kubernetes_authorization_type = "rbac"
  environment_scope             = "*"
}
```

And lastly we are not going the skip the database, as that is too easy to do.
You could potentially setup a database persistent volume in kubernetes and have
db_pods spinup, but I think that it is much easier to have the
database as a separate service outside of kubernetes. The DigitalOcean managed
database service is a great option. You pay a little extra, but it takes care of
backups etc. It is just one of those things that you don't want to worry about,
right?

Of course, we can easily add the creation of a database cluster to our terraform
setup. Note that I am using only 1 node for the cluster in this example. For actual failsafe production usage, you probably want to have at least 2 nodes.

```hcl
resource "digitalocean_database_cluster" "postgres-db" {
  name       = "postgres-db-cluster"
  engine     = "pg"
  version    = "11"
  size       = "db-s-1vcpu-1gb"
  region     = "ams3"
  node_count = 1
}
```

And while we are at it, let's create the database and firewall settings as well.

```hcl
resource "digitalocean_database_db" "test-prod" {
  cluster_id = digitalocean_database_cluster.postgres-db.id
  name       = "test_prod"
}

resource "digitalocean_database_firewall" "db-fw" {
  cluster_id = digitalocean_database_cluster.postgres-db.id

  rule {
    type  = "k8s"
    value = digitalocean_kubernetes_cluster.cl01.id
  }
}
```

This concludes our cluster setup. To get our app deployed we'll have to add some
setup to our project. We'll need to dockerize our project, add kubectl deploy
config files and add a gitlab-ci.yml that will trigger the gitlab-ci pipeline.

## A project to deploy

Now we have our kubernetes cluster up-and-running it is time to see how we would
deploy our app to the cluster.

I have a git tag prepared for you to use from my real_world_phoenix project. You
can clone that checkout to use to deploy to the cluster. It has the necessary
files to trigger deployment which I'll explain next.

Go ahead and clone the project from the tag I created:
```
git clone https://gitlab.com/drumusician/real_world_phoenix.git --branch kubernetes-deploy
```

### Gitlab pipeline

To get our app deployed to kubernetes we'll need to package it up in a container
and we'll use Gitlab CI system for all of this. That means we'll
prepare our app and package it using a 2-step dockerfile. The advantage of the
2-step dockerfile method is that we can use a larger docker image to package our
app that has all the packages for building and packaging our release and use a much slimmer container to just run our release. The release will be self-contained, so there is not a lot needed for it to run.

The steps we'll need in our CI file are:

- init             # some compiling and pushing of artifacts
- build and push   # build our container and push to our registry
- deploy           # deploy to our kubernetes cluster

For pushing we'll use the gitlab container registry that is available in every
gitlab project. The deployment will be a collection of kubernetes yaml files
that we can version control in our project. 


### Dockerfile

```docker
# ---- Build Stage ----
FROM elixir:alpine AS app_builder

# Set environment variables for building the application
ENV MIX_ENV=prod \
    TEST=1 \
    LANG=C.UTF-8

RUN apk add --update git nodejs npm && \
    rm -rf /var/cache/apk/*

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Create the application build directory
RUN mkdir /app
WORKDIR /app

# Copy over all the necessary application files and directories
COPY config ./config
COPY lib ./lib
COPY priv ./priv
COPY assets ./assets
COPY mix.exs .
COPY mix.lock .

# Fetch the application dependencies and build the application
RUN mix deps.get
RUN mix deps.compile
RUN npm run deploy --prefix ./assets
RUN mix phx.digest
RUN mix release

# ---- Application Stage ----
FROM alpine AS app

ENV LANG=C.UTF-8

# Install openssl
RUN apk add --update openssl ncurses-libs postgresql-client && \
    rm -rf /var/cache/apk/*

# Copy over the build artifact from the previous step and create a non root user
RUN adduser -D -h /home/app app
WORKDIR /home/app
COPY --from=app_builder /app/_build .
RUN chown -R app: ./prod
USER app

COPY entrypoint.sh .

# Run the Phoenix app
CMD ["./entrypoint.sh"]
```

### Entrypoint

The entrypoint.sh is basically just a bash script that verifies the db is up
and running before starting and running any pending migrations before startup as
well.

```bash
#!/bin/sh
# Docker entrypoint script.

# Wait until Postgres is ready
# while ! pg_isready -q -h $DB_HOST -p 5432 -U $DB_USER
# do
#   echo "$(date) - waiting for database to start"
#   sleep 2
# done

./prod/rel/real_world_phoenix/bin/real_world_phoenix eval RealWorldPhoenix.Release.migrate

./prod/rel/real_world_phoenix/bin/real_world_phoenix start
```

### Gitlab CI Yaml file

To trigger the gitlab-ci pipeline we'll need to add a `.gitlab-ci.yml` file in
the root of our project.

This is the content needed to initialize, build, push and deploy using the CI
pipeline. We start off creating a few variables we'll need and then define the
stages. I have added some comments in the yaml file below that should explain
the steps in detail.

Note the use of [Kaniko](https://github.com/GoogleContainerTools/kaniko) to build the container and push it to our registry. Kaniko doesn't depend on a Docker daemon and executes each command within a Dockerfile completely in userspace. This enables building container images in environments that can't easily or securely run a Docker daemon, such as a our Kubernetes cluster. Very nice!

```yaml
variables:
  REGISTRY: registry.gitlab.com
  CONTAINER_RELEASE_IMAGE: $REGISTRY/$CI_PROJECT_NAMESPACE/$CI_PROJECT_NAME:$CI_COMMIT_SHORT_SHA

stages:
  - init
  - build
  - deploy

# the dot syntax makes this a hidden step that we can include in other places further down.
.elixir_default: &elixir_default
  image: elixir:1.9
  before_script:
    - mix local.hex --force
    - mix local.rebar --force

.javascript_default: &javascript_default
  image: node:alpine
  before_script:
    - cd assets

# Compile our elixir artifacts
elixir_compile:
  <<: *elixir_default
  stage: init
  script:
    - mix deps.get --only test
    - mix compile
    - mix compile --warnings-as-errors
  artifacts:
    paths:
      - mix.lock
      - _build
      - deps

# compile javascript artifacts
javascript_deps:
  <<: *javascript_default
  stage: init
  script:
    - npm install --progress=false
  artifacts:
    paths:
      - assets/node_modules

# build our container image
build:
  stage: build
  image:
    name: gcr.io/kaniko-project/executor:debug
    entrypoint: [""]
  script:
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > /kaniko/.docker/config.json
    - /kaniko/executor --context $CI_PROJECT_DIR --dockerfile $CI_PROJECT_DIR/Dockerfile --destination $CONTAINER_RELEASE_IMAGE

# and deploy our kubernetes cluster
deploy:
  stage: deploy
  image:
    name: lwolf/kubectl_deployer:latest
  script:
    - cat deploy.yml | envsubst | kubectl apply -f -
    - cat service.yml | envsubst | kubectl apply -f -
    - cat ingress.yml | envsubst | kubectl apply -f -
  only:
    refs:
      - master
```

### Yaml deployment files: service, ingress and deploy
The last thing we need is the kubernetes yaml files that are used in the ci
pipeline:

#### service.yml

The service pod running our application. This is basically our app running in a docker container.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: real-world-phoenix-service
spec:
  ports:
  - name: web
    port: 8001
    protocol: TCP
  selector:
    app: real_world_phoenix
```

#### ingress.yml

The mapping of our domain name to our service

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: real-world-phoenix-ingress
spec:
  rules:
  - host: $DOMAIN
    http:
      paths:
      - path: "/"
        backend:
          serviceName: real-world-phoenix-service
          servicePort: web
```

#### deploy.yml

Our deployment configuration. This provides Kubernetes the info about which container image to use and how many replicas of our app we want to have running.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: real-world-phoenix
  labels:
    app: real_world_phoenix
spec:
  revisionHistoryLimit: 5
  replicas: 1
  selector:
    matchLabels:
      app: real_world_phoenix
  template:
    metadata:
      labels:
        app: real_world_phoenix
    spec:
      imagePullSecrets:
        - name: "gitlab.com"
      containers:
      - name: real-world-phoenix
        image: registry.gitlab.com/$CI_PROJECT_NAMESPACE/$CI_PROJECT_NAME:$CI_COMMIT_SHORT_SHA
        imagePullPolicy: Always
        name: real-world-phoenix-deployment
        resources: {}
        ports:
          - containerPort: 8001
        env:
          - name: SECRET_KEY_BASE
            value: $SECRET_KEY_BASE
          - name: DB_USER
            value: $DB_USER
          - name: DB_PASSWORD
            value: $DB_PASS
          - name: DB_NAME
            value: "test_prod"
          - name: DB_HOST
            value: $DB_CLUSTER
          - name: DB_PORT
            value: "25060"
          - name: APP_PORT
            value: "8001"
          - name: APP_HOSTNAME
            value: $DOMAIN
```

The above yaml file has references to a number of environment variables. The nice thing is that we can add all of these secrets inside of our Gitlab project and the deployment will use these values. In your project go to `Settings -> CI/CD -> Variables`.
Now if we have all of this in our project all we have to do is commit and push it to our gitlab repo. Then Gitlab CI will do it's magic and our application will be up and running after the pipeline jobs succeed. Nice!

## Conclusion

While it is not necessarily the easiest setup, I really like the fact that once I have this setup I can fairly easily put some configuration in any of my gitlab projects and CI will take care of the rest, even the ssl certificate is handled for me so I don't have to think about renewing them and all that stuff.

The reduction of manual work by using terraform is also a really nice benefit here. Terraform is a powerful tool, so use with care! If there is any interest in exploring terraform more, please leave a comment and I'll plan in some more in-depth post exploring the world of terraform.

I hope this post was easy to follow and I hope that for those who followed along everything worked as expected? If not, do let me know, because I want to make sure everything here works as expected.

Until next time!

