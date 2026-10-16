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
	_terminar()


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("Crónicas sala: " + nombre)


func _terminar() -> void:
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)
