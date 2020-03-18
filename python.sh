#!/bin/bash

wget https://github.com/LLNL/yorick/archive/y_2_1_06.tar.gz
tar zxvf y_2_1_06.tar.gz
make install

yum -y install gcc openssl-devel bzip2-devel
cd /usr/src
wget https://www.python.org/ftp/python/2.7.13/Python-2.7.13.tgz
tar xzf Python-2.7.13.tgz
cd Python-2.7.13
./configure --enable-optimizations
make altinstall

curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
python2.7 get-pip.py

python -m pip install --user numpy==1.12.1 scipy==0.19 matplotlib==2.0.2
python3 -m pip install --user numpy==1.13.1 scipy==0.19.1 matplotlib==2.0.2
