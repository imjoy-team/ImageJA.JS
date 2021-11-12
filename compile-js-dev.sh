# This script compiles imagej into image.js
# It requires CHEERPJ_DIR and IJ_DIR

set -e

IJ_JAR="ij-1.53m.jar"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

mvn clean
mvn install:install-file -Dfile=${CHEERPJ_DIR}/cheerpj-dom.jar -DgroupId=com.learningtech -DartifactId=cheerpj-dom -Dversion=1.0 -Dpackaging=jar
mvn package
cp target/${IJ_JAR} ${IJ_DIR}/

cd ${IJ_DIR}
${CHEERPJ_DIR}/cheerpjfy.py -j 4 ${IJ_JAR}

cp ${CHEERPJ_DIR}/cheerpj-dom.jar ${IJ_DIR}/cheerpj-dom-1.0.jar
${CHEERPJ_DIR}/cheerpjfy.py  -j 4 ${IJ_DIR}/cheerpj-dom-1.0.jar


# download and compile MorphoLibJ
curl https://github.com/ijpb/MorphoLibJ/releases/download/v1.4.2.1/MorphoLibJ_-1.4.2.1.jar -LO
mv MorphoLibJ_-1.4.2.1.jar plugins/MorphoLibJ_-1.4.2.1.jar
${CHEERPJ_DIR}/cheerpjfy.py  -j 4 --deps=${IJ_JAR} plugins/MorphoLibJ_-1.4.2.1.jar
# extract plugins.config
jar xf plugins/MorphoLibJ_-1.4.2.1.jar plugins.config
mv plugins.config plugins/MorphoLibJ_-1.4.2.1.jar.config

# download and compile Thunder_STORM
curl https://github.com/zitmen/thunderstorm/releases/download/v1.3/Thunder_STORM.jar -LO
mv Thunder_STORM.jar plugins/Thunder_STORM.jar
${CHEERPJ_DIR}/cheerpjfy.py  -j 4 --deps=${IJ_JAR} plugins/Thunder_STORM.jar
# extract plugins.config
jar xf plugins/Thunder_STORM.jar plugins.config
mv plugins.config plugins/Thunder_STORM.jar.config

# download and compile deepimagej.js
curl https://github.com/deepimagej/deepimagej.js/releases/download/v2.0.1/DeepImageJ_JS_-2.0.1-SNAPSHOT.jar -LO
mv DeepImageJ_JS_-2.0.1-SNAPSHOT.jar plugins/DeepImageJ_JS_-2.0.1-SNAPSHOT.jar
${CHEERPJ_DIR}/cheerpjfy.py  -j 4 --deps=${IJ_JAR} plugins/DeepImageJ_JS_-2.0.1-SNAPSHOT.jar
# extract plugins.config
jar xf plugins/DeepImageJ_JS_-2.0.1-SNAPSHOT.jar plugins.config
mv plugins.config plugins/DeepImageJ_JS_-2.0.1-SNAPSHOT.jar.config

# compile action bar
curl https://raw.githubusercontent.com/mutterer/ActionBar/master/dist/action_bar20150915.jar -LO
mv action_bar20150915.jar plugins/action_bar20150915.jar
${CHEERPJ_DIR}/cheerpjfy.py  -j 4 --deps=${IJ_JAR} --pack-jar=plugins/action_bar20150915-packed.jar plugins/action_bar20150915.jar
# extract plugins.config
jar xf plugins/action_bar20150915.jar plugins.config
mv plugins.config plugins/action_bar20150915.jar.config
rm plugins/action_bar20150915.jar
mv plugins/action_bar20150915-packed.jar plugins/action_bar20150915.jar

# python ${DIR}/build-plugins.py