#! /bin/bash

################################################################################
# Build
################################################################################

# Set up shell
if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
    set -x                      # Output commands
fi
set -e                          # Abort on errors



# Set locations
THORN=GSL
NAME=gsl-2.8
SRCDIR="$(dirname $0)"
BUILD_DIR=${SCRATCH_BUILD}/build/${THORN}
if [ -z "${GSL_INSTALL_DIR}" ]; then
    INSTALL_DIR=${SCRATCH_BUILD}/external/${THORN}
else
    echo "Installing GSL into ${GSL_INSTALL_DIR} "
    INSTALL_DIR=${GSL_INSTALL_DIR}
fi
DONE_FILE=${SCRATCH_BUILD}/done/${THORN}
GSL_DIR=${INSTALL_DIR}

# Set up environment
unset LIBS
if echo '' ${ARFLAGS} | grep 64 > /dev/null 2>&1; then
    export OBJECT_MODE=64
fi

echo "GSL: Preparing directory structure..."
cd ${SCRATCH_BUILD}
mkdir build external done 2> /dev/null || true
rm -rf ${BUILD_DIR} ${INSTALL_DIR}
mkdir ${BUILD_DIR} ${INSTALL_DIR}

echo "GSL: Unpacking archive..."
pushd ${BUILD_DIR}
${TAR?} xzf ${SRCDIR}/../dist/${NAME}.tar.gz

echo "GSL: Configuring..."
cd ${NAME}
./configure --prefix=${GSL_DIR} --enable-shared=no

echo "GSL: Building..."
${MAKE}

echo "GSL: Installing..."
${MAKE} install
popd

echo "GSL: Cleaning up..."
rm -rf ${BUILD_DIR}

date > ${DONE_FILE}
echo "GSL: Done."
