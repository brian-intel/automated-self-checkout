"""
INTEL CONFIDENTIAL

Copyright (C) 2022 Intel Corporation

This software and the related documents are Intel copyrighted materials, and your use of them is governed by the express
license under which they were provided to you ("License"). Unless the License provides otherwise, you may not use, modify,
copy, publish, distribute, disclose or transmit this software or the related documents without Intel's prior written permission.

This software and the related documents are provided as is, with no express or implied warranties, other than those that are expressly stated in the License.
"""
class ObjectRemovalByLabel:
    def __init__(self,
                 object_filter=["dining table", "chair", "person", "bed", "sink"]):
        self._object_filter = object_filter

    def process_frame(self, frame):
        if not self._object_filter:
            return True
        regions = list(frame.regions())
        removable_regions = [region for region in regions if region.label() in self._object_filter]

        orig_regions=list(frame.regions())
        removable_region_ids = [region.region_id() for region in removable_regions]
        for region in orig_regions:
            if region.region_id() in removable_region_ids:
                frame.remove_region(region)

        return True
