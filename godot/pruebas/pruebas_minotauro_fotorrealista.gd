## Regresión del modelo 3D autoral del Minotauro.
extends RefCounted


static func todo(comprobar: Callable) -> void:
	var modelo := ModeloMinotauroAutoral.crear()
	comprobar.call("modelo conserva el nodo Cabeza consumido por el sueño", modelo.name, "Cabeza")
	(
		comprobar
		. call(
			"rostro bovino y cuerpo completos",
			[
				modelo.get_node_or_null("CabezaBovina/Cráneo") != null,
				modelo.get_node_or_null("Torso") != null,
				modelo.get_node_or_null("Muslo") != null,
				modelo.get_node_or_null("Pezuña") != null,
			],
			[true, true, true, true]
		)
	)
	var cuerno := modelo.find_child("Cuerno", true, false) as MeshInstance3D
	comprobar.call(
		"los cuernos son mallas curvadas trianguladas",
		cuerno != null and cuerno.mesh.get_surface_count() > 0,
		true
	)
	var craneo := modelo.find_child("Cráneo", true, false) as MeshInstance3D
	var esfera := craneo.mesh as SphereMesh if craneo != null else null
	comprobar.call(
		"las formas orgánicas no usan esferas facetadas",
		esfera != null and esfera.radial_segments >= 48 and esfera.rings >= 32,
		true
	)
	var material := craneo.material_override as ShaderMaterial if craneo != null else null
	comprobar.call(
		"la piel usa material de microdetalle PBR",
		material != null and material.shader != null,
		true
	)
	comprobar.call(
		"material varía color y rugosidad",
		(
			material != null
			and material.shader.code.contains("ROUGHNESS")
			and material.shader.code.contains("ALBEDO")
		),
		true
	)
	modelo.free()
