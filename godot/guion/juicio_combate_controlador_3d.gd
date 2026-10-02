## Runtime 3D reutilizable del arquetipo CONTROLADOR (#2132).
##
## Traduce la politica pura a una zona geometrica fijada al empezar el aviso.
## No calcula navegacion, no aplica dano y no resuelve consecuencias: el host
## entrega distancia, numero de zonas activas y si queda una salida valida.
class_name JuicioCombateControlador3D
extends RefCounted

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const FEEDBACK = preload("res://guion/juicio_combate_feedback_3d.gd")

const MAX_ZONAS_VISUALES := 2
const ZONA_LARGO := 4.6
const ZONA_ANCHO := 1.7


static func montar_zonas(anfitrion: Node3D, cantidad: int = MAX_ZONAS_VISUALES) -> Array:
	var zonas: Array = []
	var total := mini(maxi(1, cantidad), MAX_ZONAS_VISUALES)
	for indice in range(total):
		var zona := MeshInstance3D.new()
		zona.name = "ZonaControlador%d" % indice
		var malla := BoxMesh.new()
		malla.size = Vector3(ZONA_ANCHO, 0.025, ZONA_LARGO)
		zona.mesh = malla
		var material := FEEDBACK.material(Color(0.70, 0.24, 0.86, 0.38), true)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		zona.material_override = material
		zona.visible = false
		anfitrion.add_child(zona)
		zonas.append(zona)
	return zonas


static func avanzar(
	unidad: Dictionary,
	delta: float,
	posicion_rival: Vector3,
	posicion_jugador: Vector3,
	zonas: Array,
	zonas_activas: int = 0,
	queda_salida_valida: bool = true,
) -> Dictionary:
	var estado_anterior := String(unidad.get("estado", ""))
	var hacia := posicion_jugador - posicion_rival
	hacia.y = 0.0
	var contexto := {
		"distancia": hacia.length(),
		"zonas_activas": maxi(0, zonas_activas),
		"queda_salida_valida": queda_salida_valida,
	}
	var paso := ARQUETIPOS.avanzar(unidad, delta, contexto)
	var nueva: Dictionary = paso["unidad"]
	var estado := String(nueva.get("estado", ""))
	var inicio_marca := (
		estado == ARQUETIPOS.MARCAR_ZONA and estado_anterior != ARQUETIPOS.MARCAR_ZONA
	)
	if inicio_marca:
		_fijar_geometria(nueva, posicion_rival, posicion_jugador, zonas)
	_pintar_zonas(zonas, nueva, estado)
	return {
		"unidad": nueva,
		"intencion": String(paso.get("intencion", "")),
		"telegraph": String(paso.get("telegraph", "")),
		"inicio_marca": inicio_marca,
		"inicio_zona":
		estado == ARQUETIPOS.ACTIVAR_ZONA and estado_anterior != ARQUETIPOS.ACTIVAR_ZONA,
		"zona_activa": estado == ARQUETIPOS.ACTIVAR_ZONA,
		"abrir_ventana":
		estado == ARQUETIPOS.RECUPERAR and estado_anterior != ARQUETIPOS.RECUPERAR,
		"geometria": geometria(nueva),
	}


static func geometria(unidad: Dictionary) -> Dictionary:
	return {
		"indice": int(unidad.get("_zona_indice", 0)),
		"origen": unidad.get("_zona_origen", Vector3.ZERO),
		"rumbo": float(unidad.get("_zona_rumbo", 0.0)),
		"largo": ZONA_LARGO,
		"ancho": ZONA_ANCHO,
	}


static func presentacion(unidad: Dictionary, reduccion_movimiento: bool) -> Dictionary:
	return {
		"geometria": geometria(unidad),
		"estado": String(unidad.get("estado", "")),
		"estilo": "corte" if reduccion_movimiento else "animado",
	}


static func _fijar_geometria(
	unidad: Dictionary,
	posicion_rival: Vector3,
	posicion_jugador: Vector3,
	zonas: Array,
) -> void:
	var disponibles := mini(zonas.size(), MAX_ZONAS_VISUALES)
	if disponibles <= 0:
		return
	var hacia := posicion_jugador - posicion_rival
	hacia.y = 0.0
	var rumbo := 0.0
	if hacia.length() >= 0.01:
		rumbo = atan2(hacia.x, hacia.z)
	var marca := maxi(1, int(unidad.get("zonas_marcadas", 1)))
	unidad["_zona_indice"] = (marca - 1) % disponibles
	unidad["_zona_origen"] = posicion_rival
	unidad["_zona_rumbo"] = rumbo


static func _pintar_zonas(zonas: Array, unidad: Dictionary, estado: String) -> void:
	for zona_variant in zonas:
		var zona := zona_variant as MeshInstance3D
		if zona != null:
			zona.visible = false
	if estado not in [ARQUETIPOS.MARCAR_ZONA, ARQUETIPOS.ACTIVAR_ZONA] or zonas.is_empty():
		return
	var indice := clampi(int(unidad.get("_zona_indice", 0)), 0, zonas.size() - 1)
	var zona := zonas[indice] as MeshInstance3D
	if zona == null:
		return
	var origen: Vector3 = unidad.get("_zona_origen", Vector3.ZERO)
	var rumbo := float(unidad.get("_zona_rumbo", 0.0))
	var direccion := Vector3(sin(rumbo), 0.0, cos(rumbo))
	zona.position = origen + Vector3(0.0, 0.03, 0.0) + direccion * (ZONA_LARGO * 0.5)
	zona.rotation = Vector3(0.0, rumbo, 0.0)
	zona.visible = true
