ARG BUILDER_IMAGE
ARG RUNTIME_IMAGE

FROM $BUILDER_IMAGE AS builder
WORKDIR /go/src/github.com/openshift/cloud-credential-operator
COPY . .
ENV GO_PACKAGE github.com/openshift/cloud-credential-operator
RUN go build -ldflags "-X $GO_PACKAGE/pkg/version.versionFromGit=$(git describe --long --tags --abbrev=7 --match 'v[0-9]*' --always)" ./cmd/cloud-credential-operator

FROM $RUNTIME_IMAGE
LABEL name="CIP Cloud Credential Operator" \
      io.k8s.display-name="CIP Cloud Credential Operator" \
      vendor="CIP Core Platform" \
      maintainer="CIP Core Platform Community" \
      url="https://github.com/cip-core-mirrors/cloud-credential-operator" \
      summary="CIP Cloud Credential Operator" \
      license="Apache 2" \
      description="The cloud credential operator is a controller that will sync on CredentialsRequest custom resources. CredentialsRequests allow CIP components to request fine grained credentials for a particular cloud provider. Check https://github.com/cip-core-mirrors/cloud-credential-operator for more information." \
      io.k8s.description="The cloud credential operator is a controller that will sync on CredentialsRequest custom resources. CredentialsRequests allow CIP components to request fine grained credentials for a particular cloud provider. Check https://github.com/cip-core-mirrors/cloud-credential-operator for more information." \
      io.openshift.expose-services="" \
      io.openshift.tags="cip cloud-credential-operator"
RUN microdnf -y update && \
    microdnf clean all && \
    rm -rf /var/cache/yum
COPY --from=builder /go/src/github.com/openshift/cloud-credential-operator/cloud-credential-operator /usr/bin/
COPY manifests /manifests
# Update perms so we can copy updated CA if needed
RUN chmod -R g+w /etc/pki/ca-trust/extracted/pem/
# TODO make path explicit here to remove need for ENTRYPOINT
# https://github.com/openshift/installer/blob/a8ddf6619794416c4600a827c2d9284724d382d8/data/data/bootstrap/files/usr/local/bin/bootkube.sh.template#L347
ENTRYPOINT [ "/usr/bin/cloud-credential-operator" ]
