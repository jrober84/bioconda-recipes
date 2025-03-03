#!/bin/bash
set -ex

if [ `uname` == Darwin ]; then
	echo $(pwd)/zig-macos-x86_64-*
	export PATH="$(pwd)/zig-macos-x86_64-0.10.1:${PATH}"
	else
	echo $(pwd)/zig-linux-x86_64-*
	export PATH="$(pwd)/zig-linux-x86_64-0.10.1:${PATH}"
fi

export INCLUDES="-I${PREFIX}/include -I. -Ihtslib -Itabixpp -I\$(INC_DIR)"
export LIBPATH="-L${PREFIX}/lib -L. -Lhtslib -Ltabixpp"
export LDFLAGS="${LDFLAGS} -L${PREFIX}/lib -lhts -ltabixpp -lpthread -lz -lm -llzma -lbz2 -fopenmp"
export CXXFLAGS="${CXXFLAGS} -O3 -D_FILE_OFFSET_BITS=64"

sed -i.bak 's/CFFFLAGS:= -O3/CFFFLAGS=-O3 -D_FILE_OFFSET_BITS=64 -std=c++0x/' contrib/smithwaterman/Makefile
sed -i.bak 's/CFLAGS/CXXFLAGS/g' contrib/smithwaterman/Makefile

sed -i.bak 's/$</$< $(LDFLAGS)/g' contrib/smithwaterman/Makefile
sed -i.bak 's/ld/$(LD)/' contrib/smithwaterman/Makefile
sed -i.bak 's/gcc/$(CC) $(CFLAGS)/g' contrib/filevercmp/Makefile
sed -i.bak 's/g++/$(CXX) $(CXXFLAGS)/g' contrib/multichoose/Makefile
sed -i.bak 's/g++/$(CXX) $(CXXFLAGS)/g' contrib/intervaltree/Makefile

# MacOSX Build fix: https://github.com/chapmanb/homebrew-cbl/issues/14
if [ "$(uname)" == "Darwin" ]; then
	sed -i.bak 's/LDFLAGS=-Wl,-s/LDFLAGS=/' contrib/smithwaterman/Makefile
	export LDFLAGS="${LDFLAGS} -Wl,-rpath,${PREFIX}/lib"
	export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_ENABLE_CXX17_REMOVED_FEATURES"
	sed -i.bak 's/-std=c++0x/-std=c++11 -stdlib=libc++/g' contrib/intervaltree/Makefile
fi

pkg-config --list-all

cmake -S . -B build \
	-DZIG=ON -DOPENMP=ON -DWFA_GITMODULE=OFF \
	-DCMAKE_BUILD_TYPE=Release \
	-DBUILD_SHARED_LIBS=ON \
	-DCMAKE_INSTALL_PREFIX="${PREFIX}" \
	-DCMAKE_CXX_COMPILER="${CXX}" \
	-DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
	-DCMAKE_C_COMPILER="${CC}" \
	-DCMAKE_INCLUDE_PATH="${PREFIX}/include" \
	-DCMAKE_LIBRARY_PATH="${PREFIX}/lib"

cmake --build build/ --target install -j 4 -v

#cp -n ../scripts/* $PREFIX/bin
#cp -n -r ../src/simde $PREFIX/include/
