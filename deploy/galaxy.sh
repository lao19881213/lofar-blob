#!/bin/bash -l

#
# Make a directory to contain the artifacts
#
ARTIFACTS_DIR=$WORKSPACE/install
mkdir -p $ARTIFACTS_DIR
if [ $? -ne 0 ]; then
    echo "Error: failed to make artifacts directory"
    exit 1
fi

module load boost

cd $WORKSPACE

mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${ARTIFACTS_DIR} -DCASACORE_ROOT_DIR=/group/askap/sord/yanda ../
make lofar-common
make
make install



