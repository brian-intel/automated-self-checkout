#
# Copyright (c) 2023 Intel Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

import sys
sys.path.append("/model_server/demos/common/python")

import cv2
import os
import ast
import grpc
import numpy as np
import classes
import datetime
import argparse
from client_utils import print_statistics
from tritonclient.grpc import service_pb2, service_pb2_grpc
from tritonclient.utils import *

DataTypeToContentsFieldName = {
    'BOOL' : 'bool_contents',
    'BYTES' : 'bytes_contents',
    'FP32' : 'fp32_contents',
    'FP64' : 'fp64_contents',
    'INT64' : 'int64_contents',
    'INT32' : 'int_contents',
    'UINT64' : 'uint64_contents',
    'UINT32' : 'uint_contents',
    'INT64' : 'int64_contents',
    'INT32' : 'int_contents',
}

# Binary alternative format...
def prepare_input_in_nchw_format(img):
    # img = cv2.imread(path).astype(np.float32)  # BGR color format, shape HWC
    width = 608
    height = 608
    img = cv2.resize(img, (width, height))
    # img = img.transpose(2,0,1).reshape(1,3,height,width)
    # img = img.astype('float32')
    return img
    #return {name: img}

def as_numpy(response, name):
    index = 0
    for output in response.outputs:
        if output.name == name:
            shape = []
            for value in output.shape:
                shape.append(value)
            datatype = output.datatype
            field_name = DataTypeToContentsFieldName[datatype]
            contents = getattr(output, "contents")
            contents = getattr(contents, f"{field_name}")
            if index < len(response.raw_output_contents):
                np_array = np.frombuffer(
                    response.raw_output_contents[index], dtype=triton_to_np_dtype(output.datatype))
            elif len(contents) != 0:
                np_array = np.array(contents,
                                    copy=False)
            else:
                np_array = np.empty(0)
            np_array = np_array.reshape(shape)
            return np_array
        else:
            index += 1
    return None

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Sends requests via KServe gRPC API using images in format supported by OpenCV. '
                                                 'It displays performance statistics and optionally the model accuracy')
    parser.add_argument('--images_list', required=False, default='input_images.txt', help='path to a file with a list of labeled images')
    parser.add_argument('--labels_numpy_path', required=False, help='numpy in shape [n,1] - can be used to check model accuracy')
    parser.add_argument('--grpc_address',required=False, default='localhost',  help='Specify url to grpc service. default:localhost')
    parser.add_argument('--grpc_port',required=False, default=9000, help='Specify port to grpc service. default: 9000')
    parser.add_argument('--input_name',required=False, default='input', help='Specify input tensor name. default: input')
    parser.add_argument('--output_name',required=False, default='resnet_v1_50/predictions/Reshape_1',
                        help='Specify output name. default: resnet_v1_50/predictions/Reshape_1')
    parser.add_argument('--batchsize', default=1,
                        help='Number of images in a single request. default: 1',
                        dest='batchsize')
    parser.add_argument('--model_name', default='resnet', help='Define model name, must be same as is in service. default: resnet',
                        dest='model_name')
    parser.add_argument('--pipeline_name', default='', help='Define pipeline name, must be same as is in service',
                        dest='pipeline_name')

    args = vars(parser.parse_args())

    address = "{}:{}".format(args['grpc_address'],args['grpc_port'])

    processing_times = np.zeros((0),int)

    input_images = args.get('images_list')
    with open(input_images) as f:
        lines = f.readlines()
    batch_size = int(args.get('batchsize'))
    while batch_size > len(lines):
        lines += lines

    if args.get('labels_numpy_path') is not None:
        lbs = np.load(args['labels_numpy_path'], mmap_mode='r', allow_pickle=False)
        matched_count = 0
        total_executed = 0
    batch_size = int(args.get('batchsize'))

    print('Start processing:')
    print('\tModel name: {}'.format(args.get('pipeline_name') if bool(args.get('pipeline_name')) else args.get('model_name')))

    iteration = 0
    is_pipeline_request = bool(args.get('pipeline_name'))

    # Create gRPC stub for communicating with the server
    channel = grpc.insecure_channel(address)
    grpc_stub = service_pb2_grpc.GRPCInferenceServiceStub(channel)

    # OpenCV RTSP Stream
    RTSP_URL = 'rtsp://192.168.0.246:8554/camera_0'
    cap = cv2.VideoCapture(RTSP_URL)

    if not cap.isOpened():
        print('Cannot open RTSP stream')
        exit(-1)

    # batch_i = 0
    # image_data = []
    # labels = []
    # for line in lines:
        # batch_i += 1
        # path, label = line.strip().split(" ")
        # with open(path, 'rb') as f:
        #     image_data.append(f.read())
        # labels.append(label)
        # if batch_i < batch_size:
        #     continue
    while True:
        # get frame from OpenCV
        _, frame = cap.read()
        img = prepare_input_in_nchw_format(frame)

        # cv2.imwrite("frame.jpg" , frame)     # save frame as JPEG file
        # with open("frame.jpg", 'rb') as f:
        #     capimage = f.read()
        img_str = cv2.imencode('.jpg', img)[1].tostring()

        # print("\nRequest shape", img.shape)
        # batch_input_bytes = []
        # request.inputs.append(single_input_request)
        # imgdata = img.tobytes()
        # batch_input_bytes.append(imgdata)
        # request.raw_input_contents.extend(batch_input_bytes)

        inputs = []
        inputs.append(service_pb2.ModelInferRequest().InferInputTensor())
        inputs[0].name = args['input_name']
        inputs[0].datatype = "BYTES"
        inputs[0].shape.extend([1])
        inputs[0].contents.bytes_contents.append(img_str)

        outputs = []
        outputs.append(service_pb2.ModelInferRequest().InferRequestedOutputTensor())
        outputs[0].name = "mask"

        request = service_pb2.ModelInferRequest()
        request.model_name = args.get('pipeline_name') if is_pipeline_request else args.get('model_name')
        request.inputs.extend(inputs)

        start_time = datetime.datetime.now()
        request.outputs.extend(outputs)
        response = grpc_stub.ModelInfer(request)
        end_time = datetime.datetime.now()

        duration = (end_time - start_time).total_seconds() * 1000
        processing_times = np.append(processing_times,np.array([int(duration)]))

        # omz instance segmentation model has three outputs
        output1 = as_numpy(response, "3523")
        output2 = as_numpy(response, "3524")
        output3 = as_numpy(response, "masks")

        nu = np.array(output1)
        nu2 = np.array(output2)
        nu3 = np.array(output3)

        # for object classification models show imagenet class
        print('Iteration {}; Processing time: {:.2f} ms; speed {:.2f} fps'.format(iteration,round(np.average(duration), 2),
                                                                                    round(1000 * batch_size / np.average(duration), 2)
                                                                                    ))
        iteration += 1
        image_data = []
        labels = []
        batch_i = 0

    print_statistics(processing_times, batch_size)

    if args.get('labels_numpy_path') is not None:
        print('Classification accuracy: {:.2f}'.format(100*matched_count/total_executed))

