# Generated by vinca http://github.com/RoboStack/vinca.
# DO NOT EDIT!

set -eo pipefail

rm -rf build
mkdir build
cd build

# necessary for correctly linking SIP files (from python_qt_bindings)
export LINK=$CXX

if [[ "$CONDA_BUILD_CROSS_COMPILATION" != "1" ]]; then
  PYTHON_EXECUTABLE=$PREFIX/bin/python
  PKG_CONFIG_EXECUTABLE=$PREFIX/bin/pkg-config
  OSX_DEPLOYMENT_TARGET="10.15"
else
  PYTHON_EXECUTABLE=$BUILD_PREFIX/bin/python
  PKG_CONFIG_EXECUTABLE=$BUILD_PREFIX/bin/pkg-config
  OSX_DEPLOYMENT_TARGET="11.0"
fi

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" == "1" ]]; then
  export QT_HOST_PATH="$BUILD_PREFIX"
else
  export QT_HOST_PATH="$PREFIX"
fi

echo "USING PYTHON_EXECUTABLE=${PYTHON_EXECUTABLE}"
echo "USING PKG_CONFIG_EXECUTABLE=${PKG_CONFIG_EXECUTABLE}"

export ROS_PYTHON_VERSION=`$PYTHON_EXECUTABLE -c "import sys; print('%i.%i' % (sys.version_info[0:2]))"`
echo "Using Python ${ROS_PYTHON_VERSION}"

# see https://github.com/conda-forge/cross-python-feedstock/issues/24
if [[ "$CONDA_BUILD_CROSS_COMPILATION" == "1" ]]; then
  find $PREFIX/lib/cmake -type f -exec sed -i "s~\${_IMPORT_PREFIX}/lib/python${ROS_PYTHON_VERSION}/site-packages~${BUILD_PREFIX}/lib/python${ROS_PYTHON_VERSION}/site-packages~g" {} + || true
  find $PREFIX/share/rosidl* -type f -exec sed -i "s~${PREFIX}/lib/python${ROS_PYTHON_VERSION}/site-packages~${BUILD_PREFIX}/lib/python${ROS_PYTHON_VERSION}/site-packages~g" {} + || true
  find $PREFIX/share/rosidl* -type f -exec sed -i "s~\${_IMPORT_PREFIX}/lib/python${ROS_PYTHON_VERSION}/site-packages~${BUILD_PREFIX}/lib/python${ROS_PYTHON_VERSION}/site-packages~g" {} + || true
  find $PREFIX/lib/cmake -type f -exec sed -i "s~message(FATAL_ERROR \"The imported target~message(WARNING \"The imported target~g" {} + || true
fi

if [[ $target_platform =~ linux.* ]]; then
    export CFLAGS="${CFLAGS} -D__STDC_FORMAT_MACROS=1"
    export CXXFLAGS="${CXXFLAGS} -D__STDC_FORMAT_MACROS=1"
fi;

# Needed for qt-gui-cpp ..
if [[ $target_platform =~ linux.* ]]; then
  ln -s $GCC ${BUILD_PREFIX}/bin/gcc
  ln -s $GXX ${BUILD_PREFIX}/bin/g++
fi;

# PYTHON_INSTALL_DIR should be a relative path, see
# https://github.com/ament/ament_cmake/blob/2.3.2/ament_cmake_python/README.md
# So we compute the relative path of $SP_DIR w.r.t. to $PREFIX,
# but it is not trivial to do this in bash scripting, so let's do it via python
export PYTHON_INSTALL_DIR=`python -c "import os;print(os.path.relpath(os.environ['SP_DIR'],os.environ['PREFIX']))"`
echo "Using PYTHON_INSTALL_DIR: $PYTHON_INSTALL_DIR"

if [[ $target_platform =~ emscripten.* ]]; then
  export CONDA_BUILD_CROSS_COMPILATION="1"
  PYTHON_EXECUTABLE=$BUILD_PREFIX/bin/python$PY_VER
  echo "set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS TRUE)"> $SRC_DIR/__vinca_shared_lib_patch.cmake
  echo "set(CMAKE_STRIP FALSE)  # used by default in pybind11 on .so modules">> $SRC_DIR/__vinca_shared_lib_patch.cmake
  echo "set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)  # fixes an error where numpy header files are not found correctly">> $SRC_DIR/__vinca_shared_lib_patch.cmake

  if [ "${PKG_NAME}" == "ros-humble-examples-rclcpp-minimal-publisher" ] || [ "${PKG_NAME}" == "ros-humble-examples-rclcpp-minimal-subscriber" ] || [ "${PKG_NAME}" == "ros-humble-rclcpp-components" ]; then
    echo "set(CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS \"-s ASSERTIONS=1 -s SIDE_MODULE=1 -sWASM_BIGINT -s USE_PTHREADS=0 -s DEMANGLE_SUPPORT=1 -s ALLOW_MEMORY_GROWTH=1 -sASYNCIFY -O3 -s ASYNCIFY_STACK_SIZE=24576 \")">> $SRC_DIR/__vinca_shared_lib_patch.cmake
    echo "set(CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS \"-s ASSERTIONS=1 -s SIDE_MODULE=1 -sWASM_BIGINT -s USE_PTHREADS=0 -s DEMANGLE_SUPPORT=1 -s ALLOW_MEMORY_GROWTH=1 -sASYNCIFY -O3 -s ASYNCIFY_STACK_SIZE=24576 \")">> $SRC_DIR/__vinca_shared_lib_patch.cmake
    echo "set(CMAKE_EXE_LINKER_FLAGS \"-sMAIN_MODULE=1 -sASSERTIONS=1 -fexceptions -lembind -sWASM_BIGINT -s USE_PTHREADS=0 -s DEMANGLE_SUPPORT=1 -sALLOW_MEMORY_GROWTH=1 -sASYNCIFY -O3 -s ASYNCIFY_STACK_SIZE=24576 -L$SRC_DIR/build -L$PREFIX/lib\")  # remove SIDE_MODULE from exe linker flags">> $SRC_DIR/__vinca_shared_lib_patch.cmake
  else
    echo "set(CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS \"-s ASSERTIONS=1 -s SIDE_MODULE=1 -sWASM_BIGINT -s USE_PTHREADS=0 -s DEMANGLE_SUPPORT=1 -s ALLOW_MEMORY_GROWTH=1 -sSTACK_SIZE=655360 \")">> $SRC_DIR/__vinca_shared_lib_patch.cmake
    echo "set(CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS \"-s ASSERTIONS=1 -s SIDE_MODULE=1 -sWASM_BIGINT -s USE_PTHREADS=0 -s DEMANGLE_SUPPORT=1 -s ALLOW_MEMORY_GROWTH=1 -sSTACK_SIZE=655360 \")">> $SRC_DIR/__vinca_shared_lib_patch.cmake
    echo "set(CMAKE_EXE_LINKER_FLAGS \"-sMAIN_MODULE=1 -sASSERTIONS=1 -fexceptions -lembind -sWASM_BIGINT -s USE_PTHREADS=0 -s DEMANGLE_SUPPORT=1 -sALLOW_MEMORY_GROWTH=1 -sSTACK_SIZE=655360 -L$SRC_DIR/build -L$PREFIX/lib\")  # remove SIDE_MODULE from exe linker flags">> $SRC_DIR/__vinca_shared_lib_patch.cmake
  fi

  # export USE_WASM=ON
  # -DTHREADS_PREFER_PTHREAD_FLAG=TRUE\
  export BUILD_TYPE="Release"
  export EXTRA_CMAKE_ARGS=" \
      -DPYTHON_SOABI="cpython-${ROS_PYTHON_VERSION//./}-wasm32-emscripten" \
      -DRMW_IMPLEMENTATION=rmw_wasm_cpp \
      -DCMAKE_FIND_ROOT_PATH=$PREFIX    \
      -DCMAKE_POSITION_INDEPENDENT_CODE=TRUE \
      -DCMAKE_PROJECT_INCLUDE=$SRC_DIR/__vinca_shared_lib_patch.cmake \
  "

    unset -f cmake
    export CMAKE_GEN="emcmake cmake"
    export CMAKE_BLD="cmake"
else
    export BUILD_TYPE="Release"
    export CMAKE_GEN="cmake"
    export CMAKE_BLD="cmake"
fi;

$CMAKE_GEN \
    -G "Ninja" \
    -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -DAMENT_PREFIX_PATH=$PREFIX \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DPYTHON_EXECUTABLE=$PYTHON_EXECUTABLE \
    -DPython_EXECUTABLE=$PYTHON_EXECUTABLE \
    -DPython3_EXECUTABLE=$PYTHON_EXECUTABLE \
    -DPython3_FIND_STRATEGY=LOCATION \
    -DPKG_CONFIG_EXECUTABLE=$PKG_CONFIG_EXECUTABLE \
    -DPYTHON_INSTALL_DIR=$PYTHON_INSTALL_DIR \
    -DSETUPTOOLS_DEB_LAYOUT=OFF \
    -DCATKIN_SKIP_TESTING=$SKIP_TESTING \
    -DCMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP=True \
    -DBUILD_SHARED_LIBS=ON  \
    -DBUILD_TESTING=OFF \
    -DCMAKE_IGNORE_PREFIX_PATH="/opt/homebrew;/usr/local/homebrew" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=$OSX_DEPLOYMENT_TARGET \
    --compile-no-warning-as-error \
    $EXTRA_CMAKE_ARGS \
    $SRC_DIR/$PKG_NAME/src/work/wasm_cpp

$CMAKE_BLD --build . --config $BUILD_TYPE --target install
