extends SceneTree

const Pista := preload("res://guion/pista_onirica.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_estado_y_fuentes()
	_probar_pista_de_un_origen()
	_probar_relacion_de_dos_origenes()
	_probar_catalogo_invalido()
	_probar_registro_idempotente()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_estado_y_fuentes() -> void:
	var caso := {"pistas": [{"id": "P-1", "descripcion": "detalle", "registroOrigen": "F-1"}]}
	_comprobar(
		Pista.resolver(caso, {"state": "fallado", "source_ids": ["F-1"]}).is_empty(),
		"un puzzle fallado no concede pista"
	)
	_comprobar(
		Pista.resolver(caso, {"state": "abandonado", "source_ids": ["F-1"]}).is_empty(),
		"un puzzle abandonado no concede pista"
	)
	_comprobar(
		Pista.resolver(caso, {"state": "completado", "source_ids": []}).is_empty(),
		"un puzzle sin fuentes no concede pista"
	)
	_comprobar(
		Pista.resolver(caso, {"state": "completado", "source_ids": ["F-9"]}).is_empty(),
		"una fuente ajena al puzzle no concede pista"
	)


func _probar_pista_de_un_origen() -> void:
	var caso := {
		"pistas": [
			{"id": "P-1", "descripcion": "el sello aparece dos veces", "registroOrigen": "F-1"}
		]
	}
	var resultado := Pista.resolver(
		caso, {"state": "completado", "source_ids": ["F-1"]}
	)
	_comprobar(
		resultado.get("id", "") == "P-1",
		"#161 puede recontextualizar una pista de su único folio"
	)
	_comprobar(
		resultado.get("descripcion", "") == "el sello aparece dos veces",
		"conserva la descripción catalogada"
	)
	_comprobar(
		resultado.get("fuentes", []) == ["F-1"],
		"devuelve únicamente el origen catalogado"
	)

	var duplicadas := Pista.resolver(
		caso, {"state": "completado", "source_ids": ["F-1", "F-1", ""]}
	)
	_comprobar(duplicadas.get("id", "") == "P-1", "normaliza fuentes duplicadas y vacías")


func _probar_relacion_de_dos_origenes() -> void:
	var caso := {
		"pistas": [
			{
				"id": "P-2",
				"descripcion": "las fechas no encajan",
				"registroOrigen": "F-1",
				"registroOrigen2": "F-2",
			}
		]
	}
	var completa := Pista.resolver(
		caso, {"state": "completado", "source_ids": ["F-2", "F-1"]}
	)
	_comprobar(
		completa.get("id", "") == "P-2",
		"una relación se concede cuando ambos orígenes participaron"
	)
	_comprobar(
		completa.get("fuentes", []) == ["F-1", "F-2"],
		"conserva los dos orígenes catalogados"
	)
	_comprobar(
		Pista.resolver(caso, {"state": "completado", "source_ids": ["F-1"]}).is_empty(),
		"una relación no se concede con solo uno de sus orígenes"
	)


func _probar_catalogo_invalido() -> void:
	var sin_id := {"pistas": [{"descripcion": "detalle", "registroOrigen": "F-1"}]}
	_comprobar(
		Pista.resolver(sin_id, {"state": "completado", "source_ids": ["F-1"]}).is_empty(),
		"rechaza pistas catalogadas sin identidad"
	)

	var sin_origen := {"pistas": [{"id": "P-X", "descripcion": "detalle"}]}
	_comprobar(
		Pista.resolver(sin_origen, {"state": "completado", "source_ids": ["F-1"]}).is_empty(),
		"rechaza pistas sin origen"
	)

	var segundo_vacio := {
		"pistas": [
			{
				"id": "P-X",
				"descripcion": "relación",
				"registroOrigen": "F-1",
				"registroOrigen2": "",
			}
		]
	}
	_comprobar(
		Pista.resolver(segundo_vacio, {"state": "completado", "source_ids": ["F-1"]}).is_empty(),
		"rechaza relaciones con segundo origen vacío"
	)

	var mismo_origen := {
		"pistas": [
			{
				"id": "P-X",
				"descripcion": "relación",
				"registroOrigen": "F-1",
				"registroOrigen2": "F-1",
			}
		]
	}
	_comprobar(
		Pista.resolver(mismo_origen, {"state": "completado", "source_ids": ["F-1"]}).is_empty(),
		"rechaza una falsa relación del documento consigo mismo"
	)


func _probar_registro_idempotente() -> void:
	var estado := {"pistas_descubiertas": []}
	_comprobar(Pista.registrar(estado, {"id": "P-1"}), "registra una recompensa catalogada")
	_comprobar(
		estado["pistas_descubiertas"] == ["P-1"],
		"persiste únicamente el id de la pista"
	)
	_comprobar(
		Pista.registrar(estado, {"id": "P-1"}),
		"repetir el registro sigue siendo una operación válida"
	)
	_comprobar(estado["pistas_descubiertas"] == ["P-1"], "reintentar no duplica la recompensa")

	var legado := {}
	_comprobar(
		Pista.registrar(legado, {"id": "P-2"}),
		"inicializa la lista ausente de una partida antigua"
	)
	_comprobar(
		legado["pistas_descubiertas"] == ["P-2"],
		"la migración mínima conserva solo el id"
	)

	var roto := {"pistas_descubiertas": {}}
	_comprobar(
		not Pista.registrar(roto, {"id": "P-3"}),
		"rechaza un estado con lista de pistas mal formada"
	)
	_comprobar(not Pista.registrar(estado, {}), "rechaza una recompensa sin identidad")


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO Pista onírica: " + nombre)
