## Vertical jugable de huellas ambientales persistentes (#959).
##
## Observa Interactuable3D que optan explícitamente al sistema y el tránsito
## repetido del caminante. Registrar una acción no añade HUD ni cambia progreso:
## solo deja una marca visual barata y guarda su intensidad en Partida.
extends Node

const META_ID := "huella_ambiental_id"
const META_TIPO := "huella_ambiental_tipo"
const META_OFFSET := "huella_ambiental_offset"
const NOMBRE_RAIZ := "HuellasAmbientales959"
const PREFIJO_TRANSITO := "transito:"
const FASES_TRANSITO := ["archivo", "trayecto", "casa"]
const CELDA_TRANSITO := 1.25
const PASADAS_PARA_MARCA := 3
const META_TIPO_MARCA := "huella_tipo_959"
const META_INTENSIDAD_MARCA := "huella_intensidad_959"

var _mundo_id := 0
var _conectados := {}
var _ultima_celda_transito := ""
var _pasadas_transito := {}
var _contexto_visual := ""


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return
	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if mundo_id != _mundo_id:
		_mundo_id = mundo_id
		_conectados.clear()
		_ultima_celda_transito = ""
		_pasadas_transito.clear()
		_contexto_visual = ""
		_asegurar_raiz(mundo)
		_montar_transito_guardado(dia, mundo)
		_sembrar_celda_actual(dia)
	_conectar_marcables(dia, mundo, mundo)
	_registrar_transito(dia, mundo)
	_sincronizar_contexto_visual(dia, mundo)


func _conectar_marcables(dia: Node, mundo: Node3D, nodo: Node) -> void:
	if nodo is Interactuable3D and nodo.has_meta(META_ID):
		var marcable := nodo as Interactuable3D
		var instancia := marcable.get_instance_id()
		if not _conectados.has(instancia):
			_conectados[instancia] = true
			var id := String(marcable.get_meta(META_ID, "")).strip_edges()
			var tipo := String(marcable.get_meta(META_TIPO, "uso"))
			if not id.is_empty():
				marcable.activado.connect(_al_activar.bind(marcable, id, tipo))
				if HuellasAmbientales.intensidad_de(dia.partida.estado, id) > 0.0:
					_montar_o_actualizar_marca(dia, mundo, marcable, id, tipo)
	for hijo in nodo.get_children():
		_conectar_marcables(dia, mundo, hijo)


func _al_activar(
	_actor: Node,
	marcable: Interactuable3D,
	id: String,
	tipo: String,
) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null or not is_instance_valid(marcable):
		return
	var fase := String(dia.jornada.get("fase", ""))
	if not Jornada.FASES.has(fase):
		return
	var huella := HuellasAmbientales.registrar(dia.partida.estado, id, tipo, fase)
	if huella.is_empty():
		return
	_montar_o_actualizar_marca(dia, dia._mundo, marcable, id, tipo)
	if dia.has_method("_guardar_o_avisar"):
		dia.call("_guardar_o_avisar", "")


func _sembrar_celda_actual(dia: Node) -> void:
	var fase := String(dia.jornada.get("fase", ""))
	if not FASES_TRANSITO.has(fase):
		return
	var caminante = dia.get("_caminante")
	if not caminante is Node3D or not is_instance_valid(caminante):
		return
	var posicion := (caminante as Node3D).global_position
	var celda := Vector2i(
		floori(posicion.x / CELDA_TRANSITO),
		floori(posicion.z / CELDA_TRANSITO),
	)
	_ultima_celda_transito = _id_transito(fase, celda)


## Una celda cuenta solo al ENTRAR en ella. Quedarse quieto o vibrar dentro de
## la misma celda no desgasta el suelo. Las dos primeras entradas viven solo en
## memoria; a partir de la tercera aparece una huella persistente y cada regreso
## posterior aumenta el mismo registro hasta el límite global de HuellasAmbientales.
func _registrar_transito(dia: Node, mundo: Node3D) -> void:
	var fase := String(dia.jornada.get("fase", ""))
	if not FASES_TRANSITO.has(fase):
		_ultima_celda_transito = ""
		return
	var caminante = dia.get("_caminante")
	if not caminante is Node3D or not is_instance_valid(caminante):
		return

	var posicion := (caminante as Node3D).global_position
	var celda := Vector2i(
		floori(posicion.x / CELDA_TRANSITO),
		floori(posicion.z / CELDA_TRANSITO),
	)
	var id := _id_transito(fase, celda)
	if id == _ultima_celda_transito:
		return
	_ultima_celda_transito = id

	var huellas := HuellasAmbientales.completar(dia.partida.estado)
	var anterior = huellas.get(id, {})
	var usos_antes := int(anterior.get("usos", 0)) if anterior is Dictionary else 0
	if usos_antes == 0:
		var pasadas := int(_pasadas_transito.get(id, 0)) + 1
		_pasadas_transito[id] = pasadas
		if pasadas < PASADAS_PARA_MARCA:
			return

	var huella := HuellasAmbientales.registrar(dia.partida.estado, id, "paso", fase)
	if huella.is_empty() or int(huella.get("usos", 0)) == usos_antes:
		return
	_montar_marca_en(
		dia,
		mundo,
		id,
		"paso",
		_centro_celda_global(celda),
		float(huella.get("intensidad", 0.0)),
	)
	if dia.has_method("_guardar_o_avisar"):
		dia.call("_guardar_o_avisar", "")


func _montar_transito_guardado(dia: Node, mundo: Node3D) -> void:
	var fase := String(dia.jornada.get("fase", ""))
	if not FASES_TRANSITO.has(fase):
		return
	for entrada in HuellasAmbientales.de_fase(dia.partida.estado, fase):
		if String(entrada.get("tipo", "")) != "paso":
			continue
		var id := String(entrada.get("id", ""))
		var celda_valor: Variant = _celda_desde_id(id, fase)
		if not celda_valor is Vector2i:
			continue
		var celda: Vector2i = celda_valor
		_montar_marca_en(
			dia,
			mundo,
			id,
			"paso",
			_centro_celda_global(celda),
			float(entrada.get("intensidad", 0.0)),
		)


func _asegurar_raiz(mundo: Node3D) -> Node3D:
	var existente := mundo.get_node_or_null(NOMBRE_RAIZ) as Node3D
	if existente != null:
		return existente
	var raiz := Node3D.new()
	raiz.name = NOMBRE_RAIZ
	mundo.add_child(raiz)
	return raiz


func _montar_o_actualizar_marca(
	dia: Node,
	mundo: Node3D,
	marcable: Interactuable3D,
	id: String,
	tipo: String,
) -> void:
	var offset = marcable.get_meta(META_OFFSET, Vector3.ZERO)
	var punto_global := marcable.global_position
	if typeof(offset) == TYPE_VECTOR3:
		punto_global = marcable.to_global(offset)
	_montar_marca_en(
		dia,
		mundo,
		id,
		tipo,
		punto_global,
		HuellasAmbientales.intensidad_de(dia.partida.estado, id),
	)


func _montar_marca_en(
	dia: Node,
	mundo: Node3D,
	id: String,
	tipo: String,
	punto_global: Vector3,
	intensidad: float,
) -> void:
	var raiz := _asegurar_raiz(mundo)
	var nombre := _nombre_marca(id)
	var marca := raiz.get_node_or_null(nombre) as MeshInstance3D
	if marca == null:
		marca = MeshInstance3D.new()
		marca.name = nombre
		marca.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		raiz.add_child(marca)

	var local := mundo.to_local(punto_global)
	local.y = 0.012
	marca.position = local
	marca.rotation.y = deg_to_rad(float(abs(id.hash()) % 35) - 17.0)

	var plano := PlaneMesh.new()
	plano.size = _tamano_de(tipo)
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 1.0
	plano.material = material
	marca.mesh = plano
	marca.set_meta(META_TIPO_MARCA, tipo)
	marca.set_meta(META_INTENSIDAD_MARCA, intensidad)
	_aplicar_contexto_visual(marca, dia.jornada, tipo, intensidad)


## #959: hora/clima cambian solo la lectura de una huella ya existente. La
## persistencia continúa siendo intensidad + usos; no guardamos el contexto.
static func perfil_visual(jornada: Dictionary, tipo: String, intensidad: float) -> Dictionary:
	var fase := String(jornada.get("fase", ""))
	var clima := String(jornada.get("clima_forzado", "")).strip_edges()
	if clima.is_empty():
		clima = Clima.estado(int(jornada.get("dia", 1)))
	var franja := Jornada.franja_horaria(jornada)
	var factor := 1.0
	var tinte := Color(0.11, 0.085, 0.065)

	if fase == "trayecto" and Clima.precipitacion(clima) and tipo in ["paso", "roce"]:
		factor *= 1.15
	if franja == "mediodia":
		factor *= 0.94
	elif franja == "noche":
		factor *= 1.08
	if tipo == "equipo" and franja in ["tarde", "noche"]:
		factor *= 1.08
	if fase == "sueño":
		factor *= 1.06
		tinte = Color(0.105, 0.085, 0.12)

	var base := 0.07 + clampf(intensidad, 0.0, HuellasAmbientales.INTENSIDAD_MAX) * 0.28
	return {
		"alpha": clampf(base * factor, 0.04, 0.30),
		"tinte": tinte,
		"clima": clima,
		"franja": franja,
	}


func _sincronizar_contexto_visual(dia: Node, mundo: Node3D) -> void:
	var clima := String(dia.jornada.get("clima_forzado", "")).strip_edges()
	if clima.is_empty():
		clima = Clima.estado(int(dia.jornada.get("dia", 1)))
	var firma := (
		"%s|%s|%s"
		% [
			String(dia.jornada.get("fase", "")),
			clima,
			Jornada.franja_horaria(dia.jornada),
		]
	)
	if firma == _contexto_visual:
		return
	_contexto_visual = firma
	var raiz := _asegurar_raiz(mundo)
	for hijo in raiz.get_children():
		if not hijo is MeshInstance3D:
			continue
		var marca := hijo as MeshInstance3D
		var tipo := String(marca.get_meta(META_TIPO_MARCA, "uso"))
		var intensidad := float(marca.get_meta(META_INTENSIDAD_MARCA, 0.0))
		_aplicar_contexto_visual(marca, dia.jornada, tipo, intensidad)


static func _aplicar_contexto_visual(
	marca: MeshInstance3D,
	jornada: Dictionary,
	tipo: String,
	intensidad: float,
) -> void:
	if marca.mesh == null or not marca.mesh is PlaneMesh:
		return
	var plano := marca.mesh as PlaneMesh
	var material := plano.material as StandardMaterial3D
	if material == null:
		return
	var perfil := perfil_visual(jornada, tipo, intensidad)
	var tinte: Color = perfil["tinte"]
	tinte.a = float(perfil["alpha"])
	material.albedo_color = tinte


func _tamano_de(tipo: String) -> Vector2:
	match tipo:
		"apertura":
			return Vector2(0.44, 0.19)
		"paso":
			return Vector2(0.50, 0.17)
		"roce":
			return Vector2(0.28, 0.24)
		"lectura":
			return Vector2(0.24, 0.20)
		"equipo":
			return Vector2(0.42, 0.34)
		_:
			return Vector2(0.34, 0.23)


func _id_transito(fase: String, celda: Vector2i) -> String:
	return "%s%s:%d:%d" % [PREFIJO_TRANSITO, fase, celda.x, celda.y]


func _celda_desde_id(id: String, fase: String) -> Variant:
	var prefijo := "%s%s:" % [PREFIJO_TRANSITO, fase]
	if not id.begins_with(prefijo):
		return null
	var partes := id.trim_prefix(prefijo).split(":")
	if partes.size() != 2 or not partes[0].is_valid_int() or not partes[1].is_valid_int():
		return null
	return Vector2i(int(partes[0]), int(partes[1]))


func _centro_celda_global(celda: Vector2i) -> Vector3:
	return Vector3(
		(float(celda.x) + 0.5) * CELDA_TRANSITO,
		0.012,
		(float(celda.y) + 0.5) * CELDA_TRANSITO,
	)


func _nombre_marca(id: String) -> String:
	return "Huella_" + id.replace(":", "_").replace("/", "_").replace(" ", "_")
