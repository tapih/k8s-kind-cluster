SUDO=sudo
LOGCTL=$(GOPATH)/bin/logcli

all: $(LOGCTL)

$(LOGCTL):
	GO111MODULE=off go get github.com/grafana/loki/cmd/logcli
