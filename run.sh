#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#
show_help() {
	echo "
         usage: PIPELINE_PROFILE=\"object_detection\" (or others from make list-profiles) [RENDER_MODE=0 or 1] [LOW_POWER=0 or 1] [CPU_ONLY=0 or 1]
                [DEVICE=\"CPU\" or other device] [MQTT=127.0.0.1:1883 if using MQTT broker] [COLOR_HEIGHT=1080] [COLOR_WIDTH=1920] [COLOR_FRAMERATE=15]
                sudo -E ./run.sh --platform core.x|xeon|dgpu.x --inputsrc RS_SERIAL_NUMBER|CAMERA_RTSP_URL|file:video.mp4|/dev/video0

         Note: 
         1.  dgpu.x should be replaced with targeted GPUs such as dgpu (for all GPUs), dgpu.0, dgpu.1, etc
         2.  core.x should be replaced with targeted GPUs such as core (for all GPUs), core.0, core.1, etc
         3.  filesrc will utilize videos stored in the sample-media folder
         4.  when using device camera like USB, put your correspondent device number for your camera like /dev/video2 or /dev/video4
         5.  Set environment variable STREAM_DENSITY_MODE=1 for starting pipeline stream density testing
         6.  Set environment variable RENDER_MODE=1 for displaying pipeline and overlay CV metadata
         7.  Set environment variable LOW_POWER=1 for using GPU usage only based pipeline for Core platforms
         8.  Set environment variable CPU_ONLY=1 for overriding inference to be performed on CPU only
         9.  Set environment variable PIPELINE_PROFILE=\"object_detection\" to run ovms pipeline profile object detection: values can be listed by \"make list-profiles\"
         10. Set environment variable STREAM_DENSITY_FPS=15.0 for setting stream density target fps value
         11. Set environment variable STREAM_DENSITY_INCREMENTS=1 for setting incrementing number of pipelines for running stream density
         12. Set environment variable DEVICE=\"CPU\" for setting device to use for pipeline run, value can be \"GPU\", \"CPU\", \"AUTO\", \"MULTI:GPU,CPU\"
         13. Set environment variable MQTT=127.0.0.1:1883 for exporting inference metadata to an MQTT broker.
         14. Set environment variable like COLOR_HEIGHT, COLOR_WIDTH, and COLOR_FRAMERATE(in FPS) for inputsrc RealSense camera use cases.
        "
}

# shellcheck source=/dev/null
source benchmark-scripts/get-gpu-info.sh

if [ -z "$PLATFORM" ] || [ -z "$INPUTSRC" ]
then
# shellcheck source=/dev/null
    while :; do
        case $1 in
        -h | -\? | --help)
            show_help
            exit
            ;;
        --platform)
            if [ "$2" ]; then
                if [ $2 == "xeon" ]; then
                    PLATFORM=$2
                    shift
                elif grep -q "core" <<< "$2"; then
                    PLATFORM="core"
                    arrgpu=(${2//./ })
                    TARGET_GPU_NUMBER=${arrgpu[1]}
                    if [ -z "$TARGET_GPU_NUMBER" ]; then
                        TARGET_GPU="GPU.0"
                        # TARGET_GPU_DEVICE="--privileged"
                    else
                        TARGET_GPU_ID=$((128+$TARGET_GPU_NUMBER))
                        TARGET_GPU="GPU."$TARGET_GPU_NUMBER
                        TARGET_GPU_DEVICE="--device=/dev/dri/renderD"$TARGET_GPU_ID
                        TARGET_GPU_DEVICE_NAME="/dev/dri/renderD"$TARGET_GPU_ID
                    fi
                    echo "CORE"
                    shift
                elif grep -q "dgpu" <<< "$2"; then			
                    PLATFORM="dgpu"
                    arrgpu=(${2//./ })
                    TARGET_GPU_NUMBER=${arrgpu[1]}
                    if [ -z "$TARGET_GPU_NUMBER" ]; then
                        TARGET_GPU="GPU.0"
                        # TARGET_GPU_DEVICE="--privileged"
                    else
                        TARGET_GPU_ID=$((128+$TARGET_GPU_NUMBER))
                        TARGET_GPU="GPU."$TARGET_GPU_NUMBER
                        TARGET_GPU_DEVICE="--device=/dev/dri/renderD"$TARGET_GPU_ID
                        TARGET_GPU_DEVICE_NAME="/dev/dri/renderD"$TARGET_GPU_ID
                    fi
                    #echo "$PLATFORM $TARGET_GPU"
                    shift	
                else
                    error 'ERROR: "--platform" requires an argument core|xeon|dgpu.'
                fi
            else
                    error 'ERROR: "--platform" requires an argument core|xeon|dgpu.'
            fi	    
            ;;
        --inputsrc)
            if [ "$2" ]; then
                INPUTSRC=$2
                shift
            else
                error 'ERROR: "--inputsrc" requires an argument RS_SERIAL_NUMBER|CAMERA_RTSP_URL|file:video.mp4|/dev/video0.'
            fi
            ;;
        -?*)
            error "ERROR: Unknown option $1"
            ;;
        ?*)
            error "ERROR: Unknown option $1"
            ;;
        *)
            break
            ;;
        esac

        shift

    done

    if [ -z $PLATFORM ] || [ -z $INPUTSRC ]
    then
        #echo "Blanks: $1 $PLATFORM $INPUTSRC"
        show_help
        exit 0
    fi

    echo "Device:"
    echo $TARGET_GPU_DEVICE
fi

echo "running pipeline profile: $PIPELINE_PROFILE"

SERVER_CONTAINER_NAME="ovms-server"
# clean up exited containers
exitedOvmsContainers=$(docker ps -a -f name="$SERVER_CONTAINER_NAME" -f status=exited -q)
if [ -n "$exitedOvmsContainers" ]
then
	docker rm "$exitedOvmsContainers"
fi

export GST_DEBUG=0

cl_cache_dir=$(pwd)/.cl-cache
echo "CLCACHE: $cl_cache_dir"


if [ "$HAS_FLEX_140" == 1 ] || [ "$HAS_FLEX_170" == 1 ] || [ "$HAS_ARC" == 1 ] 
then
    echo "OCR device defaulting to dGPU"
    OCR_DEVICE=GPU
fi

gstDockerImages="dlstreamer:dev"
re='^[0-9]+$'
if grep -q "video" <<< "$INPUTSRC"; then
	echo "assume video device..."
	# v4l2src /dev/video*
	# TODO need to pass stream info
	TARGET_USB_DEVICE="--device=$INPUTSRC"
elif [[ "$INPUTSRC" =~ $re ]]; then
	echo "assume realsense device..."
	cameras=$(find /dev/vid* | while read -r line; do echo "--device=$line"; done)
	# replace \n with white space as the above output contains \n
	cameras=("$(echo "$cameras" | tr '\n' ' ')")
	TARGET_GPU_DEVICE=$TARGET_GPU_DEVICE" ""${cameras[*]}"
	gstDockerImages="dlstreamer:realsense"
else
	echo "$INPUTSRC"
fi

if [ "$PIPELINE_PROFILE" == "gst" ]
then
	# modify gst profile DockerImage accordingly based on the inputsrc is RealSense camera or not

	docker run --rm -v "${PWD}":/workdir mikefarah/yq -i e '.OvmsClient.DockerLauncher.DockerImage |= "'"$gstDockerImages"'"' \
		/workdir/configs/opencv-ovms/cmd_client/res/gst/configuration.yaml
fi

#pipeline script is configured from configuration.yaml in opencv-ovms/cmd_client/res folder

# Set RENDER_MODE=1 for demo purposes only
if [ "$RENDER_MODE" == 1 ]
then
	xhost +local:docker
fi

#echo "DEBUG: $TARGET_GPU_DEVICE $PLATFORM $HAS_FLEX_140"
if [ "$PLATFORM" == "dgpu" ] && [ "$HAS_FLEX_140" == 1 ]
then
	if [ "$STREAM_DENSITY_MODE" == 1 ]; then
		AUTO_SCALE_FLEX_140=2
	else
		# allow workload to manage autoscaling
		AUTO_SCALE_FLEX_140=1
	fi
fi

# make sure models are downloaded or existing:
./download_models/getModels.sh

# make sure sample image is downloaded or existing:
./configs/opencv-ovms/scripts/image_download.sh

# devices supported CPU, GPU, GPU.x, AUTO, MULTI:GPU,CPU
DEVICE="${DEVICE:="CPU"}"

# PIPELINE_PROFILE is the environment variable to choose which type of pipelines to run with
# eg. grpc_python, grpc_cgo_binding, ... etc
# one example to run with this pipeline profile on the command line is like:
# PIPELINE_PROFILE="grpc_python" sudo -E ./run.sh --platform core --inputsrc rtsp://127.0.0.1:8554/camera_0
PIPELINE_PROFILE="${PIPELINE_PROFILE:=grpc_python}"
echo "starting profile-launcher with pipeline profile: $PIPELINE_PROFILE ..."
current_time=$(date "+%Y.%m.%d-%H.%M.%S")
cameras="${cameras[*]}" \
TARGET_USB_DEVICE="$TARGET_USB_DEVICE" \
TARGET_GPU_DEVICE="$TARGET_GPU_DEVICE" \
DEVICE="$DEVICE" \
MQTT="$MQTT" \
RENDER_MODE=$RENDER_MODE \
DISPLAY=$DISPLAY \
cl_cache_dir=$cl_cache_dir \
RUN_PATH=$(pwd) \
PLATFORM=$PLATFORM \
BARCODE_RECLASSIFY_INTERVAL=$BARCODE_INTERVAL \
OCR_RECLASSIFY_INTERVAL=$OCR_INTERVAL \
OCR_DEVICE=$OCR_DEVICE \
LOG_LEVEL=$LOG_LEVEL \
LOW_POWER="$LOW_POWER" \
STREAM_DENSITY_MODE=$STREAM_DENSITY_MODE \
INPUTSRC="$INPUTSRC" \
STREAM_DENSITY_FPS=$STREAM_DENSITY_FPS \
STREAM_DENSITY_INCREMENTS=$STREAM_DENSITY_INCREMENTS \
COMPLETE_INIT_DURATION=$COMPLETE_INIT_DURATION \
CPU_ONLY="$CPU_ONLY" \
PIPELINE_PROFILE="$PIPELINE_PROFILE" \
AUTO_SCALE_FLEX_140="$AUTO_SCALE_FLEX_140" \
./profile-launcher -configDir "$(dirname "$(readlink ./profile-launcher)")" > ./results/profile-launcher."$current_time".log 2>&1 &
