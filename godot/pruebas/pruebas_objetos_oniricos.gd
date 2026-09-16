extends SceneTree

const Objetos := preload("res://guion/objetos_oniricos.gd")
const Utileria := preload("res://guion/sueno_utileria.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_registro_diario()
	_probar_caducidad_y_recuperacion()
	_probar_catalogo_filtrado()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_registro_diario() -> void:
	var jornada := {"dia": 4}
	_comprobar(Objetos.registrar(jornada, "monitor"), "el primer monitor deja memoria")
	_comprobar(not Objetos.registrar(jornada, "monitor"), "repetir el monitor no fuerza otro guardado")
	_comprobar(Objetos.registrar(jornada, " silla "), "otra familia tocada se incorpora")
	_comprobar(
		Objetos.del_dia(jornada) == ["monitor", "silla"],
		"la memoria conserva ids canónicos sin duplicados"
	)
	_comprobar(not Objetos.registrar(jornada, ""), "un id vacío no crea contenido onírico")


func _probar_caducidad_y_recuperacion() -> void:
	var jornada := {"dia": 8}
	jornada[Objetos.CLAVE] = {"dia": 7, "ids": ["monitor"]}
	_comprobar(Objetos.del_dia(jornada).is_empty(), "una noche anterior no contamina el día actual")
	_comprobar(Objetos.registrar(jornada, "archivador"), "el primer toque del día reemplaza la memoria caducada")
	_comprobar(
		Objetos.del_dia(jornada) == ["archivador"],
		"tras caducar no reaparecen objetos tocados ayer"
	)

	var roto := {"dia": 2}
	roto[Objetos.CLAVE] = {"dia": 2, "ids": {}}
	_comprobar(Objetos.del_dia(roto).is_empty(), "un guardado mal formado falla vacío")
	_comprobar(Objetos.registrar(roto, "silla"), "el siguiente toque repara la lista mal formada")
	_comprobar(Objetos.del_dia(roto) == ["silla"], "la reparación no inventa otros ids")


func _probar_catalogo_filtrado() -> void:
	_comprobar(
		Utileria.prescripciones_para([]).is_empty(),
		"sin objeto tocado no existe utilería onírica de relleno"
	)
	_comprobar(
		Utileria.prescripciones_para(["papelera", "desconocido"]).is_empty(),
		"una familia sin deformación catalogada no inventa una"
	)
	var dos := Utileria.prescripciones_para(["monitor", "monitor", "silla"])
	_comprobar(dos.size() == 2, "duplicar un toque no duplica anomalías")
	_comprobar(dos[0]["objeto_id"] == "silla", "el catálogo mantiene un orden estable")
	_comprobar(dos[1]["objeto_id"] == "monitor", "solo entran originales realmente tocados")
	var archivador := Utileria.prescripciones_para(["archivador"])
	_comprobar(archivador.size() == 1, "un único original produce una única familia")
	_comprobar(
		archivador[0]["anomalia_id"] == "archivador-torcido",
		"el original reutiliza la deformación ya catalogada"
	)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO Objetos oníricos: " + nombre)
