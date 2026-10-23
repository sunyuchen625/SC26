# CMake generated Testfile for 
# Source directory: /data/home/sunyc/solverchallenge26/gpu-preparation-20261023/cpu-build-9270818/src
# Build directory: /data/home/sunyc/solverchallenge26/gpu-preparation-20261023/cpu-build-9270818/build
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
add_test([=[header_include_order_mpi_first]=] "/data/public/software/openmpi/4.18-gcc11.3/bin/mpicc" "-I/data/home/sunyc/solverchallenge26/gpu-preparation-20261023/cpu-build-9270818/src/include" "-I/data/home/sunyc/solverchallenge26/gpu-preparation-20261023/cpu-build-9270818/src" "-std=gnu99" "-Werror" "-Wno-unused-function" "-fsyntax-only" "/data/home/sunyc/solverchallenge26/gpu-preparation-20261023/cpu-build-9270818/src/tests/header_include_order_mpi_first.c")
set_tests_properties([=[header_include_order_mpi_first]=] PROPERTIES  _BACKTRACE_TRIPLES "/data/home/sunyc/solverchallenge26/gpu-preparation-20261023/cpu-build-9270818/src/CMakeLists.txt;166;add_test;/data/home/sunyc/solverchallenge26/gpu-preparation-20261023/cpu-build-9270818/src/CMakeLists.txt;0;")
add_test([=[header_include_order_reader_first]=] "/data/public/software/openmpi/4.18-gcc11.3/bin/mpicc" "-I/data/home/sunyc/solverchallenge26/gpu-preparation-20261023/cpu-build-9270818/src/include" "-I/data/home/sunyc/solverchallenge26/gpu-preparation-20261023/cpu-build-9270818/src" "-std=gnu99" "-Werror" "-Wno-unused-function" "-fsyntax-only" "/data/home/sunyc/solverchallenge26/gpu-preparation-20261023/cpu-build-9270818/src/tests/header_include_order_reader_first.c")
set_tests_properties([=[header_include_order_reader_first]=] PROPERTIES  _BACKTRACE_TRIPLES "/data/home/sunyc/solverchallenge26/gpu-preparation-20261023/cpu-build-9270818/src/CMakeLists.txt;172;add_test;/data/home/sunyc/solverchallenge26/gpu-preparation-20261023/cpu-build-9270818/src/CMakeLists.txt;0;")
subdirs("selected_problem")
