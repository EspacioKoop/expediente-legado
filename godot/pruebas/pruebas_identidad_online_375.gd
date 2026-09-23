extends SceneTree

## Regresión ejecutable de la identidad pública offline-first de #375.

const IdentidadOnline = preload("res://guion/red/identidad_online.gd")
const RUTA := "user://prueba-identidad-online-375.json"

var pasadas := 0
var fallos := 0


func _init() -> void:
	_limpiar()
	_probar_opt_in_y_persistencia()
	_probar_regeneracion()
	_probar_deshabilitar_borra_identidad()
	_probar_datos_invalidos_fail_closed()
	_limpiar()
	print("\n%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _probar_opt_in_y_persistencia() -> void:
	var identidad := IdentidadOnline.new(RUTA)
	var inicial := identidad.cargar()
	_comprobar("empieza sin identidad", inicial["status"], "disabled")
	_comprobar("empieza inactiva", identidad.activa(), false)
	_comprobar("sin id antes de opt-in", identidad.actor_public_id(), "")

	var alta := identidad.habilitar()
	_comprobar("habilitar persiste", alta["ok"], true)
	_comprobar("queda activa", identidad.activa(), true)
	_comprobar("id tiene contrato", _id_valido(String(alta["actor_public_id"])), true)
	_comprobar("fichero creado", FileAccess.file_exists(RUTA), true)

	var guardado := _leer()
	_comprobar("persistencia tiene solo tres campos", guardado.size(), 3)
	_comprobar("persistencia no contiene SO", guardado.has("os_name"), false)
	_comprobar("persistencia no contiene cuenta", guardado.has("account_name"), false)
	_comprobar("persistencia no contiene ruta local", guardado.has("local_path"), false)
	_comprobar("persistencia no contiene IP", guardado.has("ip"), false)

	var recarga := IdentidadOnline.new(RUTA)
	var resultado := recarga.cargar()
	_comprobar("recarga identidad", resultado["ok"], true)
	_comprobar("recarga activa", recarga.activa(), true)
	_comprobar("recarga conserva pseudónimo", recarga.actor_public_id(), alta["actor_public_id"])


func _probar_regeneracion() -> void:
	var identidad := IdentidadOnline.new(RUTA)
	identidad.cargar()
	var anterior := identidad.actor_public_id()
	var cambio := identidad.regenerar()
	_comprobar("regenerar activo funciona", cambio["ok"], true)
	_comprobar("estado regenerated", cambio["status"], "regenerated")
	_comprobar("regenerar cambia id", cambio["actor_public_id"] != anterior, true)
	_comprobar("id regenerado válido", _id_valido(String(cambio["actor_public_id"])), true)

	var recarga := IdentidadOnline.new(RUTA)
	recarga.cargar()
	_comprobar("regenerado queda persistido", recarga.actor_public_id(), cambio["actor_public_id"])


func _probar_deshabilitar_borra_identidad() -> void:
	var identidad := IdentidadOnline.new(RUTA)
	identidad.cargar()
	var anterior := identidad.actor_public_id()
	var baja := identidad.deshabilitar()
	_comprobar("deshabilitar responde ok", baja["ok"], true)
	_comprobar("deshabilitar limpia memoria", identidad.actor_public_id(), "")
	_comprobar("deshabilitar deja inactiva", identidad.activa(), false)
	if FileAccess.file_exists(RUTA):
		var guardado := _leer()
		_comprobar("lápida no conserva id", guardado.get("actor_public_id", "x"), "")
		_comprobar("lápida está desactivada", guardado.get("enabled", true), false)
	else:
		_comprobar("fichero de identidad eliminado", true, true)
		_comprobar("sin lápida residual", true, true)

	var recarga := IdentidadOnline.new(RUTA)
	var resultado := recarga.cargar()
	_comprobar("recarga tras baja queda desactivada", resultado["status"], "disabled")
	_comprobar("recarga tras baja no recupera id", recarga.actor_public_id(), "")

	var nueva := recarga.habilitar()
	_comprobar("nuevo opt-in vuelve a funcionar", nueva["ok"], true)
	_comprobar("nuevo opt-in no recicla id borrado", nueva["actor_public_id"] != anterior, true)


func _probar_datos_invalidos_fail_closed() -> void:
	var identidad := IdentidadOnline.new(RUTA)
	var actual := identidad.cargar()
	var id_valido := String(actual.get("actor_public_id", ""))
	_escribir(
		{
			"version": IdentidadOnline.VERSION,
			"enabled": true,
			"actor_public_id": id_valido,
			"os_name": "no-debe-existir",
		}
	)
	var con_extra := IdentidadOnline.new(RUTA)
	_comprobar("campo extra invalida fichero", con_extra.cargar()["status"], "invalid")
	_comprobar("fichero inválido no activa identidad", con_extra.activa(), false)
	_comprobar("fichero inválido no expone id", con_extra.actor_public_id(), "")

	var fichero := FileAccess.open(RUTA, FileAccess.WRITE)
	fichero.store_string("{esto no es json")
	fichero.close()
	var corrupta := IdentidadOnline.new(RUTA)
	_comprobar("json corrupto falla cerrado", corrupta.cargar()["status"], "invalid")
	_comprobar("json corrupto no crea identidad", corrupta.actor_public_id(), "")

	_limpiar()
	var desactivada := IdentidadOnline.new(RUTA)
	_comprobar("regenerar desactivada se rechaza", desactivada.regenerar()["status"], "disabled")


func _leer() -> Dictionary:
	var fichero := FileAccess.open(RUTA, FileAccess.READ)
	var datos = JSON.parse_string(fichero.get_as_text())
	fichero.close()
	return datos if typeof(datos) == TYPE_DICTIONARY else {}


func _escribir(datos: Dictionary) -> void:
	var fichero := FileAccess.open(RUTA, FileAccess.WRITE)
	fichero.store_string(JSON.stringify(datos))
	fichero.close()


func _limpiar() -> void:
	for ruta in [RUTA, RUTA + ".nuevo"]:
		if FileAccess.file_exists(ruta):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))


func _id_valido(valor: String) -> bool:
	if not valor.begins_with("anon-") or valor.length() != 37:
		return false
	for indice in range(5, valor.length()):
		if "0123456789abcdef".find(valor.substr(indice, 1)) < 0:
			return false
	return true


func _comprobar(nombre: String, obtenido: Variant, esperado: Variant) -> void:
	if obtenido == esperado:
		pasadas += 1
		return
	fallos += 1
	push_error("%s: esperado %s, obtenido %s" % [nombre, esperado, obtenido])
