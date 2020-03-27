# K8s workshop in a box

We recently organised an internal Kubernetes workshop at our office. Each participant got their own 3-node Kubernetes cluster and all they needed was a laptop with an SSH client, no other software had to be installed! How? Read on to find out!

## Why

I wanted participants to have a real cluster to experiment with, but didn't want to ask everyone to install Minikube. It's heavy weight and I didn't want people to have to mess with this, workshops should have a low as possible barrier to entry.

To pull this off I used [Kind](https://kind.sigs.k8s.io/) (Kubernetes In Docker) + a bit of scripting and Unix magic! 💪

## How it works

It works as follows:

1. A single, beefy cloud server is used to host all Kubernetes clusters.
2. Every clusters runs 3 Docker containers (via Kind) and is fully isolated from the other clusters. Every cluster consists of one master and two worker nodes.
3. The clusters are (automatically) provisioned in advance to the workshop, as creating the clusters is quite resource intensive and takes a couple of minutes per cluster.
4. During the workshop participants can claim their own cluster via SSH and then access their cluster via a new SSH session.

You can see the process from a participant perspective in action below:

[GIF here]

## Hardware & costs

A Kind cluster is quite resource intensive, though in part it depends on the workloads your workshop participants are running of course. For our workshop with 15 participants we used an AWS `m5.8xlarge` machine. This machine type has 32 VCPU's and 128GB of RAM. It costs $1,712 per hour (in `eu-west-1`) and we needed it only for about 3 hours so that's about $5 total 🙂.

In hindsight, this machine was way over provisioned for this number of clusters, so you could go even cheaper 😀

## You can use this too to run your own Kubernetes workshops!

We've open-sourced the tooling we built to do this here: https://github.com/kabisa/k8s-workshop-in-a-box. Feel free to use it and if you do please reach out to me I'd love to hear from you! ❤️