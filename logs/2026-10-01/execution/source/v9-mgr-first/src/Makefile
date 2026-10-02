.PHONY: all configure build test clean

BUILD_DIR ?= build
CMAKE ?= cmake
SC26_PROBLEM ?= 01
SC26_BUILD_MPI_GPU ?= OFF

all: build

configure:
	$(CMAKE) -S . -B $(BUILD_DIR) -DSC26_BUILD_MPI=ON -DSC26_BUILD_MPI_GPU=$(SC26_BUILD_MPI_GPU) -DSC26_ENABLE_FLOAT128=ON -DSC26_PROBLEM=$(SC26_PROBLEM)

build: configure
	$(CMAKE) --build $(BUILD_DIR) --parallel

test: build
	$(CMAKE) --build $(BUILD_DIR) --target test

clean:
	$(CMAKE) --build $(BUILD_DIR) --target clean
