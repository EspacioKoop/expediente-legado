extends SceneTree

## Vertical ejecutable de #377 sobre EventoOnline/TransporteFixture de #375.

const SenalDatos = preload("res://guion/red/senal_datos.gd")
const SenalServicio = preload("res://guion/red/senal_servicio.gd")
const SenalVocabulario = preload("res://guion/red/senal_vocabulario.gd")
const TransporteFixture = preload("res://guion/red/transporte_fixture.gd")
const TransporteNulo = preload("res://guion/red/transporte_nulo.gd")
const AHORA := 2_000_000_000

var pasadas := 0
var fallos := 0


func _init() -> void:
	_probar_vocabulario_cerrado()
	_probar_evento_y_ttl()
	_probar_fixture_y_conocimiento()
	_probar_offline_y_rate_limit()
	print("\n%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _payload(token: String = "trampa") -> Dictionary:
	return {
		"anchor_id": "calle_escaparate",
		"plantilla_id": "cuidado_con",
		"tokens": [token],
	}


func _probar_vocabulario_cerrado() -> void:
	var valido := SenalVocabulario.validar_payload(_payload())
	_comprobar("payload cerrado válido", valido["ok"], true)
	var renderizado := SenalVocabulario.renderizar(_payload())
	_comprobar("texto se reconstruye localmente", renderizado["text"], "Cuidado con trampa")

	var anchor_inventado := _payload()
	anchor_inventado["anchor_id"] = "coordenada_libre"
	_comprobar(
		"un anchor no declarado se rechaza",
		SenalVocabulario.validar_payload(anchor_inventado)["ok"],
		false
	)

	var token_inventado := _payload("texto libre enviado por red")
	_comprobar(
		"un token no catalogado se rechaza",
		SenalVocabulario.validar_payload(token_inventado)["ok"],
		false
	)

	var bloqueado := _payload("simbolo_amarillo")
	_comprobar(
		"conocimiento bloqueado no se muestra",
		SenalVocabulario.validar_payload(bloqueado)["ok"],
		false
	)
	_comprobar(
		"conocimiento desbloqueado habilita el token",
		SenalVocabulario.validar_payload(bloqueado, ["simbolo_amarillo"])["ok"],
		true
	)
	_comprobar(
		"solo hay dos anchors en el primer vertical",
		SenalVocabulario.ANCHORS.size(),
		2
	)


func _probar_evento_y_ttl() -> void:
	var creado := SenalDatos.crear_evento(
		"calle",
		"test-840",
		"anon-01",
		"calle_escaparate",
		"cuidado_con",
		["trampa"],
		AHORA,
		[],
		-1,
		"sig-01"
	)
	_comprobar("signal usa EventoOnline válido", creado["ok"], true)
	_comprobar(
		"el TTL expira la señal",
		SenalDatos.validar_evento(creado["event"], AHORA + SenalDatos.TTL_SEGUNDOS + 1)["ok"],
		false
	)
	var fuera_de_superficie := SenalDatos.crear_evento(
		"siga",
		"test-840",
		"anon-01",
		"calle_escaparate",
		"cuidado_con",
		["trampa"],
		AHORA
	)
	_comprobar("SIGA queda fuera de la superficie de señales", fuera_de_superficie["ok"], false)


func _probar_fixture_y_conocimiento() -> void:
	var normal := SenalDatos.crear_evento(
		"calle",
		"test-840",
		"anon-02",
		"calle_escaparate",
		"cuidado_con",
		["trampa"],
		AHORA,
		[],
		-1,
		"sig-normal"
	)
	var fixture := TransporteFixture.new([normal["event"]])
	var servicio := SenalServicio.new(fixture)
	var consulta := servicio.consultar("calle", [], AHORA + 1)
	_comprobar("fixture local entrega una señal", consulta["signals"].size(), 1)

	var bloqueada := SenalDatos.crear_evento(
		"calle",
		"test-840",
		"anon-03",
		"calle_escaparate",
		"cuidado_con",
		["simbolo_amarillo"],
		AHORA,
		["simbolo_amarillo"],
		-1,
		"sig-locked"
	)
	var servicio_bloqueado := SenalServicio.new(TransporteFixture.new([bloqueada["event"]]))
	var sin_conocimiento := servicio_bloqueado.consultar("calle", [], AHORA + 1)
	_comprobar("receptor sin conocimiento filtra la señal", sin_conocimiento["signals"].size(), 0)
	var con_conocimiento := servicio_bloqueado.consultar(
		"calle", ["simbolo_amarillo"], AHORA + 1
	)
	_comprobar("receptor con conocimiento ve la señal", con_conocimiento["signals"].size(), 1)
	servicio_bloqueado.ocultar_evento("sig-locked")
	var ocultada := servicio_bloqueado.consultar("calle", ["simbolo_amarillo"], AHORA + 1)
	_comprobar("una señal ocultada no reaparece", ocultada["signals"].size(), 0)


func _probar_offline_y_rate_limit() -> void:
	var offline := SenalServicio.new(TransporteNulo.new())
	var publicacion_offline := offline.publicar(
		"calle",
		"test-840",
		"anon-offline",
		"calle_portal",
		"sigue",
		["norte"],
		AHORA
	)
	_comprobar("offline no bloquea publicación", publicacion_offline["ok"], true)
	_comprobar("offline descarta explícitamente", publicacion_offline["status"], "discarded_offline")

	var online := SenalServicio.new(TransporteFixture.new())
	var primera := online.publicar(
		"calle",
		"test-840",
		"anon-rate",
		"calle_portal",
		"sigue",
		["norte"],
		AHORA,
		[],
		-1,
		"sig-rate-1"
	)
	var segunda := online.publicar(
		"calle",
		"test-840",
		"anon-rate",
		"calle_portal",
		"sigue",
		["norte"],
		AHORA + 1,
		[],
		-1,
		"sig-rate-2"
	)
	_comprobar("la primera publicación pasa", primera["ok"], true)
	_comprobar("publicar seguido queda limitado", segunda["status"], "rate_limited")


func _comprobar(nombre: String, obtenido: Variant, esperado: Variant) -> void:
	if obtenido == esperado:
		pasadas += 1
		return
	fallos += 1
	push_error("%s: esperado %s, obtenido %s" % [nombre, esperado, obtenido])
