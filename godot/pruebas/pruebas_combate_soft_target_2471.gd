## Regresión headless de soft-targeting melee (#2471).
extends SceneTree

const TARGET = preload("res://guion/juicio_combate_soft_target.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_frontal_gana()
	_probar_fuera_de_alcance()
	_probar_histeresis()
	_probar_candidato_claramente_mejor()
	_probar_desempate()
	_probar_invalidos()
	_probar_determinismo()
	print("combate_soft_target_2471: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_frontal_gana() -> void:
	var candidatos := [
		{"id": "frontal", "posicion": Vector3(0.0, 0.0, 2.4), "vivo": true},
		{"id": "lateral", "posicion": Vector3(2.0, 0.0, 2.0), "vivo": true},
	]
	var resultado := TARGET.elegir(Vector3.ZERO, 0.0, candidatos)
	_comprobar(
		String(resultado["objetivo_id"]) == "frontal",
		"objetivo frontal cercano gana frente a lateral",
	)


func _probar_fuera_de_alcance() -> void:
	var candidatos := [
		{"id": "lejos", "posicion": Vector3(0.0, 0.0, TARGET.ALCANCE + 1.0), "vivo": true}
	]
	var resultado := TARGET.elegir(Vector3.ZERO, 0.0, candidatos)
	_comprobar(String(resultado["objetivo_id"]).is_empty(), "fuera de alcance se descarta")


func _probar_histeresis() -> void:
	var candidatos := [
		{"id": "actual", "posicion": Vector3(0.25, 0.0, 2.2), "vivo": true},
		{"id": "nuevo", "posicion": Vector3(0.0, 0.0, 2.1), "vivo": true},
	]
	var resultado := TARGET.elegir(Vector3.ZERO, 0.0, candidatos, "actual")
	_comprobar(
		String(resultado["objetivo_id"]) == "actual",
		"objetivo actual se conserva ante diferencia pequeña",
	)


func _probar_candidato_claramente_mejor() -> void:
	var candidatos := [
		{"id": "actual", "posicion": Vector3(2.8, 0.0, 2.0), "vivo": true},
		{"id": "nuevo", "posicion": Vector3(0.0, 0.0, 1.4), "vivo": true},
	]
	var resultado := TARGET.elegir(Vector3.ZERO, 0.0, candidatos, "actual")
	_comprobar(
		String(resultado["objetivo_id"]) == "nuevo",
		"candidato claramente mejor rompe histéresis",
	)


func _probar_desempate() -> void:
	var candidatos := [
		{"id": "beta", "posicion": Vector3(0.0, 0.0, 2.0), "vivo": true},
		{"id": "alfa", "posicion": Vector3(0.0, 0.0, 2.0), "vivo": true},
	]
	var resultado := TARGET.elegir(Vector3.ZERO, 0.0, candidatos)
	_comprobar(
		String(resultado["objetivo_id"]) == "alfa",
		"empate exacto usa id estable",
	)


func _probar_invalidos() -> void:
	var candidatos := [
		{"id": "muerto", "posicion": Vector3(0.0, 0.0, 1.0), "vivo": false},
		{"id": "", "posicion": Vector3(0.0, 0.0, 1.0), "vivo": true},
		{"id": "espalda", "posicion": Vector3(0.0, 0.0, -1.0), "vivo": true},
	]
	var resultado := TARGET.elegir(Vector3.ZERO, 0.0, candidatos)
	_comprobar(
		String(resultado["objetivo_id"]).is_empty(),
		"muertos, ids vacíos y objetivos a la espalda se ignoran",
	)


func _probar_determinismo() -> void:
	var candidatos := [
		{"id": "uno", "posicion": Vector3(0.4, 0.0, 2.0), "vivo": true},
		{"id": "dos", "posicion": Vector3(-0.4, 0.0, 2.0), "vivo": true},
	]
	var a := TARGET.elegir(Vector3.ZERO, 0.0, candidatos)
	var b := TARGET.elegir(Vector3.ZERO, 0.0, candidatos)
	_comprobar(a == b, "mismo input produce misma salida")


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if not condicion:
		_fallos += 1
		push_error("FALLO #2471 soft target: " + mensaje)
