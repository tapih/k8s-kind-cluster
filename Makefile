SUDO:=sudo
KUBECTL:=/usr/local/bin/kubectl
HELM:=/usr/local/bin/helm
TILLER:=/usr/local/bin/tiller
KIND:=$(GOPATH)/bin/kind

KIND_VERSION:=0.4.0
KUBERNETES_VERSION:=1.14.3
HELM_VERSION:=2.14.3

CLUSTER_NAME:="kind"

start: setup
	sed s/@KUBERNETES_VERSION@/$(KUBERNETES_VERSION)/ cluster.yaml > /tmp/cluster.yaml
	env KUBECONFIG= kind create cluster --config /tmp/cluster.yaml --image kindest/node:v$(KUBERNETES_VERSION) --name=$(CLUSTER_NAME)
	@export KUBECONFIG=$(shell kind get kubeconfig-path --name=$(CLUSTER_NAME))
	$(HELM) init
	kubectl create serviceaccount --namespace kube-system tiller
	kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
	kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'

stop:
	kind delete cluster --name=$(CLUSTER_NAME) || true

setup: $(KUBECTL) $(HELM) $(TILLER) $(KIND)

$(KIND):
	cd /tmp; env GOFLAGS= GO111MODULE=on go get sigs.k8s.io/kind@v$(KIND_VERSION)

$(KUBECTL):
	$(SUDO) curl -sfL https://storage.googleapis.com/kubernetes-release/release/v$(KUBERNETES_VERSION)/bin/linux/amd64/kubectl -o $(KUBECTL)
	$(SUDO) chmod 755 $(KUBECTL)

$(HELM) $(TILER):
	curl -sfL https://get.helm.sh/helm-v$(HELM_VERSION)-linux-amd64.tar.gz -o /tmp/helm.tar.gz
	cd /tmp; tar xvzf helm.tar.gz && rm -f helm.tar.gz
	$(SUDO) mv /tmp/linux-amd64/helm $(HELM)
	$(SUDO) mv /tmp/linux-amd64/tiller $(TILLER)
	$(SUDO) chmod 755 $(HELM)
	$(SUDO) chmod 755 $(TILLER)
	$(HELM) repo update


clean: stop
	$(SUOD) rm -f $(KUBECTL) $(KIND) $(HELM) $(TILER)

.PHONY: start stop setup clean
