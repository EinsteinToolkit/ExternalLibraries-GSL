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
    
    # Check for required tools. Do this here so that we don't require
    # them when using the system library.
    if [ "x$TAR" = x ] ; then
        echo 'BEGIN ERROR'
        echo 'Could not find tar command.'
        echo 'Please make sure that the (GNU) tar command  is present,'
        echo 'and that the TAR variable is set to its location.'
        echo 'END ERROR'
        exit 1
    fi
    if [ "x$PATCH" = x ] ; then
        echo 'BEGIN ERROR'
        echo 'Could not find patch command.'
        echo 'Please make sure that the patch command is present,'
        echo 'and that the PATCH variable is set to its location.'
        echo 'END ERROR'
        exit 1
    fi

    # Set locations
    THORN=GSL
    BUILD_DIR=${SCRATCH_BUILD}/build/${THORN}
    if [ -z "${GSL_INSTALL_DIR}" ]; then
        INSTALL_DIR=${SCRATCH_BUILD}/external/${THORN}
    else
        echo "BEGIN MESSAGE"
        echo "Installing GSL into ${GSL_INSTALL_DIR} "
        echo "END MESSAGE"
        INSTALL_DIR=${GSL_INSTALL_DIR}
    fi
    GSL_DIR=${INSTALL_DIR}
    GSL_INC_DIRS="$GSL_DIR/include"
    GSL_LIB_DIRS="$GSL_DIR/lib"
    GSL_LIBS="gsl gslcblas"
else
    THORN=GSL
    DONE_FILE=${SCRATCH_BUILD}/done/${THORN}
    date > ${DONE_FILE}
fi



################################################################################
# Configure Cactus
################################################################################

# Set options
if [ -x ${GSL_DIR}/bin/gsl-config ]; then
    inc_dirs="$(${GSL_DIR}/bin/gsl-config --cflags)"
    lib_dirs="$(${GSL_DIR}/bin/gsl-config --libs)"
    libs="$(${GSL_DIR}/bin/gsl-config --libs)"
    # Translate option flags into Cactus options:
    # - for INC_DIRS, remove -I prefix from flags
    # - for LIB_DIRS, remove all -l flags, and remove -L prefix from flags
    # - for LIBS, keep only -l flags, and remove -l prefix from flags
    GSL_INC_DIRS="$(echo '' $(for flag in $inc_dirs; do echo '' $flag; done | sed -e 's/^ -I//'))"
    GSL_LIB_DIRS="$(echo '' $(for flag in $lib_dirs; do echo '' $flag; done | grep -v '^ -l' | sed -e 's/^ -L//'))"
    GSL_LIBS="$(echo '' $(for flag in $libs; do echo '' $flag; done | grep '^ -l' | sed -e 's/^ -l//'))"
fi

GSL_INC_DIRS="$(${CCTK_HOME}/lib/sbin/strip-incdirs.sh ${GSL_INC_DIRS})"
GSL_LIB_DIRS="$(${CCTK_HOME}/lib/sbin/strip-libdirs.sh ${GSL_LIB_DIRS})"

# Pass options to Cactus
echo "BEGIN MAKE_DEFINITION"
echo "GSL_DIR      = ${GSL_DIR}"
echo "GSL_INC_DIRS = ${GSL_INC_DIRS}"
echo "GSL_LIB_DIRS = ${GSL_LIB_DIRS}"
echo "GSL_LIBS     = ${GSL_LIBS}"
echo "END MAKE_DEFINITION"

echo 'INCLUDE_DIRECTORY $(GSL_INC_DIRS)'
echo 'LIBRARY_DIRECTORY $(GSL_LIB_DIRS)'
echo 'LIBRARY           $(GSL_LIBS)'
