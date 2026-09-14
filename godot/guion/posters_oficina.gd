## Láminas suministradas para la oficina (#443); procedencia IA en assets/.
class_name PostersOficina
extends RefCounted

# Centros a altura de lectura. El café deja libre la ventana y el tablón
# conserva sus avisos: los carteles se reparten por tres paredes interiores.
const UBICACIONES := [
	{"pos": Vector3(-5.25, 1.95, -4.88), "giro": 0.0, "alto": 1.35},
	{"pos": Vector3(-3.70, 1.95, -4.88), "giro": 0.0, "alto": 1.35},
	{"pos": Vector3(0.35, 1.90, -4.88), "giro": 0.0, "alto": 1.40},
	{"pos": Vector3(-5.75, 2.15, 4.88), "giro": 180.0, "alto": 1.20},
	{"pos": Vector3(1.75, 1.90, -4.88), "giro": 0.0, "alto": 1.40},
	{"pos": Vector3(-6.88, 1.95, -0.25), "giro": 90.0, "alto": 1.30},
]


static func montar(mundo: Node3D) -> void:
	if mundo.has_node("PostersOficina"):
		return
	var conjunto := Node3D.new()
	conjunto.name = "PostersOficina"
	mundo.add_child(conjunto)
	for indice in UBICACIONES.size():
		var ubicacion: Dictionary = UBICACIONES[indice]
		var textura := (
			load("res://assets/texturas/poster-1998-%02d.png" % (indice + 1)) as Texture2D
		)
		var lamina := MeshInstance3D.new()
		lamina.name = "Poster%02d" % (indice + 1)
		lamina.position = ubicacion.pos
		lamina.rotation_degrees.y = ubicacion.giro
		var plano := QuadMesh.new()
		var alto: float = ubicacion.alto
		plano.size = Vector2(alto * textura.get_width() / textura.get_height(), alto)
		lamina.mesh = plano
		# UV de la lámina completa: el triplanar de paredes repetiría y cortaría
		# el diseño. El papel recibe la luz del local sin emisión propia.
		var material := StandardMaterial3D.new()
		material.albedo_texture = textura
		material.roughness = 1.0
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		lamina.material_override = material
		lamina.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		conjunto.add_child(lamina)
