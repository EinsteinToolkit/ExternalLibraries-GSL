#! /bin/bash

################################################################################
# Prepare
################################################################################

# Set up shell
set -x                          # Output commands
set -e                          # Abort on errors

# Set locations
NAME=gsl-1.12
SRCDIR=$(dirname $0)
INSTALL_DIR=${SCRATCH_BUILD}
GSL_DIR=${INSTALL_DIR}/${NAME}

# Clean up environment
unset LIBS
unset MAKEFLAGS



################################################################################
# Build
################################################################################

(
    exec >&2                    # Redirect stdout to stderr
    set -x                      # Output commands
    set -e                      # Abort on errors
    cd ${INSTALL_DIR}
    if [ -e done-${NAME} -a done-${NAME} -nt ${SRCDIR}/dist/${NAME}.tar.gz \
                         -a done-${NAME} -nt ${SRCDIR}/GSL.sh ]
    then
        echo "GSL: The enclosed GSL library has already been built; doing nothing"
    else
        echo "GSL: Building enclosed GSL library"
        
        echo "GSL: Unpacking archive..."
        rm -rf build-${NAME}
        mkdir build-${NAME}
        pushd build-${NAME}
        # Should we use gtar or tar?
        TAR=$(gtar --help > /dev/null 2> /dev/null && echo gtar || echo tar)
        ${TAR} xzf ${SRCDIR}/dist/${NAME}.tar.gz
        popd
        
        echo "GSL: Configuring..."
        rm -rf ${NAME}
        mkdir ${NAME}
        pushd build-${NAME}/${NAME}
        ./configure --prefix=${GSL_DIR}
        
        echo "GSL: Building..."
        make
        
        echo "GSL: Installing..."
        make install
        popd
        
        echo 'done' > done-${NAME}
        echo "GSL: Done."
    fi
)

if (( $? )); then
    echo 'BEGIN ERROR'
    echo 'Error while building GSL.  Aborting.'
    echo 'END ERROR'
    exit 1
fi



################################################################################
# Configure Cactus
################################################################################

# Set options
GSL_INC_DIRS="${GSL_DIR}/include"
GSL_LIB_DIRS="${GSL_DIR}/lib"
GSL_LIBS='gsl gslcblas'

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
