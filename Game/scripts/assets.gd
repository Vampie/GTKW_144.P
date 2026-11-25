class_name Assets

## Turns glb models into single meshes, so many copies can be drawn as one MultiMesh.

static var _meshes := {}


static func mesh(path: String) -> ArrayMesh:
	if not _meshes.has(path):
		var scene: Node3D = load(path).instantiate()
		var out := ArrayMesh.new()
		for mi: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
			var xform := Transform3D.IDENTITY
			var node: Node3D = mi
			while node != scene:
				xform = node.transform * xform
				node = node.get_parent() as Node3D
			for s in mi.mesh.get_surface_count():
				var st := SurfaceTool.new()
				st.append_from(mi.mesh, s, xform)
				st.set_material(mi.mesh.surface_get_material(s))
				st.commit(out)
		scene.free()
		_meshes[path] = out
	return _meshes[path]


## source is a Mesh or the path of a glb model.
static func multimesh(source: Variant, xforms: Array, shadows := true) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = source if source is Mesh else mesh(source)
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	if not shadows:
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mmi
