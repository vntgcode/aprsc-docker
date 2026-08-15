# --- Stage 1: Build aprsc ---
FROM debian:trixie-slim AS builder

RUN apt-get update && apt-get install -y \
    build-essential \
    libevent-dev \
    libssl-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone https://github.com/hessu/aprsc.git . && \
    cd src && \
    ./configure && \
    make

# --- Stage 2: Runtime Environment ---
FROM debian:trixie-slim

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

# Setup configuration directories
RUN mkdir -p logs data && \
    chown -R aprsc:aprsc /aprsc 

USER aprsc

EXPOSE 14580 10152 8080
CMD ["/usr/sbin/aprsc", "-o", "stderr", "-c", "aprsc.conf"]
