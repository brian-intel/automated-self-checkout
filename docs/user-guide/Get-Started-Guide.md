# Get Started Guide


-   **Time to Complete:** <placeholder>
-   **Programming Language:** <placeholder>

## Get Started

NOTE: Provide step-by-step instructions for getting started. Developers
expect the process to be straightforward. Provide scripts and automation
to simplify steps.

### Prerequisites for Target System

- Intel® Core™ processor.
- At least 16 GB RAM. 
- At least 64 GB hard drive. 
- An Internet connection. 
- Ubuntu* LTS Boot Device.
- Docker*.
- Docker Compose v2(Optional).
- Git*.

### Step 1: Install prerequisites

Do the following to install the prerequisites:

1. Install [Ubuntu](https://ubuntu.com/tutorials/install-ubuntu-desktop/).
2. Install [Docker](https://docs.docker.com/engine/install/ubuntu/).
3. Install [Docker Compose v2](https://docs.docker.com/compose/install/). 
4. Complete the optional post-installation steps to [manage Docker as a non-root user](https://docs.docker.com/engine/install/linux-postinstall/).

### Step 2: Install <package name> package software

Do the following to install the software package:

1. Select <Configure & Download> to download the reference implementation package. 

2. Open a new terminal and navigate to the download folder to unzip the <package name> package:

    ``` bash
    unzip <package_name>.zip
    ```

3. Navigate to the *<package_name>*/ directory:
   
    ``` bash
    cd <package_name>/
    ```

4. Change permission of the executable edgesoftware file:
   
    ``` bash
    chmod 755 edgesoftware
    ```  

5. Install the package:

    ``` bash
    ./edgesoftware install
    ``` 

6. During the installation, you will be prompted for the Product Key. The Product Key is in the email you received from Intel confirming your download.

<!-- image to be added-->

6. When the installation is complete, you see the message “Installation of package complete” and the installation status for each module.

<!-- image to be added-->


### Step 3: Verify installation

Do the following to verify if the installation is successful.

1. Run the demo:

    ``` bash
    make run-pipeline-server
    ``` 
If the package is installed correctly, the object detection demo will run.


## Test the Microservice {or Name of a First Use Experience}

<!--A short tutorial with clear objectives: Provide the developer with a
concrete example of how the software works and its value proposition.-->

The Automated Self-Checkout Reference Implementation provides critical components required to build and deploy a self-checkout use case using Intel® hardware, software, and other open source software. The following steps will show how to run the pre-configured automated self-checkout pipelines and extract data from them.

1.  Validate whether the docker containers are running:

    ``` bash
    docker ps --format 'table{{.Names}}\t{{.Image}}\t{{.Status}}'
    ```

    The result should be like:

    ```
    | NAMES              | IMAGE                         | STATUS            |
    |--------------------|-------------------------------|-------------------|
    | camera-simulator0  | jrottenberg/ffmpeg:4.1-alpine | Up About a minute |
    | evam_2             | bmcginn/cv-workshop:2         | Up About a minute |
    | evam_0             | bmcginn/cv-workshop:2         | Up About a minute |
    | evam_1             | bmcginn/cv-workshop:2         | Up About a minute |
    | mqtt-broker        | eclipse-mosquitto:2.0.18      | Up About a minute |
    | camera-simulator   | aler9/rtsp-simple-server      | Up About a minute |
    ```


2.  Check the MQTT inference output:

    ``` bash
    mosquitto_sub -v -h localhost -p 1883 -t 'AnalyticsData0'
    mosquitto_sub -v -h localhost -p 1883 -t 'AnalyticsData1'
    mosquitto_sub -v -h localhost -p 1883 -t 'AnalyticsData2'
    ```
    The result for each sub-command be like:

    ```
    AnalyticsData0 {"objects":[{"detection":{"bounding_box":{"x_max":0.3163176067521043,"x_min":0.20249048400491532,"y_max":0.7995593662281202,"y_min":0.12237883070032396},"confidence":0.868196964263916,"label":"bottle","label_id":39},"h":731,"region_id":6199,"roi_type":"bottle","w":219,"x":389,"y":132},{"detection":{"bounding_box":{"x_max":0.7833052431819754,"x_min":0.6710088227893136,"y_max":0.810283140877349,"y_min":0.1329853767638305},"confidence":0.8499506711959839,"label":"bottle","label_id":39},"h":731,"region_id":6200,"roi_type":"bottle","w":216,"x":1288,"y":144}],"resolution":{"height":1080,"width":1920},"tags":{},"timestamp":67297301635}

    AnalyticsData0 {"objects":[{"detection":{"bounding_box":{"x_max":0.3163306922646063,"x_min":0.20249845268772138,"y_max":0.7984013488063937,"y_min":0.12254781445953},"confidence":0.8666459321975708,"label":"bottle","label_id":39},"h":730,"region_id":6201,"roi_type":"bottle","w":219,"x":389,"y":132},{"detection":{"bounding_box":{"x_max":0.7850104587729607,"x_min":0.6687324296210857,"y_max":0.7971464600783804,"y_min":0.13681757042794374},"confidence":0.8462932109832764,"label":"bottle","label_id":39},"h":713,"region_id":6202,"roi_type":"bottle","w":223,"x":1284,"y":148}],"resolution":{"height":1080,"width":1920},"tags":{},"timestamp":67330637174}
    ```

3.  Check the pipeline status:

    ```
    ./src/pipeline-server/status.sh 
    ```

    The pipeline status should be like:

    ```
    --------------------- Pipeline Status ---------------------
    ----------------8080----------------
    [
    {
        "avg_fps": 11.862402507697258,
        "avg_pipeline_latency": 0.5888091060475129,
        "elapsed_time": 268.07383918762207,
        "id": "95204aba458211efa9080242ac180006",
        "message": "",
        "start_time": 1721361269.6349292,
        "state": "RUNNING"
    }
    ]
    ----------------8081----------------
    [
    {
        "avg_fps": 11.481329713987789,
        "avg_pipeline_latency": 0.6092195660469542,
        "elapsed_time": 262.33892583847046,
        "id": "98233952458211efb5090242ac180007",
        "message": "",
        "start_time": 1721361275.3886085,
        "state": "RUNNING"
    }
    ]
    ----------------8082----------------
    [
    {
        "avg_fps": 11.374176117139063,
        "avg_pipeline_latency": 0.6153032569996222,
        "elapsed_time": 256.985634803772,
        "id": "9b2385a8458211efa46f0242ac180005",
        "message": "",
        "start_time": 1721361280.7602823,
        "state": "RUNNING"
    }
    ]
    ```

4. Stop the services:

    ```
    down-pipeline-server
    ```

## Performance

Typical performance metrics and studies include topics such as response
times, scaling (vertical/horizontal), resource usage, and monitoring.

## Summary

{Use this section to summarize what the user learned in the GSG.}

In this get started guide, you learned how to: - {Build the
microservice} - {Run the microservice} - {text}

## Learn More

-   Follow step-by-step examples to become familiar with the core
    functionality of the microservice, in
    [Tutorials](tutorials-template.rst).
-   Use the [API Reference Manual.](api-template.rst)
-   Understand the components, services, architecture, and data flow, in
    the [Overview](overview-template.rst).

## Troubleshooting

{Provide Troubleshooting steps for issues that might arise while using
this documentation.}

### Error Logs

To access the Docker Logs for EVAM server 0, run the following command: 

```
docker logs evam_0
```

Here is an example of the error log when the RSTP stream is unreachable for a pipeline:

```
{"levelname": "INFO", "asctime": "2024-07-31 23:26:47,257", "message": "===========================", "module": "pipeline_manager"}
{"levelname": "INFO", "asctime": "2024-07-31 23:26:47,257", "message": "Completed Loading Pipelines", "module": "pipeline_manager"}
{"levelname": "INFO", "asctime": "2024-07-31 23:26:47,257", "message": "===========================", "module": "pipeline_manager"}
{"levelname": "INFO", "asctime": "2024-07-31 23:26:47,330", "message": "Starting Tornado Server on port: 8080", "module": "__main__"}
{"levelname": "INFO", "asctime": "2024-07-31 23:26:51,177", "message": "Creating Instance of Pipeline detection/yolov5", "module": "pipeline_manager"}
{"levelname": "INFO", "asctime": "2024-07-31 23:26:51,180", "message": "Gstreamer RTSP Server Started on port: 8555", "module": "gstreamer_rtsp_server"}
{"levelname": "ERROR", "asctime": "2024-07-31 23:26:51,200", "message": "Error on Pipeline 5d5b3b0a4f9411efb60d0242ac120007: gst-resource-error-quark: Could not open resource for reading. (5): ../gst/rtsp/gstrtspsrc.c(6427): gst_rtspsrc_setup_auth (): /GstPipeline:pipeline3/GstURISourceBin:source/GstRTSPSrc:rtspsrc0:\nNo supported authentication protocol was found", "module": "gstreamer_pipeline"}
```

## Known Issues

-   For the list of known limitations, see [known issues](https://github.com/intel-retail/automated-self-checkout/issues?q=is%3Aopen+is%3Aissue+label%3AMVP).
-   {Provide a bullet list of issues}

