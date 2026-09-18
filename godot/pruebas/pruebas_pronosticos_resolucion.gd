extends SceneTree

const CASO := {
	"id": "caso-pronostico",
	"registros":
	[
		{"id": "factura", "tipo": "FACTURA"},
		{"id": "memo", "tipo": "MEMORANDO"},
		{"id": "acta", "tipo": "ACTA"},
	],
	"pistas":
	[
		{"id": "p1", "registroOrigen": "factura"},
		{"id": "p2", "registroOrigen": "factura", "registroOrigen2": "memo"},
		{"id": "p3", "registroOrigen": "acta"},
	],
}

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	_probar_careo()
	_probar_precipitacion()
	_probar_cierre_y_arrastre()
	_probar_documento_clave()
	_probar_empate_documental()
	_probar_fin_de_jornada()
	_probar_estados_terminales()
	_probar_sin_efectos_sistemicos()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_careo() -> void:
	var estado := _estado_con("caso-careo", "habra_duelo", true)
	var caso := {"id": "caso-careo", "registros": [], "pistas": []}
	var resultado := {"resultado": "cerrado", "duelo": {"id": "rival"}, "precipitada": false}
	var resuelto := PronosticosAuditoria.resolver_cierre(estado, caso, resultado)
	_comprobar(resuelto == Pronosticos.ESTADO_ACERTADO, "careo usa el duelo real de la firma")


func _probar_precipitacion() -> void:
	var estado := _estado_con("caso-prisa", "acusacion_precipitada", false)
	var caso := {"id": "caso-prisa", "registros": [], "pistas": []}
	var resultado := {"resultado": "cerrado", "duelo": {}, "precipitada": true}
	var resuelto := PronosticosAuditoria.resolver_cierre(estado, caso, resultado)
	_comprobar(resuelto == Pronosticos.ESTADO_FALLADO, "precipitada compara el hecho real")


func _probar_cierre_y_arrastre() -> void:
	var cierre := _estado_con("caso-cierre", "cierre_hoy", true)
	var caso_cierre := {"id": "caso-cierre", "registros": [], "pistas": []}
	var resultado := {"resultado": "cerrado", "duelo": {}, "precipitada": false}
	_comprobar(
		(
			PronosticosAuditoria.resolver_cierre(cierre, caso_cierre, resultado)
			== Pronosticos.ESTADO_ACERTADO
		),
		"firmar confirma cierre hoy",
	)

	var arrastre := _estado_con("caso-arrastre", "arrastra_manana", true)
	var caso_arrastre := {"id": "caso-arrastre", "registros": [], "pistas": []}
	_comprobar(
		(
			PronosticosAuditoria.resolver_cierre(arrastre, caso_arrastre, resultado)
			== Pronosticos.ESTADO_FALLADO
		),
		"firmar descarta arrastre a mañana",
	)


func _probar_documento_clave() -> void:
	var estado := _estado_con(String(CASO["id"]), "documento_clave", "FACTURA")
	estado["pistas_descubiertas"] = ["p1", "p2"]
	_comprobar(
		PronosticosAuditoria.tipo_documento_clave(CASO, estado["pistas_descubiertas"]) == "FACTURA",
		"documento clave sale de pistas descubiertas",
	)
	var resultado := {"resultado": "cerrado", "duelo": {}, "precipitada": false}
	_comprobar(
		(
			PronosticosAuditoria.resolver_cierre(estado, CASO, resultado)
			== Pronosticos.ESTADO_ACERTADO
		),
		"la categoría documental resuelve la apuesta",
	)


func _probar_empate_documental() -> void:
	var estado := _estado_con(String(CASO["id"]), "documento_clave", "FACTURA")
	estado["pistas_descubiertas"] = ["p2"]
	_comprobar(
		PronosticosAuditoria.tipo_documento_clave(CASO, estado["pistas_descubiertas"]) == null,
		"un empate documental no inventa ganador",
	)
	var resultado := {"resultado": "cerrado", "duelo": {}, "precipitada": false}
	_comprobar(
		(
			PronosticosAuditoria.resolver_cierre(estado, CASO, resultado)
			== Pronosticos.ESTADO_SIN_RESOLVER
		),
		"empate termina como sin resolver",
	)


func _probar_fin_de_jornada() -> void:
	var estado := Partida.nueva()
	Pronosticos.crear(estado["pronosticos"], "abierto-cierre", "cierre_hoy", false)
	Pronosticos.crear(estado["pronosticos"], "abierto-arrastre", "arrastra_manana", true)
	Pronosticos.crear(estado["pronosticos"], "cerrado-cierre", "cierre_hoy", true)
	Pronosticos.crear(estado["pronosticos"], "cerrado-arrastre", "arrastra_manana", false)
	Pronosticos.crear(estado["pronosticos"], "espera-firma", "habra_duelo", true)
	estado["veredictos"]["cerrado-cierre"] = "sospechoso"
	estado["veredictos"]["cerrado-arrastre"] = "sospechoso"

	_comprobar(
		PronosticosAuditoria.resolver_fin_jornada(estado) == 4,
		"fin de jornada solo resuelve apuestas temporales",
	)
	for expediente_id in [
		"abierto-cierre", "abierto-arrastre", "cerrado-cierre", "cerrado-arrastre"
	]:
		_comprobar(
			(
				Pronosticos.estado_de(estado["pronosticos"], expediente_id)
				== Pronosticos.ESTADO_ACERTADO
			),
			"hecho temporal resuelto: " + expediente_id,
		)
	_comprobar(
		Pronosticos.estado_de(estado["pronosticos"], "espera-firma") == Pronosticos.ESTADO_ABIERTO,
		"careo no se decide por cambiar de jornada",
	)


func _probar_estados_terminales() -> void:
	var estado := _estado_con("caso-abandono", "cierre_hoy", true)
	Pronosticos.abandonar(estado["pronosticos"], "caso-abandono")
	var caso := {"id": "caso-abandono", "registros": [], "pistas": []}
	var resultado := {"resultado": "cerrado", "duelo": {}, "precipitada": false}
	_comprobar(
		(
			PronosticosAuditoria.resolver_cierre(estado, caso, resultado)
			== Pronosticos.ESTADO_ABANDONADO
		),
		"resolver no reabre una apuesta abandonada",
	)

	var pendiente := _estado_con("caso-pendiente", "habra_duelo", false)
	var caso_pendiente := {"id": "caso-pendiente", "registros": [], "pistas": []}
	_comprobar(
		(
			PronosticosAuditoria.resolver_cierre(
				pendiente, caso_pendiente, {"resultado": "sin_acciones"}
			)
			== Pronosticos.ESTADO_ABIERTO
		),
		"una firma rechazada no resuelve",
	)


func _probar_sin_efectos_sistemicos() -> void:
	var estado := _estado_con("caso-neutro", "cierre_hoy", false)
	var jornada_antes: Dictionary = estado["jornada"].duplicate(true)
	var vida_antes: int = estado["vida"]
	var veredictos_antes: Dictionary = estado["veredictos"].duplicate(true)
	PronosticosAuditoria.resolver_fin_jornada(estado)
	_comprobar(estado["jornada"] == jornada_antes, "resolver no consume jornada")
	_comprobar(estado["vida"] == vida_antes, "resolver no toca vidas")
	_comprobar(estado["veredictos"] == veredictos_antes, "resolver no crea veredictos")


func _estado_con(expediente_id: String, tipo: String, valor: Variant) -> Dictionary:
	var estado := Partida.nueva()
	Pronosticos.crear(estado["pronosticos"], expediente_id, tipo, valor)
	return estado


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO PronosticosResolucion: " + nombre)
