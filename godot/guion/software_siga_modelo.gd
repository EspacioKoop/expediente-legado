## Catálogo y estado local del shareware/freeware ficticio del OS98 (#663).
##
## Es una simulación pura: describe paquetes y conserva únicamente qué software se
## instaló y cuántas veces se ejecutó. No abre procesos, sockets ni rutas del host.
class_name SoftwareSigaModelo
extends RefCounted

const PAQUETES := [
	{
		"id": "pixelvista-14",
		"nombre": "PixelVista 1.4",
		"tipo": "Visor de imágenes",
		"version": "1.4",
		"licencia": "freeware",
		"tamano_kb": 864,
		"origen_superficie": "cd",
		"origen": "CD Archivo 98 · Utilidades gráficas",
		"descripcion": "Visor rápido para GIF, BMP y formatos ficticios del archivo corporativo.",
		"interaccion": "visor",
	},
	{
		"id": "archivazo-21",
		"nombre": "Archivazo 2.1",
		"tipo": "Compresor",
		"version": "2.1",
		"licencia": "shareware",
		"tamano_kb": 512,
		"origen_superficie": "bbs",
		"origen": "Byte Local BBS · Área de ficheros",
		"descripcion":
		"Empaqueta carpetas en contenedores .AZO. La compresión es enteramente simulada.",
		"interaccion": "compresor",
	},
	{
		"id": "bannerlab-95",
		"nombre": "BannerLab 95",
		"tipo": "Texto decorativo",
		"version": "0.95b",
		"licencia": "freeware",
		"tamano_kb": 248,
		"origen_superficie": "web",
		"origen": "Web personal · /descargas/bannerlab.zip",
		"descripcion": "Genera rótulos ASCII para firmas, tablones y documentos internos.",
		"interaccion": "banner",
	},
	{
		"id": "nebulosa-scr",
		"nombre": "Nebulosa.scr",
		"tipo": "Salvapantallas",
		"version": "3.0",
		"licencia": "freeware",
		"tamano_kb": 332,
		"origen_superficie": "disquete",
		"origen": "Disquete sin etiqueta · recomendado por un compañero",
		"descripcion": "Campo estelar configurable con densidad, estelas y reloj opcional.",
		"interaccion": "salvapantallas",
	},
	{
		"id": "relojito-pro",
		"nombre": "Relojito Pro",
		"tipo": "Reloj / alarma",
		"version": "1.8 TRIAL",
		"licencia": "trial",
		"tamano_kb": 176,
		"origen_superficie": "correo",
		"origen": "Adjunto controlado de correo · RELOJ18.ZIP",
		"descripcion":
		"Reloj de sobremesa con alarmas ficticias. El trial solo aporta ambientación.",
		"interaccion": "reloj",
	},
	{
		"id": "iconomatic-12",
		"nombre": "IconoMatic 1.2",
		"tipo": "Editor de iconos",
		"version": "1.2",
		"licencia": "shareware",
		"tamano_kb": 624,
		"origen_superficie": "bbs",
		"origen": "BBS La Escotilla · Gráficos",
		"descripcion": "Editor de iconos 16×16 y 32×32 con una paleta reducida de oficina.",
		"interaccion": "iconos",
	},
	{
		"id": "turboindice-98",
		"nombre": "TurboÍndice 98",
		"tipo": "Benchmark absurdo",
		"version": "98.4",
		"licencia": "freeware",
		"tamano_kb": 96,
		"origen_superficie": "web",
		"origen": "Mirror universitario · utilidades/bench",
		"descripcion": "Mide un supuesto Índice Administrativo Total sin consultar hardware real.",
		"interaccion": "benchmark",
	},
	{
		"id": "astro-topo-demo",
		"nombre": "Astro Topo DEMO",
		"tipo": "Demo de juego",
		"version": "0.9",
		"licencia": "demo",
		"tamano_kb": 1420,
		"origen_superficie": "cd",
		"origen": "CD Revista Byte Lunar · DEMOS",
		"descripcion":
		"Demo de un minuto: un topo astronauta recoge tres tornillos y vuelve al módulo.",
		"interaccion": "demo",
	},
]

var _instalados: Array[String] = []
var _ejecuciones: Dictionary = {}
var _obtenidos: Array[String] = []


func catalogo() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	for paquete in PAQUETES:
		var copia := (paquete as Dictionary).duplicate(true)
		copia["obtenido"] = esta_obtenido(String(copia.get("id", "")))
		salida.append(copia)
	return salida


func ficha(id: String) -> Dictionary:
	for paquete in PAQUETES:
		if String((paquete as Dictionary).get("id", "")) == id:
			return (paquete as Dictionary).duplicate(true)
	return {}


func esta_obtenido(id: String) -> bool:
	return _obtenidos.has(id)


func registrar_obtencion(id: String) -> bool:
	if ficha(id).is_empty():
		return false
	if not _obtenidos.has(id):
		_obtenidos.append(id)
		_obtenidos.sort()
	return true


func esta_instalado(id: String) -> bool:
	return _instalados.has(id)


func instalar(id: String) -> bool:
	if ficha(id).is_empty():
		return false
	if not _instalados.has(id):
		_instalados.append(id)
		_instalados.sort()
	return true


func desinstalar(id: String) -> bool:
	if not _instalados.has(id):
		return false
	_instalados.erase(id)
	return true


func ejecutar(id: String) -> Dictionary:
	if not esta_instalado(id):
		return {"ok": false, "mensaje": "El programa no está instalado."}
	var paquete := ficha(id)
	if paquete.is_empty():
		return {"ok": false, "mensaje": "Paquete desconocido."}

	var numero := int(_ejecuciones.get(id, 0)) + 1
	_ejecuciones[id] = numero
	var mensaje := ""
	match String(paquete.get("interaccion", "")):
		"benchmark":
			# Resultado deliberadamente ficticio y determinista: nunca inspecciona CPU/GPU.
			var indice := 680 + numero * 13
			mensaje = (
				"Índice Administrativo Total: %d puntos. Archivo de sellos: EXCELENTE." % indice
			)
		"banner":
			mensaje = "===  EXPEDIENTE  ===  · rótulo generado en memoria."
		"demo":
			mensaje = "Astro Topo: 3 tornillos encontrados. DEMO COMPLETADA."
		"reloj":
			mensaje = "Alarma ficticia programada para dentro de 15 minutos narrativos."
		"salvapantallas":
			mensaje = "Vista previa: 48 estrellas, estela corta, reloj desactivado."
		"compresor":
			mensaje = "Simulación: 12 archivos → ARCHIVO.AZO (41% de ahorro ficticio)."
		"iconos":
			mensaje = "Lienzo 32×32 abierto con paleta de 16 colores."
		_:
			mensaje = "PixelVista muestra una imagen de ejemplo integrada."
	return {"ok": true, "mensaje": mensaje}


func exportar_estado() -> Dictionary:
	return {
		"instalados": _instalados.duplicate(),
		"ejecuciones": _ejecuciones.duplicate(true),
		"obtenidos": _obtenidos.duplicate(),
	}


func importar_estado(estado: Dictionary) -> void:
	_instalados.clear()
	_ejecuciones.clear()
	_obtenidos.clear()
	var obtenidos: Variant = estado.get("obtenidos", [])
	if obtenidos is Array:
		for valor in obtenidos as Array:
			var id := String(valor)
			if not ficha(id).is_empty() and not _obtenidos.has(id):
				_obtenidos.append(id)
	_obtenidos.sort()
	var instalados: Variant = estado.get("instalados", [])
	if instalados is Array:
		for valor in instalados as Array:
			var id := String(valor)
			if not ficha(id).is_empty() and not _instalados.has(id):
				_instalados.append(id)
				if not _obtenidos.has(id):
					_obtenidos.append(id)
	_instalados.sort()
	_obtenidos.sort()
	var ejecuciones: Variant = estado.get("ejecuciones", {})
	if ejecuciones is Dictionary:
		for clave in (ejecuciones as Dictionary).keys():
			var id := String(clave)
			if not ficha(id).is_empty():
				_ejecuciones[id] = max(0, int((ejecuciones as Dictionary).get(clave, 0)))
