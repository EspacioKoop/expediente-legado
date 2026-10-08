## Secuencias de arquitectura imposible del catálogo psicodélico.
##
## Separadas del catálogo principal para mantener cada módulo bajo el límite
## de complejidad/líneas del proyecto. Conservan el mismo contrato declarativo.
class_name CinematicasPsicodelicasImposibles
extends RefCounted


static func _plano(
	nombre: String,
	decorado: Dictionary,
	camara: Vector3,
	mira: Vector3,
	segundos: float,
	rotulo: String = "",
	voz: String = ""
) -> Dictionary:
	return {
		"tipo": "3d",
		"nombre": nombre,
		"decorado": decorado,
		"camara": camara,
		"mira": mira,
		"segundos": segundos,
		"rotulo": rotulo,
		"voz": voz,
	}


static func _pieza(pos: Vector3, tam: Vector3, color: Color, emisivo: bool = false) -> Dictionary:
	var pieza := {"pos": pos, "tam": tam, "color": color}
	if emisivo:
		pieza["emisivo"] = true
	return pieza


static func _figura(
	pos: Vector3,
	_ropa: Color,
	_piel: Color,
	escala: float = 1.0,
	modelo: String = "rocketbox/male_adult_13",
	retrato: String = "",
	gesto: String = "idle"
) -> Dictionary:
	return {
		"modelo": modelo,
		"retrato": retrato,
		"pos": pos,
		"rumbo": 180.0,
		"escala": escala,
		"gesto": gesto,
		"desfase": float(absi(hash("%s:%s" % [modelo, pos])) % 1000) / 1000.0,
	}


static func _decorado(
	piezas: Array, luz: Color, energia: float = 1.0, personas: Array = [], modelos: Array = []
) -> Dictionary:
	var decorado := (
		MesaCinematica
		. con(
			piezas,
			[
				{
					"pos": Vector3(0.0, 3.5, 1.0),
					"color": luz,
					"energia": energia,
					"alcance": 8.0,
					"carcasa": false,
				}
			]
		)
	)
	decorado["personas"] = personas
	decorado["modelos"] = modelos
	return decorado


static func _modelo(
	modelo: String,
	pos: Vector3,
	escala: float = 1.0,
	rotacion: Vector3 = Vector3.ZERO,
	nombre: String = ""
) -> Dictionary:
	return {
		"modelo": modelo,
		"pos": pos,
		"escala": escala,
		"rotacion": rotacion,
		"nombre": nombre,
	}


static func _oficina(figuras: Array = []) -> Dictionary:
	var piezas := [
		_pieza(Vector3(0, 0.05, -1.2), Vector3(6.0, 0.1, 5.0), Color("68686f")),
		_pieza(Vector3(0, 3.0, -1.4), Vector3(6.0, 0.08, 0.18), Color("d8d4bc"), true),
	]
	var modelos := [
		_modelo("oficina_psx/desk1", Vector3(-1.35, 0.0, -0.55), 1.0),
		_modelo("oficina_psx/desk2", Vector3(1.35, 0.0, -0.55), 1.0),
		_modelo("oficina_psx/computer_monitor", Vector3(-1.25, 0.78, -0.72), 0.95),
		_modelo("oficina_psx/computer_monitor", Vector3(1.25, 0.78, -0.72), 0.95),
		_modelo("oficina_psx/desk_phone", Vector3(0.0, 0.78, -0.35), 0.95),
		_modelo("oficina_psx/office_chair_black", Vector3(-0.55, 0.0, 0.35), 0.95),
		_modelo("oficina_psx/office_chair_black", Vector3(0.55, 0.0, 0.35), 0.95),
	]
	return _decorado(piezas, Color("d6d0b7"), 0.95, figuras, modelos)


static func _archivo(figuras: Array = []) -> Dictionary:
	var piezas := [
		_pieza(Vector3(0, 0.05, -1.5), Vector3(5.0, 0.1, 7.0), Color("4d4e55")),
		_pieza(Vector3(0, 2.9, -3.2), Vector3(1.0, 0.08, 0.5), Color("b9b197"), true),
	]
	var modelos := [
		_modelo("oficina_psx/file_cabinet_large", Vector3(-1.7, 0.0, -2.0), 1.0),
		_modelo("oficina_psx/file_cabinet_large", Vector3(1.7, 0.0, -2.0), 1.0),
		_modelo("oficina_psx/file_cabinet_smaller", Vector3(-1.7, 0.0, 0.2), 1.0),
		_modelo("oficina_psx/file_cabinet_smaller", Vector3(1.7, 0.0, 0.2), 1.0),
		_modelo("cardboardBoxClosed", Vector3(0.0, 0.0, -2.8), 0.75),
	]
	return _decorado(piezas, Color("b9b197"), 0.7, figuras, modelos)


static func _escuela(figuras: Array = []) -> Dictionary:
	var piezas := [
		_pieza(Vector3(0, 0.05, -1.2), Vector3(6.0, 0.1, 5.0), Color("776f65")),
		_pieza(Vector3(0, 1.65, -3.0), Vector3(4.5, 2.8, 0.12), Color("d0c6ae")),
		_pieza(Vector3(0, 1.8, -2.9), Vector3(2.8, 1.4, 0.04), Color("263d34")),
	]
	var modelos := [
		_modelo("styloo_school/principal_office_desk", Vector3(0.0, 0.0, -1.1), 1.0),
		_modelo("styloo_school/principal_office_chair", Vector3(0.0, 0.0, 0.15), 1.0),
		_modelo("styloo_school/principal_office_shelf", Vector3(-2.0, 0.0, -2.45), 0.9),
		_modelo("styloo_school/principal_office_telephone", Vector3(0.65, 0.78, -1.1), 0.9),
		_modelo("styloo_school/computer_pc_old", Vector3(-0.65, 0.78, -1.1), 0.85),
	]
	return _decorado(piezas, Color("d5c69f"), 1.0, figuras, modelos)


static func _desierto(figuras: Array = []) -> Dictionary:
	var piezas := [
		_pieza(Vector3(0, -0.1, -2.0), Vector3(12.0, 0.15, 12.0), Color("b68d57")),
		_pieza(Vector3(-2.6, 0.8, -3.8), Vector3(1.1, 1.8, 1.1), Color("9c7048")),
		_pieza(Vector3(2.8, 1.3, -5.0), Vector3(0.7, 2.8, 0.7), Color("8b6548")),
		_pieza(Vector3(0, 4.5, -8.0), Vector3(7.0, 0.15, 2.0), Color("dfb47a"), true),
	]
	return _decorado(piezas, Color("e2a66d"), 1.4, figuras)


static func _castillo(figuras: Array = []) -> Dictionary:
	var piezas := [
		_pieza(Vector3(0, 0.0, -2.0), Vector3(7.0, 0.12, 7.0), Color("272931")),
		_pieza(Vector3(-2.2, 2.0, -4.0), Vector3(1.1, 4.0, 1.1), Color("393b45")),
		_pieza(Vector3(2.2, 2.0, -4.0), Vector3(1.1, 4.0, 1.1), Color("393b45")),
		_pieza(Vector3(0, 2.5, -4.3), Vector3(3.4, 4.8, 0.6), Color("32343c")),
		_pieza(Vector3(0, 2.8, -3.9), Vector3(0.3, 3.5, 0.1), Color("824f68"), true),
	]
	return _decorado(piezas, Color("726d93"), 0.9, figuras)


static func _vacio(figuras: Array = []) -> Dictionary:
	var piezas := [
		_pieza(Vector3(0, -0.15, -1.0), Vector3(15.0, 0.08, 15.0), Color("090a0f")),
		_pieza(Vector3(0, 5.0, -8.0), Vector3(0.18, 10.0, 0.18), Color("9b88b6"), true),
		_pieza(Vector3(-3.0, 2.0, -6.0), Vector3(0.12, 4.0, 0.12), Color("5f8b9c"), true),
		_pieza(Vector3(3.5, 3.0, -7.0), Vector3(0.12, 6.0, 0.12), Color("a97474"), true),
	]
	return _decorado(piezas, Color("6e6384"), 0.65, figuras)


static func _jardin_colgante(figuras: Array = []) -> Dictionary:
	var piezas := [
		_pieza(Vector3(0, 0.0, -2.0), Vector3(9.0, 0.16, 9.0), Color("8c744f")),
		_pieza(Vector3(-2.8, 1.4, -4.2), Vector3(1.2, 2.8, 1.2), Color("726044")),
		_pieza(Vector3(2.8, 2.1, -4.8), Vector3(1.4, 4.2, 1.4), Color("726044")),
		_pieza(Vector3(0, 1.5, -5.5), Vector3(4.6, 0.18, 2.6), Color("6f8b61")),
		_pieza(Vector3(-1.2, 2.3, -5.5), Vector3(1.6, 0.18, 1.6), Color("739b67")),
		_pieza(Vector3(1.4, 2.8, -5.8), Vector3(1.8, 0.18, 1.5), Color("789e6a")),
		_pieza(Vector3(0, 3.9, -7.2), Vector3(5.5, 0.12, 0.5), Color("91b978"), true),
	]
	return _decorado(piezas, Color("c5a86d"), 1.25, figuras)


static func _faro(figuras: Array = []) -> Dictionary:
	var piezas := [
		_pieza(Vector3(0, -0.05, -2.0), Vector3(10.0, 0.12, 10.0), Color("24313f")),
		_pieza(Vector3(0, 2.4, -5.5), Vector3(1.6, 4.8, 1.6), Color("c0b59b")),
		_pieza(Vector3(0, 5.1, -5.5), Vector3(2.0, 0.4, 2.0), Color("d3c5a2")),
		_pieza(Vector3(0, 5.4, -5.2), Vector3(0.6, 0.45, 0.6), Color("e4d48b"), true),
		_pieza(Vector3(2.7, 0.3, -4.6), Vector3(3.2, 0.45, 1.2), Color("394b5c")),
	]
	return _decorado(piezas, Color("8495a8"), 1.15, figuras)


static func _archivo_infinito(figuras: Array = []) -> Dictionary:
	var piezas := [
		_pieza(Vector3(0, 0.0, -3.0), Vector3(8.0, 0.12, 14.0), Color("303238")),
		_pieza(Vector3(0, 4.8, -8.0), Vector3(0.12, 9.0, 0.12), Color("c6b891"), true),
	]
	var modelos := []
	for fila in range(5):
		var z := -1.5 - float(fila) * 2.2
		modelos.append(_modelo("oficina_psx/file_cabinet_large", Vector3(-2.4, 0.0, z), 1.0))
		modelos.append(
			_modelo("oficina_psx/file_cabinet_large", Vector3(2.4, 0.0, z), 1.0, Vector3(0, 180, 0))
		)
	modelos.append(_modelo("bookcaseClosed", Vector3(0, 0.0, -10.5), 1.4))
	return _decorado(piezas, Color("b9b197"), 0.72, figuras, modelos)


static func _oficina_vertical(figuras: Array = []) -> Dictionary:
	var piezas := [
		_pieza(Vector3(0, 0.0, -2.0), Vector3(7.0, 0.12, 7.0), Color("46484f")),
		_pieza(Vector3(0, 3.5, -4.2), Vector3(7.0, 7.0, 0.12), Color("555861")),
	]
	var modelos := [
		_modelo("oficina_psx/desk1", Vector3(-1.4, 0.0, -0.8), 1.0),
		_modelo("oficina_psx/desk2", Vector3(2.3, 1.6, -4.0), 1.0, Vector3(0, 0, 90)),
		_modelo(
			"oficina_psx/office_chair_black", Vector3(-2.0, 4.4, -3.7), 1.0, Vector3(180, 0, 0)
		),
		_modelo("oficina_psx/computer_monitor", Vector3(2.2, 2.3, -4.0), 0.95, Vector3(0, 0, 90)),
		_modelo(
			"oficina_psx/file_cabinet_smaller", Vector3(-2.5, 1.3, -4.0), 1.0, Vector3(0, 0, -90)
		),
	]
	return _decorado(piezas, Color("d3c9ad"), 0.9, figuras, modelos)


static func _calle_subterranea(figuras: Array = []) -> Dictionary:
	var piezas := [
		_pieza(Vector3(0, -0.05, -3.0), Vector3(12.0, 0.1, 14.0), Color("282b30")),
		_pieza(Vector3(0, 5.0, -8.0), Vector3(9.0, 0.08, 0.7), Color("69717a"), true),
	]
	var modelos := [
		_modelo("traffic_road/Manhole_Cover", Vector3(-1.2, 0.02, -1.6), 1.0),
		_modelo("traffic_road/Road_Block", Vector3(2.0, 0.0, -3.2), 1.0),
		_modelo("traffic_road/Traffic_Cone", Vector3(-2.2, 0.0, -4.2), 1.0),
		_modelo("street_furniture/TrashCan", Vector3(2.7, 0.0, -5.4), 1.0),
		_modelo("street_furniture/GarbageBag", Vector3(2.3, 0.0, -5.1), 1.0),
		_modelo("psx_cars/Car03", Vector3(0.0, 0.0, -7.0), 1.0, Vector3(0, 180, 0)),
	]
	return _decorado(piezas, Color("8290a2"), 0.8, figuras, modelos)


static func ciudad_bajo_el_archivo() -> Array:
	var piel := Color("c6a18b")
	var archivista := _figura(
		Vector3(0, 0, -1.8), Color("4f5966"), piel, 1.0, "rocketbox/business_female_02", "", "work"
	)
	var visitante := _figura(
		Vector3(1.4, 0, -2.2), Color("5e5148"), piel, 1.0, "rocketbox/male_adult_05"
	)
	var planos := [
		_plano(
			"archivo-normal",
			_archivo([archivista]),
			Vector3(0, 1.7, 2.5),
			Vector3(0, 1.35, -2.0),
			3.8,
			"El último pasillo debería terminar aquí."
		),
		_plano(
			"archivo-infinito",
			_archivo_infinito([archivista]),
			Vector3(0, 1.9, 4.8),
			Vector3(0, 1.5, -7.5),
			4.6,
			"Los archivadores continúan más allá del edificio."
		),
		_plano(
			"oficina-vertical",
			_oficina_vertical([visitante]),
			Vector3(-2.2, 2.1, 4.4),
			Vector3(0, 2.4, -3.6),
			4.5,
			"En la siguiente planta, la gravedad pertenece a otro departamento."
		),
		_plano(
			"techo",
			_oficina_vertical([archivista, visitante]),
			Vector3(2.4, 3.6, 3.8),
			Vector3(-1.0, 3.2, -3.7),
			4.2,
			"Hay empleados trabajando en la pared."
		),
		_plano(
			"calle-subterranea",
			_calle_subterranea([archivista]),
			Vector3(-2.8, 1.6, 5.0),
			Vector3(0, 1.2, -5.8),
			4.8,
			"Debajo del archivo aparece una calle sin cielo."
		),
		_plano(
			"coche",
			_calle_subterranea([visitante]),
			Vector3(2.2, 1.4, 3.6),
			Vector3(0, 1.0, -6.8),
			4.0,
			"Un coche lleva años esperando un semáforo que no existe."
		),
		_plano(
			"archivo-sobre-calle",
			_archivo_infinito([archivista, visitante]),
			Vector3(0, 2.5, 5.5),
			Vector3(0, 2.0, -8.5),
			4.8,
			"Los edificios de la ciudad son archivadores vistos desde dentro."
		),
		_plano(
			"oficina-caida",
			_oficina_vertical([archivista]),
			Vector3(0, 4.2, 3.0),
			Vector3(0, 1.2, -3.5),
			4.4,
			"Tu mesa cae hacia arriba."
		),
		_plano(
			"retorno",
			_archivo([archivista]),
			Vector3(0, 1.7, 2.3),
			Vector3(0, 1.35, -2.0),
			3.6,
			"La puerta vuelve a ser una puerta."
		),
		_plano(
			"remate-ciudad",
			_vacio([]),
			Vector3(0, 1.8, 3.3),
			Vector3(0, 1.8, -4.0),
			3.0,
			"PLANTA ACTUAL: -∞"
		),
	]
	planos[0]["camara_desde"] = Vector3(2.0, 1.8, 3.0)
	planos[4]["fundido_desde"] = 0.0
	planos[4]["fundido_hasta"] = 0.3
	planos[9]["fundido_desde"] = 0.0
	planos[9]["fundido_hasta"] = 1.0
	return planos


static func cinco_oficinas_del_tiempo() -> Array:
	var piel := Color("c5a18a")
	var puyi := _figura(
		Vector3(-2.0, 0, -2.1),
		Color("4d5666"),
		piel,
		1.0,
		"rocketbox/business_male_02",
		"emperador",
		"work"
	)
	var melville := _figura(
		Vector3(-1.0, 0, -2.0),
		Color("485263"),
		piel,
		1.0,
		"rocketbox/male_adult_05",
		"aduanero_ny",
		"work"
	)
	var pessoa := _figura(
		Vector3(0, 0, -2.0),
		Color("66534a"),
		piel,
		1.0,
		"rocketbox/business_male_03",
		"correspondencia",
		"work"
	)
	var cavafis := _figura(
		Vector3(1.0, 0, -2.0),
		Color("5b6268"),
		piel,
		1.0,
		"rocketbox/business_male_04",
		"riegos",
		"work"
	)
	var rousseau := _figura(
		Vector3(2.0, 0, -2.1),
		Color("556050"),
		piel,
		1.0,
		"rocketbox/male_adult_03",
		"fielato",
		"work"
	)
	var cinco := [puyi, melville, pessoa, cavafis, rousseau]
	var planos := [
		_plano(
			"fichaje",
			_oficina(cinco),
			Vector3(0, 1.8, 4.2),
			Vector3(0, 1.35, -2.0),
			4.5,
			"Cinco empleados fichan con un siglo de diferencia."
		),
		_plano(
			"puyi",
			_archivo([puyi]),
			Vector3(-1.7, 1.7, 2.8),
			Vector3(-1.8, 1.4, -2.0),
			4.0,
			"Puyi ordena documentos de un imperio convertido en departamento."
		),
		_plano(
			"melville",
			_calle_subterranea([melville]),
			Vector3(2.2, 1.6, 4.5),
			Vector3(-0.8, 1.35, -2.2),
			4.2,
			"Melville inspecciona una aduana sin puerto."
		),
		_plano(
			"pessoa",
			_oficina_vertical([pessoa]),
			Vector3(-2.0, 2.1, 3.8),
			Vector3(0, 1.5, -3.6),
			4.2,
			"Pessoa redacta cartas para empresas que todavía no existen."
		),
		_plano(
			"cavafis",
			_faro([cavafis]),
			Vector3(2.4, 2.4, 5.0),
			Vector3(0.8, 2.4, -5.2),
			4.4,
			"Cavafis registra el agua mientras Alejandría arde fuera de horario."
		),
		_plano(
			"rousseau",
			_jardin_colgante([rousseau]),
			Vector3(-2.5, 2.2, 4.7),
			Vector3(1.8, 1.8, -4.8),
			4.4,
			"Rousseau pinta una selva detrás del mostrador del fielato."
		),
		_plano(
			"cinco-archivo",
			_archivo_infinito(cinco),
			Vector3(0, 2.1, 5.6),
			Vector3(0, 1.8, -7.8),
			5.0,
			"Sus expedientes ocupan el mismo pasillo."
		),
		_plano(
			"cinco-pared",
			_oficina_vertical(cinco),
			Vector3(2.6, 3.0, 4.8),
			Vector3(0, 2.5, -3.8),
			4.8,
			"Cuando la oficina gira, ninguno deja de trabajar."
		),
		_plano(
			"cinco-vacio",
			_vacio(cinco),
			Vector3(0, 2.0, 5.4),
			Vector3(0, 1.8, -3.0),
			4.8,
			"Cinco biografías terminan en la misma nómina."
		),
		_plano(
			"cierre-historico",
			_archivo([]),
			Vector3(0, 1.7, 2.4),
			Vector3(0, 1.5, -2.8),
			3.6,
			"ANTIGÜEDAD RECONOCIDA: NO CONSTA"
		),
	]
	planos[0]["camara_desde"] = Vector3(3.2, 1.9, 4.8)
	planos[6]["fundido_desde"] = 0.0
	planos[6]["fundido_hasta"] = 0.25
	planos[9]["fundido_desde"] = 0.0
	planos[9]["fundido_hasta"] = 1.0
	return planos
