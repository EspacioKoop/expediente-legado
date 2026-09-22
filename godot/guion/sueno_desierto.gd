## Identidad lógica del desierto onírico (#284).
##
## Reutiliza la familia FRAGMENTADA como extensión mineral abierta. El contenido
## sigue naciendo en #87: una frase ya conocida se desplaza al teléfono aislado
## y el resto de anomalías no modifica expediente, economía ni veredictos.
class_name SuenoDesierto
extends RefCounted

const ID := "desierto"
const FORMA := "peine"
const FAMILIA := SuenoFamilias.FRAGMENTADA


static func es_forma(id: String) -> bool:
	return id == FORMA


static func adaptar_espacio(
	espacio_base: Dictionary, estado_presentacion: Dictionary = {}
) -> Dictionary:
	if espacio_base.is_empty():
		return {}

	var familia := SuenoFamilias.de(FAMILIA)
	if familia.is_empty():
		return espacio_base.duplicate(true)

	var resultado := espacio_base.duplicate(true)
	resultado["identidad_onirica"] = ID
	resultado["estado_presentacion"] = estado_presentacion.duplicate(true)
	resultado["exterior"] = true
	resultado["ambiente"] = Color(0.58, 0.43, 0.26)
	resultado["ambiente_energia"] = 0.64
	resultado["sol"] = 0.72
	resultado["contorno"] = familia["contorno"]
	resultado["altura_contorno"] = float(familia.get("altura", 3.0))
	resultado["tabiques_poligonales"] = familia.get("tabiques", []).duplicate(true)
	resultado["entrada"] = Vector3(familia.get("entrada", Vector3(-10, 0, -10)))

	var anclas: Array = familia.get("anclas", []).duplicate(true)
	var telefono_pos := Vector3(6, 0, -8)
	var archivador_pos := Vector3(-3, 0, 7)
	var salida_pos := Vector3(9, 0, 8)
	if anclas.size() > 0:
		telefono_pos = Vector3(anclas[0])
	if anclas.size() > 1:
		archivador_pos = Vector3(anclas[1])
	if anclas.size() > 2:
		salida_pos = Vector3(anclas[2])
	var papel_pos := telefono_pos.lerp(archivador_pos, 0.56) + Vector3(1.2, 0, 0.8)
	resultado["desierto_telefono_pos"] = telefono_pos
	resultado["desierto_archivador_pos"] = archivador_pos
	resultado["desierto_papel_pos"] = papel_pos

	# El `peine` histórico conserva timing/mapa, pero su salida ortogonal ya no
	# pertenece a esta silueta. Solo se cambia la posición del mismo destino.
	var salidas: Array = resultado.get("salidas", []).duplicate(true)
	if not salidas.is_empty():
		var salida_principal: Dictionary = salidas[0].duplicate(true)
		salida_principal["pos"] = salida_pos + Vector3(0, 1.1, 0)
		salidas[0] = salida_principal
	resultado["salidas"] = salidas

	# Figuras y textos del `peine` venían en coordenadas de celdas. Se conservan
	# como contenido, pero se recolocan en anclas caminables de la familia nueva.
	var sitios := [telefono_pos, archivador_pos, papel_pos]
	var figuras: Array = resultado.get("figuras", []).duplicate(true)
	for i in figuras.size():
		var figura: Dictionary = figuras[i].duplicate(true)
		figura["pos"] = sitios[i % sitios.size()] + Vector3(0, 0, 1.6)
		figuras[i] = figura
	resultado["figuras"] = figuras

	var carteles: Array = resultado.get("carteles", []).duplicate(true)
	var frase_conocida := ""
	if not carteles.is_empty():
		var primero: Dictionary = carteles.pop_front()
		frase_conocida = String(primero.get("texto", "")).strip_edges()
	for i in carteles.size():
		var cartel: Dictionary = carteles[i].duplicate(true)
		cartel["pos"] = sitios[(i + 1) % sitios.size()] + Vector3(0, 1.55, 0)
		cartel["giro"] = 0.0
		carteles[i] = cartel
	resultado["carteles"] = carteles

	resultado["luces"] = [
		{
			"pos": telefono_pos + Vector3(0, 2.2, 0),
			"color": Color(0.88, 0.58, 0.28),
			"energia": 0.82,
			"alcance": 7.0,
			"carcasa": false,
		},
	]
	resultado["anomalias_oniricas"] = {
		"horizonte_recede": {"activa": true},
		"silencio_local": {"activa": true},
		"huellas_geometricas": {"activa": true},
		"papel_enterrado": {"activa": true, "pos": papel_pos},
		"telefono_con_tono": {"activa": true, "pos": telefono_pos},
	}

	# El teléfono no inventa una voz: al acercarse devuelve exactamente una
	# frase que el sueño ya había recibido del contenido conocido de #87.
	if not frase_conocida.is_empty():
		(
			salidas
			. append(
				{
					"pos": telefono_pos + Vector3(0, 1.15, 0),
					"destino": "",
					"frase": frase_conocida,
					"tam": Vector3(2.8, 2.4, 2.8),
					"visible": false,
				}
			)
		)
		resultado["salidas"] = salidas

	return resultado
