#!/bin/bash
#
# Copyright (C) 2024 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

if [ ! -f coca-cola-4465029-1920-15-bench.mp4 ]; then
   wget -O coca-cola-4465029-1920-15-bench.mp4 https://www.pexels.com/download/video/4465029
fi

if [ ! -f barcode-1920-15-bench.mp4 ]; then
   wget -O barcode-1920-15-bench.mp4 https://github.com/antoniomtz/sample-clips/raw/main/barcode.mp4
fi

if [ ! -f vehicle-bike-1920-15-bench.mp4 ]; then
   wget -O vehicle-bike-1920-15-bench.mp4 https://www.pexels.com/download/video/853908
fi