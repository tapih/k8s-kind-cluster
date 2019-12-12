SUDO:=sudo
KUBECTL:=/usr/local/bin/kubectl
KIND:=$(GOPATH)/bin/kind
KIND_VERSION:=0.6.1
KUBERNETES_VERSION:=1.16.3
CLUSTER_NAME:="kind"

start: setup
	sed s/@KUBERNETES_VERSION@/$(KUBERNETES_VERSION)/ cluster.yaml > /tmp/cluster.yaml
	kind create cluster --config /tmp/cluster.yaml --image kindest/node:v$(KUBERNETES_VERSION) --name=$(CLUSTER_NAME)

run: start
	go run -mod=vendor main.go

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

.PHONY: start stop setup clean run
