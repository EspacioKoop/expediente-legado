## Importación selectiva: conserva atlas UV y la caja física ya declarada.
class_name AssetCc0
extends RefCounted


static func sustituir(cuerpo: Node3D, nombre: String, tam: Vector3) -> bool:
	if cuerpo.has_node("AssetCc0"):
		return true
	var escena := Modelos.cargar(nombre)
	if escena == null:
		return false
	var anteriores := Modelos._mallas(cuerpo)
	var pieza := escena.instantiate() as Node3D
	pieza.name = "AssetCc0"
	cuerpo.add_child(pieza)
	Modelos._encajar(pieza, tam)
	_adaptar_materiales(pieza)
	# No se retiran cuerpos, áreas ni hijos de interacción: solo el visual
	# sustituido. La ausencia de un fichero conserva el modelo anterior.
	for malla in anteriores:
		malla.layers = 0
	return true


static func _adaptar_materiales(pieza: Node3D) -> void:
	for nodo in Modelos._mallas(pieza):
		var malla: MeshInstance3D = nodo
		var adaptados: Array[Material] = []
		for superficie in malla.mesh.get_surface_count():
			var original := malla.get_active_material(superficie) as BaseMaterial3D
			var material := ShaderMaterial.new()
			material.shader = load(Espacio3D.shader_del_sitio())
			material.set_shader_parameter("usar_uv", true)
			if original != null:
				material.set_shader_parameter("color_base", original.albedo_color)
				if original.albedo_texture != null:
					material.set_shader_parameter("textura", original.albedo_texture)
					material.set_shader_parameter("con_textura", true)
			malla.set_surface_override_material(superficie, material)
			adaptados.append(material)
		# La malla suelta sus materiales por superficie ANTES de que el servidor
		# libere su instancia, y con malla de sombra y LOD importadas el servidor
		# aún los consulta: «Parameter "material" is null» al liberar el asset,
		# también en GPU. Los metadatos se sueltan después, así que los retienen.
		malla.set_meta(&"materiales_adaptados", adaptados)
