## Regresion de lectura visual del Arconte sobre CONTROLADOR (#2149).
extends SceneTree

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const CONTROLADOR = preload("res://guion/juicio_combate_controlador_3d.gd")
const ARCONTE = preload("res://guion/juicio_combate_arconte_3d.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_montaje()
	_probar_marca_activacion_y_recuperacion()
	_probar_reduccion_movimiento()
	_probar_sin_reglas_paralelas()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_montaje() -> void:
	var anfitrion := Node3D.new()
	var zonas := ARCONTE.montar_zonas(anfitrion, 2)
	_comprobar(zonas.size() == 2, "monta dos zonas logicas")
	_comprobar(anfitrion.get_child_count() == 4, "anade una copia de umbral por zona")
	for indice in range(zonas.size()):
		var zona := zonas[indice] as MeshInstance3D
		_comprobar(zona != null, "zona base es geometria 3D")
		if zona == null:
			continue
		_comprobar(zona.name == "ZonaControlador%d" % indice, "conserva nombre neutro de zona")
		var copia := (\n\t\t\tanfitrion.get_node_or_null(NodePath(String(zona.name) + "_copia")) as MeshInstance3D\n\t\t)
		_comprobar(copia != null, "cada zona tiene plano de umbral desplazado")
		if copia != null:
			_comprobar(
				copia.position.distance_to(zona.position) > 0.0,
				"la copia visual no coincide exactamente con el plano base",
			)
	anfitrion.free()


func _probar_marca_activacion_y_recuperacion() -> void:
	var anfitrion := Node3D.new()
	var zonas := ARCONTE.montar_zonas(anfitrion, 2)
	var unidad := ARQUETIPOS.nuevo(ARQUETIPOS.CONTROLADOR, 2149)
	var rival := Vector3.ZERO
	var jugador := Vector3(0.0, 0.0, 6.0)

	var paso := ARCONTE.avanzar(unidad, 0.0, rival, jugador, zonas)
	unidad = paso["unidad"]
	_comprobar(unidad["estado"] == ARQUETIPOS.MARCAR_ZONA, "entra en MARCAR_ZONA")
	var geometria_marca: Dictionary = paso["geometria"]
	var indice := int(geometria_marca["indice"])
	var zona := zonas[indice] as MeshInstance3D
	_comprobar(zona != null and zona.visible, "MARCAR_ZONA muestra el plano previo")
	if zona != null:
		var material_marca := zona.material_override as StandardMaterial3D
		_comprobar(material_marca != null, "MARCAR_ZONA conserva material legible")
		if material_marca != null:
			_comprobar(
				material_marca.albedo_color.is_equal_approx(Color(0.4, 0.6, 1.0, 0.4)),
				"MARCAR_ZONA usa lectura tenue de umbral",
			)
	var posicion_marca := zona.position if zona != null else Vector3.ZERO
	var rotacion_marca := zona.rotation if zona != null else Vector3.ZERO

	paso = ARCONTE.avanzar(
		unidad,
		ARQUETIPOS.CONTROLADOR_TELEGRAFO,
		rival,
		Vector3(6.0, 0.0, 0.0),
		zonas,
	)
	unidad = paso["unidad"]
	_comprobar(unidad["estado"] == ARQUETIPOS.ACTIVAR_ZONA, "entra en ACTIVAR_ZONA")
	_comprobar(paso["geometria"] == geometria_marca, "ACTIVAR_ZONA conserva geometria fijada")
	zona = zonas[indice] as MeshInstance3D
	_comprobar(zona != null and zona.visible, "ACTIVAR_ZONA mantiene visible el area")
	if zona != null:
		_comprobar(zona.position.is_equal_approx(posicion_marca), "ACTIVAR_ZONA conserva origen")
		_comprobar(zona.rotation.is_equal_approx(rotacion_marca), "ACTIVAR_ZONA conserva rumbo")
		var material_activa := zona.material_override as StandardMaterial3D
		_comprobar(material_activa != null, "ACTIVAR_ZONA conserva material")
		if material_activa != null:
			_comprobar(
				material_activa.albedo_color.is_equal_approx(Color(1.0, 1.0, 1.0, 0.8)),
				"ACTIVAR_ZONA intensifica el mismo plano",
			)

	paso = ARCONTE.avanzar(
		unidad,
		ARQUETIPOS.CONTROLADOR_ACTIVACION,
		rival,
		Vector3(-6.0, 0.0, 0.0),
		zonas,
	)
	unidad = paso["unidad"]
	_comprobar(unidad["estado"] == ARQUETIPOS.RECUPERAR, "entra en RECUPERAR")
	zona = zonas[indice] as MeshInstance3D
	_comprobar(zona != null and not zona.visible, "RECUPERAR apaga la presion visual")
	anfitrion.free()


func _probar_reduccion_movimiento() -> void:
	var unidad := ARQUETIPOS.nuevo(ARQUETIPOS.CONTROLADOR, 2149, 1)
	unidad["estado"] = ARQUETIPOS.MARCAR_ZONA
	unidad["temporizador"] = 0.37
	unidad["_zona_indice"] = 1
	unidad["_zona_origen"] = Vector3(1.0, 0.0, -2.0)
	unidad["_zona_rumbo"] = 0.75
	var original := unidad.duplicate(true)

	var animada := ARCONTE.presentacion(unidad, false)
	var reducida := ARCONTE.presentacion(unidad, true)
	_comprobar(animada["geometria"] == reducida["geometria"], "reduccion mantiene area")
	_comprobar(animada["estado"] == reducida["estado"], "reduccion mantiene estado")
	_comprobar(animada["estilo"] == "animado", "presentacion normal conserva estilo animado")
	_comprobar(reducida["estilo"] == "corte", "reduccion usa corte estatico")
	_comprobar(unidad == original, "presentacion no altera tiempos ni estado")


func _probar_sin_reglas_paralelas() -> void:
	var host_base := Node3D.new()
	var host_arconte := Node3D.new()
	var zonas_base := CONTROLADOR.montar_zonas(host_base, 2)
	var zonas_arconte := ARCONTE.montar_zonas(host_arconte, 2)
	var unidad := ARQUETIPOS.nuevo(ARQUETIPOS.CONTROLADOR, 2149, 2)
	var base := CONTROLADOR.avanzar(
		unidad,
		0.0,
		Vector3.ZERO,
		Vector3(0.0, 0.0, 5.0),
		zonas_base,
	)
	var arconte := ARCONTE.avanzar(
		unidad,
		0.0,
		Vector3.ZERO,
		Vector3(0.0, 0.0, 5.0),
		zonas_arconte,
	)
	_comprobar(arconte == base, "Arconte no crea reglas paralelas sobre CONTROLADOR")
	for clave in ["dano", "consecuencia", "religion", "cultura", "seleccion_cultural"]:
		_comprobar(not arconte.has(clave), "salida visual no expone %s" % clave)
	host_base.free()
	host_arconte.free()


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if not condicion:
		_fallos += 1
		push_error(mensaje)
