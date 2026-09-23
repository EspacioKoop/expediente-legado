extends SceneTree

## Primer vertical ejecutable de #378 sobre #375/#377.

const AyudaCatalogo = preload("res://guion/red/ayuda_catalogo.gd")
const AyudaDatos = preload("res://guion/red/ayuda_datos.gd")
const AyudaServicio = preload("res://guion/red/ayuda_servicio.gd")
const TransporteFixture = preload("res://guion/red/transporte_fixture.gd")
const TransporteNulo = preload("res://guion/red/transporte_nulo.gd")
const AHORA := 2_000_000_000
const ESCENA := "suenio/primera_noche"

var pasadas := 0
var fallos := 0


func _init() -> void:
	_probar_catalogo_y_conocimiento()
	_probar_evento_seguro()
	_probar_fixture_opt_out_y_spam()
	_probar_offline_y_rate_limit()
	print("\n%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _evento(
	actor: String,
	anchor: String,
	conocimiento: Array,
	event_id: String,
	instante: int = AHORA
) -> Dictionary:
	var creado := AyudaDatos.crear_evento(
		ESCENA,
		"test-378",
		actor,
		anchor,
		"resonancia",
		"leve",
		instante,
		conocimiento,
		event_id
	)
	return creado


func _probar_catalogo_y_conocimiento() -> void:
	_comprobar("hay dos anchors oníricos", AyudaCatalogo.ANCHORS.size(), 2)
	var abierto := {
		"anchor_id": "suenio_umbral",
		"help_type": "resonancia",
		"strength": "leve",
	}
	_comprobar("payload cerrado válido", AyudaCatalogo.validar_payload(abierto)["ok"], true)
	var prohibido := abierto.duplicate(true)
	prohibido["objetivo_completado"] = true
	_comprobar(
		"campos de progreso remoto se rechazan",
		AyudaCatalogo.validar_payload(prohibido)["ok"],
		false
	)
	var bloqueado := {
		"anchor_id": "suenio_figura",
		"help_type": "resonancia",
		"strength": "leve",
		"knowledge_gate": "figura_onirica",
	}
	_comprobar(
		"contenido desconocido queda filtrado",
		AyudaCatalogo.validar_payload(bloqueado, [])["ok"],
		false
	)
	_comprobar(
		"contenido conocido habilita la resonancia",
		AyudaCatalogo.validar_payload(bloqueado, ["figura_onirica"])["ok"],
		true
	)
	var feedback := AyudaCatalogo.feedback_para(abierto)
	_comprobar("feedback visual cerrado", feedback["feedback"]["visual"], "pulso_luz")
	_comprobar("feedback sonoro cerrado", feedback["feedback"]["audio"], "eco_breve")


func _probar_evento_seguro() -> void:
	var creado := _evento("anon-01", "suenio_umbral", [], "help-01")
	_comprobar("help usa EventoOnline válido", creado["ok"], true)
	_comprobar("kind es help", creado["event"]["kind"], "help")
	_comprobar(
		"el TTL expira la ayuda",
		AyudaDatos.validar_evento(creado["event"], AHORA + AyudaDatos.TTL_SEGUNDOS + 1)["ok"],
		false
	)
	var escena_incorrecta := AyudaDatos.crear_evento(
		"siga",
		"test-378",
		"anon-01",
		"suenio_umbral",
		"resonancia",
		"leve",
		AHORA
	)
	_comprobar("SIGA queda fuera de esta ayuda", escena_incorrecta["ok"], false)


func _probar_fixture_opt_out_y_spam() -> void:
	var normal := _evento("anon-02", "suenio_umbral", [], "help-normal")
	var bloqueada := _evento(
		"anon-03", "suenio_figura", ["figura_onirica"], "help-locked"
	)
	var extra_1 := _evento("anon-04", "suenio_umbral", [], "help-extra-1")
	var extra_2 := _evento("anon-05", "suenio_umbral", [], "help-extra-2")
	var servicio := AyudaServicio.new(
		TransporteFixture.new(
			[normal["event"], bloqueada["event"], extra_1["event"], extra_2["event"]]
		)
	)
	var sin_conocimiento := servicio.consultar(ESCENA, [], AHORA + 1)
	_comprobar(
		"receptor sin conocimiento no ve anchor bloqueado",
		sin_conocimiento["helps"].size(),
		2
	)
	var con_conocimiento := servicio.consultar(ESCENA, ["figura_onirica"], AHORA + 1)
	_comprobar(
		"spam por anchor queda acotado pero otro anchor entra",
		con_conocimiento["helps"].size(),
		3
	)
	servicio.ocultar_evento("help-normal")
	var ocultada := servicio.consultar(ESCENA, ["figura_onirica"], AHORA + 1)
	_comprobar("ocultar una ayuda es local e inmediato", ocultada["helps"].size(), 3)
	servicio.set_ayudas_visibles(false)
	var desactivadas := servicio.consultar(ESCENA, ["figura_onirica"], AHORA + 1)
	_comprobar("el opt-out oculta todas las ayudas", desactivadas["helps"].size(), 0)
	_comprobar("el opt-out queda consultable", servicio.ayudas_visibles(), false)


func _probar_offline_y_rate_limit() -> void:
	var offline := AyudaServicio.new(TransporteNulo.new())
	var publicacion_offline := offline.publicar(
		ESCENA,
		"test-378",
		"anon-offline",
		"suenio_umbral",
		"resonancia",
		"leve",
		AHORA
	)
	_comprobar("offline no bloquea publicación", publicacion_offline["ok"], true)
	_comprobar(
		"offline descarta explícitamente",
		publicacion_offline["status"],
		"discarded_offline"
	)

	var online := AyudaServicio.new(TransporteFixture.new())
	var primera := online.publicar(
		ESCENA,
		"test-378",
		"anon-rate",
		"suenio_umbral",
		"resonancia",
		"leve",
		AHORA,
		[],
		"help-rate-1"
	)
	var segunda := online.publicar(
		ESCENA,
		"test-378",
		"anon-rate",
		"suenio_umbral",
		"resonancia",
		"leve",
		AHORA + 1,
		[],
		"help-rate-2"
	)
	_comprobar("la primera publicación pasa", primera["ok"], true)
	_comprobar("publicar seguido queda limitado", segunda["status"], "rate_limited")


func _comprobar(nombre: String, obtenido: Variant, esperado: Variant) -> void:
	if obtenido == esperado:
		pasadas += 1
		return
	fallos += 1
	push_error("%s: esperado %s, obtenido %s" % [nombre, esperado, obtenido])
