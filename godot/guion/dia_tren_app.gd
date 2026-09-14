## Capa de #217 sobre el día: añade un tren CC0 discreto al trayecto.
##
## Las mallas son archivos originales del Modular Train Pack de Quaternius.
## Esta capa solo decide montaje, escala y material para integrarlas en SIGA-98;
## no modifica la geometría fuente ni añade colisión, IA o interacción.
extends "res://guion/dia_cielo_app.gd"

const MALLA_VAGON := preload("res://assets/cc0/quaternius_modular_train/CargoTrain_WagonEmpty.obj")
const MALLA_VIA := preload("res://assets/cc0/quaternius_modular_train/RailwayTrack_Straight.obj")


func _entrar_en(fase: String) -> void:
	super._entrar_en(fase)
	if fase == "trayecto":
		_montar_tren_fondo()


func _montar_tren_fondo() -> void:
	var raiz := Node3D.new()
	raiz.name = "TrenFondoCC0"
	raiz.position = Vector3(7.2, 2.9, 0.0)
	raiz.rotation_degrees.y = 90.0
	_mundo.add_child(raiz)

	var material_via := StandardMaterial3D.new()
	material_via.albedo_color = Color(0.16, 0.15, 0.14)
	material_via.roughness = 0.9

	var material_vagon := StandardMaterial3D.new()
	material_vagon.albedo_color = Color(0.20, 0.19, 0.17)
	material_vagon.roughness = 0.85

	for desplazamiento in [-9.0, 9.0]:
		var via := MeshInstance3D.new()
		via.mesh = MALLA_VIA
		via.position.x = desplazamiento
		via.material_override = material_via
		via.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		raiz.add_child(via)

	for desplazamiento in [-5.0, 4.2]:
		var vagon := MeshInstance3D.new()
		vagon.mesh = MALLA_VAGON
		vagon.position = Vector3(desplazamiento, 0.14, 0.0)
		vagon.material_override = material_vagon
		vagon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		raiz.add_child(vagon)
