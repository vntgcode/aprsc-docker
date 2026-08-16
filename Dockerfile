# --- Stage 1: Build aprsc ---
FROM debian:trixie-slim AS builder

ARG APRSC_VERSION=2.1.21

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    autoconf \
    automake \
    libevent-dev \
    libpopt-dev \
    libssl-dev \
    zlib1g-dev \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --branch release/${APRSC_VERSION} --depth 1  https://github.com/hessu/aprsc.git . && \
    cd src && \
    ./configure && \
    make

# --- Stage 2: Runtime Environment ---
FROM debian:trixie-slim

ARG APRSC_VERSION=2.1.21

LABEL aprsc.version=${APRSC_VERSION}
LABEL aprsc.web=http://he.fi/aprsc/

RUN apt-get update && apt-get install -y \
    libevent-2.1-7 \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

# Replicate the aprsc user
RUN useradd aprsc -u 1000 -d /aprsc

WORKDIR /aprsc

# Copy binary from build stage
COPY --from=builder /src/src/aprsc /usr/sbin/aprsc
COPY --from=builder /src/src/web /aprsc/web
COPY entrypoint.sh /aprsc

# Setup configuration directories
RUN mkdir -p logs data && \
    chown -R aprsc:aprsc /aprsc && \
    chmod 0755 /aprsc/entrypoint.sh

USER aprsc

EXPOSE 8080 8080/udp 10152 14501 14580

ENTRYPOINT ["/aprsc/entrypoint.sh"]

CMD ["/usr/sbin/aprsc", "-o", "stderr", "-c", "aprsc.conf"]
