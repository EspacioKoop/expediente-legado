## Contrato de datos del Parte de incidencias (#381).
##
## Mantiene separado el texto escrito por la persona tester del diagnóstico
## técnico. El diagnóstico se construye por lista blanca y nunca inspecciona
## variables de entorno, partidas, rutas de usuario ni logs arbitrarios.
class_name ParteIncidencias
extends RefCounted

const ETIQUETA := "Parte de incidencias"
const RUTA_CONFIG := "res://datos/incidencias.json"
const ORIGEN_REPORTE := "siga98-f9"
const CATEGORIAS := ["bug", "mejora", "sugerencia", "queja", "accesibilidad", "otro"]
const CLAVES_DIAGNOSTICO := [
	"build",
	"godot",
	"plataforma",
	"escena",
	"renderer",
	"reduccion_movimiento",
]


static func cargar_configuracion(ruta: String = RUTA_CONFIG) -> Dictionary:
	if not FileAccess.file_exists(ruta):
		return {}
	var datos = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	return datos if datos is Dictionary else {}


static func url_configurada(configuracion: Dictionary = {}) -> String:
	var datos := configuracion if not configuracion.is_empty() else cargar_configuracion()
	var url := String(datos.get("feedback_url", "")).strip_edges()
	if url.begins_with("https://") or url.begins_with("http://"):
		return url
	return ""


static func url_issue_fallback(configuracion: Dictionary = {}) -> String:
	var datos := configuracion if not configuracion.is_empty() else cargar_configuracion()
	var url := String(datos.get("fallback_issue_url", "")).strip_edges()
	if url.begins_with("https://github.com/") and url.contains("/issues/new"):
		return url
	return ""


static func texto_fallback(configuracion: Dictionary = {}) -> String:
	var datos := configuracion if not configuracion.is_empty() else cargar_configuracion()
	return String(
		(
			datos
			. get(
				"fallback",
				"No se pudo enviar automáticamente. Se abrirá GitHub con el reporte preparado.",
			)
		)
	)


static func texto_interfaz(clave: String, configuracion: Dictionary = {}) -> String:
	var datos := configuracion if not configuracion.is_empty() else cargar_configuracion()
	var textos = datos.get("textos", {})
	if textos is Dictionary:
		return String(textos.get(clave, clave))
	return clave


static func diagnostico(escena: String, reduccion_movimiento: bool) -> Dictionary:
	var caracteristicas = ProjectSettings.get_setting(
		"application/config/features", PackedStringArray()
	)
	var version_godot := "desconocida"
	if caracteristicas is PackedStringArray and not caracteristicas.is_empty():
		version_godot = String(caracteristicas[0])
	var candidato := {
		"build": build_actual(),
		"godot": version_godot,
		"plataforma": plataforma_generica(OS.get_name()),
		"escena": escena_segura(escena),
		"renderer":
		String(ProjectSettings.get_setting("rendering/renderer/rendering_method", "desconocido")),
		"reduccion_movimiento": reduccion_movimiento,
	}
	return filtrar_diagnostico(candidato)


static func build_actual(ruta_explicita: String = "") -> String:
	var ruta := ruta_explicita
	if ruta.is_empty():
		var ejecutable := OS.get_executable_path()
		if not ejecutable.is_empty():
			ruta = ejecutable.get_base_dir().path_join("BUILD-INFO.txt")
	if not ruta.is_empty() and FileAccess.file_exists(ruta):
		for linea in FileAccess.get_file_as_string(ruta).split("\n"):
			var limpia := String(linea).strip_edges()
			if not limpia.begins_with("build_sha="):
				continue
			var sha := limpia.trim_prefix("build_sha=").strip_edges()
			if _sha_seguro(sha):
				return sha
	var version := (
		String(ProjectSettings.get_setting("application/config/version", "dev")).strip_edges()
	)
	return "dev" if version.is_empty() else version


static func _sha_seguro(valor: String) -> bool:
	if valor.length() < 7 or valor.length() > 64:
		return false
	var patron := RegEx.new()
	if patron.compile("^[0-9a-fA-F]{7,64}$") != OK:
		return false
	return patron.search(valor) != null


static func crear_payload(campos: Dictionary, adjunto: Dictionary = {}) -> Dictionary:
	var categoria := String(campos.get("categoria", "otro"))
	if categoria not in CATEGORIAS:
		categoria = "otro"
	var titulo := String(campos.get("titulo", "")).strip_edges()
	var diagnostico_filtrado := filtrar_diagnostico(adjunto)
	return {
		"schema": 1,
		"source": ORIGEN_REPORTE,
		"category": categoria,
		"title": titulo,
		"body": compilar(campos, diagnostico_filtrado),
		"diagnostic": diagnostico_filtrado,
	}


static func url_issue_preparado(payload: Dictionary, configuracion: Dictionary = {}) -> String:
	var base := url_issue_fallback(configuracion)
	if base.is_empty():
		return ""
	var categoria := String(payload.get("category", "otro")).to_upper()
	var titulo := String(payload.get("title", "")).strip_edges()
	var asunto := "[Playtest][%s] %s" % [categoria, titulo]
	var cuerpo := String(payload.get("body", ""))
	return "%s?title=%s&body=%s" % [base, asunto.uri_encode(), cuerpo.uri_encode()]


static func filtrar_diagnostico(candidato: Dictionary) -> Dictionary:
	var resultado := {}
	for clave in CLAVES_DIAGNOSTICO:
		if candidato.has(clave):
			resultado[clave] = candidato[clave]
	return resultado


static func plataforma_generica(nombre: String) -> String:
	match nombre.to_lower():
		"windows":
			return "windows"
		"macos", "osx":
			return "macos"
		"linux", "freebsd", "netbsd", "openbsd", "bsd":
			return "linux"
		_:
			return "otra"


static func escena_segura(ruta: String) -> String:
	if not ruta.begins_with("res://"):
		return "desconocida"
	return ruta.get_file().get_basename()


static func compilar(campos: Dictionary, adjunto: Dictionary = {}) -> String:
	var categoria := String(campos.get("categoria", "otro"))
	if categoria not in CATEGORIAS:
		categoria = "otro"
	var lineas: Array[String] = [
		"PARTE DE INCIDENCIAS · SIGA-98",
		"Categoría: %s" % categoria,
		"Título: %s" % String(campos.get("titulo", "")).strip_edges(),
		"",
		"Descripción:",
		String(campos.get("descripcion", "")).strip_edges(),
	]
	if categoria == "bug":
		lineas.append("")
		lineas.append("Pasos para reproducir:")
		lineas.append(String(campos.get("pasos", "")).strip_edges())
	_agregar_campo(lineas, "Esperado", String(campos.get("esperado", "")))
	_agregar_campo(lineas, "Observado", String(campos.get("observado", "")))
	var diagnostico_filtrado := filtrar_diagnostico(adjunto)
	if not diagnostico_filtrado.is_empty():
		lineas.append("")
		lineas.append("--- DIAGNÓSTICO TÉCNICO (consentido) ---")
		for clave in CLAVES_DIAGNOSTICO:
			if diagnostico_filtrado.has(clave):
				lineas.append("%s: %s" % [clave, diagnostico_filtrado[clave]])
	return "\n".join(lineas).strip_edges() + "\n"


static func formatear_diagnostico(adjunto: Dictionary) -> String:
	var filtrado := filtrar_diagnostico(adjunto)
	if filtrado.is_empty():
		return ""
	var lineas: Array[String] = []
	for clave in CLAVES_DIAGNOSTICO:
		if filtrado.has(clave):
			lineas.append("%s: %s" % [clave, filtrado[clave]])
	return "\n".join(lineas)


static func guardar_local(texto: String, ruta: String = "") -> String:
	var destino := ruta
	if destino.is_empty():
		var marca := Time.get_datetime_string_from_system().replace(":", "-")
		destino = "user://parte-incidencias-%s.txt" % marca
	var fichero := FileAccess.open(destino, FileAccess.WRITE)
	if fichero == null:
		return ""
	fichero.store_string(texto)
	fichero.close()
	return destino


static func _agregar_campo(lineas: Array[String], nombre: String, valor: String) -> void:
	var limpio := valor.strip_edges()
	if limpio.is_empty():
		return
	lineas.append("")
	lineas.append("%s:" % nombre)
	lineas.append(limpio)
