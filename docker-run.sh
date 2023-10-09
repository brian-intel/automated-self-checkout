#!/bin/bash
#
# Copyright (C) 2023 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0
#

#!/bin/bash

VOLUME="-v `pwd`/results:/tmp/results -v `pwd`/configs/opencv-ovms/models/2022:/home/pipeline-server/models -v `pwd`/configs/opencv-ovms/models/2022:/models" 
ENVIRONMENT=""
DEVICE=CPU
INPUTSRC=/dev/video0

while :; do
    case $1 in
    --device)
        if [ "$2" ]; then
            if [ $2 == "CPU" ]; then
                DEVICE=$2
                shift
            elif [ $2 == "MULTI:GPU,CPU" ]; then
                DEVICE=$2
                TARGET_GPU_DEVICE="--privileged"
                shift
            elif grep -q "GPU" <<< "$2"; then			
                DEVICE="GPU"
                arrgpu=(${2//./ })
                TARGET_GPU_NUMBER=${arrgpu[1]}
                if [ -z "$TARGET_GPU_NUMBER" ]; then
                    TARGET_GPU_DEVICE="--privileged"
                else
                    TARGET_GPU_ID=$((128+$TARGET_GPU_NUMBER))
                    TARGET_GPU_DEVICE="--device=/dev/dri/renderD"$TARGET_GPU_ID
                fi
                shift	
            else
                error 'ERROR: "--device" requires an argument CPU|GPU|MULTI'
            fi
        else
                echo 'DEBUG: "--device" no device set using default CPU'
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

# Increment container id count
cid_count="${cid_count:=0}"

# Set RENDER_MODE=1 for demo purposes only
RUN_MODE="-itd"
if [ "$RENDER_MODE" == 1 ]
then
	RUN_MODE="-it -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix"
fi

# Mount the USB if using a usb camera
TARGET_USB_DEVICE=""
if [[ "$INPUTSRC" == *"/dev/vid"* ]]
then
	TARGET_USB_DEVICE="--device=$INPUTSRC"
fi

volFullExpand=$(eval echo "$VOLUMES")
envFullExpand=$(eval echo "$ENVIRONMENT")

# "$TARGET_USB_DEVICE" "$TARGET_GPU_DEVICE"
docker run --network host --user root --ipc=host  --name "$CONTAINER_NAME" -e RENDER_MODE="$RENDER_MODE" "$RUN_MODE" $volFullExpand --env-file "$ENV_FILE" $envFullExpand -e cid_count=$cid_count -e INPUTSRC="$INPUTSRC" -e DEVICE="$DEVICE" "$DOCKER_IMAGE" $COMMAND