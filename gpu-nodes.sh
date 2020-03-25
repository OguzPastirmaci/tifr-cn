#!/bin/bash

set -ex

export INSTALL_DIR="/home/opc/dependencies"
export CUDA_VERSION=10.1
export UCX_DIR=$INSTALL_DIR/ucx
export GDR_DIR=$INSTALL_DIR/gdrcopy
export LD_LIBRARY_PATH=$GDR_DIR/lib64:$LD_LIBRARY_PATH
export CUDA_DIR=/usr/local/cuda-$CUDA_VERSION
GCC_VERSION="5.4.0"

systemctl stop firewalld

yum install -y oracle-epel-release-el7 oracle-release-el7 git screen emacs

rm -rf $INSTALL_DIR
mkdir -p $INSTALL_DIR

# CUDA
cd $INSTALL_DIR
wget https://developer.nvidia.com/compute/cuda/8.0/Prod2/local_installers/cuda_8.0.61_375.26_linux-run
wget https://developer.nvidia.com/compute/cuda/8.0/Prod2/patches/2/cuda_8.0.61.2_linux-run
sh cuda_8.0.61_375.26_linux-run --silent
sh cuda_8.0.61.2_linux-run --silent --accept-eula

echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda-8.0/lib64:\$LD_LIBRARY_PATH" > /etc/profile.d/cuda.sh
echo "export PATH=/usr/local/cuda-8.0/bin:/usr/local/cuda-8.0/NsightCompute-2019.1${PATH:+:${PATH}}" >> /etc/profile.d/cuda.sh
source /etc/profile.d/cuda.sh

# gcc 5.4.0
CURRENT_GCC_VERSION=$(gcc --version | grep gcc | awk '{print $3}')
if [ "$CURRENT_GCC_VERSION" != "$GCC_VERSION" ]
then
    yum -y install gcc-c++ gmp-devel mpfr-devel libmpc-devel
    cd $INSTALL_DIR
    wget https://ftp.gnu.org/gnu/gcc/gcc-5.4.0/gcc-5.4.0.tar.bz2
    tar jxvf gcc-5.4.0.tar.bz2
    mkdir gcc-5.4.0-build
    cd gcc-5.4.0-build
    ../gcc-5.4.0/configure --enable-languages=c,c++ --disable-multilib
    make -j$(nproc) && make install
    export PATH=/usr/local/bin:$PATH
    echo "export LD_LIBRARY_PATH=/usr/local/lib64:$LD_LIBRARY_PATH" | sudo tee /etc/profile.d/gcc.sh
fi

# GDRCopy
cd $INSTALL_DIR
git clone https://github.com/NVIDIA/gdrcopy.git
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

# OPENMPI
cd $INSTALL_DIR
wget https://download.open-mpi.org/release/open-mpi/v3.1/openmpi-3.1.6.tar.gz
tar zxvf openmpi-3.1.6.tar.gz
cd openmpi-3.1.6
./configure --with-cuda=$CUDA_DIR --with-ucx=$UCX_DIR
make -j$(nproc)
make -j$(nproc) install

# HDF5 1.8.16
cd $INSTALL_DIR
wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.16/bin/linux-centos7-x86_64-gcc483/hdf5-1.8.16-linux-centos7-x86_64-gcc483-shared.tar.gz
mkdir -p /opt/hdf5
cd /opt/hdf5
tar zxvf $INSTALL_DIR/hdf5-1.8.16-linux-centos7-x86_64-gcc483-shared.tar.gz
ln -sfn hdf5-1.8.16-linux-centos7-x86_64-gcc483-shared latest
cd /opt/hdf5/latest/bin/
./h5redeploy -force
echo "export PATH=$PATH:/opt/hdf5/latest/bin" | sudo tee /etc/profile.d/hdf5.sh

# GSL 2.4
cd $INSTALL_DIR
wget ftp://ftp.gnu.org/gnu/gsl/gsl-2.4.tar.gz
tar zxvf gsl-2.4.tar.gz
cd gsl-2.4
mkdir -p /opt/gsl
./configure --prefix=/opt/gsl
make -j$(nproc)
make check
make install
echo "export LD_LIBRARY_PATH=/opt/gsl/lib:$LD_LIBRARY_PATH" | sudo tee /etc/profile.d/gsl.sh

# INTEL MKL 2017
yum-config-manager --add-repo https://yum.repos.intel.com/mkl/setup/intel-mkl.repo
rpm --import https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB
yum -y install intel-mkl-2017.4-061.x86_64

# FFTW 2
cd $INSTALL_DIR
wget http://www.fftw.org/fftw-2.1.5.tar.gz
tar zxvf fftw-2.1.5.tar.gz
cd fftw-2.1.5
./configure --enable-type-prefix --enable-mpi
make -j$(nproc)
make install
make clean
./configure --enable-float --enable-type-prefix --enable-mpi
make -j$(nproc)
make install

# PYTHON, NUMPY, SCIPY, MATPLOTLIB
yum -y install gcc openssl-devel bzip2-devel python3
cd /usr/src
wget https://www.python.org/ftp/python/2.7.13/Python-2.7.13.tgz
tar xzf Python-2.7.13.tgz
cd Python-2.7.13
./configure --enable-optimizations
make altinstall

curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
python2.7 get-pip.py

python2.7 -m pip install --user numpy==1.12.1 scipy==0.19 matplotlib==2.0.2
python3.6 -m pip install --user numpy==1.13.1 scipy==0.19.1 matplotlib==2.0.2

# YORICK 2.1.06
cd $INSTALL_DIR
wget https://github.com/LLNL/yorick/archive/y_2_1_06.tar.gz
tar zxvf y_2_1_06.tar.gz
cd y_2_1_06
make install

rm $INSTALL_DIR/*.tar.gz
