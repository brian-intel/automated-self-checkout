#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

FROM intel/dlstreamer:2022.3.0-ubuntu22-gpu555

USER root 

# RUN if [ -n "$HTTP_PROXY" ] ; then  echo "Acquire::http::Proxy \"$HTTP_PROXY\";" >  /etc/apt/apt.conf; fi
# RUN apt-get update -y || true; DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
#     build-essential \
#     autoconf \
#     git \
#     libssl-dev \
#     libusb-1.0-0-dev \
#     libudev-dev \
#     pkg-config \
#     libgtk-3-dev \
#     libglfw3-dev \
#     libgl1-mesa-dev \
#     libglu1-mesa-dev \
#     nasm \
#     ninja-build \
#     cmake  \
#     python3  \
#     python3-pip  \
#     meson \
#     flex \
#     bison && \
#     apt-get clean && \
#     rm -rf /var/lib/apt/lists/*

# # Upgrade meson as the gstreamer needs later version
# RUN  echo "upgrading meson to the latest version..." && pip3 install --user meson --upgrade

# # Install realsense
# RUN mkdir -p /rs
# WORKDIR /rs
# RUN git clone https://github.com/gwen2018/librealsense.git
# WORKDIR /rs/librealsense
# RUN  git checkout stream_d436_b
# COPY ./patch/libusb.h /rs/librealsense/src/libusb/libusb.h
#      #./scripts/setup_udev_rules.sh && \
# RUN mkdir build
# WORKDIR /rs/librealsense/build
# SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# RUN cmake ../ \
#         -DBUILD_SHARED_LIBS=true \
#         -DBUILD_WITH_JPEGTURBO=true \
#         -DBUILD_PYTHON_BINDINGS:bool=true \
#         -DBUILD_WITH_CUDA=false \
#         -DFORCE_RSUSB_BACKEND=false \
#         -DPYTHON_EXECUTABLE=/usr/bin/python3 \
#         -DBUILD_GLSL_EXTENSIONS=false \
#         -DBUILD_WITH_CPU_EXTENSIONS=true \
#         -DBUILD_UNIT_TESTS=false \
# 	-DBUILD_GRAPHICAL_EXAMPLES=false \
# 	-DCMAKE_BUILD_TYPE=Release && \
#     make -j"$(cat < /proc/cpuinfo |grep -c proc)" && \
#     make install && \
#     export PYTHONPATH="$PYTHONPATH":/usr/lib/python3/dist-packages/pyrealsense2 && \
#     python3 -c "import pyrealsense2 as rs; print(rs)"
# RUN mv /rs/librealsense/build/libjpeg-turbo/lib/libturbojpeg.so* /usr/local/lib
# # # Build gst realsense element. Use github version once pull request is accepted with bug fixes
# WORKDIR /rs
# RUN git clone https://github.com/brian-intel/realsense-gstreamer
# WORKDIR /rs/realsense-gstreamer
# RUN /usr/bin/meson setup build && ninja -C build && /usr/bin/meson . build && ninja -C build && \
#     cp /rs/realsense-gstreamer/build/src/libgstrealsense_meta.so /opt/intel/dlstreamer/gstreamer/lib/ && \
#     cp /rs/realsense-gstreamer/build/src/libgstrealsensesrc.so /opt/intel/dlstreamer/gstreamer/lib/gstreamer-1.0 && \
#     cp /usr/local/lib/libturbojpeg.so* /opt/intel/dlstreamer/gstreamer/lib/
# #RUN gst-inspect-1.0 realsensesrc

COPY ./requirements.txt /requirements.txt
RUN pip3 install --upgrade pip --no-cache-dir -r /requirements.txt

COPY /configs/dlstreamer/extensions /home/pipeline-server/extensions
COPY /configs/dlstreamer/framework-pipelines /home/pipeline-server/framework-pipelines

WORKDIR /home/pipeline-server
ENTRYPOINT [ "bash", "-c", "$GST_PIPELINE_LAUNCH" ]