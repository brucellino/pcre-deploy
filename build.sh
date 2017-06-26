#!/bin/bash -e
. /etc/profile.d/modules.sh
module avail
module add ci
module add  bzip2
module add readline
module  add  ncurses
module add  cmake

SOURCE_FILE=${NAME}-${VERSION}.tar.gz

mkdir -p ${WORKSPACE}
mkdir -p ${SRC_DIR}
mkdir -p ${SOFT_DIR}

#  Download the source file

if [ ! -e ${SRC_DIR}/${SOURCE_FILE}.lock ] && [ ! -s ${SRC_DIR}/${SOURCE_FILE} ] ; then
  touch  ${SRC_DIR}/${SOURCE_FILE}.lock
  echo "seems like this is the first build - let's get the source"
  wget https://ftp.pcre.org/pub/pcre/${NAME}-${VERSION}.tar.gz -O ${SRC_DIR}/${SOURCE_FILE}
  echo "releasing lock"
  rm -v ${SRC_DIR}/${SOURCE_FILE}.lock
elif [ -e ${SRC_DIR}/${SOURCE_FILE}.lock ] ; then
  # Someone else has the file, wait till it's released
  while [ -e ${SRC_DIR}/${SOURCE_FILE}.lock ] ; do
    echo " There seems to be a download currently under way, will check again in 5 sec"
    sleep 5
  done
else
  echo "continuing from previous builds, using source at " ${SRC_DIR}/${SOURCE_FILE}
fi
tar xzf  ${SRC_DIR}/${SOURCE_FILE} -C ${WORKSPACE} --skip-old-files
mkdir -p ${WORKSPACE}/${NAME}-${VERSION}/build-${BUILD_NUMBER}
cd ${WORKSPACE}/${NAME}-${VERSION}/build-${BUILD_NUMBER}
cmake ../ -G"Unix Makefiles" \
  -DCMAKE_INSTALL_PREFIX=$SOFT_DIR \
  -DBUILD_SHARED_LIBS=ON \
  -DBUILD_STATIC_LIBS=ON \
  -DPCRE2_BUILD_PCRE2_16=ON \
  -DPCRE2_BUILD_PCRE2_32=ON \
  -DBZIP2_INCLUDE_DIR=${BZLIB_DIR}/include \
  -DBZIP2_LIBRARY_RELEASE=${BZLIB_DIR}/lib/libbz2.so \
  -DNCURSES_LIBRARY=${NCURSES_DIR}/lib/libncurses.so \
  -DNCURSES_INCLUDE_DIR=${NCURSES_DIR}/include \
  -DREADLINE_INCLUDE_DIR="${READLINE_DIR}/include" \
  -DREADLINE_LIBRARY="${READLINE_DIR}/lib/libreadline.so" \
  -DPCRE2_SUPPORT_LIBREADLINE=ON \
  -DPCRE2_SUPPORT_LIBBZ2=ON

LDFLAGS="-L${NCURSES_DIR}/lib -lncurses" make
