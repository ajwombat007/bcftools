# ============================================================
# Multi-stage Dockerfile for bcftools 1.23.1
# ============================================================

# ----------------------------------------------------------
# Stage 1: Build
# ----------------------------------------------------------
FROM debian:bookworm AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    autoconf \
    automake \
    make \
    gcc \
    perl \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libcurl4-gnutls-dev \
    libssl-dev \
    libperl-dev \
    libgsl0-dev \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ARG BCFTOOLS_VERSION=1.23.1

WORKDIR /build

# Clone and build HTSlib
RUN git clone --depth 1 --recurse-submodules --branch ${BCFTOOLS_VERSION} \
    https://github.com/samtools/htslib.git /build/htslib

WORKDIR /build/htslib
RUN autoreconf -i && ./configure && make -j"$(nproc)" && make install

# Copy and build bcftools
COPY . /build/bcftools

WORKDIR /build/bcftools
RUN autoheader && autoconf && \
    ./configure \
        --enable-libgsl \
        --enable-perl-filters \
        --with-htslib=/build/htslib && \
    make -j"$(nproc)" && \
    make install

# ----------------------------------------------------------
# Stage 2: Runtime
# ----------------------------------------------------------
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    zlib1g \
    libbz2-1.0 \
    liblzma5 \
    libcurl3-gnutls \
    libssl3 \
    perl \
    libperl5.36 \
    libgsl27 \
    libgslcblas0 \
    && rm -rf /var/lib/apt/lists/*

# Copy all installed files from builder
COPY --from=builder /usr/local/ /usr/local/
RUN ldconfig

# Set plugin path
ENV BCFTOOLS_PLUGINS=/usr/local/libexec/bcftools

WORKDIR /data
