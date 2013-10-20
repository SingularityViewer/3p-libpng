#!/bin/bash

top="$(dirname "$0")"
stage=$(pwd)
cd "$top"

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e
LIB_NAME="libpng"
LIB_VERSION="1.5.10"
LIB_SOURCE_DIR="$LIB_NAME-$LIB_VERSION"


if [ -z "$AUTOBUILD" ] ; then 
    fail
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    export AUTOBUILD="$(cygpath -u $AUTOBUILD)"
fi

# load autbuild provided shell functions and variables
set +x
# load autbuild provided shell functions and variables
eval "$("$AUTOBUILD" source_environment)"
#install prebuilt packages
eval "$AUTOBUILD install"
set -x


pushd "$LIB_SOURCE_DIR"
    case "$AUTOBUILD_PLATFORM" in
        windows*)
            if [ "$AUTOBUILD_PLATFORM" == "windows64" ]; then
                build_target="x64"
            else
                build_target="Win32"
            fi
            build_sln "projects/vstudio/vstudio.sln" "Debug Library|$build_target"
            build_sln "projects/vstudio/vstudio.sln" "Release Library|$build_target"
            mkdir -p "$stage/lib/debug"
            mkdir -p "$stage/lib/release"
            cp projects/vstudio/Release\ Library/libpng15.lib "$stage/lib/release/libpng15.lib"
            cp projects/vstudio/Debug\ Library/libpng15.lib "$stage/lib/debug/libpng15.lib"
            mkdir -p "$stage/include/libpng15"
            cp {png.h,pngconf.h,pnglibconf.h} "$stage/include/libpng15"
        ;;
        "darwin")
            ./configure --prefix="$stage" --with-zlib-prefix="$stage/packages"
            make
            make install
	    mkdir -p "$stage/lib/release"
	    cp "$stage/lib/libpng15.a" "$stage/lib/release/"
        ;;
        "linux")
            export CFLAGS="-m32 -O3 -I$stage/packages/include"
            export CXXFLAGS=$CFLAGS
            export LDFLAGS="-m32 -L$stage/packages/lib/release"
            if [ -f Makefile ]; then
	      make distclean
            fi
           ./configure --prefix="\${PREBUILD_DIR}" \
                       --bindir="\${prefix}/bin" \
                       --libdir="\${prefix}/lib/release" \
                       --includedir="\${prefix}/include"

            make
            make install DESTDIR="$stage"

	    # build the debug version and link against the debug zlib
	    make distclean
	    export CFLAGS="-m32 -O0 -gstabs+ -I$stage/packages/include"
	    export CXXFLAGS=$CFLAGS
            export LDFLAGS="-m32 -L$stage/packages/lib/debug"

           ./configure --prefix="\${PREBUILD_DIR}" \
                       --bindir="\${prefix}/bin" \
                       --libdir="\${prefix}/lib/debug" \
                       --includedir="\${prefix}/include"

            make
            make install DESTDIR="$stage"

        ;;
        "linux64")
            export CFLAGS="-m64 -O3 -fPIC -I$stage/packages/include"
            export CXXFLAGS=$CFLAGS
            export LDFLAGS="-L$stage/packages/lib/release"
            if [ -f Makefile ]; then
	      make distclean
            fi
           ./configure --prefix="\${PREBUILD_DIR}" \
                       --bindir="\${prefix}/bin" \
                       --libdir="\${prefix}/lib/release" \
                       --includedir="\${prefix}/include" \
                       --with-pic

            make
            make install DESTDIR="$stage"

	    # build the debug version and link against the debug zlib
	    make distclean
	    export CFLAGS="-m64 -O0 -fPIC -gstabs+ -I$stage/packages/include"
	    export CXXFLAGS=$CFLAGS
            export LDFLAGS="-L$stage/packages/lib/debug"

           ./configure --prefix="\${PREBUILD_DIR}" \
                       --bindir="\${prefix}/bin" \
                       --libdir="\${prefix}/lib/debug" \
                       --includedir="\${prefix}/include" \
                       --with-pic

            make
            make install DESTDIR="$stage"
        ;;
    esac
    mkdir -p "$stage/LICENSES"
    cp LICENSE "$stage/LICENSES/libpng.txt"
popd

pass
