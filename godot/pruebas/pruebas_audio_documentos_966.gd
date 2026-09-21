extends SceneTree

const VISOR := preload("res://guion/visor_expediente.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	process_frame.connect(_ejecutar, CONNECT_ONE_SHOT)


func _ejecutar() -> void:
	_probar_clasificacion_por_fecha()
	_probar_tono_en_voz_real()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_clasificacion_por_fecha() -> void:
	_comprobar(
		is_equal_approx(VISOR.tono_documento({"fecha": "1958-03-03"}), VISOR.TONO_PAPEL_ANTIGUO),
		"un documento de 1958 usa el tono antiguo",
	)
	_comprobar(
		is_equal_approx(VISOR.tono_documento({"fecha": "1989-12-31"}), VISOR.TONO_PAPEL_ANTIGUO),
		"1989 sigue dentro de la textura antigua",
	)
	_comprobar(
		is_equal_approx(VISOR.tono_documento({"fecha": "1990-01-01"}), 1.0),
		"1990 conserva el tono normal",
	)
	_comprobar(
		is_equal_approx(VISOR.tono_documento({"fecha": null}), 1.0),
		"un registro sin fecha no recibe una edad inventada",
	)
	_comprobar(
		is_equal_approx(VISOR.tono_documento({"fecha": "s/f"}), 1.0),
		"una fecha no numérica tampoco recibe una edad inventada",
	)


func _probar_tono_en_voz_real() -> void:
	var anfitrion := Node.new()
	root.add_child(anfitrion)
	Sonido.sonar(anfitrion, "documento", VISOR.TONO_PAPEL_ANTIGUO)
	var voces := anfitrion.find_children("*", "AudioStreamPlayer", false, false)
	_comprobar(voces.size() == 1, "la lectura crea una única voz")
	if voces.size() == 1:
		var voz := voces[0] as AudioStreamPlayer
		_comprobar(voz.stream == Sonido.stream("documento"), "reutiliza la misma toma CC0 de papel")
		_comprobar(
			is_equal_approx(voz.pitch_scale, VISOR.TONO_PAPEL_ANTIGUO),
			"la voz aplica el tono antiguo solicitado",
		)
		_comprobar(voz.playing, "la voz queda sonando")
	anfitrion.free()


func _comprobar(condicion: bool, descripcion: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO: " + descripcion)
