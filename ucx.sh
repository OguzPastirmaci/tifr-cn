#!/bin/bash

set -x

export INSTALL_DIR=/home/opc/dependencies
export UCX_DIR=$INSTALL_DIR/ucx
export OMPI_DIR=$INSTALL_DIR/ompi
#export GDR_DIR=$INSTALL_DIR/gdrcopy
export LD_LIBRARY_PATH=$GDR_DIR/lib64:$LD_LIBRARY_PATH
export CUDA_DIR=/usr/local/cuda-10.1

# gdrcopy
#cd $INSTALL_DIR
#yum install check check-devel subunit subunit-devel -y
#yum groupinstall 'Development Tools' -y
#yum install rpm-build make check check-devel subunit subunit-devel -y
#CUDA=$CUDA_DIR ./build-rpm-packages.sh
#rpm -Uvh gdrcopy-kmod-2.0-4.x86_64.rpm
#rpm -Uvh gdrcopy-2.0-4.x86_64.rpm
#rpm -Uvh gdrcopy-devel-2.0-4.x86_64.rpm

# UCX
cd $INSTALL_DIR
yum install numactl-devel -y
git clone https://github.com/openucx/ucx.git
cd ucx
./autogen.sh
mkdir build
cd build
../contrib/configure-release --prefix=$UCX_DIR --with-cuda=$CUDA_DIR
make -j$(nproc)
make -j$(nproc) install

# OpenMPI
cd $INSTALL_DIR
wget https://download.open-mpi.org/release/open-mpi/v3.1/openmpi-3.1.5.tar.gz
tar zxvf openmpi-3.1.5.tar.gz
cd openmpi-3.1.5
./configure --with-cuda=$CUDA_DIR --with-ucx=$UCX_DIR
make -j$(nproc)
make -j$(nproc) install
