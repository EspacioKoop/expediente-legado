extends SceneTree

const Bandeja := preload("res://guion/archivado_bandeja.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_dialogo()
	_probar_desorden_derivado()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_dialogo() -> void:
	_comprobar(
		DialogoArchivadoCompaneros.resolver("becario", 0).is_empty(),
		"sin desorden conserva el diálogo base",
	)
	_comprobar(
		DialogoArchivadoCompaneros.resolver("becario", 1) == "COMPA_ARCHIVO_BECARIO_LEVE",
		"un error produce comentario leve",
	)
	_comprobar(
		DialogoArchivadoCompaneros.resolver("becario", 2) == "COMPA_ARCHIVO_BECARIO_LEVE",
		"dos errores siguen en nivel leve",
	)
	_comprobar(
		DialogoArchivadoCompaneros.resolver("becario", 3) == "COMPA_ARCHIVO_BECARIO_ALTO",
		"tres errores cruzan el umbral alto",
	)
	_comprobar(
		DialogoArchivadoCompaneros.resolver("telefono", 4).is_empty(),
		"un actor sin línea específica conserva su diálogo normal",
	)


func _probar_desorden_derivado() -> void:
	var caso := {
		"id": "caso-prueba",
		"anioSuceso": 1998,
		"estado": "ABIERTO",
		"confidencial": false,
		"registros": [{"folio": "F-1998-001"}],
	}
	var estado := Bandeja.nueva([caso], ["F-1998-001"])
	var sesion := ArchivadoSesion3D.new()
	sesion._estado_archivado = estado
	_comprobar(sesion.desorden_total() == 0, "sesión ordenada informa cero")

	Bandeja.colocar(estado, caso, "1980-ABIERTO-GENERAL")
	_comprobar(sesion.desorden_total() == 1, "el primer error se expone al diálogo")
	Bandeja.colocar(estado, caso, "1970-CERRADO-GENERAL")
	_comprobar(sesion.desorden_total() == 2, "el total suma destinos distintos")

	Bandeja.colocar(estado, caso, Archivado.destino_de(caso))
	_comprobar(
		sesion.desorden_total() == 0,
		"corregir el caso elimina también la reacción narrativa",
	)


func _comprobar(actual, esperado = true, nombre: String = "") -> void:
	if typeof(esperado) == TYPE_STRING and nombre.is_empty():
		nombre = String(esperado)
		esperado = true
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO diálogo archivado #965: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
