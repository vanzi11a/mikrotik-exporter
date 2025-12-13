# Stage 1: Builder
FROM golang:1.23-bookworm AS builder

WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Build arguments for version injection
ARG VERSION
ARG REVISION
ARG BUILD_DATE
ARG BUILD_USER=docker
ARG BRANCH

# Build the binary with proper ldflags
RUN CGO_ENABLED=0 \
    go build \
    -ldflags "-X github.com/prometheus/common/version.Version=${VERSION} \
              -X github.com/prometheus/common/version.Revision=${REVISION} \
              -X github.com/prometheus/common/version.BuildDate=${BUILD_DATE} \
              -X github.com/prometheus/common/version.BuildUser=${BUILD_USER} \
              -X github.com/prometheus/common/version.Branch=${BRANCH} \
              -w -s" \
    -trimpath \
    -o /build/mikrotik-exporter \
    ./cli/

# Stage 2: Runtime
FROM gcr.io/distroless/static-debian12:nonroot

LABEL org.opencontainers.image.title="Mikrotik Exporter" \
      org.opencontainers.image.description="Prometheus exporter for MikroTik RouterOS devices" \
      org.opencontainers.image.vendor="vanzi11a" \
      org.opencontainers.image.source="https://github.com/vanzi11a/mikrotik-exporter" \
      org.opencontainers.image.licenses="BSD 3-Clause License"

COPY --from=builder /build/mikrotik-exporter /usr/local/bin/mikrotik-exporter

EXPOSE 9436

# distroless:nonroot - uid:gid 65532:65532
USER nonroot:nonroot

ENTRYPOINT ["/usr/local/bin/mikrotik-exporter"]
CMD []
