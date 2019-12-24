FROM golang:1.13-alpine AS builder

ARG TWINT_GENERATOR_VERSION

RUN apk add --no-cache make

COPY .  /go/src/github.com/shurcooL/gtdo
WORKDIR /go/src/github.com/shurcooL/gtdo

RUN cd /go/src/github.com/shurcooL/gtdo \
    && go build -o gtdo-server -v

FROM golang:1.13-alpine AS runtime

# Build argument
ARG VERSION
ARG BUILD
ARG NOW

# Install tini to /usr/local/sbin
ADD https://github.com/krallin/tini/releases/download/v0.18.0/tini-muslc-amd64 /usr/local/sbin/tini

# Install runtime dependencies & create runtime user
RUN apk --no-cache --no-progress add ca-certificates git \
 && chmod +x /usr/local/sbin/tini && mkdir -p /opt \
 && adduser -D shurcooL -h /opt/gtdo -s /bin/sh \
 && su shurcooL -c 'cd /opt/gtdo; mkdir -p bin config data'

# Switch to user context
USER shurcooL
WORKDIR /opt/gtdo/data

# Copy gtdo binary to /opt/gtdo/bin
COPY --from=builder /go/src/github.com/shurcooL/gtdo/gtdo-server /opt/gtdo/bin/gtdo
ENV PATH $PATH:/opt/gtdo/bin

# Container metadata
LABEL name="gtdo" \
      version="$VERSION" \
      build="$BUILD" \
      architecture="x86_64" \
      build_date="$NOW" \
      vendor="shurcooL" \
      maintainer="x0rzkov <x0rzkov@protonmail.com>" \
      url="https://github.com/shurcooL/gtdo" \
      summary="Dockerized gtdo project" \
      description="Dockerized gtdo project" \
      vcs-type="git" \
      vcs-url="https://github.com/shurcooL/gtdo" \
      vcs-ref="$VERSION" \
      distribution-scope="public"

# Container configuration
VOLUME ["/opt/gtdo/data"]
ENTRYPOINT ["tini", "-g", "--"]
CMD ["/opt/gtdo/bin/gtdo"]




