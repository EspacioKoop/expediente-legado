extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_gate_y_semilla()
	_probar_radio_deliberada()
	_probar_umbral_reversible()
	_probar_objetos_y_reflejos()
	_probar_accesibilidad_y_reproduccion()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_gate_y_semilla() -> void:
	var jornada := {"dia": 6}
	_comprobar(not SuenoTirNaNog.puede_entrar(jornada), "sin semilla no entra")
	_comprobar(
		not SuenoTirNaNog.registrar_semilla(jornada, false, true),
		"escuchar sin sintonizar no activa",
	)
	_comprobar(
		not SuenoTirNaNog.registrar_semilla(jornada, true, false),
		"sintonizar sin completar no activa",
	)
	_comprobar(
		SuenoTirNaNog.registrar_semilla(jornada, true, true),
		"programa deliberado registra semilla",
	)
	_comprobar(SuenoTirNaNog.puede_entrar(jornada), "semilla habilita familia")
	_comprobar(
		SemillasOniricas.familias_activas(jornada),
		["tir_na_nog"],
		"Tír na nÓg usa catálogo común",
	)
	var entrada: Dictionary = (
		SemillasOniricas.obtener_semillas(jornada)["semilla_onirica_tir_na_nog"]
	)
	_comprobar(entrada["fuentes"], ["radio:tir_na_nog_98"], "fuente estable")
	_comprobar(entrada["intensidad"], 2, "intensidad conservada")
	jornada["dia"] = 7
	_comprobar(not SuenoTirNaNog.puede_entrar(jornada), "semilla no cruza de jornada")


func _probar_radio_deliberada() -> void:
	var jornada := {"dia": 2}
	var radio := TirNaNogVigilia.new()
	get_root().add_child(radio)
	radio.configurar(jornada)
	_comprobar(not radio.esta_activada(), "radio presente no activa sola")
	_comprobar(not radio.programa_sintonizado(), "empieza fuera del programa")
	radio.usar()
	_comprobar(radio.programa_sintonizado(), "primera interacción sintoniza")
	_comprobar(radio.segmentos_escuchados(), 0, "sintonizar no cuenta como escucha")
	_comprobar(not radio.esta_activada(), "sintonizar no activa")
	radio.usar()
	_comprobar(radio.segmentos_escuchados(), 1, "primer tramo escuchado")
	_comprobar(not radio.esta_activada(), "un tramo no basta")
	radio.usar()
	_comprobar(radio.segmentos_escuchados(), 2, "segundo tramo completa programa")
	_comprobar(radio.esta_activada(), "programa completo activa")
	var intensidad := int(
		SemillasOniricas.obtener_semillas(jornada)["semilla_onirica_tir_na_nog"]["intensidad"]
	)
	radio.usar()
	_comprobar(
		SemillasOniricas.obtener_semillas(jornada)["semilla_onirica_tir_na_nog"]["intensidad"],
		intensidad,
		"misma fuente sigue idempotente",
	)
	radio.queue_free()


func _probar_umbral_reversible() -> void:
	var sueno := SuenoTirNaNog.new()
	get_root().add_child(sueno)
	sueno.preparar()
	_comprobar(sueno.versiones_disponibles().size(), 2, "máximo de dos versiones")
	_comprobar(
		SuenoTirNaNog.MAX_VERSIONES_SIMULTANEAS,
		2,
		"límite simultáneo declarado",
	)
	_comprobar(sueno.version_actual(), SuenoTirNaNog.VERSION_RECIENTE, "empieza reciente")
	_comprobar(sueno.get_node_or_null("Version_reciente") != null, "existe versión reciente")
	_comprobar(sueno.get_node_or_null("Version_envejecida") != null, "existe versión envejecida")
	_comprobar(sueno.get_node_or_null("UmbralPrincipal") != null, "umbral visible existe")
	_comprobar(sueno.ruta_retorno_disponible(), "retorno existe antes de cruzar")

	var ida := sueno.cruzar_umbral()
	_comprobar(ida["ok"], "cruce válido")
	_comprobar(ida["desde"], SuenoTirNaNog.VERSION_RECIENTE, "sale de reciente")
	_comprobar(ida["hacia"], SuenoTirNaNog.VERSION_ENVEJECIDA, "entra en envejecida")
	_comprobar(not ida["irreversible"], "cruce declara reversibilidad")
	_comprobar(not ida["objetos_criticos_borrados"], "cruce no borra objetos críticos")
	_comprobar(ida["retorno_disponible"], "retorno sigue disponible")

	var vuelta := sueno.cruzar_umbral()
	_comprobar(vuelta["hacia"], SuenoTirNaNog.VERSION_RECIENTE, "segundo cruce vuelve")
	_comprobar(sueno.version_actual(), SuenoTirNaNog.VERSION_RECIENTE, "estado vuelve a origen")
	var invalido := sueno.cruzar_umbral("arco_inexistente")
	_comprobar(not invalido["ok"], "umbral desconocido se rechaza")
	_comprobar(invalido["retorno_disponible"], "error no elimina retorno")
	sueno.queue_free()


func _probar_objetos_y_reflejos() -> void:
	var sueno := SuenoTirNaNog.new()
	get_root().add_child(sueno)
	sueno.preparar()
	var inicial := sueno.estado_reproducible()
	_comprobar(
		inicial["objetos"][SuenoTirNaNog.OBJ_TAZA][SuenoTirNaNog.VERSION_RECIENTE],
		"mesa",
		"taza empieza en mesa",
	)

	var taza := sueno.mover_objeto(SuenoTirNaNog.OBJ_TAZA)
	_comprobar(taza["ok"], "taza se puede mover")
	_comprobar(taza["version_origen"], SuenoTirNaNog.VERSION_RECIENTE, "acción conserva origen")
	_comprobar(taza["version_reflejo"], SuenoTirNaNog.VERSION_ENVEJECIDA, "efecto aparece al otro lado")
	_comprobar(taza["estado_origen"], "alfeizar", "posición reciente es explícita")
	_comprobar(taza["estado_reflejo"], "marca_circular_alfeizar", "otra versión deja huella legible")
	_comprobar(taza["rastreable"], "feedback declara trazabilidad")

	sueno.cruzar_umbral()
	var estado := sueno.estado_reproducible()
	_comprobar(
		estado["objetos"][SuenoTirNaNog.OBJ_TAZA][SuenoTirNaNog.VERSION_ENVEJECIDA],
		"marca_circular_alfeizar",
		"huella persiste al cruzar",
	)
	var silla := sueno.mover_objeto(SuenoTirNaNog.OBJ_SILLA)
	_comprobar(silla["version_origen"], SuenoTirNaNog.VERSION_ENVEJECIDA, "también se actúa desde envejecida")
	_comprobar(silla["version_reflejo"], SuenoTirNaNog.VERSION_RECIENTE, "reflejo puede volver a reciente")
	_comprobar(silla["estado_reflejo"], "junto_puerta_desgastada", "reflejo inverso es determinista")
	var archivador := sueno.mover_objeto(SuenoTirNaNog.OBJ_ARCHIVADOR)
	_comprobar(archivador["rastreable"], "archivador usa la misma regla legible")

	var invalido := sueno.mover_objeto("reloj_magico")
	_comprobar(not invalido["ok"], "objeto no declarado se rechaza")
	_comprobar(invalido["retorno_disponible"], "objeto inválido no softlockea")
	sueno.queue_free()


func _probar_accesibilidad_y_reproduccion() -> void:
	var sueno := SuenoTirNaNog.new()
	get_root().add_child(sueno)
	sueno.preparar()
	var normal := sueno.cruzar_umbral(SuenoTirNaNog.UMBRAL_PRINCIPAL, false)
	_comprobar(normal["modo"], "cruce_breve", "modo normal usa cruce breve")
	_comprobar(normal["duracion"], 0.18, "transición normal está acotada")
	_comprobar(not normal["time_lapse"], "nunca usa time-lapse")
	_comprobar(not normal["reloj_contrarreloj"], "no hay reloj de castigo")

	var reducida := sueno.cruzar_umbral(SuenoTirNaNog.UMBRAL_PRINCIPAL, true)
	_comprobar(reducida["modo"], "corte_fundido", "movimiento reducido usa corte/fundido")
	_comprobar(reducida["duracion"], 0.0, "movimiento reducido no interpola")
	_comprobar(
		reducida["hacia"],
		SuenoTirNaNog.VERSION_RECIENTE,
		"accesibilidad conserva versión destino",
	)

	sueno.mover_objeto(SuenoTirNaNog.OBJ_ARCHIVADOR)
	var guardado := sueno.estado_reproducible()
	var copia := SuenoTirNaNog.new()
	get_root().add_child(copia)
	copia.preparar()
	copia.restaurar_estado(guardado)
	_comprobar(copia.estado_reproducible(), guardado, "save reproduce exactamente el estado")
	_comprobar(copia.ruta_retorno_disponible(), "restaurar mantiene salida")

	copia.restaurar_estado({"version_actual": "siglo_imposible", "objetos": {}})
	_comprobar(
		copia.version_actual(),
		SuenoTirNaNog.VERSION_RECIENTE,
		"versión desconocida cae a estado seguro",
	)
	_comprobar(copia.ruta_retorno_disponible(), "estado corrupto tampoco elimina retorno")
	sueno.queue_free()
	copia.queue_free()


func _comprobar(actual, esperado = true, nombre: String = "") -> void:
	if typeof(esperado) == TYPE_STRING and nombre.is_empty():
		nombre = String(esperado)
		esperado = true
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO Tír na nÓg: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
