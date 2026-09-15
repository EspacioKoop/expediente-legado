## Persistencia declarada de aplicaciones del escritorio (#535).
##
## Separada a propósito de `Partida`: la campaña vive en su propio fichero y
## en su propio formato versionado, y esto no lo toca ni lo conoce. Aquí solo
## entran las aplicaciones que declaran `persistir_estado = true`, y solo su
## estado local (`exportar_estado`/`importar_estado`); nunca posición ni
## tamaño de ventana, que son cosméticos del shell y no del dominio.
class_name EstadoAplicacionesSiga
extends RefCounted

const RUTA := "user://estado_aplicaciones.json"


## Vuelca a disco el estado de las apps de [param apps] que lo declaren.
## Devuelve true solo si quedó escrito; un fallo aquí no debe impedir que la
## campaña (`Partida`) se guarde, así que quien llame decide si lo cuenta.
static func guardar(apps: Array, ruta: String = RUTA) -> bool:
	var estado := {}
	for elemento in apps:
		if not (elemento is EscritorioSigaApp):
			continue
		var aplicacion: EscritorioSigaApp = elemento
		if not aplicacion.persistir_estado:
			continue
		estado[aplicacion.id] = aplicacion.exportar_estado()

	var temporal := ruta + ".nuevo"
	var fichero := FileAccess.open(temporal, FileAccess.WRITE)
	if fichero == null:
		push_error("No se pudo escribir %s" % temporal)
		return false
	fichero.store_string(JSON.stringify(estado, "\t"))
	fichero.close()

	var error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temporal), ProjectSettings.globalize_path(ruta)
	)
	return error == OK


## Repone en cada app de [param apps] su estado guardado, si lo hay y si la
## app sigue declarando `persistir_estado = true`. Una app que ya no lo
## declare simplemente no recibe nada, aunque el fichero aún la mencione.
static func cargar(apps: Array, ruta: String = RUTA) -> void:
	if not FileAccess.file_exists(ruta):
		return
	var fichero := FileAccess.open(ruta, FileAccess.READ)
	if fichero == null:
		return
	var crudo = JSON.parse_string(fichero.get_as_text())
	fichero.close()
	if typeof(crudo) != TYPE_DICTIONARY:
		return

	for elemento in apps:
		if not (elemento is EscritorioSigaApp):
			continue
		var aplicacion: EscritorioSigaApp = elemento
		if not aplicacion.persistir_estado:
			continue
		var guardado: Variant = crudo.get(aplicacion.id, null)
		if typeof(guardado) == TYPE_DICTIONARY:
			aplicacion.importar_estado(guardado)
