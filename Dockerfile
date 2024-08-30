FROM ubuntu:22.04

WORKDIR /app

# Install the required packages
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    autoconf \
    automake \
    autotools-dev \
    curl \
    gtkwave \
    git \
    libmpc-dev \
    libmpfr-dev \
    libgmp-dev \
    gawk \
    build-essential \
    bison \
    flex \
    texinfo \
    gperf \
    libtool \
    bc \
    zlib1g-dev \
    help2man \
    device-tree-compiler \
    cmake \
    && rm -rf /var/lib/apt/lists/*

# Set NUM_JOBS to the number of cores for parallel make
ENV NUM_JOBS=8

# Clone the repository
RUN git clone https://github.com/openhwgroup/cva6.git

WORKDIR /app/cva6

RUN git submodule update --init --recursive

# Install the GCC toolchain
WORKDIR /app/cva6/tools

WORKDIR /app/cva6/util/toolchain-builder

RUN apt-get install autoconf automake autotools-dev curl git libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool bc zlib1g-dev

RUN bash get-toolchain.sh

RUN bash build-toolchain.sh /app/cva6/tools

# Set the RISCV environment variable
ENV RISCV=/app/cva6/tools

# Install the riscv-dv requirements
WORKDIR /app/cva6

RUN pip3 install --no-cache-dir -r verif/sim/dv/requirements.txt

# Install Verilator and Spike
RUN export DV_SIMULATORS=veri-testharness && bash verif/regress/smoke-tests.sh