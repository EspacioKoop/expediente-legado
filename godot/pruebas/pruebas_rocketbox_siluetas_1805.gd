extends SceneTree

const Siluetas := preload("res://guion/rocketbox_siluetas_modulares.gd")

const CASOS := {
	"emperador": "rocketbox/business_male_02",
	"aduanero_ny": "rocketbox/male_adult_05",
	"correspondencia": "rocketbox/business_male_03",
}

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	var firmas: Array[String] = []
	for retrato in CASOS:
		var resultado := await _probar_variante(retrato, CASOS[retrato])
		firmas.append(String(resultado.get("firma", "")))
	_comprobar(firmas.size() == 3, "se auditan tres variantes")
	_comprobar(not firmas.has(""), "ninguna variante queda sin silueta")
	_comprobar(firmas[0] != firmas[1], "Puyi y Melville difieren sin color")
	_comprobar(firmas[0] != firmas[2], "Puyi y Pessoa difieren sin color")
	_comprobar(firmas[1] != firmas[2], "Melville y Pessoa difieren sin color")
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_variante(retrato: String, cuerpo_id: String) -> Dictionary:
	var escena := Modelos.cargar(cuerpo_id)
	_comprobar(escena != null, "%s conserva su Rocketbox" % retrato)
	if escena == null:
		return {}
	var pieza := escena.instantiate() as Node3D
	root.add_child(pieza)
	Modelos._adaptar_realista(pieza)
	IdentidadHistoricaRocketboxFixture.aplicar(pieza, retrato)
	await process_frame

	var antes := Siluetas.auditar(pieza)
	var esqueletos_antes := int(antes["skeletons"])
	var identidad := pieza.find_child("IdentidadHistorica275", true, false)
	_comprobar(identidad != null, "%s conserva identidad histórica" % retrato)

	var aplicado := Siluetas.aplicar(pieza, retrato)
	await process_frame
	var despues := Siluetas.auditar(pieza)
	_comprobar(aplicado, "%s recibe el kit modular" % retrato)
	_comprobar(int(despues["skeletons"]) == esqueletos_antes, "%s no añade Skeleton3D" % retrato)
	_comprobar(int(despues["overlay_piezas"]) >= 4, "%s cambia contorno con varias piezas" % retrato)
	_comprobar(int(despues["texturas"]) == int(antes["texturas"]), "%s no duplica texturas" % retrato)
	_comprobar(Siluetas.dentro_de_presupuesto(antes, despues), "%s respeta presupuesto" % retrato)
	_comprobar(
		pieza.find_child("IdentidadHistorica275", true, false) == identidad,
		"%s no sustituye sus rasgos históricos" % retrato,
	)

	for clip in ["idle", "walk", "telefono", "conversar"]:
		_comprobar(AnimacionesUAL.reproducir(pieza, clip, 0.2), "%s mantiene %s" % [retrato, clip])
		var reproductor := Modelos._reproductor(pieza)
		_comprobar(
			reproductor != null and String(reproductor.current_animation).begins_with("rocketbox/"),
			"%s resuelve %s con Rocketbox" % [retrato, clip],
		)

	var firma := Siluetas.firma_silueta(pieza)
	_comprobar(not firma.is_empty(), "%s produce firma geométrica" % retrato)
	var salida := {
		"firma": firma,
		"antes": antes,
		"despues": despues,
	}
	pieza.queue_free()
	await process_frame
	return salida


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if condicion:
		return
	_fallos += 1
	push_error(mensaje)


## Alias local para que el smoke use exactamente la misma implementación del
## runtime sin depender del nombre de autoload.
class IdentidadHistoricaRocketboxFixture:
	static func aplicar(pieza: Node3D, retrato: String) -> void:
		var identidad := preload("res://guion/identidad_historica_rocketbox.gd")
		identidad.aplicar(pieza, retrato)
