# Copyright (c) Facebook, Inc. and its affiliates.
# This file defines a container that compiles the C++ examples of detectron2.
# See docker/README.md for usage.

# Depends on the image produced by "./Dockerfile"
FROM detectron2:v0

USER appuser
ENV HOME=/home/appuser
WORKDIR $HOME

RUN sudo apt-get update && sudo apt-get install libopencv-dev --yes

RUN wget https://download.pytorch.org/libtorch/cu121/libtorch-cxx11-abi-shared-with-deps-2.3.0%2Bcu121.zip && unzip libtorch-cxx11-abi-shared-with-deps-2.3.0+cu121.zip && rm libtorch-cxx11-abi-shared-with-deps-2.3.0+cu121.zip

# install libtorchvision
RUN git clone https://github.com/pytorch/vision/

RUN mkdir vision/build && cd vision/build && \
	cmake .. -DCMAKE_INSTALL_PREFIX=$HOME/.local -DCMAKE_BUILD_TYPE=Release -DWITH_CUDA=on -DTORCH_CUDA_ARCH_LIST=$TORCH_CUDA_ARCH_LIST -DCMAKE_PREFIX_PATH=~/libtorch && \
	make -j && make install

# make our installation take effect
ENV CPATH=$HOME/.local/include \
	  LIBRARY_PATH=$HOME/.local/lib \
	  LD_LIBRARY_PATH=$HOME/.local/lib

# RUN sed -i s/CXX_STANDARD\ 14/CXX_STANDARD\ 17/g  ~/detectron2_repo/tools/deploy/CMakeLists.txt

# build C++ examples of detectron2
RUN cd detectron2_repo/tools/deploy && mkdir build && cd build && \
	 cmake -DTORCH_CUDA_ARCH_LIST=$TORCH_CUDA_ARCH_LIST -DCMAKE_PREFIX_PATH=~/libtorch \
	  -DTorch_DIR=~/.local/lib/python3.8/site-packages/torch .. && make
# binaries will be available under tools/deploy/build

RUN pip install git+https://github.com/facebookresearch/detectron2@main#subdirectory=projects/DensePose
