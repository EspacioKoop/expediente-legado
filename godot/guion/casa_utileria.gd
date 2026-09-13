## Utilería doméstica procedural para dar lectura 3D a la casa (#282).
##
## No introduce estado ni interacción: son objetos reconocibles construidos con
## primitivas simples para reducir la sensación de greybox sin añadir assets
## externos ni comprometer procedencia/licencias.
class_name CasaUtileria
extends RefCounted


static func montar(raiz: Node3D) -> void:
	_montar_mesita(raiz, Vector3(1.7, 0.0, -2.1))
	_montar_lampara_pie(raiz, Vector3(3.0, 0.0, -1.3))


static func _montar_mesita(raiz: Node3D, pos: Vector3) -> void:
	var mesa := Node3D.new()
	mesa.name = "MesitaCasa"
	mesa.position = pos
	raiz.add_child(mesa)

	_agregar_caja(mesa, Vector3(0, 0.55, 0), Vector3(0.82, 0.12, 0.62), Color(0.32, 0.23, 0.17))
	for x in [-0.31, 0.31]:
		for z in [-0.21, 0.21]:
			_agregar_caja(
				mesa, Vector3(x, 0.28, z), Vector3(0.10, 0.56, 0.10), Color(0.27, 0.19, 0.14)
			)


static func _montar_lampara_pie(raiz: Node3D, pos: Vector3) -> void:
	var lampara := Node3D.new()
	lampara.name = "LamparaPieCasa"
	lampara.position = pos
	raiz.add_child(lampara)

	_agregar_cilindro(lampara, Vector3(0, 0.05, 0), 0.28, 0.10, Color(0.18, 0.17, 0.16))
	_agregar_cilindro(lampara, Vector3(0, 0.82, 0), 0.045, 1.55, Color(0.26, 0.24, 0.22))
	_agregar_pantalla(lampara, Vector3(0, 1.62, 0))


static func _agregar_pantalla(raiz: Node3D, pos: Vector3) -> void:
	var malla := MeshInstance3D.new()
	var cono := CylinderMesh.new()
	cono.top_radius = 0.22
	cono.bottom_radius = 0.38
	cono.height = 0.46
	malla.mesh = cono
	malla.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.72, 0.61, 0.43)
	material.roughness = 1.0
	malla.material_override = material
	raiz.add_child(malla)


static func _agregar_caja(raiz: Node3D, pos: Vector3, tam: Vector3, color: Color) -> void:
	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	malla.material_override = material
	raiz.add_child(malla)


static func _agregar_cilindro(
	raiz: Node3D, pos: Vector3, radio: float, alto: float, color: Color
) -> void:
	var malla := MeshInstance3D.new()
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = radio
	cilindro.bottom_radius = radio
	cilindro.height = alto
	malla.mesh = cilindro
	malla.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	malla.material_override = material
	raiz.add_child(malla)
