"""
INTEL CONFIDENTIAL

Copyright (C) 2022 Intel Corporation

This software and the related documents are Intel copyrighted materials, and your use of them is governed by the express
license under which they were provided to you ("License"). Unless the License provides otherwise, you may not use, modify,
copy, publish, distribute, disclose or transmit this software or the related documents without Intel's prior written permission.

This software and the related documents are provided as is, with no express or implied warranties, other than those that are expressly stated in the License.
"""
class ObjectFilter:
    def __init__(self,
                 enable=False,
                 max_objects=None,
                 min_objects=None,
                 fake_object_width=1,
                 fake_object_height=1):
        self.enable = enable
        self._min_objects = min_objects
        self._max_objects = max_objects
        self._fake_object_width = fake_object_width
        self._fake_object_height = fake_object_height

    def process_frame(self, frame):
        if not self.enable:
            return True
        regions = list(frame.regions())
        if self._min_objects and len(regions) < self._min_objects:
            for _ in range(len(regions), self._min_objects):
                regions.append(frame.add_region(0, 0, self._fake_object_width, self._fake_object_height, "fake", 1.0, True))

        if self._max_objects and len(regions) > self._max_objects:
            regions = regions[0:self._max_objects]

        return True