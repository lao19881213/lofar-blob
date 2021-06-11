pipeline {
  agent {
    docker {
      image 'sord/yanda:latest'
    }

  }
  stages {
    stage('Building lofar-common') {
      steps {
        dir(path: '.') {
          sh '''if [ -d  ]; then
echo "lofar-common directory already exists"
rm -rf lofar-common
fi
git clone https://bitbucket.csiro.au/scm/askapsdp/lofar-common.git
cd lofar-common
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} ../
make -j2
make -j2 install
'''
        }

      }
    }
    stage('Building lofar-blob') {
      steps {
        dir(path: '.') {
          sh '''if [ -d lofar-blob ]; then
echo "lofar-blob directory already exists"
rm -rf lofar-blob
fi
git clone https://bitbucket.csiro.au/scm/askapsdp/lofar-blob.git
cd lofar-blob
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} ../
make -j2
make -j2 install
'''
        }

      }
    }
  }
  environment {
    WORKSPACE = pwd()
    PREFIX = "${WORKSPACE}/install"
  }
}

