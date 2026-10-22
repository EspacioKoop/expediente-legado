## Índice de los assets REALES del proyecto para la biblioteca del editor (#2942).
##
## La biblioteca anterior ofrecía los cinco nombres de `Modelos.MATERIALES_MUEBLE`:
## una lista escrita a mano que no crece cuando entra un asset nuevo. Aquí no hay
## lista: se recorre el proyecto y se ofrece lo que hay. Un pack que alguien
## añada mañana aparece sin tocar este archivo, y uno que se borre deja de
## aparecer sin dejar una entrada muerta en un diccionario.
##
## Tres decisiones que no son de comodidad:
##
## 1. **El índice se construye leyendo el disco, no declarándolo.** Es la única
##    forma de que «todos los assets» signifique todos y no «los que alguien
##    recordó apuntar».
## 2. **La ruta es el identificador.** Un asset se guarda en el documento como su
##    `res://…` completa, así que el nivel o la cinemática apuntan a un archivo
##    verificable; un nombre suelto sólo resuelve dentro de `assets/modelos/` y
##    dejaba fuera todo `arte/`.
## 3. **Se mide antes de colocar.** Al insertar se calcula el AABB real del asset
##    y se escribe como `tam`, porque `Modelos` encaja la pieza en el `tam`
##    declarado: con un `tam` inventado, un árbol de ocho metros entraría
##    aplastado en un cubo de uno. Medir es lo que hace que la previsualización y
##    el juego coincidan.
extends RefCounted

## Carpetas donde vive el contenido del juego. `.godot/` y los directorios de
## trabajo quedan fuera: no son assets, son caché del importador.
const RAICES: Array[String] = [
	"res://assets/",
	"res://arte/",
	"res://espacios/",
	"res://escenas/",
	"res://interactables/",
	"res://rituales/",
	"res://scenes/",
]

const EXTENSIONES := {
	"modelo": [".glb", ".gltf", ".fbx", ".obj"],
	"escena": [".tscn", ".scn"],
	"imagen": [".png", ".jpg", ".jpeg", ".webp", ".svg"],
	"audio": [".ogg", ".wav", ".mp3"],
	"material": [".tres", ".res", ".gdshader"],
	"fuente": [".ttf", ".otf"],
}

## Lo que se puede meter en un decorado o en un nivel como pieza 3D. Una imagen
## o un audio del proyecto siguen siendo visibles en el índice —se consultan y
## se copia su ruta—, pero no se colocan como bulto: su contrato es otro.
const TIPOS_COLOCABLES: Array[String] = ["modelo", "escena"]

const TIPO_OTRO := "otro"

## Sufijos que el exportador añade a un recurso importado. Al escanear un `.pck`
## el archivo fuente ya no está y lo que aparece es su remapeo; sin normalizarlo,
## la biblioteca saldría vacía en un build exportado.
const SUFIJOS_DERIVADOS: Array[String] = [".import", ".remap"]

static var _cache: Array[Dictionary] = []


## Todos los assets del proyecto, ordenados por ruta. Se cachea porque recorrer
## el árbol en cada pulsación de tecla del buscador sería un escaneo por letra.
static func indice(recargar: bool = false) -> Array[Dictionary]:
	if not recargar and not _cache.is_empty():
		return _cache
	var encontrados: Dictionary = {}
	for raiz in RAICES:
		_recorrer(raiz, encontrados)
	var rutas: Array = encontrados.keys()
	rutas.sort()
	var salida: Array[Dictionary] = []
	for ruta in rutas:
		salida.append(encontrados[ruta])
	_cache = salida
	return _cache


static func _recorrer(carpeta: String, encontrados: Dictionary) -> void:
	var dir := DirAccess.open(carpeta)
	if dir == null:
		return
	dir.list_dir_begin()
	var nombre := dir.get_next()
	while not nombre.is_empty():
		if nombre.begins_with("."):
			nombre = dir.get_next()
			continue
		var ruta := carpeta.path_join(nombre)
		if dir.current_is_dir():
			_recorrer(ruta, encontrados)
		else:
			var real := _normalizar(ruta)
			if not real.is_empty() and not encontrados.has(real):
				var entrada := _entrada(real)
				if not entrada.is_empty():
					encontrados[real] = entrada
		nombre = dir.get_next()
	dir.list_dir_end()


## Quita el sufijo del importador y descarta lo que no es un asset consultable.
static func _normalizar(ruta: String) -> String:
	var real := ruta
	for sufijo in SUFIJOS_DERIVADOS:
		if real.ends_with(sufijo):
			real = real.substr(0, real.length() - sufijo.length())
			break
	var extension := "." + real.get_extension().to_lower()
	if extension == ".":
		return ""
	if tipo_de(real) == TIPO_OTRO and not _extension_conocida(extension):
		return ""
	return real


static func _extension_conocida(extension: String) -> bool:
	for tipo in EXTENSIONES:
		if EXTENSIONES[tipo].has(extension):
			return true
	return false


static func _entrada(ruta: String) -> Dictionary:
	var tipo := tipo_de(ruta)
	return {
		"ruta": ruta,
		"nombre": ruta.get_file().get_basename(),
		"carpeta": carpeta_de(ruta),
		"tipo": tipo,
		"colocable": TIPOS_COLOCABLES.has(tipo),
	}


static func tipo_de(ruta: String) -> String:
	var extension := "." + ruta.get_extension().to_lower()
	for tipo in EXTENSIONES:
		if EXTENSIONES[tipo].has(extension):
			return String(tipo)
	return TIPO_OTRO


## La carpeta que agrupa el asset, sin el `res://`. Es lo que se ofrece como
## categoría: `assets/modelos/household_goods` dice de dónde viene la pieza, y
## eso en un pack de cincuenta objetos importa más que su nombre de archivo.
static func carpeta_de(ruta: String) -> String:
	return ruta.trim_prefix("res://").get_base_dir()


static func carpetas(entradas: Array = []) -> PackedStringArray:
	var origen: Array = entradas if not entradas.is_empty() else indice()
	var vistas: Dictionary = {}
	for entrada in origen:
		vistas[String(entrada.get("carpeta", ""))] = true
	var claves: Array = vistas.keys()
	claves.sort()
	var salida := PackedStringArray()
	for clave in claves:
		salida.append(String(clave))
	return salida


static func tipos(entradas: Array = []) -> PackedStringArray:
	var origen: Array = entradas if not entradas.is_empty() else indice()
	var vistos: Dictionary = {}
	for entrada in origen:
		vistos[String(entrada.get("tipo", TIPO_OTRO))] = true
	var claves: Array = vistos.keys()
	claves.sort()
	var salida := PackedStringArray()
	for clave in claves:
		salida.append(String(clave))
	return salida


## Filtra por carpeta, tipo y texto libre. Una cadena vacía en carpeta o tipo
## significa «todas»: el buscador no obliga a elegir antes de poder buscar.
static func filtrar(
	carpeta: String = "", tipo: String = "", texto: String = "", solo_colocables: bool = false
) -> Array[Dictionary]:
	var aguja := texto.strip_edges().to_lower()
	var salida: Array[Dictionary] = []
	for entrada in indice():
		if solo_colocables and not bool(entrada.get("colocable", false)):
			continue
		if not carpeta.is_empty() and String(entrada.get("carpeta", "")) != carpeta:
			continue
		if not tipo.is_empty() and String(entrada.get("tipo", "")) != tipo:
			continue
		if not aguja.is_empty():
			var ruta := String(entrada.get("ruta", "")).to_lower()
			if not ruta.contains(aguja):
				continue
		salida.append(entrada)
	return salida


static func hay(ruta: String) -> bool:
	for entrada in indice():
		if String(entrada.get("ruta", "")) == ruta:
			return true
	return false


static func es_colocable(ruta: String) -> bool:
	if not TIPOS_COLOCABLES.has(tipo_de(ruta)) or not ResourceLoader.exists(ruta):
		return false
	if tipo_de(ruta) == "escena":
		var recurso: Resource = load(ruta)
		if not recurso is PackedScene:
			return false
		var instancia := (recurso as PackedScene).instantiate()
		var es_3d := instancia is Node3D
		instancia.free()
		return es_3d
	return true


## Etiqueta para la lista: carpeta corta + nombre. Dos packs distintos traen un
## `chair.glb` cada uno, así que el nombre a secas no distingue nada.
static func etiqueta(entrada: Dictionary) -> String:
	var carpeta := String(entrada.get("carpeta", ""))
	var corta := carpeta.get_file() if not carpeta.is_empty() else ""
	var nombre := String(entrada.get("nombre", ""))
	if corta.is_empty():
		return nombre
	return "%s / %s" % [corta, nombre]


## El tamaño REAL del asset en metros, medido sobre sus mallas.
##
## Se instancia fuera del árbol: así no corre ningún `_ready` del asset y medir
## no tiene efectos secundarios. Devuelve `Vector3.ZERO` si no se puede medir,
## y entonces quien llame decide el tamaño por defecto en vez de heredar un cero.
static func medida(ruta: String) -> Vector3:
	if not ResourceLoader.exists(ruta):
		return Vector3.ZERO
	var recurso: Resource = load(ruta)
	var nodo: Node = null
	if recurso is PackedScene:
		nodo = (recurso as PackedScene).instantiate()
	elif recurso is Mesh:
		var malla := MeshInstance3D.new()
		malla.mesh = recurso
		nodo = malla
	if nodo == null:
		return Vector3.ZERO
	var caja := _limites(nodo)
	nodo.free()
	if caja.size.x <= 0.0 or caja.size.y <= 0.0 or caja.size.z <= 0.0:
		return Vector3.ZERO
	return caja.size


## Los límites de todo lo que cuelga de un nodo. Godot da el AABB de UNA malla;
## un prop suele ser varias, y la mayor de ellas no es la pieza.
static func _limites(nodo: Node) -> AABB:
	var total := AABB()
	var primera := true
	for malla in _mallas(nodo):
		var instancia := malla as VisualInstance3D
		var caja := instancia.get_aabb()
		var origen := instancia as Node3D
		var transformada := AABB(
			origen.transform * caja.position, caja.size * origen.transform.basis.get_scale()
		)
		if primera:
			total = transformada
			primera = false
		else:
			total = total.merge(transformada)
	return total


static func _mallas(nodo: Node) -> Array:
	var salida: Array = []
	if nodo is VisualInstance3D:
		salida.append(nodo)
	for hijo in nodo.get_children():
		salida.append_array(_mallas(hijo))
	return salida
