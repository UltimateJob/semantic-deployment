[English](curobo-main-deployment.md) | [简体中文](curobo-main-deployment.zh-CN.md)

# cuRobo main deployment migration

Updated 2026-09-30; applies to new Linux x86_64 machines with an existing Isaac / BEHAVIOR environment and legitimate assets.
The current source baseline uses `curobo-release-lock.json` in the same directory as the single entry point. Use the original deployment branches:

| Repository directory | Release branch |
| --- | --- |
| semantic-framework | feature/behavior-test |
| semantic-web | feature/behavior-isaac |
| semantic-simulation/isaac-runtime | feature/behavior-test |
| semantic-robot-deployment | feature/behavior-test |
| semantic-robotsdk/robot-sdk | feature/behavior-test |
| semantic-ability/r1pro-behavior-ability | feature/behavior-test |
| semantic-ability/ability-runtime | develop |
| semantic-skill/robot-skill | feature/behavior-test |

When checking out, use the full commits in the manifest; do not substitute the latest branch commits for the locked versions.
AbilityFramework's develop already has newer rebuilt artifacts; this manifest still pins the `258386e` used on this machine
and does not mix binary updates not adopted on this machine into this baseline.
This alignment covers the machine's core source only; it does not include Trace, screen-recording working directories, test-run data, or machine run configuration.
`semantic-20260928-lock.json` is kept as an old deployment snapshot and cannot serve as the source lock for this new deployment.

## Runtime structure

The Server manages the scene lifecycle and starts the Runtime, Pilot, and AbilityFramework. Abilities submit goals through the existing SDK HTTP
interface; the SDK's cuRobo planner runs inside the Runtime's native engine process, and the Runtime advances the trajectories.
The browser uses Semantic Web's scene geometry and pose rendering; sensor observations come from the native cameras.

Current rebuildable versions:

| Component | Version |
| --- | --- |
| Robot runtime package | 0.1.28, includes Ability 0.5.24 and the Skill Worker offline-dependency fix |
| Runtime source | 0.1.27, native startup, without the screen-recording branch |
| SDK / Ability | 0.5.6 / 0.5.24 |
| behavior-init / behavior-nav | 0.1.6 / 0.1.9 |
| behavior-grasp | 0.1.47 |
| behavior-upright / behavior-place | 0.1.1 / 0.1.7 |
| behavior-radio-button | 0.1.37 |

Package version numbers cannot substitute for source commits: components such as the SDK may have code differences under the same version number.
The machine's previous Robot base platform was 0.1.26; the new build uses the 0.1.28 recipe published on the deployment branch, fixing old Ability
wheel filenames and adding python-fcl and cython; it does not change the robot business source locked this time.
The Ability is locked at release commit `80bec60`, whose business source is identical to this machine's `c123fe6`; it only cleans up two temporary test databases.

## 1. Prepare adjacent repositories

Keep the following directory layout; the build recipes reference adjacent repositories:

```text
semantic/
  semantic-framework/
  semantic-web/
  semantic-robot-deployment/       # remote project name: semantic-deployment
  semantic-robotsdk/robot-sdk/
  semantic-ability/r1pro-behavior-ability/
  semantic-ability/ability-runtime/ # AbilityFramework + ability_py wheel
  semantic-skill/robot-skill/
  semantic-simulation/isaac-runtime/ # remote project name: issac-runtime
  third_party/curobo/
  third_party/sam3/
  third_party/behavior-curobo/       # BEHAVIOR-1K, including OmniGibson / bddl3 / joylo
```

First obtain this guide and the source lock from the deployment repo's `feature/behavior-test` branch.
Create the adjacent repositories per each path and URL in `curobo-release-lock.json`; clone the corresponding release
branches for the Semantic repos, and fetch third_party from the respective official repositories. Then check out the manifest-specified
commits everywhere, keeping full history or ensuring the exact commits are fetched; do not substitute the latest code of default
branches. The deployment repo itself uses the commit that contains this manifest.
For example, preparing the Skill in a fresh empty workspace:

```bash
git clone --branch feature/behavior-test \
  https://github.com/insightos-community/semantic-skill/robot-skill.git \
  semantic-skill/robot-skill
git -C semantic-skill/robot-skill checkout --detach c379432d25a40cf1050665338c68392e5cb0eaee
```

Before switching commits in an existing workspace, check for uncommitted changes and do not overwrite local files.
Large files in `ability-runtime` need `git lfs pull`; verify the AbilityFramework executable works and the wheel unpacks normally.

## 2. Align the native environment and robot assets

The machine's core native environment is Python 3.11.16, Isaac Sim 5.1.0.0, OmniGibson 3.9.2 from locked source,
PyTorch 2.7.0+cu128, Warp 1.12.0, NumPy 1.26.0, SciPy 1.15.3, Trimesh 4.5.1.
See `curobo-native-environment.json` for the core version list; it does not replace a full transitive-dependency lock.
cuRobo must use the `78612f45...` commit from the source lock; the installed package version string depends on how it was built and cannot be used as the sole evidence.

The native venv inherits system packages from the Python 3.11 environment where Isaac / BEHAVIOR are already installed, then installs the locked
OmniGibson, bddl3, joylo, SDK, and Runtime. The host environment's OmniGibson may show 3.9.3,
but the native environment must actually load the 3.9.2 source in `third_party/behavior-curobo/OmniGibson`.
On this machine that directory comes from a clean archive of the locked commit and does not need the WebRTC local changes from old deployment records.
New machines should rebuild the venv rather than copy an existing environment. Once matching dependencies are prepared, the source can be installed:

```bash
uv pip install --python "$SEMANTIC_ROOT/envs/native/bin/python" --no-build-isolation --no-deps \
  -e "$SEMANTIC_ROOT/third_party/behavior-curobo/bddl3" \
  -e "$SEMANTIC_ROOT/third_party/behavior-curobo/OmniGibson" \
  -e "$SEMANTIC_ROOT/third_party/behavior-curobo/joylo" \
  -e "$SEMANTIC_ROOT/semantic-robotsdk/robot-sdk/packages/core" \
  -e "$SEMANTIC_ROOT/semantic-robotsdk/robot-sdk/packages/r1pro" \
  -e "$SEMANTIC_ROOT/semantic-simulation/isaac-runtime"
uv pip install --python "$SEMANTIC_ROOT/envs/native/bin/python" --no-build-isolation --no-deps \
  -e "$SEMANTIC_ROOT/third_party/curobo"
```

The cuRobo CUDA extension must be built on the target machine with the CUDA 12.8 toolchain matching PyTorch, choosing the
architecture for the target GPU; do not reuse build caches across machines. The existing startup flow with `SEMANTIC_CUROBO=1` is retained.
The standalone environments for Robot / Ability use `type-packages/r1pro-behavior-atomic/requirements.lock`;
their NumPy and other versions are managed separately from the native environment and do not overwrite each other.

The asset root should contain `2026-challenge-task-instances/metadata/available_tasks.yaml`.
Verify the robot file digests in `curobo-assets/r1pro-assets.json`. Keep the URDF, USD, cuRobo
configuration, and their referenced meshes; already installed scene assets can be reused. The fixed collision-sphere JSON has been committed with the SDK source.

The USD change for two-finger synchronization is in `curobo-assets/r1pro-gripper-mimic.patch`; back up first, then run
`patch --dry-run -p1 < <patch path>` in the robot asset directory and apply it only after the check passes. The patch only covers two-finger synchronization;
when other file digests differ, compare them or obtain an identical robot directory from the legitimate asset holder.
Full assets, model weights, and CUDA/Shader caches are not delivered with the Git repository.

The main deployment has removed the override that force-enables GPU Dynamics; the migration follows the native engine's physics configuration.
cuRobo's GPU planning and physics GPU Dynamics are configured separately.

## 3. Configure native Runtime startup

Copy `examples/curobo-native.env.example` into the new workspace as `curobo-native.env` and fill in the environment, assets,
GPU, and ports. Set `SEMANTIC_BEHAVIOR_LIB_DIR` when extra Conda dynamic libraries are needed.
`SEMANTIC_BEHAVIOR_MAX_STEPS` sets the cumulative step budget for a whole scene round and must be a positive integer;
when unset it defaults to `10000`, and the example sets `100000`, suitable for long flows with multiple planning rounds.
Simulation steps during idle and planning waits also count against the budget; this value does not change the simulation update rate or per-action timeout.
After changing `curobo-native.env`, restart the Runtime and reload the scene; the current scene does not update immediately.
Create the workspace `run-native-runtime.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/curobo-native.env"
exec "$HERE/semantic-robot-deployment/scripts/run-curobo-runtime.sh" "$@"
```

Give it execute permission. The launcher loads the Runtime and SDK from the same workspace; after migration no `.integration` experiment copy is needed.
The Server is responsible for invoking this script; there is usually no need to start the Runtime again in another terminal.

## 4. Build and install

Configure Go, uv, and Node in the new workspace; build the Framework and Web from their respective repositories.
On first use, the Framework generates a standalone configuration and data directory via `semantic init -c <install config path>`.
Place `examples/native-curobo-runtime.yaml` into the configured `simulation.runtimes_dir`, replacing all
workspace and asset absolute paths in it. Keep `endpoint` consistent with the Runtime script port.

Managed robot configuration example:

```yaml
robot_runtime:
  enabled: true
  server_http_url: http://127.0.0.1:18200
  server_websocket_url: ws://127.0.0.1:18201/ws/pilot
  ability_port_first: 18300
  ability_port_last: 18399
```

Keep the other path fields generated by the initializer. Server HTTP / WS are set to 18200 / 18201; ports can be adjusted
as long as the callback addresses are updated in sync. A new machine may use the same ports provided there is no local conflict.

SAM3.1 uses a separate Python 3.12 environment and the SAM source pinned by the manifest. This machine runs Python 3.12.14,
PyTorch 2.10.0+cu128, torchvision 0.25.0+cu128, NumPy 1.26.4.
Weights use `sam3.1_multiplex.pt`; see `external_assets.model` in the source lock for the download source, revision, and SHA-256;
verify the digest after downloading and do not add the weights to Git.
Generate `model-registry.json` in the same directory from
`type-packages/r1pro-behavior-atomic/templates/model-registry.example.json`, replacing the Python / source / checkpoint paths and GPU configuration before building.
Initialization and navigation can be validated before the perception service is ready; grasping and placement require a working perception environment.

Build commands (`SEMANTIC_ROOT` already points at the adjacent-repo workspace):

```bash
cd "$SEMANTIC_ROOT/semantic-framework"
make build
mkdir -p "$SEMANTIC_ROOT/semantic-robot-deployment/.output/bin"
go build -o "$SEMANTIC_ROOT/semantic-robot-deployment/.output/bin/semantic-pilot" ./cmd/semantic-pilot
cd "$SEMANTIC_ROOT/semantic-robot-deployment"
mkdir -p .output/bin
go build -o .output/bin/semantic-robot-instance ./cmd/semantic-robot-instance
export SEMANTIC_CLI="$SEMANTIC_ROOT/semantic-framework/.output/bin/semantic"
mkdir -p "$SEMANTIC_ROOT/packages/curobo"
"$SEMANTIC_CLI" build type-packages/r1pro-behavior-atomic \
  --output "$SEMANTIC_ROOT/packages/curobo/r1pro-behavior-atomic-0.1.28.zip"
"$SEMANTIC_CLI" build "$SEMANTIC_ROOT/semantic-ability/r1pro-behavior-ability" \
  --output "$SEMANTIC_ROOT/packages/curobo/r1pro-behavior-abilities-0.5.24.zip"
```

Read the six Skills' versions from the source lock and build them, avoiding reuse of old ZIP filenames:

```bash
python3 - <<'PY_BUILD'
import json, os, pathlib, subprocess
root = pathlib.Path(os.environ["SEMANTIC_ROOT"])
lock = json.loads((root / "semantic-robot-deployment/docs/curobo-release-lock.json").read_text())
for name, version in lock["skills"].items():
    source = root / "semantic-skill/robot-skill/semantic_robot_skills/skills" / name.replace("-", "_")
    output = root / "packages/curobo" / f"{name}-{version}.zip"
    subprocess.run([os.environ["SEMANTIC_CLI"], "build", str(source), "--output", str(output)], check=True)
PY_BUILD
cd "$SEMANTIC_ROOT/semantic-web"
npm ci
npm run build
```

Import the two scene packages trash and radio: `behavior-picking_up_trash-scenes-3.9.3.zip` and
`behavior-turning_on_radio-scenes-3.9.3.zip`. Verification digests of existing export packages are in
`external_assets.scene_packages`; the packages themselves and the full BEHAVIOR assets are delivered separately.
You can also re-export with the locked Runtime's `--data-root ... --export-scenes ... --scene ...` and
then run `semantic build`; before exporting, use `--catalog` to verify `behavior-picking_up_trash-0`,
`behavior-turning_on_radio-0`, and the required layouts. Record fresh digests for re-exported packages; do not reuse the old ZIP hashes.

Start the new Server and Web, and create your own admin credentials, project, and LLM configuration. From the Web, install the scene packages,
the Robot runtime package, and the Ability package; bind the Abilities to the project R1Pro or a specific robot. Choose a scene initial state and start
the Layout; the Server generates the corresponding Pilot credential and brings up the managed Robot. Then upload the six Skills, and
install and enable the current versions on the robot. Templates are not prefilled with old Skill references.

When browsing the Web from other machines, `VITE_SERVER_HTTP` / `VITE_SERVER_WS` must use the
new Server address reachable from the browser, e.g. `http://<new machine IP>:18200` and `ws://<new machine IP>:18201`.
Backend local calls to the Runtime and Pilot callback connections can keep using 127.0.0.1.

## 5. Installation verification

After deployment, verify the source commits, the actually loaded paths, and the installed and enabled package versions. In particular, confirm:

- init 0.1.6 accepts `arm_posture=down/raised`, default down.
- nav 0.1.9 defaults to `arrival_radius_m=0.06`; explicit input is still honored.
- grasp 0.1.47's automatic observation posture includes a 0.01 m torso self-collision clearance.
- place 0.1.7 accepts the `object_size_m` and `eef_from_object` returned by grasp. Cross-step reuse is up to the caller,
  which reads this round's successful grasp result for the same object and passes it through unchanged; merely installing the new Skill does not automatically supply task inputs.

Check in order: scene loading, all eight Ability types ready, Robot idle, native cameras, SAM recognition, and cuRobo plan-only;
then execute tasks as needed. Aligning source and package versions is not equivalent to completing scene acceptance on the target machine.
This manifest carries no test prompts, run records, run databases, credentials, or host configuration; historical deployment snapshots are for archiving
only — do not take old component packages from them for new deployments. Existing runtime configuration is maintained independently per target machine.
