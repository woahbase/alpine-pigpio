# syntax=docker/dockerfile:1
#
ARG IMAGEBASE=frommakefile
#
FROM ${IMAGEBASE} AS builder
#
ARG NPROC=6
ARG VERSION
#
RUN set -ex \
    && mkdir -p /tmp/build \
    && apk add -Uu --no-cache alpine-sdk curl \
    && echo "Using version: $VERSION" \
    && curl \
        -o /tmp/pigpio_v${VERSION}.tar.gz \
        -jSLN https://github.com/joan2937/pigpio/archive/refs/tags/v${VERSION}.tar.gz \
    && tar -xzf /tmp/pigpio_v${VERSION}.tar.gz -C /tmp/build --strip 1 \
    && cd /tmp/build \
    # Fix for compiling on Alpine, https://github.com/joan2937/pigpio/issues/107
    && sed -i -e 's/ldconfig/echo ldconfig disabled/g' Makefile \
    && make -j${NPROC} \
    && make install
#
FROM ${IMAGEBASE}
#
ENV \
    PIGPIO_PORT=8888
#
COPY --from=builder /usr/local /usr/local
COPY --from=builder /opt/pigpio/cgi /opt/pigpio/cgi
COPY root/ /
#
# RUN set -ex \
#     && apk add -Uu --no-cache tzdata \
#     && rm -rf /var/cache/apk/* /tmp/*
#
EXPOSE ${PIGPIO_PORT}
#
HEALTHCHECK \
    --interval=2m \
    --retries=5 \
    --start-period=5m \
    --timeout=10s \
    CMD \
    nc -z -i 1 -w 1 localhost ${PIGPIO_PORT:-8888} || exit 1
#
ENTRYPOINT ["/init"]
