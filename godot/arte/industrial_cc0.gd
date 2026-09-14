## Adaptación low-poly de cuatro props de `Free CC0 Industrial 3D Models`.
## Fuente oficial: https://3dmodelscc0.itch.io/free-cc0-industrial-3d-models
## Licencia del pack de referencia: CC0-1.0 / dominio público.
##
## Referencias usadas: Cable Drum, Electrical Box, Platform Trolley y
## Work Light Small. No se redistribuye `IndustrialPack.rar` ni sus modelos o
## texturas: se reconstruyen únicamente siluetas reconocibles con primitivas
## Godot y el shader PSX común. Es dressing secundario de fondo, sin colisión,
## interacción, luces dinámicas ni dependencia del pack completo.
class_name IndustrialCC0
extends RefCounted

const FUENTE := "https://3dmodelscc0.itch.io/free-cc0-industrial-3d-models"
const LICENCIA := "CC0-1.0 / public domain"
const REFERENCIAS := ["Cable Drum", "Electrical Box", "Platform Trolley", "Work Light Small"]

const METAL := Color(0.24, 0.25, 0.25)
const METAL_CLARO := Color(0.38, 0.39, 0.38)
const CABLE := Color(0.12, 0.11, 0.10)
const AMARILLO_OBRA := Color(0.62, 0.48, 0.12)
const LENTE := Color(0.76, 0.72, 0.52)

static var _materiales := {}


static func crear_zona_servicio() -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "IndustrialCC0"
	_bobina(raiz)
	_cuadro_electrico(raiz)
	_carro_plataforma(raiz)
	_foco_obra(raiz)
	return raiz


static func _bobina(raiz: Node3D) -> void:
	var grupo := Node3D.new()
	grupo.name = "CableDrum"
	grupo.position = Vector3(-1.35, 0.58, 0.30)
	raiz.add_child(grupo)

	_cilindro(grupo, "DiscoIzquierdo", 0.12, 0.58, Vector3(-0.42, 0, 0), METAL_CLARO, Vector3(0, 0, 90))
	_cilindro(grupo, "DiscoDerecho", 0.12, 0.58, Vector3(0.42, 0, 0), METAL_CLARO, Vector3(0, 0, 90))
	_cilindro(grupo, "NucleoCable", 0.72, 0.27, Vector3.ZERO, CABLE, Vector3(0, 0, 90))


static func _cuadro_electrico(raiz: Node3D) -> void:
	var grupo := Node3D.new()
	grupo.name = "ElectricalBox"
	grupo.position = Vector3(0.0, 0.66, 0.56)
	raiz.add_child(grupo)

	_caja(grupo, "CajaMetalica", Vector3(0.78, 1.18, 0.28), Vector3.ZERO, METAL)
	_caja(grupo, "Puerta", Vector3(0.70, 1.08, 0.04), Vector3(0, 0, -0.16), METAL_CLARO)
	_caja(grupo, "Maneta", Vector3(0.05, 0.24, 0.05), Vector3(0.24, 0, -0.20), Color(0.10, 0.10, 0.10))


static func _carro_plataforma(raiz: Node3D) -> void:
	var grupo := Node3D.new()
	grupo.name = "PlatformTrolley"
	grupo.position = Vector3(1.28, 0.23, -0.52)
	raiz.add_child(grupo)

	_caja(grupo, "Plataforma", Vector3(1.08, 0.12, 0.64), Vector3.ZERO, METAL_CLARO)
	_caja(grupo, "AsaIzquierda", Vector3(0.06, 0.92, 0.06), Vector3(-0.48, 0.48, 0.26), METAL)
	_caja(grupo, "AsaDerecha", Vector3(0.06, 0.92, 0.06), Vector3(0.48, 0.48, 0.26), METAL)
	_caja(grupo, "AsaSuperior", Vector3(1.02, 0.06, 0.06), Vector3(0, 0.92, 0.26), METAL)
	for x in [-0.42, 0.42]:
		for z in [-0.24, 0.24]:
			_cilindro(
				grupo,
				"Rueda_%s_%s" % [x, z],
				0.10,
				0.11,
				Vector3(x, -0.13, z),
				Color(0.09, 0.09, 0.09),
				Vector3(0, 0, 90),
			)


static func _foco_obra(raiz: Node3D) -> void:
	var grupo := Node3D.new()
	grupo.name = "WorkLightSmall"
	grupo.position = Vector3(-0.28, 0.0, -0.98)
	raiz.add_child(grupo)

	_caja(grupo, "PataA", Vector3(0.08, 0.06, 0.72), Vector3(-0.20, 0.05, 0.05), METAL)
	_caja(grupo, "PataB", Vector3(0.08, 0.06, 0.72), Vector3(0.20, 0.05, 0.05), METAL)
	_caja(grupo, "Mastil", Vector3(0.08, 0.92, 0.08), Vector3(0, 0.50, 0), METAL)
	_caja(grupo, "Carcasa", Vector3(0.46, 0.34, 0.24), Vector3(0, 1.08, 0), AMARILLO_OBRA)
	_caja(grupo, "Lente", Vector3(0.36, 0.25, 0.025), Vector3(0, 1.08, -0.135), LENTE)


static func _caja(
	padre: Node3D, nombre: String, tamano: Vector3, posicion: Vector3, color: Color
) -> void:
	var instancia := MeshInstance3D.new()
	instancia.name = nombre
	var malla := BoxMesh.new()
	malla.size = tamano
	malla.material = _material(color)
	instancia.mesh = malla
	instancia.position = posicion
	padre.add_child(instancia)


static func _cilindro(
	padre: Node3D,
	nombre: String,
	altura: float,
	radio: float,
	posicion: Vector3,
	color: Color,
	giro: Vector3 = Vector3.ZERO,
) -> void:
	var instancia := MeshInstance3D.new()
	instancia.name = nombre
	var malla := CylinderMesh.new()
	malla.height = altura
	malla.top_radius = radio
	malla.bottom_radius = radio
	malla.radial_segments = 10
	malla.material = _material(color)
	instancia.mesh = malla
	instancia.position = posicion
	instancia.rotation_degrees = giro
	padre.add_child(instancia)


static func _material(color: Color) -> ShaderMaterial:
	var clave := color.to_html()
	if _materiales.has(clave):
		return _materiales[clave]
	var material := ShaderMaterial.new()
	material.shader = load(Espacio3D.SHADER_PSX)
	material.set_shader_parameter("color_base", color)
	_materiales[clave] = material
	return material
