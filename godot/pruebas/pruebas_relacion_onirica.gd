extends SceneTree

const Relacion := preload("res://guion/relacion_onirica.gd")
const Puzzle := preload("res://guion/puzzle_onirico.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_fuentes_y_distractor()
	_probar_determinismo_y_contenido()
	_probar_acierto()
	_probar_fallo_unico()
	_probar_restauracion_pendiente()
	_probar_restauracion_terminal_y_manipulada()
	_probar_abandono_y_serializacion()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _caso() -> Dictionary:
	return {
		"id": "caso-relacion",
		"registros":
		[
			{
				"id": "r1",
				"folio": "F-1",
				"tipo": "MEMO",
				"fecha": "1999-01-01",
				"contenido": "El pago se autorizó antes de completar la revisión administrativa.",
			},
			{
				"id": "r2",
				"folio": "F-2",
				"tipo": "ACTA",
				"fecha": "1999-01-02",
				"contenido":
				"El acta afirma que la revisión ya estaba completada al aprobar el pago.",
			},
			{
				"id": "r3",
				"folio": "F-3",
				"tipo": "EMPLEADO",
				"fecha": "1999-01-03",
				"contenido": "Una ficha de personal sin relación directa con la autorización.",
			},
			{
				"id": "r4",
				"folio": "F-4",
				"tipo": "FACTURA",
				"fecha": "1999-01-04",
				"contenido": "Una factura adicional leída el mismo día.",
			},
		],
		"pistas":
		[
			{
				"id": "P-REL",
				"registroOrigen": "r1",
				"registroOrigen2": "r2",
				"descripcion": "La autorización y el acta no encajan entre sí.",
			}
		],
	}


func _pista() -> Dictionary:
	return _caso()["pistas"][0]


func _probar_fuentes_y_distractor() -> void:
	var caso := _caso()
	var pista: Dictionary = caso["pistas"][0]
	_comprobar(
		Relacion.crear(caso, pista, ["F-1", "F-2"], 17) == null,
		"sin tercer documento leído no monta una pareja trivial",
	)
	_comprobar(
		Relacion.crear(caso, pista, ["F-1", "F-3", "F-4"], 17) == null,
		"rechaza una relación si falta uno de sus dos orígenes",
	)
	var relacion = Relacion.crear(caso, pista, ["F-1", "F-2", "F-3"], 17)
	_comprobar(relacion != null, "crea la relación al leer dos orígenes y un distractor")
	_comprobar(relacion.documentos.size() == 3, "presenta tres documentos cuando hay un distractor")
	_comprobar(
		relacion.nucleo.reward_id == "P-REL", "dirige la recompensa a la relación catalogada"
	)
	_comprobar(
		relacion.nucleo.source_ids == ["F-1", "F-2"],
		"el núcleo solo declara como fuentes los dos documentos relacionados",
	)


func _probar_determinismo_y_contenido() -> void:
	var caso := _caso()
	var pista: Dictionary = caso["pistas"][0]
	var leidos := ["F-1", "F-2", "F-3", "F-4"]
	var a = Relacion.crear(caso, pista, leidos, 991)
	var b = Relacion.crear(caso, pista, leidos, 991)
	_comprobar(a != null and b != null, "crea la misma relación con cuatro documentos leídos")
	var ids_a: Array = a.documentos.map(func(d): return d["id"])
	var ids_b: Array = b.documentos.map(func(d): return d["id"])
	_comprobar(ids_a == ids_b, "misma semilla conserva distractores y presentación")
	_comprobar(
		a.documentos.size() == Relacion.MAX_DOCUMENTOS, "limita la presentación a cuatro documentos"
	)
	for documento in a.documentos:
		_comprobar(
			not String(documento.get("extracto", "")).contains("no encajan entre sí"),
			"antes de resolver solo muestra texto del documento, no la conclusión",
		)


func _probar_acierto() -> void:
	var caso := _caso()
	var relacion = Relacion.crear(caso, caso["pistas"][0], ["F-1", "F-2", "F-3"], 45)
	var i1 := _indice(relacion.documentos, "r1")
	var i2 := _indice(relacion.documentos, "r2")
	_comprobar(i1 >= 0 and i2 >= 0, "los dos orígenes están presentes")
	_comprobar(relacion.seleccionar(i1) == "seleccionado", "la primera elección no resuelve sola")
	_comprobar(relacion.seleccionar(i2) == "completado", "la pareja correcta completa el puzzle")
	_comprobar(
		relacion.nucleo.state == Puzzle.ESTADO_COMPLETADO,
		"el acierto deja el núcleo en completado",
	)
	_comprobar(relacion.cerrada, "tras acertar la pareja queda cerrada")
	_comprobar(relacion.seleccionar(i1) == "cerrado", "no permite volver a cobrar la relación")


func _probar_fallo_unico() -> void:
	var caso := _caso()
	var relacion = Relacion.crear(caso, caso["pistas"][0], ["F-1", "F-2", "F-3"], 45)
	var i1 := _indice(relacion.documentos, "r1")
	var i3 := _indice(relacion.documentos, "r3")
	_comprobar(relacion.seleccionar(i1) == "seleccionado", "puede fijar un primer documento")
	_comprobar(relacion.seleccionar(i3) == "fallado", "una pareja incorrecta termina el intento")
	_comprobar(
		relacion.nucleo.state == Puzzle.ESTADO_FALLADO,
		"el error deja estado terminal y evita fuerza bruta",
	)
	_comprobar(
		relacion.seleccionar(_indice(relacion.documentos, "r2")) == "cerrado",
		"no hay segundo intento"
	)
	_comprobar(relacion.salir(), "fallar no bloquea la salida segura")


func _probar_restauracion_pendiente() -> void:
	var caso := _caso()
	var pista: Dictionary = caso["pistas"][0]
	var leidos := ["F-1", "F-2", "F-3", "F-4"]
	var relacion = Relacion.crear(caso, pista, leidos, 811)
	var ids_antes: Array = relacion.documentos.map(func(d): return d["id"])
	_comprobar(
		relacion.seleccionar(_indice(relacion.documentos, "r1")) == "seleccionado",
		"puede guardar una relación después de la primera elección",
	)
	var texto := JSON.stringify(relacion.serializar())
	var datos: Dictionary = JSON.parse_string(texto)
	var restaurada = Relacion.restaurar(datos, caso, pista, leidos)
	_comprobar(restaurada != null, "restaura una relación pendiente tras pasar por JSON")
	_comprobar(
		restaurada.documentos.map(func(d): return d["id"]) == ids_antes,
		"la recarga conserva exactamente el tablero derivado de la semilla",
	)
	_comprobar(restaurada.seleccion == ["r1"], "la recarga conserva la primera elección")
	_comprobar(not restaurada.cerrada, "la selección parcial sigue pendiente")
	_comprobar(
		restaurada.seleccionar(_indice(restaurada.documentos, "r2")) == "completado",
		"puede terminar correctamente desde la selección restaurada",
	)


func _probar_restauracion_terminal_y_manipulada() -> void:
	var caso := _caso()
	var pista: Dictionary = caso["pistas"][0]
	var leidos := ["F-1", "F-2", "F-3"]
	var fallida = Relacion.crear(caso, pista, leidos, 912)
	fallida.seleccionar(_indice(fallida.documentos, "r1"))
	fallida.seleccionar(_indice(fallida.documentos, "r3"))
	var datos: Dictionary = JSON.parse_string(JSON.stringify(fallida.serializar()))
	var restaurada = Relacion.restaurar(datos, caso, pista, leidos)
	_comprobar(restaurada != null, "restaura un fallo terminal válido")
	_comprobar(
		restaurada.nucleo.state == Puzzle.ESTADO_FALLADO,
		"recargar no devuelve un fallo al estado pendiente",
	)
	_comprobar(restaurada.cerrada, "un fallo restaurado permanece cerrado")
	_comprobar(
		restaurada.seleccionar(_indice(restaurada.documentos, "r2")) == "cerrado",
		"recargar no concede un segundo intento",
	)

	var abierta := datos.duplicate(true)
	abierta["cerrada"] = false
	_comprobar(
		Relacion.restaurar(abierta, caso, pista, leidos) == null,
		"rechaza reabrir a mano un resultado terminal",
	)
	var falsa := datos.duplicate(true)
	falsa["seleccion"] = ["r1", "r2"]
	_comprobar(
		Relacion.restaurar(falsa, caso, pista, leidos) == null,
		"rechaza cambiar la pareja después de conocer el fallo",
	)
	var mal_tipo := datos.duplicate(true)
	mal_tipo["seleccion"] = "r1"
	_comprobar(
		Relacion.restaurar(mal_tipo, caso, pista, leidos) == null,
		"rechaza una selección serializada con tipo inválido",
	)

	var completada = Relacion.crear(caso, pista, leidos, 913)
	completada.seleccionar(_indice(completada.documentos, "r1"))
	completada.seleccionar(_indice(completada.documentos, "r2"))
	var restaurada_ok = Relacion.restaurar(completada.serializar(), caso, pista, leidos)
	var resultados: Array = []
	restaurada_ok.nucleo.resultado.connect(func(resultado): resultados.append(resultado))
	_comprobar(
		restaurada_ok.seleccionar(_indice(restaurada_ok.documentos, "r1")) == "cerrado",
		"un acierto restaurado tampoco puede ejecutarse otra vez",
	)
	_comprobar(resultados.is_empty(), "restaurar no reemite la recompensa ya consumida")


func _probar_abandono_y_serializacion() -> void:
	var caso := _caso()
	var relacion = Relacion.crear(caso, caso["pistas"][0], ["F-1", "F-2", "F-3"], 73)
	_comprobar(relacion.salir(), "se puede abandonar antes de elegir pareja")
	_comprobar(
		relacion.nucleo.state == Puzzle.ESTADO_ABANDONADO,
		"abandonar queda distinguido de fallar",
	)
	var datos: Dictionary = relacion.serializar()
	_comprobar(datos.get("cerrada", false), "serializa que la relación ya está cerrada")
	_comprobar(
		datos.get("nucleo", {}).get("reward_id", "") == "P-REL",
		"serializa la identidad de recompensa sin copiar la conclusión",
	)


func _indice(documentos: Array, registro_id: String) -> int:
	for indice in range(documentos.size()):
		if String(documentos[indice].get("id", "")) == registro_id:
			return indice
	return -1


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO Relación onírica: " + nombre)
