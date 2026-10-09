# LIBERO / Franka standalone deployment

[English](README.md) | [简体中文](README.zh-CN.md)

This model package only starts `FrankaVLA.V2`; the model is bound by the Franka
Ability's `configs/smolvla-libero.json`. The Robot Skill `vla-manipulation` is
published separately to the Server and then installed via desired/installed
reconciliation; it does not reuse the R1 tools, URDF, or depalletizing Skill.

## Isolation and prerequisite artifacts

Run from the Semantic home directory; the example install root is
`.cache/libero-behavior-vla/deployment`. The original `.output`, R1 database,
and their services are left untouched. The new Server uses 19080/19081, the Web
uses 3001, the LIBERO Runtime uses 19090, and the managed AbilityFramework uses
19100–19149.

The following are source development deployment tools, not a published
self-contained installer. Prepare before running `assemble`:

- `ROOT/bin/semantic-server`, `semantic`, `semantic-pilot`: built from the
  current Framework source.
- `ROOT/bin/semantic-robot-bundle`, `semantic-robot-instance`: built from the
  current source of this repository.
- `ROOT/build/wheels`: the full SmolVLA dependencies locked by the Franka
  Ability's `uv.lock`, plus the Robot SDK Core, Franka SDK, Franka Ability, and
  Robot Skill SDK wheels from the current source.
- `ROOT/build/requirements.txt`: the dependency manifest exported with
  `uv export --project semantic-ability/franka-ability --frozen --no-dev --extra smolvla --no-emit-local --no-hashes`;
  then prepare offline wheels with `pip wheel --no-deps -r ...`.
- The existing AbilityFramework and ability-py wheels in
  `semantic-ability/ability-runtime`, and `.venv/bin/ability-scaffold`.
- LIBERO native assets, `profiles/libero/.venv`, the Franka Ability `.venv`,
  and the local model cache. The current scripts use
  `.cache/libero-behavior-vla/LIBERO` and the `huggingface` cache under that
  directory; offline mode is enabled at model runtime, with no ad-hoc downloads
  or model revision changes during startup.

## Assembly and startup

```bash
export LIBERO_DEPLOY_ROOT="$PWD/.cache/libero-behavior-vla/deployment"
semantic-ability/franka-ability/.venv/bin/python \
  semantic-robot-deployment/scripts/deploy_franka_libero.py assemble --root "$LIBERO_DEPLOY_ROOT"
semantic-ability/franka-ability/.venv/bin/python \
  semantic-robot-deployment/scripts/deploy_franka_libero.py configure --root "$LIBERO_DEPLOY_ROOT"
semantic-ability/franka-ability/.venv/bin/python \
  semantic-robot-deployment/scripts/deploy_franka_libero.py serve --root "$LIBERO_DEPLOY_ROOT"
```

`assemble` packages the Ability in the build copy, preserves the dependency
lock, and separately checks the offline installability of the Ability
environment and the Skill's dependencies. When a Bundle already exists at the
same path, the Robot using it is safely stopped first, the old package is moved
into backup, and then the build proceeds; a running read-only package is never
overwritten.

In another terminal, start in `semantic-web`:

```bash
VITE_SERVER_HTTP=http://127.0.0.1:19080 \
VITE_SERVER_WS=ws://127.0.0.1:19081 npm run dev -- --host 0.0.0.0 --port 3001
```

In the new Web, configure the model service and key, create a LIBERO project,
select `LIBERO Spatial · Task 0` and the native initial state, then start the
scene. Publish `ROOT/build/vla-manipulation-<source version>.zip` and confirm
the Robot's installed version matches the source. An existing Robot's desired
version is not forcibly overwritten by template updates; the new version must
be selected through the device page or the official Skill install interface.

## Acceptance boundaries

1. A scene running with a continuously advancing pose stream does not mean the
   Robot is ready; you must also check that the Ability is Running, Pilot is
   online, and `vla-manipulation` is installed successfully and enabled.
2. Skill debugging on the device page can verify execution, stage images, and
   native evaluation, but it cannot replace Agent acceptance.
3. Agent acceptance must invoke the Skill in a real conversation. Grasping a
   specified object uses `objective=grasp`; the native full task uses
   `objective=native_task` — the two success criteria must not be conflated.
4. Model keys are not copied with the Bundle, source, or build evidence. When
   the new Server has no valid key configured, the conversation loop counts as
   incomplete and must not be substituted with Mock or standalone inference
   results.
5. Failed executions and images are retained in the standalone Server data
   directory; task success cannot be reported without passing the native
   objective judgment.

This model package does not include BEHAVIOR/R1Pro π0.5; it cannot be used to
claim that BEHAVIOR is deployed and usable.
