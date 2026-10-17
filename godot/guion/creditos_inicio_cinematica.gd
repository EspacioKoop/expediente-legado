## Créditos #795, corte 2: cuarenta encuadres sobre lugares del juego.
##
## Los nombres y atribuciones solo proceden de CreditosInicio. La lista larga
## sigue en el catálogo canónico para el corte 4: la apertura deja respirar
## lugares concretos de la oficina, el trayecto, la casa y las pesadillas.
## Ningún estado de Partida/Jornada se modifica desde esta pieza.
class_name CreditosInicioCinematica
extends RefCounted

const ID := "creditos-inicio"
const DURACION_PLANO := 2.1

## Cada zona enfoca un lugar físico distinto; un recorte del atrezo próximo
## evita presentar cuarenta veces una sala idéntica con otra cámara.
## Coordenadas de EspaciosCatalogo: ocho rincones de oficina, ocho tramos
## de calle y seis rincones de casa (22 localizaciones de vigilia).
const ZONAS_DIA := [
	{"id": "archivo-puesto-norte", "sitio": "oficina", "camara": Vector3(-1.8, 1.65, 0.0), "mira": Vector3(-4.2, 1.0, -2.0)},
	{"id": "archivo-clasificacion", "sitio": "oficina", "camara": Vector3(1.7, 1.55, 2.4), "mira": Vector3(3.6, 0.9, 0.0)},
	{"id": "archivo-armarios", "sitio": "oficina", "camara": Vector3(2.6, 1.7, -1.4), "mira": Vector3(5.4, 1.2, -2.7)},
	{"id": "archivo-cafetera", "sitio": "oficina", "camara": Vector3(-3.9, 1.6, 2.8), "mira": Vector3(-6.0, 1.0, 4.1)},
	{"id": "archivo-tablon", "sitio": "oficina", "camara": Vector3(-0.8, 1.7, -2.1), "mira": Vector3(-1.5, 1.7, -4.8)},
	{"id": "archivo-puesto-sur", "sitio": "oficina", "camara": Vector3(2.7, 1.58, 3.0), "mira": Vector3(1.0, 1.0, 1.0)},
	{"id": "archivo-puerta", "sitio": "oficina", "camara": Vector3(-3.8, 1.6, 2.1), "mira": Vector3(-6.8, 1.1, 3.5)},
	{"id": "archivo-ventanas", "sitio": "oficina", "camara": Vector3(0.8, 1.65, 2.0), "mira": Vector3(2.6, 1.7, 4.85)},
	{"id": "calle-extremo-sur", "sitio": "calle", "camara": Vector3(-0.4, 1.65, -14.0), "mira": Vector3(-2.6, 1.7, -11.0)},
	{"id": "calle-primera-farola", "sitio": "calle", "camara": Vector3(1.2, 1.6, -10.5), "mira": Vector3(0.0, 2.5, -10.0)},
	{"id": "calle-cartel-sur", "sitio": "calle", "camara": Vector3(-0.7, 1.6, -7.2), "mira": Vector3(-3.7, 1.7, -8.0)},
	{"id": "calle-fachada-oeste", "sitio": "calle", "camara": Vector3(0.7, 1.6, -3.7), "mira": Vector3(-3.2, 1.4, -2.8)},
	{"id": "calle-cruce-central", "sitio": "calle", "camara": Vector3(0.2, 1.7, 0.0), "mira": Vector3(3.1, 1.4, 1.0)},
	{"id": "calle-cartel-norte", "sitio": "calle", "camara": Vector3(-0.6, 1.65, 3.4), "mira": Vector3(-3.7, 1.7, 2.4)},
	{"id": "calle-tercera-farola", "sitio": "calle", "camara": Vector3(1.4, 1.65, 9.3), "mira": Vector3(0.0, 2.5, 10.0)},
	{"id": "calle-portal", "sitio": "calle", "camara": Vector3(-0.4, 1.65, 13.0), "mira": Vector3(0.0, 1.2, 15.5)},
	{"id": "casa-cama", "sitio": "casa", "camara": Vector3(-0.7, 1.55, 1.0), "mira": Vector3(-2.4, 0.8, -2.0)},
	{"id": "casa-televisor", "sitio": "casa", "camara": Vector3(-1.6, 1.6, 2.6), "mira": Vector3(-3.55, 1.1, 1.35)},
	{"id": "casa-comedero-gato", "sitio": "casa", "camara": Vector3(1.0, 1.55, 3.1), "mira": Vector3(2.8, 0.3, 1.5)},
	{"id": "casa-cocina", "sitio": "casa", "camara": Vector3(2.1, 1.7, -0.6), "mira": Vector3(4.6, 1.2, -1.6)},
	{"id": "casa-pasillo", "sitio": "casa", "camara": Vector3(0.6, 1.65, -2.4), "mira": Vector3(0.0, 1.3, 1.0)},
	{"id": "casa-entrada", "sitio": "casa", "camara": Vector3(2.0, 1.6, 1.5), "mira": Vector3(0.5, 1.2, 3.4)},
]

## Siete espacios oníricos por datos. Ni textos del día inventados ni cambios
## en la selección jugable de sueños. La semilla local del Duat solo configura
## el decorado cinematográfico, no se escribe en la jornada del jugador.
const FORMAS_SUENO := [
	{"id": "vacio", "forma": "escalera", "camara": Vector3(-5.0, 2.1, 7.0), "mira": Vector3(0.0, 1.2, 0.0)},
	{"id": "escuela", "forma": "crucero", "camara": Vector3(-9.5, 1.65, -10.5), "mira": Vector3(2.0, 1.35, 2.5)},
	{"id": "montana", "forma": "embudo", "camara": Vector3(-10.5, 1.65, -11.5), "mira": Vector3(5.2, 1.25, 2.0)},
	{"id": "desierto", "forma": "peine", "camara": Vector3(-9.5, 1.65, -9.0), "mira": Vector3(5.0, 1.35, 0.0)},
	{"id": "castillo", "forma": "patio", "camara": Vector3(-13.0, 1.65, 11.5), "mira": Vector3(-1.5, 1.55, 0.0)},
	{"id": "duat", "forma": "gilgamesh", "camara": Vector3(5.0, 2.5, 10.0), "mira": Vector3(0.0, 1.2, -4.0)},
	{"id": "horror-texturas", "forma": "escalera", "camara": Vector3(8.5, 1.8, -8.0), "mira": Vector3(0.0, 1.25, 0.0)},
]

## Once verticales existentes: cada una tiene arquitectura propia, y se monta
## directamente gracias a Espacio3D.escena, integrado por #2526.
const VERTICALES := [
	"res://escenas/sueno_anansi_akan.tscn",
	"res://escenas/sueno_aquiles.tscn",
	"res://escenas/sueno_aquiles_alineacion.tscn",
	"res://escenas/sueno_baba_yaga.tscn",
	"res://escenas/sueno_gilgamesh.tscn",
	"res://escenas/sueno_mari.tscn",
	"res://escenas/sueno_maui_tamanuitera.tscn",
	"res://escenas/sueno_popol_wuj.tscn",
	"res://escenas/sueno_simurgh.tscn",
	"res://escenas/sueno_tir_na_nog.tscn",
	"res://escenas/sueno_yggdrasil.tscn",
]


static func planos() -> Array:
	var bloques: Array = CreditosInicio.bloques_completos()
	var salida: Array = []
	for zona in ZONAS_DIA:
		var indice := salida.size()
		salida.append(_plano(
			String(zona["id"]), _decorado_dia(zona),
			Vector3(zona["camara"]), Vector3(zona["mira"]), indice, bloques
		))

	for forma in FORMAS_SUENO:
		var indice := salida.size()
		salida.append(_plano(
			"sueno-" + String(forma["id"]), _decorado_sueno(forma),
			Vector3(forma["camara"]), Vector3(forma["mira"]), indice, bloques
		))

	for ruta in VERTICALES:
		var indice := salida.size()
		var n := indice - ZONAS_DIA.size() - FORMAS_SUENO.size()
		var angulo := 0.48 * float(n) + 0.40
		var camara := Vector3(5.5 * cos(angulo), 1.9 + 0.12 * float(n % 4), 5.5 * sin(angulo))
		var mira := Vector3(0.0, 1.2, 0.0)
		salida.append(_plano(
			ruta.get_file().get_basename(), {"escena": ruta},
			camara, mira, indice, bloques
		))

	# Título al final y sin una pantalla negra 2D: lo cierra la última vertical.
	salida[salida.size() - 1]["segundos"] = 4.0
	salida[salida.size() - 1]["fundido_desde"] = 0.0
	salida[salida.size() - 1]["fundido_hasta"] = 0.18
	return Cinematica.resolver(salida)


static func _plano(
	nombre: String, decorado: Dictionary, camara: Vector3, mira: Vector3,
	indice: int, bloques: Array
) -> Dictionary:
	# Travellings breves, con vectores distintos en cada localización. El
	# reproductor fija la cámara en "camara" si hay reducción de movimiento.
	var paso := Vector3(
		0.10 + 0.04 * float(indice % 5), 0.02,
		-0.15 - 0.025 * float(indice % 7)
	)
	return {
		"tipo": "3d",
		"nombre": nombre,
		"decorado": decorado,
		"camara_desde": camara + paso,
		"mira_desde": mira,
		"camara": camara,
		"mira": mira,
		"segundos": DURACION_PLANO,
		"rotulo": _rotulo_para(indice, bloques),
		# "voz" queda ausente: no se usa la franja de subtítulos para créditos.
	}


static func _decorado_dia(zona: Dictionary) -> Dictionary:
	var sitio := String(zona["sitio"])
	var decorado: Dictionary
	match sitio:
		"oficina":
			decorado = EspaciosCatalogo.OFICINA.duplicate(true)
		"calle":
			decorado = EspaciosCatalogo.CALLE.duplicate(true)
		_:
			decorado = EspaciosCatalogo.CASA.duplicate(true)
	# Localización identificable, no un decorado cíclico con cinco travellings.
	# Los muebles de la misma sala fuera del encuadre se omiten del plató para
	# que el contenido 3D de cada zona sea realmente distinto, no solo su etiqueta.
	var objetivo: Vector3 = zona["mira"]
	var objetos: Array = []
	for objeto in decorado.get("bultos", []):
		if not (objeto is Dictionary):
			continue
		var pos: Vector3 = objeto.get("pos", Vector3.ZERO)
		if Vector2(pos.x, pos.z).distance_to(Vector2(objetivo.x, objetivo.z)) <= 4.3:
			objetos.append(objeto)
	decorado["bultos"] = objetos
	decorado["zona_creditos"] = String(zona["id"])
	return decorado


static func _decorado_sueno(forma: Dictionary) -> Dictionary:
	var id := String(forma["id"])
	var base := Sueno.espacio(String(forma["forma"]), 0)
	match id:
		"vacio":
			return SuenoVacio.adaptar_espacio(base)
		"escuela":
			return SuenoEscuela.adaptar_espacio(base)
		"montana":
			return SuenoMontana.adaptar_espacio(base)
		"desierto":
			return SuenoDesierto.adaptar_espacio(base)
		"castillo":
			return SuenoCastillo.adaptar_espacio(base)
		"duat":
			var jornada_local := {"dia": 1}
			SemillasOniricas.activar_semilla_onirica(
				jornada_local, SuenoDuat.ID, SuenoDuat.FUENTE_TV
			)
			return SuenoDuat.adaptar_espacio(base, jornada_local, [], 0, true)
		_:
			var horror := HorrorTexturas.aplicar(base, String(forma["forma"]), 2)
			horror["identidad_onirica"] = "horror-texturas"
			return horror


## Un nombre, no una página de atribuciones. El catálogo completo permanece
## accesible para el corte 4; no se hardcodean nombres ni licencias aquí.
static func _rotulo_para(indice: int, bloques: Array) -> String:
	var id := ""
	var entrada := 0
	match indice:
		0, 4, 8:
			id = "open_source"
			entrada = int(indice / 4)
		16:
			id = "agradecimientos"
		24, 26, 29, 33:
			id = "desarrollo"
			match indice:
				24: entrada = 0
				26: entrada = 1
				29: entrada = 2
				_: entrada = 3
		38:
			id = "direccion"
		39:
			id = "titulo"
	if id.is_empty():
		return ""
	for bloque in bloques:
		if String(bloque.get("id", "")) != id:
			continue
		var entradas: Array = bloque.get("entradas", [])
		if entrada >= entradas.size() or not (entradas[entrada] is Dictionary):
			return ""
		return String(entradas[entrada].get("nombre", "")).strip_edges()
	return ""
