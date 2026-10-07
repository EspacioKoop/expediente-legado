## Regresión del contrato del museo de vidas no ocurridas (#2467).
##
## Lo que importa es que el sueño no toque la partida: la misma entrada da
## siempre las mismas tres vidas, ninguna es canónica, solo una se explora y
## el contexto que se le pasa sale intacto.
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var contexto := {
		"dia": 3,
		"vuelta": 2,
		"fase": "trayecto",
		"companeros": ["paco"],
		"eventos": [{"id": "impago"}],
	}
	var antes := SuenoMuseoVidasNoOcurridas.snapshot(contexto)
	var vidas := SuenoMuseoVidasNoOcurridas.posibilidades(contexto, 1234)

	_comprobar(vidas.size() == 3, "salen exactamente tres vidas")
	var explorables := vidas.filter(func(v: Dictionary) -> bool: return v["explorable"])
	_comprobar(explorables.size() == 1, "exactamente una es explorable")
	for vida in vidas:
		_comprobar(vida["canonica"] == false, "%s no es canónica" % vida["id"])
		_comprobar(
			String(vida["clave_texto"]).begins_with("SUENO_MUSEO_"),
			"%s usa una clave de traducción" % vida["id"]
		)
		_comprobar(
			not String(vida.get("origen", "")).is_empty(), "%s dice de dónde sale" % vida["id"]
		)
	var ids := vidas.map(func(v: Dictionary) -> String: return v["id"])
	_comprobar(ids.size() == _sin_repetir(ids).size(), "las tres vidas son distintas")

	_comprobar(SuenoMuseoVidasNoOcurridas.es_igual(antes, contexto), "el contexto sale intacto")
	var otra_vez := SuenoMuseoVidasNoOcurridas.posibilidades(contexto, 1234)
	_comprobar(str(otra_vez) == str(vidas), "misma entrada y semilla, mismas vidas")

	var minimo := SuenoMuseoVidasNoOcurridas.posibilidades({}, 7)
	_comprobar(minimo.size() == 3, "un contexto vacío también da tres vidas")
	_comprobar(
		minimo.filter(func(v: Dictionary) -> bool: return v["explorable"]).size() == 1,
		"y una sola explorable"
	)

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _sin_repetir(lista: Array) -> Array:
	var vistos := {}
	for elemento in lista:
		vistos[elemento] = true
	return vistos.keys()


func _comprobar(condicion: bool, descripcion: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		print("FALLO: " + descripcion)
