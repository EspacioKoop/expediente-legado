extends SceneTree

const GolfCoopAcceso = preload("res://guion/golf_coop_acceso.gd")
const TransporteFixture = preload("res://guion/red/transporte_fixture.gd")

const AHORA := 2_100_500_000
const SALA := "ABC234"

var pasadas := 0
var fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _configuraciones_faciles() -> Array:
	var salida: Array = []
	for _i in range(3):
		(
			salida
			. append(
				{
					"inicio": Vector2.ZERO,
					"objetivo": Vector2(0.0, -0.14625),
					"limite": Rect2(-1.0, -1.0, 2.0, 2.0),
					"radio_objetivo": 0.04,
					"obstaculos": [],
				}
			)
		)
	return salida


func _nuevo_cliente(actor: String, transporte: TransporteFixture) -> Dictionary:
	var superficie := Node3D.new()
	superficie.name = "Superficie_%s" % actor
	root.add_child(superficie)
	var acceso := GolfCoopAcceso.new()
	acceso.name = "Coop_%s" % actor
	acceso.ahora_override = AHORA
	acceso.configurar(superficie, _configuraciones_faciles(), actor, transporte)
	superficie.add_child(acceso)
	return {"superficie": superficie, "acceso": acceso, "transporte": transporte}


func _probar() -> void:
	var cliente_a := _nuevo_cliente("anon-a", TransporteFixture.new())
	var cliente_b := _nuevo_cliente("anon-b", TransporteFixture.new())
	await process_frame

	var a: GolfCoopAcceso = cliente_a["acceso"]
	var b: GolfCoopAcceso = cliente_b["acceso"]
	var transporte_a: TransporteFixture = cliente_a["transporte"]
	var transporte_b: TransporteFixture = cliente_b["transporte"]

	a._abrir_sala(SALA)
	b._abrir_sala(SALA)
	_comprobar(a._servicio != null, "cliente A entra en sala")
	_comprobar(b._servicio != null, "cliente B entra en sala")
	_comprobar(transporte_a.publicados().size() == 1, "A publica ready")
	_comprobar(transporte_b.publicados().size() == 1, "B publica ready")

	transporte_b.inyectar(transporte_a.publicados()[0])
	transporte_a.inyectar(transporte_b.publicados()[0])
	a._consultar_acciones()
	b._consultar_acciones()
	await process_frame

	_comprobar(a._autoridad != null and a._autoridad.valida(), "A monta autoridad existente")
	_comprobar(b._autoridad != null and b._autoridad.valida(), "B monta autoridad existente")
	_comprobar(is_instance_valid(a._hoyo), "A reutiliza GolfHoyoApp")
	_comprobar(is_instance_valid(b._hoyo), "B reutiliza GolfHoyoApp")

	var indice_a := 1
	var indice_b := 1
	for tiro in range(6):
		var snapshot := a._autoridad.snapshot() if a._autoridad != null else b._autoridad.snapshot()
		var actor := String(snapshot["state"]["current_player"])
		var origen: GolfCoopAcceso = a if actor == "anon-a" else b
		var destino: GolfCoopAcceso = b if actor == "anon-a" else a
		var transporte_origen: TransporteFixture = (
			transporte_a if actor == "anon-a" else transporte_b
		)
		var transporte_destino: TransporteFixture = (
			transporte_b if actor == "anon-a" else transporte_a
		)

		_comprobar(origen._turno_local(), "el cliente correcto tiene el turno %d" % tiro)
		origen._hoyo.angulo_grados = 0.0
		origen._hoyo.potencia = 0.1
		origen._publicar_tiro()

		var indice := indice_a if actor == "anon-a" else indice_b
		var publicados := transporte_origen.publicados()
		_comprobar(publicados.size() > indice, "el tiro %d se publica" % tiro)
		if publicados.size() <= indice:
			break
		transporte_destino.inyectar(publicados[indice])
		if actor == "anon-a":
			indice_a += 1
		else:
			indice_b += 1
		destino._consultar_acciones()
		await process_frame

	_comprobar(bool(a.ultimo_resultado.get("completa", false)), "A recibe resultado completo")
	_comprobar(bool(b.ultimo_resultado.get("completa", false)), "B recibe resultado completo")
	_comprobar(a.ultimo_resultado == b.ultimo_resultado, "ambos clientes convergen")
	_comprobar(int(a.ultimo_resultado["totales"]["anon-a"]) == 3, "A completa tres hoyos")
	_comprobar(int(a.ultimo_resultado["totales"]["anon-b"]) == 3, "B completa tres hoyos")
	_comprobar(a._servicio == null and b._servicio == null, "resultado cierra la sala")
	_comprobar(not is_instance_valid(a._hoyo), "A sale de la superficie coop")
	_comprobar(not is_instance_valid(b._hoyo), "B sale de la superficie coop")

	cliente_a["superficie"].queue_free()
	cliente_b["superficie"].queue_free()
	await process_frame
	print("golf_coop_superficie_383: %d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		pasadas += 1
		return
	fallos += 1
	push_error("FALLO #383: " + nombre)
