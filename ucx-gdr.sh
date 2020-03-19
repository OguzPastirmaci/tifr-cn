#!/bin/bash

set -x

export INSTALL_DIR=/home/opc/dependencies
export UCX_DIR=$INSTALL_DIR/ucx
export OMPI_DIR=$INSTALL_DIR/ompi
export GDR_DIR=$INSTALL_DIR/gdrcopy
export LD_LIBRARY_PATH=$GDR_DIR/lib64:$LD_LIBRARY_PATH
export CUDA_DIR=/usr/local/cuda-10.1
export OMPI_INSTALL_VERSION=4.0.3

mkdir -p $INSTALL_DIR
yum install -y git

# gdrcopy
cd $INSTALL_DIR
git clone https://github.com/NVIDIA/gdrcopy.git
yum install check check-devel subunit subunit-devel -y
yum groupinstall 'Development Tools' -y
yum install rpm-build make check check-devel subunit subunit-devel -y
cd $INSTALL_DIR/gdrcopy/packages
CUDA=$CUDA_DIR ./build-rpm-packages.sh
rpm -Uvh gdrcopy-kmod-2.0-4.x86_64.rpm
rpm -Uvh gdrcopy-2.0-4.x86_64.rpm
rpm -Uvh gdrcopy-devel-2.0-4.x86_64.rpm

# UCX
cd $INSTALL_DIR
yum install numactl-devel -y
git clone https://github.com/openucx/ucx.git
cd ucx
./autogen.sh
mkdir build
cd build
../contrib/configure-release --prefix=$UCX_DIR --with-cuda=$CUDA_DIR --with-gdrcopy=$GDR_DIR
make -j$(nproc)
make -j$(nproc) install

# OpenMPI
cd $INSTALL_DIR
https://download.open-mpi.org/release/open-mpi/v4.0/openmpi-$OMPI_INSTALL_VERSION.tar.gz
tar zxvf openmpi-$OMPI_INSTALL_VERSION.tar.gz
cd openmpi-$OMPI_INSTALL_VERSION
./configure --with-cuda=$CUDA_DIR --with-ucx=$UCX_DIR
make -j$(nproc)
make -j$(nproc) install
