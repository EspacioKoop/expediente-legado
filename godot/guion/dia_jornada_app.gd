## Capa de #69 sobre el día completo: presenta cada jornada una sola vez.
##
## El calendario ya ha avanzado y el estado ya está guardado cuando se abre la
## cinemática. Esta capa no llama a ninguna regla de Jornada: solo reconoce un
## comienzo por `vuelta:día`, bloquea el cuerpo durante la presentación y
## devuelve el control al mismo archivo al terminar o saltar.
extends "res://guion/dia_tren_app.gd"

const ESCENA_INICIO_JORNADA := preload("res://escenas/cinematica.tscn")
const CLAVE_ULTIMO_INICIO := "inicio_jornada_ultimo"

var _inicio_jornada: Node3D = null


func _entrar_en(fase: String) -> void:
	super._entrar_en(fase)
	if fase == "archivo":
		call_deferred("_abrir_inicio_jornada_si_toca")


## #68 manda al principio de una vida laboral. Cuando termina, #69 puede poner
## la ficha de ese primer día; así no compiten dos reproductores por la pantalla.
func _cerrar_vuelta() -> void:
	super._cerrar_vuelta()
	call_deferred("_abrir_inicio_jornada_si_toca")


## Si el guardado previo al inicio falló, el reintento debe poder recuperar la
## presentación: no se marca una jornada como vista mientras no esté persistida.
func _reintentar_guardado() -> void:
	super._reintentar_guardado()
	if not partida.guardado_pendiente:
		call_deferred("_abrir_inicio_jornada_si_toca")


func _abrir_inicio_jornada_si_toca() -> void:
	if _inicio_jornada != null or _entrada != null or _pantalla != null:
		return
	if partida.guardado_pendiente:
		return
	if jornada.get("fase", "") != "archivo":
		return
	# A mitad de una jornada no aparece porque se recargue o se vuelva del
	# visor. El comienzo tiene todas sus acciones disponibles.
	if int(jornada.get("acciones", 0)) != Jornada.ACCIONES_POR_DIA:
		return

	var marca := InicioJornadaCinematica.marca_de(jornada)
	if String(partida.estado.get(CLAVE_ULTIMO_INICIO, "")) == marca:
		return

	# La marca se escribe ANTES de reproducir. Saltar la escena o cerrar el juego
	# a mitad no puede hacer avanzar el día ni convertir una recarga en otro
	# comienzo. Si el disco falla, se deshace la marca en memoria y no se rueda.
	var anterior := String(partida.estado.get(CLAVE_ULTIMO_INICIO, ""))
	partida.estado[CLAVE_ULTIMO_INICIO] = marca
	if not _guardar_o_avisar(""):
		if anterior.is_empty():
			partida.estado.erase(CLAVE_ULTIMO_INICIO)
		else:
			partida.estado[CLAVE_ULTIMO_INICIO] = anterior
		return

	_caminante.set_physics_process(false)
	_hud.visible = false
	_inicio_jornada = ESCENA_INICIO_JORNADA.instantiate()
	add_child(_inicio_jornada)
	_inicio_jornada.terminada.connect(_cerrar_inicio_jornada)
	var vistas := Cinematica.vistas_de(partida.estado, InicioJornadaCinematica.ID)
	_inicio_jornada.reproducir(
		InicioJornadaCinematica.planos_de(jornada, vistas),
		InicioJornadaCinematica.ID,
		partida.estado
	)


func _cerrar_inicio_jornada() -> void:
	if _inicio_jornada == null:
		return
	_inicio_jornada.queue_free()
	_inicio_jornada = null
	_caminante.set_physics_process(true)
	_hud.visible = true
	# El reproductor acaba de anotar la vista. El día y la marca ya estaban
	# guardados antes de empezar; este segundo guardado solo conserva la cuenta.
	_guardar_o_avisar("")
