#! /bin/bash

################################################################################
# Prepare
################################################################################

# Set up shell
if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
    set -x                      # Output commands
fi
set -e                          # Abort on errors



################################################################################
# Search
################################################################################

if [ -z "${GSL_DIR}" ]; then
    echo "BEGIN MESSAGE"
    echo "GSL selected, but GSL_DIR not set. Checking some places..."
    echo "END MESSAGE"
    
    FILES="include/gsl/gsl_math.h"
    DIRS="/usr /usr/local /usr/local/gsl /usr/local/packages/gsl /usr/local/apps/gsl ${HOME} c:/packages/gsl"
    for dir in $DIRS; do
        GSL_DIR="$dir"
        for file in $FILES; do
            if [ ! -r "$dir/$file" ]; then
                unset GSL_DIR
                break
            fi
        done
        if [ -n "$GSL_DIR" ]; then
            break
        fi
    done
    
    if [ -z "$GSL_DIR" ]; then
        echo "BEGIN MESSAGE"
        echo "GSL not found"
        echo "END MESSAGE"
    else
        echo "BEGIN MESSAGE"
        echo "Found GSL in ${GSL_DIR}"
        echo "END MESSAGE"
    fi
fi



################################################################################
# Build
################################################################################

if [ -z "${GSL_DIR}"                                            \
     -o "$(echo "${GSL_DIR}" | tr '[a-z]' '[A-Z]')" = 'BUILD' ]
then
    echo "BEGIN MESSAGE"
    echo "Using bundled GSL..."
    echo "END MESSAGE"
    
    # Set locations
    THORN=GSL
    NAME=gsl-1.15
    SRCDIR=$(dirname $0)
    BUILD_DIR=${SCRATCH_BUILD}/build/${THORN}
    if [ -z "${GSL_INSTALL_DIR}" ]; then
        INSTALL_DIR=${SCRATCH_BUILD}/external/${THORN}
    else
        echo "BEGIN MESSAGE"
        echo "Installing GSL into ${GSL_INSTALL_DIR} "
        echo "END MESSAGE"
        INSTALL_DIR=${GSL_INSTALL_DIR}
    fi
    DONE_FILE=${SCRATCH_BUILD}/done/${THORN}
    GSL_DIR=${INSTALL_DIR}
    
    if [ -e ${DONE_FILE} -a ${DONE_FILE} -nt ${SRCDIR}/dist/${NAME}.tar.gz \
                         -a ${DONE_FILE} -nt ${SRCDIR}/GSL.sh ]
    then
        echo "BEGIN MESSAGE"
        echo "GSL has already been built; doing nothing"
        echo "END MESSAGE"
    else
        echo "BEGIN MESSAGE"
        echo "Building GSL"
        echo "END MESSAGE"
        
        # Build in a subshell
        (
        exec >&2                    # Redirect stdout to stderr
        if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
            set -x                  # Output commands
        fi
        set -e                      # Abort on errors
        cd ${SCRATCH_BUILD}
        
        # Set up environment
        unset LIBS
        if echo '' ${ARFLAGS} | grep 64 > /dev/null 2>&1; then
            export OBJECT_MODE=64
        fi
        
        echo "GSL: Preparing directory structure..."
        mkdir build external done 2> /dev/null || true
        rm -rf ${BUILD_DIR} ${INSTALL_DIR}
        mkdir ${BUILD_DIR} ${INSTALL_DIR}
        
        echo "GSL: Unpacking archive..."
        pushd ${BUILD_DIR}
        ${TAR} xzf ${SRCDIR}/dist/${NAME}.tar.gz
        
        echo "GSL: Configuring..."
        cd ${NAME}
        ./configure --prefix=${GSL_DIR}
        
        echo "GSL: Building..."
        ${MAKE}
        
        echo "GSL: Installing..."
        ${MAKE} install
        popd
        
        echo "GSL: Cleaning up..."
        rm -rf ${BUILD_DIR}
        
        date > ${DONE_FILE}
        echo "GSL: Done."
        
        )
        if (( $? )); then
            echo 'BEGIN ERROR'
            echo 'Error while building GSL. Aborting.'
            echo 'END ERROR'
            exit 1
        fi
    fi
    
fi



################################################################################
# Configure Cactus
################################################################################

# Set options
if [ -x ${GSL_DIR}/bin/gsl-config ]; then
    # Obtain configuration options from GSL's configuration:
    # - for INC_DIRS, remove "standard" directories, and remove -I
    #   prefix from flags
    # - for LIB_DIRS, remove all -l flags, and remove "standard"
    #   directories, and remove -L prefix from flags
    # - for LIBS, keep only -l flags, and remove -l prefix from flags
    GSL_INC_DIRS="$(echo '' $(${GSL_DIR}/bin/gsl-config --cflags) '' | sed -e 's+ -I/include + +g;s+ -I/usr/include + +g;s+ -I/usr/local/include + +g' | sed -e 's/ -I/ /g')"
    GSL_LIB_DIRS="$(echo '' $(${GSL_DIR}/bin/gsl-config --libs) '' | sed -e 's/ -l[^ ]*/ /g' | sed -e 's+ -L/lib + +g;s+ -L/lib64 + +g;s+ -L/usr/lib + +g;s+ -L/usr/lib64 + +g;s+ -L/usr/local/lib + +g;s+ -L/usr/local/lib64 + +g' | sed -e 's/ -L/ /g')"
    GSL_LIBS="$(echo '' $(${GSL_DIR}/bin/gsl-config --libs) '' | sed -e 's/ -[^l][^ ]*/ /g' | sed -e 's/ -l/ /g')"
fi

# Pass options to Cactus
echo "BEGIN MAKE_DEFINITION"
echo "HAVE_GSL     = 1"
echo "GSL_DIR      = ${GSL_DIR}"
echo "GSL_INC_DIRS = ${GSL_INC_DIRS}"
echo "GSL_LIB_DIRS = ${GSL_LIB_DIRS}"
echo "GSL_LIBS     = ${GSL_LIBS}"
echo "END MAKE_DEFINITION"

echo 'INCLUDE_DIRECTORY $(GSL_INC_DIRS)'
echo 'LIBRARY_DIRECTORY $(GSL_LIB_DIRS)'
echo 'LIBRARY           $(GSL_LIBS)'
