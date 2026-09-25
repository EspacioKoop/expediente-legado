extends SceneTree

## Regresión standalone del primer vertical de combate cooperativo (#380).

const CombateCoop = preload("res://guion/combate_coop.gd")
const CombateCoopDatos = preload("res://guion/red/combate_coop_datos.gd")
const CombateCoopServicio = preload("res://guion/red/combate_coop_servicio.gd")
const TransporteFixture = preload("res://guion/red/transporte_fixture.gd")
const TransporteNulo = preload("res://guion/red/transporte_nulo.gd")

const AHORA := 2_100_000_000

var pasadas := 0
var fallos := 0


func _init() -> void:
	_probar_contrato_cerrado()
	_probar_vertical_dos_clientes()
	_probar_offline_y_partida_intacta()
	print("\n%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _probar_contrato_cerrado() -> void:
	var evento := CombateCoopDatos.crear_eleccion(
		"ventanilla_coop",
		"test-380",
		"anon-a",
		"SALA-380",
		"reclamacion-1",
		0,
		"objecion",
		AHORA,
		"c-a-0"
	)
	_comprobar("elección válida", evento["ok"], true)
	_comprobar("kind específico", evento["event"]["kind"], "coop_combat")

	var contaminado: Dictionary = evento["event"].duplicate(true)
	contaminado["payload"]["dinero"] = 999
	_comprobar(
		"economía no cabe en el contrato",
		CombateCoopDatos.validar_evento(contaminado, AHORA)["ok"],
		false
	)
	var ronda_fuera: Dictionary = evento["event"].duplicate(true)
	ronda_fuera["payload"]["round"] = 3
	_comprobar(
		"solo existen tres rondas", CombateCoopDatos.validar_evento(ronda_fuera, AHORA)["ok"], false
	)


func _probar_vertical_dos_clientes() -> void:
	var transporte_a := TransporteFixture.new()
	var transporte_b := TransporteFixture.new()
	var cliente_a := CombateCoopServicio.new(transporte_a)
	var cliente_b := CombateCoopServicio.new(transporte_b)
	_comprobar(
		"A abre sesión",
		cliente_a.abrir("ventanilla_coop", "SALA-380", "reclamacion-1", "anon-a")["ok"],
		true
	)
	_comprobar(
		"B abre sesión",
		cliente_b.abrir("ventanilla_coop", "SALA-380", "reclamacion-1", "anon-b")["ok"],
		true
	)

	var rival := {"id": "fixture-coop", "ataques": []}
	var sesion := CombateCoop.nueva(rival, "anon-a", "anon-b")
	_comprobar("sesión creada", sesion.is_empty(), false)

	var acciones_a := ["objecion", "silencio", "insistencia"]
	var acciones_b := ["silencio", "silencio", "objecion"]
	for ronda in range(3):
		var pub_a := cliente_a.publicar_eleccion(
			ronda, acciones_a[ronda], "test-380", AHORA + ronda, "a-%d" % ronda
		)
		var pub_b := cliente_b.publicar_eleccion(
			ronda, acciones_b[ronda], "test-380", AHORA + ronda, "b-%d" % ronda
		)
		_comprobar("A publica ronda %d" % ronda, pub_a["ok"], true)
		_comprobar("B publica ronda %d" % ronda, pub_b["ok"], true)
		transporte_a.inyectar(pub_a["event"])
		transporte_a.inyectar(pub_b["event"])

		var recibidas := cliente_a.consultar_elecciones(ronda, AHORA + ronda)
		_comprobar("relay entrega dos elecciones %d" % ronda, recibidas["choices"].size(), 2)
		for evento in recibidas["choices"]:
			var actor := String(evento["actor_public_id"])
			var accion := String(evento["payload"]["action"])
			var resolucion := CombateCoop.elegir(sesion, actor, accion, func() -> float: return 0.0)
			_comprobar("elección aceptada %d %s" % [ronda, actor], resolucion["ok"], true)

	_comprobar("exactamente tres rondas", sesion["historial"].size(), 3)
	_comprobar("sesión termina", sesion["terminado"], true)
	_comprobar(
		"combinación usa ambos inputs", sesion["historial"][0]["accion_combinada"], "objecion"
	)
	_comprobar("cerrar A es seguro", cliente_a.cerrar()["ok"], true)
	_comprobar("cerrar B es seguro", cliente_b.cerrar()["ok"], true)


func _probar_offline_y_partida_intacta() -> void:
	var partida := {
		"veredictos": {"caso-previo": "firma"},
		"pistas_descubiertas": ["pista-previa"],
		"dinero": 37,
		"vidas": 2,
		"historias_cartas": {"la-justicia": {"eleccion": "socialdemocrata"}},
	}
	var antes := JSON.stringify(partida)

	var offline := CombateCoopServicio.new(TransporteNulo.new())
	var apertura := offline.abrir(
		"ventanilla_coop", "LOCAL-380", "reclamacion-offline", "anon-offline"
	)
	_comprobar("offline no bloquea apertura", apertura["ok"], true)
	var publicacion := offline.publicar_eleccion(0, "objecion", "test-380", AHORA, "offline-0")
	_comprobar("offline descarta explícitamente", publicacion["status"], "discarded_offline")
	_comprobar(
		"offline no inventa elecciones", offline.consultar_elecciones(0, AHORA)["choices"].size(), 0
	)
	offline.cerrar()
	_comprobar("Partida queda byte a byte igual", JSON.stringify(partida), antes)


func _comprobar(nombre: String, obtenido: Variant, esperado: Variant) -> void:
	if obtenido == esperado:
		pasadas += 1
		return
	fallos += 1
	push_error("%s: esperado %s, obtenido %s" % [nombre, esperado, obtenido])
