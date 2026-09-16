# Froppy refactor

This bundle separates player movement, tongue behavior, and pullable-object
physics. Integrate it only after committing the currently working prototype.

## 1. Scene setup

Add a `Node` named `TongueController` directly below `Frog` and attach
`tongue_controller.gd`.

Assign these exported references in its Inspector:

- Tongue Origin: `Visuals/TongueOrigin`
- Tongue Ray: `Visuals/TongueOrigin/TongueRay`
- Tongue Mesh: `Visuals/TongueOrigin/TongueMesh`
- Mouth Carry Point: `Visuals/ShakePivot/MouthCarryPoint`

Replace the script on `Frog` with the new `frog.gd`. Assign the Camera again if
the exported reference is empty.

Attach `pullable_object.gd` to the `PullableObject` root. Its root must be a
`RigidBody3D` and remain in the `tongue_pullable` group.

## 2. Win goal

Create this scene:

```text
Goal (Area3D, spit_goal.gd)
├── MeshInstance3D
└── CollisionShape3D
```

A flat `CylinderMesh` with a green material works well as the first goal. Give
the collision shape enough height that a flying cube reliably enters it.

Add the following UI to the test level:

```text
CanvasLayer
└── WinScreen (ColorRect, Full Rect)
	└── Label (text: YOU WIN!)
```

Set `WinScreen` to hidden and drag it into the Goal's exported `Win Screen`
property. Ensure the Goal's collision mask includes the pullable object's
collision layer.

## 3. Git

Copy `.gitignore` into the root directory containing `project.godot`, then run:

```bash
git init
git add .
git status
git commit -m "Build Froppy tongue and spit prototype"
git branch -M main
git remote add origin https://github.com/YOUR-NAME/froppy-game.git
git push -u origin main
```

Commit `project.godot`, `.gd`, `.tscn`, imported source assets, SVGs, textures,
models, and `export_presets.cfg`. Do not commit `.godot/`, `.env` files, or
`export_credentials.cfg`.
