[English](curobo-release-validation.md) | [简体中文](curobo-release-validation.zh-CN.md)

# cuRobo release consolidation validation (2026-09-25)

## Code checks in this round

- Runtime atomic control, end-effector precision, grip attachments: 24 items passed.
- SDK fixed collision spheres, plan reuse, trajectories, and planning inputs: 27 items passed.
- Ability cuRobo forwarding, gripper, joint actions, and navigation: 76 items and 16 subtests passed.
- Deployment instance / bundle Go package tests passed; launcher Bash syntax check passed.
- BEHAVIOR Skill implementation tests and related scene snapshots were removed at the user's request; old test results were not counted toward this acceptance.
- New runtime package r1pro-behavior-atomic 0.1.26 built successfully; the ZIP's bundle/wheel references and registry installation method were checked.
- Runtime source and the actual runtime overlay directory were verified file by file; the SDK execution source is identical, source package version 0.5.6.
- Modified files passed diff-whitespace and common credential-format scans; runtime credentials, databases, model weights, and full assets were not committed.

## Artifact evidence

New runtime package SHA256:
`b590a65c1f9fac92a200d1983aadf9f4bca09fef55c3c326b13d25fbd6bbbbb0`

The build used a credential-free SAM configuration example; target-machine paths must be filled in and the package rebuilt before deployment.
The ZIP is kept in the source deployment's `.integration/curobo-release-20260925/`; it has not been installed on site.
This build validation reused an existing build machine's dependency downloads and engine environment; offline installation on an empty machine has not been verified yet.

## Existing physical evidence

- On the main deployment, the six Skills — can initialization, navigation, grasping, return-to-upright, carrying navigation, and placement — were all completed at one point.
  Placement returned release_and_retreat_motion; the same-round native evaluation was not obtained because of the later reset.
- The new navigation actually completed arrival, with a distance error of about 4.78 cm.
- The observation posture's first joint with an 8° margin moved directly from the paused position after the failure and succeeded, with a maximum four-joint error of about 1.7e-6 rad;
  the final-segment first-joint torque was about 3.2 N·m. The new Skill is enabled; the path from the initial standing posture to the full task still needs the next round of on-robot testing.
- This Git consolidation did not restart the Runtime, did not reset the scene, and did not start additional physical motions; the test deployment was not switched.
