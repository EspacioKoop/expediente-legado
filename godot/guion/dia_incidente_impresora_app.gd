## Controller autónomo del microincidente de impresora de oficina (#1768).
##
## Puede montarse como hijo de Dia sin modificar su orquestador. La impresora
## física existe durante archivo; la incidencia se materializa al alcanzar el
## umbral determinista y persiste en Jornada durante ese día.
class_name DiaIncidenteImpresoraApp
extends Node

const CLAVE_ESTADO := "incidente_impresora"
const POSICION_DEFECTO := Vector3(2.55, 0.58, -2.15)

@export var posicion_impresora := POSICION_DEFECTO

var _host: Node
var _mundo_id := 0
var _impresora: Interactuable3D
var _bandeja: MeshInstance3D
var _papel: MeshInstance3D
var _led: MeshInstance3D


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia != null:
		sincronizar(dia)


func _exit_tree() -> void:
	_desmontar()


func sincronizar(dia: Node) -> Dictionary:
	if dia == null:
		_desmontar()
		return {"status": "sin_host"}
	var jornada_valor: Variant = dia.get("jornada")
	if not jornada_valor is Dictionary:
		_desmontar()
		return {"status": "sin_jornada"}
	var jornada := jornada_valor as Dictionary
	_host = dia

	if String(jornada.get("fase", "")) != "archivo":
		_desmontar()
		return {"status": "fuera_archivo"}

	var mundo_valor: Variant = dia.get("_mundo")
	if not mundo_valor is Node3D or not is_instance_valid(mundo_valor):
		_desmontar()
		return {"status": "sin_mundo"}
	var mundo := mundo_valor as Node3D

	var actual := _estado_actual(jornada)
	if actual.is_empty():
		_limpiar_estado_obsoleto(jornada)
		actual = _materializar_si_toca(jornada)

	_montar(mundo)
	_aplicar_presentacion(actual)
	return {
		"status": "incidencia" if not actual.is_empty() else "normal",
		"estado": actual.duplicate(true),
		"evento_publicado": _eventos(jornada).has(IncidenteImpresoraOficina.EVENTO),
	}


func _estado_actual(jornada: Dictionary) -> Dictionary:
	var valor: Variant = jornada.get(CLAVE_ESTADO, {})
	if not valor is Dictionary:
		return {}
	var estado := valor as Dictionary
	if estado.is_empty():
		return {}
	if int(estado.get("dia", -1)) != int(jornada.get("dia", 1)):
		return {}
	if int(estado.get("vuelta", -1)) != int(jornada.get("vuelta", 1)):
		return {}
	return estado


func _limpiar_estado_obsoleto(jornada: Dictionary) -> void:
	var valor: Variant = jornada.get(CLAVE_ESTADO, {})
	if valor is Dictionary and not (valor as Dictionary).is_empty():
		jornada.erase(CLAVE_ESTADO)
	_retirar_evento(jornada)


func _materializar_si_toca(jornada: Dictionary) -> Dictionary:
	var raiz := int(jornada.get("raiz", 0))
	var plan := IncidenteImpresoraOficina.programacion(jornada, raiz)
	if not bool(plan.get("activa", false)):
		return {}
	if _acciones_consumidas(jornada) < int(plan.get("tras_accion", 1)):
		return {}

	var estado := IncidenteImpresoraOficina.nuevo(
		int(jornada.get("dia", 1)),
		int(jornada.get("vuelta", 1)),
	)
	jornada[CLAVE_ESTADO] = estado
	_publicar_evento(jornada)
	return estado


func _acciones_consumidas(jornada: Dictionary) -> int:
	var bonus := maxi(0, int(jornada.get("acciones_bonus_hoy", 0)))
	var disponibles_iniciales := Jornada.ACCIONES_POR_DIA + bonus
	return maxi(0, disponibles_iniciales - int(jornada.get("acciones", disponibles_iniciales)))


func _publicar_evento(jornada: Dictionary) -> void:
	var eventos := _eventos(jornada)
	if not eventos.has(IncidenteImpresoraOficina.EVENTO):
		eventos.append(IncidenteImpresoraOficina.EVENTO)
	jornada["eventos"] = eventos


func _retirar_evento(jornada: Dictionary) -> void:
	var eventos := _eventos(jornada)
	while eventos.has(IncidenteImpresoraOficina.EVENTO):
		eventos.erase(IncidenteImpresoraOficina.EVENTO)
	jornada["eventos"] = eventos


func _eventos(jornada: Dictionary) -> Array[String]:
	var salida: Array[String] = []
	var valor: Variant = jornada.get("eventos", [])
	if not valor is Array:
		return salida
	for bruto in valor as Array:
		var evento := String(bruto)
		if not evento.is_empty() and not salida.has(evento):
			salida.append(evento)
	return salida


func _montar(mundo: Node3D) -> void:
	var id := mundo.get_instance_id()
	if id == _mundo_id and is_instance_valid(_impresora):
		return
	_desmontar()
	_mundo_id = id

	_impresora = Interactuable3D.new()
	_impresora.name = "ImpresoraCompartidaIncidente"
	_impresora.position = posicion_impresora
	_impresora.sonido = Interactuable3D.SIN_SONIDO
	_impresora.activado.connect(_al_activar)
	mundo.add_child(_impresora)

	var colision := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = Vector3(0.72, 0.42, 0.58)
	colision.shape = caja
	colision.position.y = 0.20
	_impresora.add_child(colision)

	_agregar_cuerpo()
	_agregar_bandeja()
	_agregar_papel()
	_agregar_led()


func _agregar_cuerpo() -> void:
	var cuerpo := MeshInstance3D.new()
	cuerpo.name = "Carcasa"
	var caja := BoxMesh.new()
	caja.size = Vector3(0.72, 0.42, 0.58)
	cuerpo.mesh = caja
	cuerpo.position.y = 0.20
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.58, 0.57, 0.52)
	material.roughness = 0.82
	cuerpo.material_override = material
	_impresora.add_child(cuerpo)


func _agregar_bandeja() -> void:
	_bandeja = MeshInstance3D.new()
	_bandeja.name = "Bandeja"
	var caja := BoxMesh.new()
	caja.size = Vector3(0.56, 0.06, 0.30)
	_bandeja.mesh = caja
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.31, 0.31, 0.29)
	material.roughness = 0.88
	_bandeja.material_override = material
	_impresora.add_child(_bandeja)


func _agregar_papel() -> void:
	_papel = MeshInstance3D.new()
	_papel.name = "PapelAtascado"
	var caja := BoxMesh.new()
	caja.size = Vector3(0.43, 0.012, 0.22)
	_papel.mesh = caja
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.88, 0.85, 0.72)
	material.roughness = 0.95
	_papel.material_override = material
	_impresora.add_child(_papel)


func _agregar_led() -> void:
	_led = MeshInstance3D.new()
	_led.name = "LedEstado"
	var caja := BoxMesh.new()
	caja.size = Vector3(0.045, 0.03, 0.025)
	_led.mesh = caja
	_led.position = Vector3(0.26, 0.38, 0.30)
	_impresora.add_child(_led)


func _aplicar_presentacion(estado: Dictionary) -> void:
	if not is_instance_valid(_impresora):
		return
	var activa := not estado.is_empty() and not bool(estado.get("resuelta", false))
	_impresora.habilitado = activa
	_impresora.nombre_objeto = "impresora compartida"
	_bandeja.position = Vector3(
		0.0,
		0.06,
		0.32
		if String(estado.get("estado", "")) == IncidenteImpresoraOficina.BANDEJA_ABIERTA
		else 0.22,
	)
	_papel.position = Vector3(0.0, 0.10, 0.39)
	_papel.visible = String(estado.get("estado", "")) == IncidenteImpresoraOficina.BANDEJA_ABIERTA
	_actualizar_led(activa)
	_actualizar_verbo(estado)


func _actualizar_led(atascada: bool) -> void:
	if not is_instance_valid(_led):
		return
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.82, 0.16, 0.10) if atascada else Color(0.18, 0.68, 0.24)
	material.emission_enabled = true
	material.emission = material.albedo_color
	_led.material_override = material


func _actualizar_verbo(estado: Dictionary) -> void:
	if not is_instance_valid(_impresora) or estado.is_empty():
		return
	var accion := _siguiente_accion(estado)
	match accion:
		IncidenteImpresoraOficina.INSPECCIONAR:
			_impresora.verbo = Interactuable3D.Verbo.EXAMINAR
		IncidenteImpresoraOficina.ABRIR_BANDEJA:
			_impresora.verbo = Interactuable3D.Verbo.ABRIR
		IncidenteImpresoraOficina.RETIRAR_PAPEL:
			_impresora.verbo = Interactuable3D.Verbo.COGER
		IncidenteImpresoraOficina.CERRAR_BANDEJA:
			_impresora.verbo = Interactuable3D.Verbo.CERRAR


func _siguiente_accion(estado: Dictionary) -> String:
	var actual := String(estado.get("estado", ""))
	if actual == IncidenteImpresoraOficina.ATASCADA:
		return (
			IncidenteImpresoraOficina.ABRIR_BANDEJA
			if bool(estado.get("inspeccionada", false))
			else IncidenteImpresoraOficina.INSPECCIONAR
		)
	if actual == IncidenteImpresoraOficina.BANDEJA_ABIERTA:
		return IncidenteImpresoraOficina.RETIRAR_PAPEL
	if actual == IncidenteImpresoraOficina.PAPEL_RETIRADO:
		return IncidenteImpresoraOficina.CERRAR_BANDEJA
	return ""


func _al_activar(_actor: Node) -> void:
	if _host == null or not is_instance_valid(_host):
		return
	var jornada_valor: Variant = _host.get("jornada")
	if not jornada_valor is Dictionary:
		return
	var jornada := jornada_valor as Dictionary
	var estado := _estado_actual(jornada)
	var accion := _siguiente_accion(estado)
	if accion.is_empty():
		return

	var resultado := IncidenteImpresoraOficina.transicionar(estado, accion)
	if not bool(resultado.get("ok", false)):
		return
	var actualizado: Dictionary = resultado["estado"]
	jornada[CLAVE_ESTADO] = actualizado
	_host.set_meta(
		"ultimo_feedback_impresora",
		{
			"accion": accion,
			"estado": String(actualizado.get("estado", "")),
			"resuelta": bool(actualizado.get("resuelta", false)),
		},
	)
	_aplicar_presentacion(actualizado)


func _desmontar() -> void:
	_mundo_id = 0
	if is_instance_valid(_impresora):
		_impresora.queue_free()
	_impresora = null
	_bandeja = null
	_papel = null
	_led = null
