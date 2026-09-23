## Textos de interfaz de la biblioteca de software ficticio OS98 (#663).
##
## Mantenerlos fuera de la pantalla evita que la UI vuelva a incrustar copy y
## deja un único punto de sustitución para una futura traducción/catálogo.
class_name SoftwareSigaTextos
extends RefCounted

const TEXTOS := {
	"titulo_app": "Archivo de programas",
	"cabecera": "Archivo de programas · 1998",
	"ayuda": "Enter/doble clic instala o ejecuta. Todo ocurre dentro del OS ficticio.",
	"ejecutar": "Ejecutar / probar",
	"instalado_marca": "[instalado] ",
	"fuente_marca": "[fuente] ",
	"ficha_titulo": "%s · v%s",
	"ficha_tipo": "Tipo: %s · %d KB ficticios",
	"ficha_origen": "Procedencia: %s",
	"ficha_licencia": "Licencia ficticia: %s",
	"estado_instalado": "Estado: instalado",
	"estado_disponible": "Estado: disponible",
	"fuente_obtenida": "fuente obtenida",
	"fuente_pendiente": "fuente no abierta",
	"desinstalar": "Desinstalar",
	"instalar": "Instalar",
	"desinstalacion_ok": "Desinstalación simulada completada.",
	"instalacion_ok": "Instalación simulada completada.",
}


static func texto(clave: String) -> String:
	return String(TEXTOS.get(clave, clave))
