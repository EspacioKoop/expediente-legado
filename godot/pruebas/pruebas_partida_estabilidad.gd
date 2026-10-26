## Estabilidad del guardado/carga de una partida completa (#2739).
##
## Las suites por subsistema prueban que SU bloque sobrevive al round-trip. Esta
## comprueba el contrato transversal: que el estado COMPLETO que el jugador
## deja en memoria es el mismo que recupera del disco, clave a clave, y que las
## operaciones repetidas (guardar dos veces, cargar dos veces) no derivan.
extends SceneTree

const RUTA := "user://prueba_partida_estabilidad.json"

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_limpiar()
	_probar_round_trip_completo()
	_probar_segundo_guardado_no_deriva()
	_probar_segundo_cargado_no_deriva()
	_probar_partida_nueva_tras_borrar()
	_probar_corrupta_se_aparta_y_no_se_pisa()
	_limpiar()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


## Un estado con todos los bloques de SIGA y del sueño tocados: la comparación
## tiene que ver contenido real, no catálogos de serie.
func _estado_trabajado() -> Dictionary:
	var estado := Partida.nueva()
	estado["semilla"] = 987654321
	estado["vida"] = 2
	estado["pistas_descubiertas"] = ["pista_archivo_1", "pista_sello_2"]
	estado["sellos_obtenidos"] = ["sello_a"]
	estado["anomalias_descubiertas"] = ["anomalia_x"]
	estado["anomalias_descubiertas_vuelta"] = ["anomalia_y"]
	estado["cartas_conocidas"] = ["carta_1"]
	estado["sueno_vencidos"] = ["vigia"]
	estado["coliseo_racha_mejor"] = 4
	estado["cinematicas_vistas"] = {"careo": 3}
	estado["veredictos"] = {"caso_1": "culpable"}
	estado["historias_pospuestas"] = ["carta_2"]
	estado["historias_pospuestas_conteo"] = {"carta_2": 2}
	estado["historial_decisiones"] = [{"id": "dec_1", "paso": 1}]
	estado["huellas_ambientales"] = {"archivo_puerta": {"veces": 2}}
	estado["jornada"]["dia"] = 3
	estado["jornada"]["vuelta"] = 2
	estado["jornada"]["dinero"] = 40
	estado["jornada"]["leidos_total"] = 7
	estado["inventario"][Inventario.CARRIED] = [{"id": "documento_nomina"}]
	return estado


func _probar_round_trip_completo() -> void:
	var partida := Partida.new()
	partida.estado = _estado_trabajado()
	_comprobar(partida.guardar(RUTA), "el estado trabajado se guarda")

	var recargada := Partida.new()
	var resultado := recargada.cargar(RUTA)
	_comprobar(
		String(resultado.get("resultado", "")) == "cargada",
		"el estado trabajado se recarga desde disco",
	)
	_comprobar_diferencias(partida.estado, recargada.estado, "round trip del estado completo")


func _probar_segundo_guardado_no_deriva() -> void:
	var partida := Partida.new()
	partida.estado = _estado_trabajado()
	partida.guardar(RUTA)
	var primer_disco := _leer_disco(RUTA)
	partida.guardar(RUTA)
	var segundo_disco := _leer_disco(RUTA)
	_comprobar_diferencias(primer_disco, segundo_disco, "guardar dos veces escribe lo mismo")


func _probar_segundo_cargado_no_deriva() -> void:
	var partida := Partida.new()
	partida.estado = _estado_trabajado()
	partida.guardar(RUTA)
	var primera := Partida.new()
	primera.cargar(RUTA)
	var segunda := Partida.new()
	segunda.cargar(RUTA)
	_comprobar_diferencias(primera.estado, segunda.estado, "cargar dos veces obtiene lo mismo")


func _probar_partida_nueva_tras_borrar() -> void:
	var partida := Partida.new()
	partida.estado = _estado_trabajado()
	partida.guardar(RUTA)
	_comprobar(partida.borrar(RUTA), "borrar deja el hueco limpio")

	var fresca := Partida.new()
	var resultado := fresca.cargar(RUTA)
	_comprobar(
		String(resultado.get("resultado", "")) == "nueva",
		"tras borrar, cargar empieza una partida nueva",
	)
	_comprobar_diferencias(fresca.estado, Partida.nueva(), "la partida nueva es la de serie")


func _probar_corrupta_se_aparta_y_no_se_pisa() -> void:
	var partida := Partida.new()
	partida.estado = _estado_trabajado()
	partida.guardar(RUTA)

	var fichero := FileAccess.open(RUTA, FileAccess.WRITE)
	fichero.store_string("{ esto no es una partida")
	fichero.close()

	var nueva := Partida.new()
	var resultado := nueva.cargar(RUTA)
	_comprobar(
		String(resultado.get("resultado", "")) == "apartada",
		"la partida corrupta se aparta en vez de interpretarse",
	)
	_comprobar(
		FileAccess.file_exists(RUTA + ".roto"),
		"la copia corrupta queda en disco para recuperarla",
	)
	_comprobar(
		not FileAccess.file_exists(RUTA),
		"cargar una corrupta no restaura el fichero dañado en su sitio",
	)
	_limpiar()


func _leer_disco(ruta: String):
	var fichero := FileAccess.open(ruta, FileAccess.READ)
	if fichero == null:
		return null
	var crudo = JSON.parse_string(fichero.get_as_text())
	fichero.close()
	return crudo


## Compara dos estados con mensajes que señalan la clave exacta del primer
## desacuerdo, porque "el round trip no conserva el estado" no arregla nada.
func _comprobar_diferencias(esperado: Dictionary, actual: Dictionary, nombre: String) -> void:
	var pendientes := [[esperado, actual, "raíz"]]
	while not pendientes.is_empty():
		var par: Array = pendientes.pop_back()
		var a: Dictionary = par[0]
		var b: Dictionary = par[1]
		var prefijo := String(par[2])
		for clave in a:
			var camino := prefijo + "." + String(clave)
			if not b.has(clave):
				_comprobar(false, "%s: falta %s tras recargar" % [nombre, camino])
				continue
			var va = a[clave]
			var vb = b[clave]
			if typeof(va) == TYPE_DICTIONARY and typeof(vb) == TYPE_DICTIONARY:
				pendientes.append([va, vb, camino])
			elif typeof(va) == TYPE_ARRAY and typeof(vb) == TYPE_ARRAY:
				_comprobar_array(va, vb, camino, nombre)
			else:
				_comprobar(
					_iguales(va, vb),
					(
						"%s: %s vale %s en memoria y %s tras recargar"
						% [nombre, camino, str(va), str(vb)]
					)
				)
	_comprobar(true, "%s conserva todas las claves presentes" % nombre)


func _comprobar_array(esperado: Array, actual: Array, camino: String, nombre: String) -> void:
	_comprobar(
		esperado.size() == actual.size(),
		"%s: %s tiene %d elementos y recargan %d" % [nombre, camino, esperado.size(), actual.size()]
	)
	for indice in mini(esperado.size(), actual.size()):
		var va = esperado[indice]
		var vb = actual[indice]
		if typeof(va) == TYPE_DICTIONARY and typeof(vb) == TYPE_DICTIONARY:
			_comprobar_diferencias(va, vb, "%s[%d]" % [camino, indice])
		elif typeof(va) == TYPE_ARRAY and typeof(vb) == TYPE_ARRAY:
			_comprobar_array(va, vb, "%s[%d]" % [camino, indice], nombre)
		else:
			_comprobar(
				_iguales(va, vb),
				(
					"%s: %s[%d] vale %s en memoria y %s tras recargar"
					% [nombre, camino, indice, str(va), str(vb)]
				)
			)


## El JSON no distingue enteros de decimales y CAMPOS_ENTEROS los coacciona al
## cargar: comparar 4 con 4.0 como "iguales" es el contrato, no un fallo.
func _iguales(a, b) -> bool:
	if typeof(a) in [TYPE_INT, TYPE_FLOAT] and typeof(b) in [TYPE_INT, TYPE_FLOAT]:
		return is_equal_approx(float(a), float(b))
	return a == b


func _limpiar() -> void:
	for ruta in [RUTA, RUTA + ".roto", RUTA + ".nuevo"]:
		if FileAccess.file_exists(ruta):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))


func _comprobar(condicion: bool, descripcion: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO PartidaEstabilidad: " + descripcion)
