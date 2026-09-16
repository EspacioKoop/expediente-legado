extends SceneTree

const Dia := preload("res://guion/dia_app.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_tomas_por_suelo()
	_probar_suelo_de_cada_espacio()
	_probar_suelo_pisado_en_dia()
	_probar_impacto_careo()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_tomas_por_suelo() -> void:
	var esperado := {
		"moqueta": "carpet", "linoleo": "concrete", "asfalto": "concrete", Sonido.NIEVE: "snow"
	}
	for suelo in esperado:
		var tomas: Array = Sonido.PASOS_POR_SUELO[suelo]
		_comprobar(tomas.size() > 1, "%s tiene varias tomas" % suelo)
		for i in tomas.size():
			var pista := Sonido.paso_sobre(suelo, i)
			_comprobar(pista != null, "%s toma %d existe" % [suelo, i])
			_comprobar(
				pista != null and pista.resource_path.contains(esperado[suelo]),
				"%s suena a %s" % [suelo, esperado[suelo]]
			)
		_comprobar(
			Sonido.paso_sobre(suelo, 0) == Sonido.paso_sobre(suelo, tomas.size()),
			"%s se puede pedir en orden" % suelo
		)
	_comprobar(Sonido.paso_sobre("", 1) == Sonido.paso(1), "sin suelo quedan los pasos genéricos")
	_comprobar(
		Sonido.paso_sobre("baldosa_onirica", 2) == Sonido.paso(2),
		"un suelo sin entrada quedan los pasos genéricos"
	)


func _probar_suelo_de_cada_espacio() -> void:
	for fase in EspaciosCatalogo.POR_FASE:
		var suelo := String(EspaciosCatalogo.de_fase(fase).get("textura_suelo", ""))
		_comprobar(
			Sonido.PASOS_POR_SUELO.has(suelo), "el suelo de %s (%s) tiene pasos" % [fase, suelo]
		)


func _probar_suelo_pisado_en_dia() -> void:
	var dia_nieve := 2
	while Clima.estado(dia_nieve) != Clima.NIEVE:
		dia_nieve += 1
	var dia: Node = Dia.new()
	dia._espacio_actual = EspaciosCatalogo.CALLE
	dia.jornada = {"fase": "trayecto", "dia": 1}
	_comprobar(dia._suelo_pisado() == "asfalto", "la calle despejada es asfalto")
	dia.jornada = {"fase": "trayecto", "dia": dia_nieve}
	_comprobar(dia._suelo_pisado() == Sonido.NIEVE, "la calle nevada suena a nieve")
	dia._espacio_actual = EspaciosCatalogo.CASA
	dia.jornada = {"fase": "casa", "dia": dia_nieve}
	_comprobar(dia._suelo_pisado() == "moqueta", "dentro de casa no se pisa nieve")
	dia._espacio_actual = {}
	dia.jornada = {"fase": "sueño", "dia": dia_nieve}
	_comprobar(dia._suelo_pisado() == "", "el sueño no declara suelo")
	dia.free()


func _probar_impacto_careo() -> void:
	var golpe := Sonido.impacto_careo()
	_comprobar(golpe is AudioStreamOggVorbis, "el careo usa una toma real")
	_comprobar(golpe == Sonido.impacto_careo(), "y es siempre la misma")
	_comprobar(Sonido.ficheros().has(Sonido.IMPACTO_CAREO), "con ficha comprobable")


func _comprobar(condicion: bool, descripcion: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO: " + descripcion)
