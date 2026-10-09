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
DEPLOYMENT_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
WORKSPACE=$(cd -- "$DEPLOYMENT_ROOT/.." && pwd)
: "${SEMANTIC_BEHAVIOR_PYTHON:?设置已安装 OmniGibson/cuRobo 的 Python 绝对路径}"
: "${OMNIGIBSON_DATA_PATH:?设置共享 BEHAVIOR datasets 路径}"
: "${SEMANTIC_BEHAVIOR_GPU:?选择可用 GPU 编号}"
: "${SEMANTIC_RUNTIME_PORT:?选择独立 Runtime 端口}"
export PYTHONPATH="$WORKSPACE/semantic-simulation/isaac-runtime/src:$WORKSPACE/semantic-robotsdk/robot-sdk/packages/r1pro/src:$WORKSPACE/semantic-robotsdk/robot-sdk/packages/core/src"
export SEMANTIC_CUROBO=1
export PYTHONNOUSERSITE=1 OMNIGIBSON_HEADLESS=1 OMNI_KIT_ACCEPT_EULA=YES
export CUDA_VISIBLE_DEVICES="$SEMANTIC_BEHAVIOR_GPU"
if [[ -n "${SEMANTIC_BEHAVIOR_LIB_DIR:-}" ]]; then
  export LD_LIBRARY_PATH="$SEMANTIC_BEHAVIOR_LIB_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi
exec "$SEMANTIC_BEHAVIOR_PYTHON" -m semantic_isaac_runtime \
  --data-root "$OMNIGIBSON_DATA_PATH" --host "${SEMANTIC_RUNTIME_HOST:-127.0.0.1}" \
  --port "$SEMANTIC_RUNTIME_PORT" --viewer --observation-mode development_full "$@"
