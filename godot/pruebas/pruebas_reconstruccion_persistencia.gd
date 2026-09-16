extends SceneTree

const RUTA := "user://prueba_reconstruccion_persistencia_155.json"
const RUTA_ANTIGUA := "user://prueba_reconstruccion_persistencia_155_antigua.json"
const CASO_ID := "caso_prueba_155"
const CASO := {
	"registros": [
		{"id": "doc_a", "tipo": "informe", "folio": "1", "fecha": "1998-01-01"},
		{"id": "doc_b", "tipo": "oficio", "folio": "2", "fecha": "1998-01-02"},
	]
}

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_limpiar()
	_probar_mejor_resultado()
	_probar_guardado_y_recarga()
	_probar_migracion_partida_antigua()
	_probar_validacion()
	_limpiar()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_mejor_resultado() -> void:
	var estado := Partida.nueva()
	var parcial := ReconstruccionExpediente.guardar_mejor(estado, CASO_ID, CASO, ["doc_a"])
	_comprobar(parcial["actualizado"], "el primer intento queda registrado")
	_comprobar(parcial["mejor"]["rango"] == "consistente", "un orden parcial compatible es consistente")

	var completo := ReconstruccionExpediente.guardar_mejor(
		estado, CASO_ID, CASO, ["doc_a", "doc_b"]
	)
	_comprobar(completo["actualizado"], "a igual puntuación gana la cobertura completa")
	_comprobar(completo["mejor"]["rango"] == "ejemplar", "el orden completo compatible es ejemplar")

	var peor := ReconstruccionExpediente.guardar_mejor(estado, CASO_ID, CASO, ["doc_b", "doc_a"])
	_comprobar(not peor["actualizado"], "un intento con contradicción no pisa el mejor")
	var mejor := ReconstruccionExpediente.mejor_guardado(estado, CASO_ID)
	_comprobar(mejor["orden"] == ["doc_a", "doc_b"], "se conserva el orden del mejor intento")


func _probar_guardado_y_recarga() -> void:
	var partida := Partida.new()
	partida.estado = Partida.nueva()
	ReconstruccionExpediente.guardar_mejor(
		partida.estado, CASO_ID, CASO, ["doc_a", "doc_b"]
	)
	_comprobar(partida.guardar(RUTA), "guarda una partida con reconstrucción")

	var recargada := Partida.new()
	var carga := recargada.cargar(RUTA)
	_comprobar(carga.get("resultado", "") == "cargada", "recarga la partida con reconstrucción")
	var mejor := ReconstruccionExpediente.mejor_guardado(recargada.estado, CASO_ID)
	_comprobar(mejor["orden"] == ["doc_a", "doc_b"], "la recarga conserva el mejor orden")
	_comprobar(int(mejor["puntuacion"]) == 100, "la recarga conserva la puntuación")
	_comprobar(float(mejor["cobertura"]) == 1.0, "la recarga conserva la cobertura")


func _probar_migracion_partida_antigua() -> void:
	var antigua := Partida.nueva()
	antigua.erase("reconstrucciones")
	_comprobar(_escribir_json(RUTA_ANTIGUA, antigua), "prepara una partida antigua sin reconstrucciones")

	var migrada := Partida.new()
	var carga := migrada.cargar(RUTA_ANTIGUA)
	_comprobar(carga.get("resultado", "") == "cargada", "la partida antigua sigue cargando")
	_comprobar(migrada.estado.has("reconstrucciones"), "la migración repone la clave reconstrucciones")
	_comprobar(migrada.estado["reconstrucciones"].is_empty(), "la migración no inventa resultados")


func _probar_validacion() -> void:
	var errores := Partida.validar({"version": Partida.VERSION, "reconstrucciones": []})
	_comprobar(
		errores.has("reconstrucciones no es un objeto"),
		"rechaza reconstrucciones con forma incompatible"
	)


func _escribir_json(ruta: String, datos: Dictionary) -> bool:
	var fichero := FileAccess.open(ruta, FileAccess.WRITE)
	if fichero == null:
		return false
	fichero.store_string(JSON.stringify(datos, "\t"))
	fichero.close()
	return true


func _limpiar() -> void:
	for ruta in [RUTA, RUTA + ".nuevo", RUTA + ".roto", RUTA_ANTIGUA, RUTA_ANTIGUA + ".roto"]:
		if FileAccess.file_exists(ruta):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO ReconstruccionPersistencia: " + nombre)
