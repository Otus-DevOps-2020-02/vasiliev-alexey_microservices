FROM golang:1.11
WORKDIR /go/src/github.com/percona/
RUN git clone https://github.com/percona/mongodb_exporter.git
WORKDIR /go/src/github.com/percona/mongodb_exporter
RUN make build
FROM quay.io/prometheus/busybox:latest
COPY --from=0 /go/src/github.com/percona/mongodb_exporter/bin/mongodb_exporter /bin/mongodb_exporter
EXPOSE 9216
ENTRYPOINT [ "/bin/mongodb_exporter" ]
