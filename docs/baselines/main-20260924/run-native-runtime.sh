#!/usr/bin/env bash
# Copyright 2026 InsightOS
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail
ROOT=/home/amax/dyc/semantic-isaac
export PYTHONPATH="$ROOT/semantic-simulation/isaac-runtime/src"
export PYTHONNOUSERSITE=1
exec >> "$ROOT/.integration/managed-atomic/runtime.log" 2>&1
export CUDA_VISIBLE_DEVICES="${SEMANTIC_BEHAVIOR_GPU:-1}"
export OMNIGIBSON_HEADLESS=1
export OMNI_KIT_ACCEPT_EULA=YES
export OMNIGIBSON_DATA_PATH=/home/amax/dyc/BEHAVIOR-1K/datasets
export LD_LIBRARY_PATH="/home/amax/.conda/envs/behavior/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec "$ROOT/.integration/native-env/bin/python" -m semantic_isaac_runtime --data-root "$OMNIGIBSON_DATA_PATH" --host 127.0.0.1 --port 18100 --viewer --observation-mode development_full "$@"
