FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install the required packages
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    gtkwave \
    nano \
    git

# Set NUM_JOBS to the number of cores for parallel make
ENV NUM_JOBS=8

# Clone the repository
RUN git clone https://github.com/openhwgroup/cva6.git /cva6

WORKDIR /cva6

RUN git submodule update --init --recursive

# Install the GCC toolchain
WORKDIR /cva6/tools

WORKDIR /cva6/util/toolchain-builder

RUN apt-get install -y autoconf automake autotools-dev curl git libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool bc zlib1g-dev

RUN bash get-toolchain.sh

RUN bash build-toolchain.sh /cva6/tools

# Install CMake
RUN apt-get install -y cmake

# Set the RISCV environment variable
ENV RISCV=/cva6/tools

# Install help2man and device-tree-compiler
RUN apt-get install -y help2man device-tree-compiler

# Install the riscv-dv requirements
WORKDIR /cva6

RUN pip3 install --no-cache-dir -r verif/sim/dv/requirements.txt

# Install Verilator and Spike
RUN export DV_SIMULATORS=veri-testharness,spike
RUN bash verif/regress/smoke-tests-cv64a6_imafdc_sv39.sh