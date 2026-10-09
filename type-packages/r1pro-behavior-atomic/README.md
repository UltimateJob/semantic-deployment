# BEHAVIOR atomic control runtime support

[English](README.md) | [简体中文](README.zh-CN.md)

This type package connects to the Semantic-managed Isaac Runtime and contains eight Ability types plus the common Skill Worker SDK. The six behavior Skills are installed via the Server Registry. For the new-machine deployment entry, see [cuRobo main deployment migration](../../docs/curobo-main-deployment.md).

Before building, generate templates/model-registry.json in this directory from templates/model-registry.example.json and fill in the new machine's SAM Python, source, and weight paths; the actual configuration is not committed to Git. After installation, the model configuration is copied by the launcher and injected via MODEL_REGISTRY_PATH.

Build .output/bin/semantic-robot-instance and .output/bin/semantic-pilot first, then build with semantic build type-packages/r1pro-behavior-atomic --output <package path>. The SDK and Abilities come from the adjacent integration repositories.

The scene UUID, Runtime address, Robot ID, Pilot credential, and Ability ports are all injected by the Server; deployment does not specify a fixed simulation instance number.

The deployment template selects the eight independent Abilities via ability_name, and actions under the same semantic role keep their original Action types. The template's robot_skills starts empty; Skills are installed from the Registry and enabled once the robot comes online. The common wheel lock must cover the Skill Worker's dependencies; the Ability components use their own independent Python environments.
