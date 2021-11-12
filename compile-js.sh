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
mvn package


mkdir -p imagej-js-dist
cd imagej-js-dist

# download ij153 from imagej.net
export IJ1_VERSION=ij153
export IJ_JAR=ij-1.53m.jar

curl http://wsr.imagej.net/distros/cross-platform/${IJ1_VERSION}.zip -LO
unzip -q -o ${IJ1_VERSION}.zip
rm ${IJ1_VERSION}.zip
rm -rf ${IJ1_VERSION}
mv ImageJ ${IJ1_VERSION}
# Remove the command finder tool
awk '!/Command Finder Built-in Tool/' ${IJ1_VERSION}/macros/StartupMacros.txt > temp && mv temp ${IJ1_VERSION}/macros/StartupMacros.txt

cp ../target/${IJ_JAR} ${IJ1_VERSION}/
cd ${IJ1_VERSION}


# remove all the plugins except Filters
mkdir useful_plugins
mv plugins/Filters useful_plugins/Filters
rm -rf plugins
mv useful_plugins plugins

# compile cheerpj dom
cp ${CHEERPJ_DIR}/cheerpj-dom.jar cheerpj-dom-1.0.jar
${CHEERPJ_DIR}/cheerpjfy.py  -j 4 cheerpj-dom-1.0.jar

# compile ij.jar and we should get
${CHEERPJ_DIR}/cheerpjfy.py  -j 4 --pack-jar=${IJ_JAR}.packed.jar ${IJ_JAR}
rm ${IJ_JAR}
mv ${IJ_JAR}.packed.jar ${IJ_JAR}

# download and compile MorphoLibJ
curl https://github.com/ijpb/MorphoLibJ/releases/download/v1.4.2.1/MorphoLibJ_-1.4.2.1.jar -LO
mv MorphoLibJ_-1.4.2.1.jar plugins/MorphoLibJ_-1.4.2.1.jar
${CHEERPJ_DIR}/cheerpjfy.py  -j 4 --deps=${IJ_JAR} --pack-jar=plugins/MorphoLibJ_-1.4.2.1-packed.jar plugins/MorphoLibJ_-1.4.2.1.jar
# extract plugins.config
jar xf plugins/MorphoLibJ_-1.4.2.1.jar plugins.config
mv plugins.config plugins/MorphoLibJ_-1.4.2.1.jar.config
rm plugins/MorphoLibJ_-1.4.2.1.jar
mv plugins/MorphoLibJ_-1.4.2.1-packed.jar plugins/MorphoLibJ_-1.4.2.1.jar

# download and compile Thunder_STORM
curl https://github.com/zitmen/thunderstorm/releases/download/v1.3/Thunder_STORM.jar -LO
mv Thunder_STORM.jar plugins/Thunder_STORM.jar
${CHEERPJ_DIR}/cheerpjfy.py  -j 4 --deps=${IJ_JAR} --pack-jar=plugins/Thunder_STORM-packed.jar plugins/Thunder_STORM.jar
# extract plugins.config
jar xf plugins/Thunder_STORM.jar plugins.config
mv plugins.config plugins/Thunder_STORM.jar.config
rm plugins/Thunder_STORM.jar
mv plugins/Thunder_STORM-packed.jar plugins/Thunder_STORM.jar

# download and compile deepimagej.js
curl https://github.com/deepimagej/deepimagej.js/releases/download/v2.0.1/DeepImageJ_JS_-2.0.1-SNAPSHOT.jar -LO
mv DeepImageJ_JS_-2.0.1-SNAPSHOT.jar plugins/DeepImageJ_JS_-2.0.1-SNAPSHOT.jar
${CHEERPJ_DIR}/cheerpjfy.py  -j 4 --deps=${IJ_JAR} --pack-jar=plugins/DeepImageJ_JS_-2.0.1-SNAPSHOT-packed.jar plugins/DeepImageJ_JS_-2.0.1-SNAPSHOT.jar
# extract plugins.config
jar xf plugins/DeepImageJ_JS_-2.0.1-SNAPSHOT.jar plugins.config
mv plugins.config plugins/DeepImageJ_JS_-2.0.1-SNAPSHOT.jar.config
rm plugins/DeepImageJ_JS_-2.0.1-SNAPSHOT.jar
mv plugins/DeepImageJ_JS_-2.0.1-SNAPSHOT-packed.jar plugins/DeepImageJ_JS_-2.0.1-SNAPSHOT.jar

# compile action bar
curl https://raw.githubusercontent.com/mutterer/ActionBar/master/dist/action_bar20150915.jar -LO
mv action_bar20150915.jar plugins/action_bar20150915.jar
${CHEERPJ_DIR}/cheerpjfy.py  -j 4 --deps=${IJ_JAR} --pack-jar=plugins/action_bar20150915-packed.jar plugins/action_bar20150915.jar
# extract plugins.config
jar xf plugins/action_bar20150915.jar plugins.config
mv plugins.config plugins/action_bar20150915.jar.config
rm plugins/action_bar20150915.jar
mv plugins/action_bar20150915-packed.jar plugins/action_bar20150915.jar

rm ImageJ.exe
rm run
rm -rf ImageJ.app

python ../../build-plugins.py
