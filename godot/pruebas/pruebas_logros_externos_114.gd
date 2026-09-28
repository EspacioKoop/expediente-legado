extends SceneTree


class BackendFalso:
	extends LogrosBackend

	var activo := true
	var publicados: Array[String] = []
	var llamadas_desbloquear: Array[String] = []
	var guardados := 0
	var fallar_ids: Array[String] = []

	func disponible() -> bool:
		return activo

	func esta_desbloqueado(logro_id: String) -> bool:
		return publicados.has(logro_id)

	func desbloquear(logro_id: String) -> bool:
		llamadas_desbloquear.append(logro_id)
		if fallar_ids.has(logro_id):
			return false
		if not publicados.has(logro_id):
			publicados.append(logro_id)
		return true

	func guardar() -> bool:
		guardados += 1
		return true


var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	_probar_backend_nulo()
	_probar_publicacion_idempotente()
	_probar_fallo_no_muta_local()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _estado() -> Dictionary:
	return {
		"logros":
		[
			{"id": "zeta", "desbloqueado": true, "por_vuelta": true},
			{"id": "alfa", "desbloqueado": true, "por_vuelta": false},
			{"id": "bloqueado", "desbloqueado": false, "por_vuelta": false},
			{"id": "alfa", "desbloqueado": true, "por_vuelta": false},
		]
	}


func _probar_backend_nulo() -> void:
	var estado := _estado()
	var antes := estado.duplicate(true)
	var resultado := LogrosExternos.sincronizar(estado, LogrosBackendNulo.new())
	_comprobar(not resultado["backend_disponible"], "el backend nulo declara plataforma ausente")
	_comprobar(resultado["publicados"].is_empty(), "sin plataforma no publica")
	_comprobar(estado == antes, "sin plataforma no toca el estado local")
	_comprobar(
		resultado["candidatos"] == ["alfa", "zeta"],
		"los candidatos son ids desbloqueados, únicos y estables",
	)


func _probar_publicacion_idempotente() -> void:
	var estado := _estado()
	var backend := BackendFalso.new()
	var primera := LogrosExternos.sincronizar(estado, backend)
	_comprobar(primera["publicados"] == ["alfa", "zeta"], "publica los dos logros desbloqueados")
	_comprobar(backend.guardados == 1, "guarda stats una vez tras publicar novedades")

	var segunda := LogrosExternos.sincronizar(estado, backend)
	_comprobar(segunda["publicados"].is_empty(), "repetir sincronización no desbloquea de nuevo")
	_comprobar(
		segunda["ya_publicados"] == ["alfa", "zeta"],
		"el backend reconoce los logros ya publicados",
	)
	_comprobar(backend.guardados == 1, "sin novedades no vuelve a guardar stats")
	_comprobar(
		backend.llamadas_desbloquear == ["alfa", "zeta"],
		"cada logro se envía una sola vez",
	)


func _probar_fallo_no_muta_local() -> void:
	var estado := _estado()
	var antes := estado.duplicate(true)
	var backend := BackendFalso.new()
	backend.fallar_ids = ["zeta"]
	var resultado := LogrosExternos.sincronizar(estado, backend)
	_comprobar(resultado["publicados"] == ["alfa"], "un logro válido se publica aunque otro falle")
	_comprobar(resultado["fallidos"] == ["zeta"], "el fallo externo queda explícito")
	_comprobar(estado == antes, "el fallo externo nunca reescribe Prometeo/Partida")
	_comprobar(backend.guardados == 1, "las novedades válidas aún se guardan")


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO LogrosExternos114: " + nombre)
