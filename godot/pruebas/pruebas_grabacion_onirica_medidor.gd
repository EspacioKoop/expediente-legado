## Regresión ejecutable del medidor runtime de grabación onírica (#1237).
extends SceneTree

const Contrato = preload("res://guion/grabacion_onirica_contrato.gd")
const Medidor = preload("res://guion/grabacion_onirica_medidor.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	var camara := Camera3D.new()
	root.add_child(camara)

	var delante := Vector3(0.0, 0.0, -5.0)
	var detras := Vector3(0.0, 0.0, 5.0)
	_comprobar("punto delante dentro del frustum", Medidor.esta_en_cuadro(camara, delante), true)
	_comprobar("punto detrás fuera del frustum", Medidor.esta_en_cuadro(camara, detras), false)

	_probar_mayoria_en_cuadro(camara, delante, detras)
	_probar_cincuenta_por_ciento(camara, delante, detras)
	_probar_interrupcion(camara, delante)
	_probar_deteccion(camara, delante)
	_probar_delta_invalido(camara, delante)

	camara.queue_free()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_mayoria_en_cuadro(camara: Camera3D, delante: Vector3, detras: Vector3) -> void:
	var medidor := Medidor.new()
	medidor.iniciar("folio-123", true)
	medidor.muestrear(camara, delante, 0.6)
	medidor.muestrear(camara, detras, 0.4)
	var toma := medidor.finalizar(true, false)

	_comprobar("finalizar cierra la toma", medidor.esta_activa(), false)
	_comprobar_casi("duración total", float(toma.get("duracion_total", -1.0)), 1.0)
	_comprobar_casi("tiempo en cuadro", float(toma.get("tiempo_sujeto", -1.0)), 0.6)
	_comprobar("conserva original", toma.get("original_id"), "folio-123")
	_comprobar(
		"más de la mitad puede ser válida",
		Contrato.evaluar_toma(toma),
		Contrato.EstadoGrabacion.VALIDA
	)


func _probar_cincuenta_por_ciento(
	camara: Camera3D, delante: Vector3, detras: Vector3
) -> void:
	var medidor := Medidor.new()
	medidor.iniciar("folio-50", true)
	medidor.muestrear(camara, delante, 0.5)
	medidor.muestrear(camara, detras, 0.5)
	var toma := medidor.finalizar(true, false)
	_comprobar(
		"exactamente cincuenta por ciento contamina",
		Contrato.evaluar_toma(toma),
		Contrato.EstadoGrabacion.CONTAMINADA
	)


func _probar_interrupcion(camara: Camera3D, delante: Vector3) -> void:
	var medidor := Medidor.new()
	medidor.iniciar("folio-corte", true)
	medidor.muestrear(camara, delante, 0.6)
	medidor.interrumpir()
	medidor.muestrear(camara, delante, 0.4)
	var toma := medidor.finalizar(true, false)

	_comprobar("el corte queda registrado", toma.get("hubo_corte"), true)
	_comprobar(
		"el corte contamina aunque el encuadre sea bueno",
		Contrato.evaluar_toma(toma),
		Contrato.EstadoGrabacion.CONTAMINADA
	)


func _probar_deteccion(camara: Camera3D, delante: Vector3) -> void:
	var medidor := Medidor.new()
	medidor.iniciar("folio-detectado", true)
	medidor.muestrear(camara, delante, 1.0)
	var toma := medidor.finalizar(true, true)

	_comprobar("la detección llega al contrato", toma.get("figura_detecto_camara"), true)
	_comprobar(
		"ser detectado contamina",
		Contrato.evaluar_toma(toma),
		Contrato.EstadoGrabacion.CONTAMINADA
	)


func _probar_delta_invalido(camara: Camera3D, delante: Vector3) -> void:
	var medidor := Medidor.new()
	medidor.iniciar("folio-tiempo", true)
	medidor.muestrear(camara, delante, -3.0)
	medidor.muestrear(camara, delante, 0.0)
	medidor.muestrear(camara, delante, 0.75)
	var toma := medidor.finalizar(true, false)

	_comprobar_casi("delta no positivo no consume toma", float(toma["duracion_total"]), 0.75)
	_comprobar_casi("delta no positivo no suma encuadre", float(toma["tiempo_sujeto"]), 0.75)


func _comprobar(nombre: String, obtenido, esperado) -> void:
	if obtenido == esperado:
		_pasadas += 1
		return
	_fallos += 1
	printerr("FALLO %s: esperado=%s obtenido=%s" % [nombre, esperado, obtenido])


func _comprobar_casi(nombre: String, obtenido: float, esperado: float) -> void:
	if is_equal_approx(obtenido, esperado):
		_pasadas += 1
		return
	_fallos += 1
	printerr("FALLO %s: esperado=%s obtenido=%s" % [nombre, esperado, obtenido])
