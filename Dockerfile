FROM --platform=$BUILDPLATFORM golang:1.25.9-alpine as gobuild

ARG TARGETOS
ARG TARGETARCH

WORKDIR /build
ADD go.mod go.sum /build/
RUN go mod download -x
ADD cmd /build/cmd
ADD pkg /build/pkg
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -a -ldflags '-extldflags "-static"' -o ./s3driver ./cmd/s3driver

FROM alpine:latest

ARG TARGETARCH

LABEL maintainers="Vitaliy Filippov <vitalif@yourcmc.ru>"
LABEL description="csi-s3 slim image"

RUN apk add --no-cache fuse3 fuse mailcap rclone curl
RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/community s3fs-fuse

RUN curl -fsSL -o /usr/bin/geesefs \
      "https://github.com/yandex-cloud/geesefs/releases/latest/download/geesefs-linux-${TARGETARCH}" \
    && chmod 755 /usr/bin/geesefs

COPY --from=gobuild /build/s3driver /s3driver
ENTRYPOINT ["/s3driver"]
