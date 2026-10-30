## Sistema de ayuda contextual para Software SIGA (#2967).
##
## Proporciona explicaciones claras y contextuales para la biblioteca de software
## ficticio, mejorando la accesibilidad y comprensión del sistema SIGA-98.
class_name SoftwareSigaAyuda
extends RefCounted

## Tipos de software y sus descripciones extendidas
const DESCRIPCIONES_TIPOS := {
	"juego": "Programas de entretenimiento. Incluyen juegos de estrategia, aventuras y simulaciones.",
	"herramienta": "Utilidades para productividad. Editores de texto, calculadoras, etc.",
	"oficina": "Aplicaciones de oficina. Procesadores de texto, hojas de cálculo.",
	"graficacion": "Programas de diseño gráfico y edición de imágenes.",
	"multimedia": "Reproductores de audio/video y editores multimedia.",
	"utilidad": "Herramientas del sistema. Compresión, backup, gestión de archivos.",
	"educacion": "Software educativo y de aprendizaje.",
	"red": "Programas de comunicación y red. Navegadores, clientes de correo.",
}

## Licencias y sus explicaciones
const DESCRIPCIONES_LICENCIAS := {
	"freeware": "Gratis para uso personal. Puede distribuirse libremente.",
	"shareware": "Prueba gratuita con limitaciones. Requiere pago para versión completa.",
	"comercial": "Software de pago. Requiere licencia para su uso.",
	"demo": "Versión de demostración con funcionalidad limitada.",
	"public_domain": "Dominio público. Libre para cualquier uso sin restricciones.",
}

## Orígenes comunes
const DESCRIPCIONES_ORIGENES := {
	"ShareIt": "Plataforma de distribución de shareware popular en los 90.",
	"BBS": "Bulletin Board System. Redes de intercambio de software tempranas.",
	"CD-ROM": "Distribución en discos compactos, común en colecciones de software.",
	"FTP": "Protocolos de transferencia de archivos. Descarga desde servidores remotos.",
	"Revistas": "Software incluido en revistas de computación en disquetes o CDs.",
	"Compañeros": "Programas compartidos por otros empleados de la oficina.",
}

## Consejos generales para el usuario
const CONSEJOS_GENERALES := [
	"Haga clic en un programa para seleccionarlo y ver sus detalles.",
	"Use el botón 'Instalar' para añadir el software a su sistema.",
	"Use el botón 'Ejecutar' para probar el software instalado.",
	"Los programas marcados como [instalado] ya están disponibles en su sistema.",
	"Los programas con [fuente] tienen código fuente disponible.",
	"Use los botones de navegación para moverse entre las categorías.",
]

## Obtener descripción extendida para un tipo de software
static func descripcion_tipo(tipo: String) -> String:
	return String(DESCRIPCIONES_TIPOS.get(tipo.to_lower(), ""))


## Obtener descripción extendida para una licencia
static func descripcion_licencia(licencia: String) -> String:
	return String(DESCRIPCIONES_LICENCIAS.get(licencia.to_lower(), ""))


## Obtener descripción extendida para un origen
static func descripcion_origen(origen: String) -> String:
	return String(DESCRIPCIONES_ORIGENES.get(origen, ""))


## Obtener todos los consejos generales
static func consejos_generales() -> Array[String]:
	return CONSEJOS_GENERALES.duplicate()


## Generar un tooltip completo para una entrada de software
static func tooltip_entrada(titulo: String, tipo: String, tamano: int, origen: String, licencia: String) -> String:
	var lines := []
	lines.append("\n" + titulo)
	lines.append("Tipo: " + tipo)
	lines.append("Tamaño: %d KB" % tamano)
	lines.append("Origen: " + origen)
	lines.append("Licencia: " + licencia)
	return "\n".join(lines)


## Generar ayuda contextual para la interfaz principal
static func ayuda_interfaz() -> String:
	var ayuda := "\nBIBLIOTECA DE SOFTWARE SIGA-98\n"
	ayuda += "\n"
	ayuda += "Esta es la biblioteca de programas disponibles en su sistema OS98.\n"
	ayuda += "\n"
	ayuda += "QUÉ PUEDE HACER:\n"
	ayuda += "- Navegar por la lista de programas disponibles\n"
	ayuda += "- Seleccionar un programa para ver sus detalles\n"
	ayuda += "- Instalar programas en su sistema\n"
	ayuda += "- Ejecutar programas ya instalados\n"
	ayuda += "- Desinstalar programas que ya no necesite\n"
	ayuda += "\n"
	ayuda += "CÓMO USAR:\n"
	ayuda += "1. Haga clic en un programa de la lista para seleccionarlo\n"
	ayuda += "2. Aparecerán sus detalles en el panel derecho\n"
	ayuda += "3. Use los botones 'Instalar' o 'Ejecutar' según corresponda\n"
	ayuda += "\n"
	ayuda += "ESTADO DE LOS PROGRAMAS:\n"
	ayuda += "- [instalado] = El programa está instalado en su sistema\n"
	ayuda += "- [fuente] = Código fuente disponible\n"
	ayuda += "- Sin marcas = Programa disponible para instalar\n"
	return ayuda
