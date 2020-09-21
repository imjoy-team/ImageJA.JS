# This script compiles imagej into image.js
# It requires CHEERPJ_DIR and IJ_DIR

set -e

IJ_JAR="ij-1.53e.jar"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

mvn install:install-file -Dfile=${CHEERPJ_DIR}/cheerpj-dom.jar -DgroupId=com.learningtech -DartifactId=cheerpj-dom -Dversion=1.0 -Dpackaging=jar
mvn -Pdeps package
cp target/${IJ_JAR} ${IJ_DIR}/

cd ${IJ_DIR}
${CHEERPJ_DIR}/cheerpjfy.py ${IJ_JAR}

cp ${CHEERPJ_DIR}/cheerpj-dom.jar ${IJ_DIR}/cheerpj-dom-1.0.jar
${CHEERPJ_DIR}/cheerpjfy.py ${IJ_DIR}/cheerpj-dom-1.0.jar

curl https://github.com/zitmen/thunderstorm/releases/download/v1.3/Thunder_STORM.jar -LO
mv Thunder_STORM.jar plugins/Thunder_STORM.jar
${CHEERPJ_DIR}/cheerpjfy.py  --deps=${IJ_JAR} plugins/Thunder_STORM.jar

# python ${DIR}/build-plugins.py