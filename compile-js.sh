# This script compiles imagej into image.js
# It requires CHEERPJ_DIR and IJ_DIR
set -e

# compile from scratch
if [ -z ${CHEERPJ_DIR+x} ]
then
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl https://d3415aa6bfa4.leaningtech.com/cheerpj_linux_2.1.tar.gz -LO
        tar -xvf cheerpj_linux_2.1.tar.gz
        export CHEERPJ_DIR=$(pwd)/cheerpj_2.1
    else
        echo "Please download cheerpj from https://www.leaningtech.com/pages/cheerpj.html#Download and set the CHEERPJ_DIR env variable "
        exit 1
    fi
fi

# compile imagej
mvn install:install-file -Dfile=${CHEERPJ_DIR}/cheerpj-dom.jar -DgroupId=com.learningtech -DartifactId=cheerpj-dom -Dversion=1.0 -Dpackaging=jar
mvn -Pdeps package


mkdir -p imagej-js-dist
cd imagej-js-dist

# download ij153 from imagej.net
export IJ1_VERSION=ij153
export IJ_JAR=ij-1.53e.jar

curl http://wsr.imagej.net/distros/cross-platform/${IJ1_VERSION}.zip -LO
unzip -q -o ${IJ1_VERSION}.zip
rm ${IJ1_VERSION}.zip
rm -rf ${IJ1_VERSION}
mv ImageJ ${IJ1_VERSION}

cp ../target/${IJ_JAR} ${IJ1_VERSION}/
cd ${IJ1_VERSION}


# remove all the plugins except Filters
mkdir useful_plugins
mv plugins/Filters useful_plugins/Filters
rm -rf plugins
mv useful_plugins plugins

# compile cheerpj dom
cp ${CHEERPJ_DIR}/cheerpj-dom.jar cheerpj-dom-1.0.jar
${CHEERPJ_DIR}/cheerpjfy.py cheerpj-dom-1.0.jar

# compile ij.jar and we should get
${CHEERPJ_DIR}/cheerpjfy.py --pack-jar=${IJ_JAR}.packed.jar ${IJ_JAR}

# download thunderSTORM
curl https://github.com/zitmen/thunderstorm/releases/download/v1.3/Thunder_STORM.jar -LO
mv Thunder_STORM.jar plugins/Thunder_STORM.jar
${CHEERPJ_DIR}/cheerpjfy.py --deps=${IJ_JAR} --pack-jar=plugins/Thunder_STORM-packed.jar plugins/Thunder_STORM.jar


# replace with the packed version
rm ${IJ_JAR}
mv ${IJ_JAR}.packed.jar ${IJ_JAR}
rm plugins/Thunder_STORM.jar
mv plugins/Thunder_STORM-packed.jar plugins/Thunder_STORM.jar
rm ImageJ.exe
rm run
rm -rf ImageJ.app

python ../../build-plugins.py
