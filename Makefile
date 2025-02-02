# Copyright © 2024 Intel Corporation. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

.PHONY: download-models download-sample-videos clean-models run-pipeline-server down-pipeline-server helm-package

RETAIL_USE_CASE_ROOT ?= $(PWD)

download-models:
	./download_models/downloadModels.sh

download-sample-videos:
	cd sample-media && ./download_sample_videos.sh

clean-models:
	@find ./models/ -mindepth 1 -maxdepth 1 -type d -exec sudo rm -r {} \;

run-pipeline-server: | download-models download-sample-videos
	RETAIL_USE_CASE_ROOT=$(RETAIL_USE_CASE_ROOT) docker compose -f src/docker-compose.pipeline-server.yml up -d

down-pipeline-server:
	docker compose -f src/docker-compose.pipeline-server.yml down

helm-package:
	helm package helm/ -u -d .deploy
	helm package helm/
	helm repo index .
	helm repo index --url https://github.com/intel-retail/automated-self-checkout .