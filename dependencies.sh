#!/bin/bash

set -x
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/etc/log.out 2>&1

yum install -y oracle-epel-release-el7 oracle-release-el7

# gcc 5.4.0
yum -y install gcc-c++ gmp-devel mpfr-devel libmpc-devel
cd ~
wget https://ftp.gnu.org/gnu/gcc/gcc-5.4.0/gcc-5.4.0.tar.bz2
tar jxvf gcc-5.4.0.tar.bz2
mkdir gcc-5.4.0-build
cd gcc-5.4.0-build
../gcc-5.4.0/configure --enable-languages=c,c++ --disable-multilib
make -j$(nproc) && make install
export PATH=/usr/local/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/lib64:$LD_LIBRARY_PATH

# HDF5 1.8.16
cd ~
wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.16/bin/linux-centos7-x86_64-gcc483/hdf5-1.8.16-linux-centos7-x86_64-gcc483-shared.tar.gz
mkdir -p /opt/hdf5
cd /opt/hdf5
tar zxvf ~/hdf5-1.8.16-linux-centos7-x86_64-gcc483-shared.tar.gz
ln -s hdf5-1.8.16-linux-centos7-x86_64-gcc483-shared latest
cd /opt/hdf5/latest/bin/
./h5redeploy -force
echo 'export PATH=$PATH:/opt/hdf5/latest/bin' | sudo tee /etc/profile.d/hdf5.sh

# GSL 2.4
cd ~
wget ftp://ftp.gnu.org/gnu/gsl/gsl-2.4.tar.gz
tar zxvf gsl-2.4.tar.gz
cd gsl-2.4
mkdir /opt/gsl
./configure --prefix=/opt/gsl
make
make check
make install

# INTEL MKL 2017
yum-config-manager --add-repo https://yum.repos.intel.com/setup/intelproducts.repo
yum-config-manager --add-repo https://yum.repos.intel.com/mkl/setup/intel-mkl.repo
rpm --import https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB
yum -y install intel-mkl-2017.4-061.x86_64

# FFTW 2 & FFTW 3
yum -y install fftw2-devel
yum -y install fftw-devel

# CUDA 10
[ -f /usr/local/cuda/bin/nvcc ] && ln -s /usr/local/cuda/bin/nvcc /usr/bin/nvcc

# OPENMPI 1.10.7
yum -y install openmpi-devel-1.10.7-5.el7.x86_64
ln -s /usr/lib64/openmpi/bin/mpicc /usr/bin/mpicc

# PYTHON, NUMPY, SCIPY, MATPLOTLIB
yum -y install python3
yum -y install python-devel
yum -y install python3-devel
python3 -m pip install --upgrade pip
python3 -m pip install --user numpy==1.12.1 scipy==0.19 matplotlib==2.0.0
