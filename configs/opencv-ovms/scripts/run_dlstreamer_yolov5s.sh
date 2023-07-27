#!/bin/bash

GRPC_PORT="${GRPC_PORT:=9000}"

echo "running grpc_go with GRPC_PORT=$GRPC_PORT"

# /scripts is mounted during the docker run 

rmDocker=--rm
if [ ! -z "$DEBUG" ]
then
	# when there is non-empty DEBUG env, the output of app outputs to the console for easily debugging
	rmDocker=""
fi

echo $rmDocker
docker run --network host $cameras $TARGET_USB_DEVICE $TARGET_GPU_DEVICE --user root --ipc=host --name automated-self-checkout$cid_count -e RENDER_MODE=$RENDER_MODE -e cl_cache_dir=/home/pipeline-server/.cl-cache -v $cl_cache_dir:/home/pipeline-server/.cl-cache -v /tmp/.X11-unix:/tmp/.X11-unix -v $RUN_PATH/sample-media/:/home/pipeline-server/vids -v $RUN_PATH/configs/dlstreamer/pipelines:/home/pipeline-server/pipelines -v $RUN_PATH/configs/dlstreamer/extensions:/home/pipeline-server/extensions -v $RUN_PATH/results:/tmp/results -v $RUN_PATH/configs/dlstreamer/models/2022:/home/pipeline-server/models -v $RUN_PATH/configs/dlstreamer/framework-pipelines:/home/pipeline-server/framework-pipelines -w /home/pipeline-server -e LOG_LEVEL=$LOG_LEVEL -e GST_DEBUG=$GST_DEBUG -e pre_process="$pre_process" -e LOW_POWER="$LOW_POWER" -e cid_count=$cid_count -e inputsrc="$inputsrc" $RUN_MODE -e AUTO_SCALE_FLEX_140="$AUTO_SCALE_FLEX_140" $TAG bash -c "bash /home/pipeline-server/framework-pipelines/yolov5_pipeline/yolov5s.sh"