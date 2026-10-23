## Prueba de escena real del primer cuarto 3D de Crónicas (#2589).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar_escena")


func _probar_escena() -> void:
	var escena := load("res://escenas/cronicas/bastion_nombres_ausentes.tscn") as PackedScene
	_comprobar(escena != null, "PackedScene existe")
	if escena == null:
		_terminar()
		return

	var sala := escena.instantiate() as CronicasBastion3D
	_comprobar(sala != null, "controlador 3D original existe")
	if sala == null:
		_terminar()
		return

	get_root().add_child(sala)
	await process_frame

	var jugador := sala.get_node_or_null("Caminante")
	_comprobar(jugador is CharacterBody3D, "reutiliza Caminante canónico")
	_comprobar(jugador.get_node_or_null("Camara") is Camera3D, "cámara real controlada")
	_comprobar(sala.get_node_or_null("Suelo") is StaticBody3D, "suelo con colisión")
	_comprobar(sala.get_node_or_null("MuroNorte") is StaticBody3D, "límite navegable")
	_comprobar(sala.get_node_or_null("InterfazCronicas") is CanvasLayer, "HUD legible")

	var inicial: Dictionary = sala.estado_local()
	_comprobar(inicial["lecturas"] == 0 and not inicial["duelo_resuelto"], "sin progreso inventado")
	_comprobar(not sala.puede_combatir() and not sala.puede_salir(), "sin saltar lectura")

	var libro := sala.get_node("DosCronicas") as Interactuable3D
	_comprobar(libro != null and libro.habilitado, "libro real interactuable")
	libro.interactuar(jugador)
	_comprobar(sala.estado_local()["lecturas"] == 1, "primera crónica")
	_comprobar(not sala.puede_combatir(), "no combate sin leer versión contraria")
	libro.interactuar(jugador)
	_comprobar(sala.estado_local()["lecturas"] == 2, "segunda crónica")
	_comprobar(sala.puede_combatir(), "duelo tras las dos crónicas")
	libro.interactuar(jugador)
	_comprobar(sala.estado_local()["lecturas"] == 2, "lectura idempotente")

	var custodio := sala.get_node("Custodio") as Interactuable3D
	_comprobar(custodio.habilitado, "custodio se desbloquea")
	custodio.interactuar(jugador)
	_comprobar(sala.estado_local()["en_combate"], "interacción abre duelo existente")
	_comprobar(sala.get_node_or_null("DueloCustodio") is JuicioCombate3D, "usa JuicioCombate3D")
	_comprobar(not sala.puede_salir(), "batalla pendiente no concede salida")
	sala._al_terminar_combate(false)
	await process_frame
	_comprobar(sala.puede_combatir(), "tras derrota puede reintentar")
	_comprobar(not sala.puede_salir(), "derrota no da acceso")
	_comprobar(
		(jugador as CharacterBody3D).process_mode == Node.PROCESS_MODE_INHERIT,
		"se restaura movimiento tras combate"
	)

	var completados := [0]
	sala.completado.connect(func(): completados[0] += 1)
	sala.registrar_resultado_duelo(true)
	_comprobar(sala.puede_salir(), "victoria local habilita umbral")
	_comprobar(sala.solicitar_salida(), "salida accesible tras encuentro")
	_comprobar(completados[0] == 1, "una señal de cierre")
	_comprobar(not sala.solicitar_salida(), "sin segundo cierre")
	_comprobar(completados[0] == 1, "cierre idempotente")

	get_root().remove_child(sala)
	sala.free()
	await process_frame
	await _probar_archivo_cronista()
	_terminar()


func _probar_archivo_cronista() -> void:
	var escena := load("res://escenas/cronicas/archivo_cronista.tscn") as PackedScene
	_comprobar(escena != null, "Archivo del Cronista carga como escena")
	if escena == null:
		return

	var archivo := escena.instantiate() as CronicasArchivoCronista3D
	_comprobar(archivo != null, "controlador del Archivo del Cronista existe")
	if archivo == null:
		return

	get_root().add_child(archivo)
	await process_frame
	var mural := archivo.get_node_or_null("MuroNombres") as Node3D
	var placa := mural.get_node_or_null("PlacaRaspada_0") if mural != null else null
	_comprobar(mural != null and placa is MeshInstance3D, "arcada y placa de memoria visibles")

	var rotulo := mural.get_node_or_null("RotuloNombres") as Label3D if mural != null else null
	_comprobar(
		(
			rotulo != null
			and rotulo.text == TranslationServer.translate("CRONICAS_ARCHIVO_MURO_NOMBRES")
		),
		"rotulo de memoria localizado",
	)
	var objetivo := archivo.find_child("Objetivo", true, false) as Label
	_comprobar(
		(
			objetivo != null
			and objetivo.text == TranslationServer.translate("CRONICAS_ARCHIVO_OBJETIVO")
		),
		"objetivo del archivo localizado",
	)

	var inicial: Dictionary = archivo.estado_local()
	_comprobar(
		not bool(inicial["muro_nombres_inspeccionado"]) and int(inicial["conteo_actas"]) == 0,
		"la pista empieza local y sin lecturas",
	)
	var interactuable := archivo.get_node_or_null("MuroNombresInteractuable") as Interactuable3D
	var jugador := archivo.get_node_or_null("Caminante")
	_comprobar(interactuable != null, "muro de nombres interactuable")
	_comprobar(jugador is CharacterBody3D, "se conserva el caminante real")
	if interactuable != null and jugador != null:
		interactuable.interactuar(jugador)

	var tras_inspeccion: Dictionary = archivo.estado_local()
	_comprobar(
		(
			bool(tras_inspeccion["muro_nombres_inspeccionado"])
			and int(tras_inspeccion["conteo_actas"]) == 0
			and not bool(tras_inspeccion["fuga_abierta"])
		),
		"inspeccionar el muro no altera la progresión",
	)
	_comprobar(
		(
			objetivo != null
			and objetivo.text == TranslationServer.translate("CRONICAS_ARCHIVO_NOMBRES_FRAGMENTO")
		),
		"el muro revela la manipulación de los nombres",
	)
	_comprobar(not archivo.seleccionar_version(1), "el muro no salta las actas")
	archivo.inspeccionar_acta(0)
	archivo.inspeccionar_acta(1)
	archivo.inspeccionar_acta(2)
	_comprobar(archivo.seleccionar_version(1), "el acta fundamentada aún abre la fuga")
	var final: Dictionary = archivo.estado_local()
	_comprobar(bool(final["fuga_abierta"]), "el Cronista admite el borrado y habilita la salida")
	_comprobar(
		(
			objetivo != null
			and (
				objetivo.text
				== TranslationServer.translate("CRONICAS_ARCHIVO_VERSION_FUNDAMENTADA")
			)
		),
		"la confesión del Cronista está localizada",
	)

	get_root().remove_child(archivo)
	archivo.free()
	await process_frame


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("Crónicas sala: " + nombre)


func _terminar() -> void:
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)
