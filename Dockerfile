#
# Copyright 2026 The OKDP Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

ARG GO_VERSION=1.24

FROM golang:${GO_VERSION} AS go-build

ARG TARGETOS
ARG TARGETARCH
ARG GO_LICENSES_VERSION=v2.0.1

WORKDIR /workspace/spark-web-proxy

COPY Makefile Makefile
COPY go.* ./
COPY *.go ./
COPY internal/ internal/
COPY cmd/ cmd/
COPY LICENSE ./

RUN go mod download

RUN go install github.com/google/go-licenses/v2@${GO_LICENSES_VERSION}

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -a -o spark-web-proxy main.go

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go-licenses save ./... --save_path=/LICENSES

FROM alpine:3.23.2

RUN apk --no-cache upgrade && \
    apk --no-cache add ca-certificates && \
    update-ca-certificates

COPY --from=go-build /workspace/spark-web-proxy /usr/local/bin/
COPY --from=go-build /LICENSES/* /LICENSES/

USER 65534:65534

EXPOSE 8090

ENTRYPOINT ["spark-web-proxy"]

