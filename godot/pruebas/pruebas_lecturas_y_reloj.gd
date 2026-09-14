## Regresiones de #163. Las llama recorrido.gd dentro de datos aislados.
class_name PruebasLecturasYReloj
extends RefCounted


## Se usa el visor real: probar solo anotar_lectura no detectaba esta costura.
static func lecturas(archivo, comprobar: Callable) -> void:
	archivo.jornada["fase"] = "archivo"
	archivo.jornada["acciones"] = 0
	archivo.jornada["leido_hoy"] = []
	var caso_id: String = archivo.caso["id"]
	var folio: String = archivo.caso["registros"][1]["folio"]
	var firma: String = archivo.partida.estado["veredictos"][caso_id]
	var pistas: Array = archivo.descubiertas.duplicate()
	archivo._al_elegir_documento(1)
	comprobar.call(
		"releer cerrado sin acciones permite leer", archivo.registro_actual["folio"], folio
	)
	comprobar.call("releer cerrado sin acciones no cobra", archivo.jornada["acciones"], 0)
	comprobar.call("la lectura gratuita alimenta la noche", archivo.jornada["leido_hoy"], [folio])
	archivo._al_elegir_documento(1)
	comprobar.call(
		"repetir la lectura gratuita no duplica el folio", archivo.jornada["leido_hoy"], [folio]
	)

	var guardada := Partida.new()
	comprobar.call("la lectura gratuita se guarda", guardada.cargar()["resultado"], "cargada")
	comprobar.call(
		"recargar conserva la lectura gratuita", guardada.estado["jornada"]["leido_hoy"], [folio]
	)
	comprobar.call(
		"releer conserva la firma", guardada.estado["veredictos"].get(caso_id, ""), firma
	)
	comprobar.call("releer no descubre pistas", archivo.descubiertas, pistas)
	var fuentes := SuenoContenido.fuentes(
		archivo.jornada["leido_hoy"],
		archivo.contenido.casos,
		pistas,
		archivo.partida.estado["veredictos"]
	)
	comprobar.call("el sueño recibe el caso releído", fuentes["casos"].has(caso_id), true)

	# Una lectura denegada no entra en el sueño. La siguiente permitida cuesta
	# una sola acción, por muchas veces que después se vuelva al documento.
	archivo._al_elegir_caso(1)
	var otro: String = archivo.caso["registros"][0]["folio"]
	archivo._al_elegir_documento(0)
	comprobar.call(
		"sin acciones no se abre un caso nuevo", archivo.registro_actual.is_empty(), true
	)
	comprobar.call(
		"una apertura denegada no se recuerda", archivo.jornada["leido_hoy"].has(otro), false
	)
	comprobar.call("una apertura denegada no cobra", archivo.jornada["acciones"], 0)
	archivo.jornada["acciones"] = 2
	archivo._al_elegir_documento(0)
	archivo._al_elegir_documento(0)
	comprobar.call("leer y releer un caso abierto cobra una vez", archivo.jornada["acciones"], 1)
	comprobar.call(
		"solo se registran lecturas realizadas", archivo.jornada["leido_hoy"], [folio, otro]
	)


## El itinerario se consume, pero no debe encoger la duración de la noche.
static func reloj(comprobar: Callable) -> void:
	var partida := Partida.new()
	partida.estado = Partida.nueva()
	var noche: Dictionary = partida.estado["jornada"]
	noche["fase"] = "casa"
	Jornada.dormir(noche)
	var total := Sueno.segundos_de_noche(noche["sueno_escenas"])
	comprobar.call("dormir fija una duración total positiva", total > 0.0, true)
	comprobar.call("la duración total queda en la jornada", noche.get("sueno_total", 0.0), total)
	Jornada.gastar_sueno(noche, total * 0.4)
	comprobar.call(
		"el reloj refleja el tiempo consumido",
		is_equal_approx(Jornada.noche_restante(noche), 0.6),
		true
	)
	noche["sueno_escenas"].pop_front()
	comprobar.call(
		"atravesar una salida no rejuvenece la noche",
		is_equal_approx(Jornada.noche_restante(noche), 0.6),
		true
	)
	Jornada.gastar_sueno(noche, total * 0.1)
	comprobar.call(
		"el reloj sigue bajando tras la salida",
		is_equal_approx(Jornada.noche_restante(noche), 0.5),
		true
	)

	var ruta := "user://regresion-reloj.json"
	comprobar.call("la noche se guarda", partida.guardar(ruta), true)
	var releida := Partida.new()
	comprobar.call("la noche se recupera", releida.cargar(ruta)["resultado"], "cargada")
	var cargada: Dictionary = releida.estado["jornada"]
	comprobar.call(
		"recargar conserva la proporción nocturna",
		is_equal_approx(Jornada.noche_restante(cargada), 0.5),
		true
	)
	comprobar.call(
		"recargar conserva las salas pendientes", cargada["sueno_escenas"], noche["sueno_escenas"]
	)
	comprobar.call(
		"recargar conserva la duración total",
		is_equal_approx(cargada.get("sueno_total", 0.0), total),
		true
	)
	Jornada.gastar_sueno(cargada, total)
	comprobar.call("una noche agotada llega a cero", Jornada.noche_restante(cargada), 0.0)
	comprobar.call("se puede guardar al agotarse el reloj", releida.guardar(ruta), true)
	comprobar.call(
		"se puede cargar al agotarse el reloj", releida.cargar(ruta)["resultado"], "cargada"
	)
	cargada = releida.estado["jornada"]
	comprobar.call("recargar no regala otra noche al agotarse", cargada["sueno_resto"], 0.0)
	Jornada.despertar(cargada)
	comprobar.call("despertar limpia la duración total", cargada.get("sueno_total", -1.0), 0.0)
	comprobar.call("fuera del sueño la proporción es cero", Jornada.noche_restante(cargada), 0.0)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))
	_migracion(comprobar)


## Sin el itinerario completo antiguo no se inventa su duración original:
## se fija una referencia a partir de lo que queda, sin regalar segundos.
static func _migracion(comprobar: Callable) -> void:
	var antigua := Jornada.nueva()
	antigua["fase"] = "casa"
	Jornada.dormir(antigua)
	Jornada.gastar_sueno(antigua, antigua["sueno_resto"] * 0.4)
	antigua["sueno_escenas"].pop_front()
	antigua.erase("sueno_total")
	var segundos: float = antigua["sueno_resto"]
	var salas: Array = antigua["sueno_escenas"].duplicate()
	var referencia := maxf(segundos, Sueno.segundos_de_noche(salas))
	Jornada.completar(antigua)
	comprobar.call("migrar conserva los segundos restantes", antigua["sueno_resto"], segundos)
	comprobar.call("migrar conserva las salas pendientes", antigua["sueno_escenas"], salas)
	comprobar.call(
		"migrar fija una referencia conservadora", antigua.get("sueno_total", 0.0), referencia
	)
	var proporcion := Jornada.noche_restante(antigua)
	antigua["sueno_escenas"].pop_front()
	Jornada.completar(antigua)
	comprobar.call(
		"completar otra vez no recalcula el total", antigua.get("sueno_total", 0.0), referencia
	)
	comprobar.call(
		"una noche migrada tampoco retrocede",
		is_equal_approx(Jornada.noche_restante(antigua), proporcion),
		true
	)

	# Un guardado anterior al reloj no tiene tiempo pendiente que conservar.
	var sin_reloj := Jornada.nueva()
	sin_reloj["fase"] = "sueño"
	sin_reloj.erase("sueno_total")
	sin_reloj.erase("sueno_resto")
	Jornada.completar(sin_reloj)
	comprobar.call(
		"una partida anterior al reloj recibe tiempo", sin_reloj["sueno_resto"] > 0.0, true
	)
	comprobar.call(
		"la primera noche migrada comienza entera", Jornada.noche_restante(sin_reloj), 1.0
	)
	Jornada.despertar_de_golpe(sin_reloj)
	comprobar.call(
		"despertar de golpe también limpia el total", sin_reloj.get("sueno_total", -1.0), 0.0
	)
