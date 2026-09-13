extends SceneTree

const Contexto = preload("res://guion/contexto_careo.gd")

var pasadas := 0
var fallos := 0


func _init() -> void:
	var caso := {
		"id": "caso-prueba",
		"titulo": "CASO_PRUEBA_TITULO",
		"registros":
		[
			{"id": "r1", "folio": "F-1"},
			{"id": "r2", "folio": "F-2"},
		],
		"pistas":
		[
			{"id": "simple", "registroOrigen": "r1", "descripcion": "simple"},
			{
				"id": "relacion-a",
				"registroOrigen": "r1",
				"registroOrigen2": "r2",
				"descripcion": "relación A",
			},
			{
				"id": "relacion-b",
				"registroOrigen": "r2",
				"registroOrigen2": "r1",
				"descripcion": "relación B",
			},
		],
	}
	var otro := {
		"id": "otro",
		"titulo": "OTRO_TITULO",
		"registros": [{"id": "x", "folio": "X-1"}],
		"pistas":
		[
			{
				"id": "ajena",
				"registroOrigen": "x",
				"registroOrigen2": "y",
				"descripcion": "no debe filtrarse",
			}
		],
	}

	comprobar("sin descubrir no hay contexto", Contexto.de_caso(caso, []), {})
	comprobar("una pista simple no basta", Contexto.de_caso(caso, ["simple"]), {})
	comprobar(
		"una relación descubierta se presenta",
		Contexto.de_caso(caso, ["relacion-a"])["id"],
		"relacion-a"
	)
	comprobar(
		"varias relaciones respetan el orden del catálogo",
		Contexto.de_caso(caso, ["relacion-b", "relacion-a"])["id"],
		"relacion-a"
	)
	comprobar(
		"el folio resuelve su caso",
		Contexto.de_folio([caso, otro], "F-2", ["relacion-a"])["id"],
		"relacion-a"
	)
	comprobar("un folio ajeno no filtra contexto", Contexto.de_folio([caso], "X-1", ["ajena"]), {})
	comprobar(
		"la pista ajena se queda en su caso",
		Contexto.de_folio([caso, otro], "X-1", ["ajena"])["id"],
		"ajena"
	)
	comprobar(
		"el título sirve de respaldo estable",
		Contexto.de_folio([caso], "CASO_PRUEBA_TITULO", ["relacion-a"])["id"],
		"relacion-a"
	)

	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func comprobar(nombre: String, obtenido, esperado) -> void:
	if obtenido == esperado:
		pasadas += 1
	else:
		fallos += 1
		printerr("FALLO %s\n  esperado: %s\n  obtenido: %s" % [nombre, esperado, obtenido])
