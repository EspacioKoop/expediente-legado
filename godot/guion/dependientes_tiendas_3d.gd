## Cuerpo y conversación de los dependientes en sus tiendas.
##
## Qué dice cada uno lo decide `DependientesTiendas`; esta capa busca la tienda
## ya montada en la calle (el quiosco y El Trastero de `ComercioBarrio3D`, los
## interiores de `CalleLocalesComerciales3D`), le pone delante un avatar
## Rocketbox con su gesto y cuelga de él el mismo interactuable que usan los
## compañeros de la oficina. Si una tienda no está montada, su dependiente no
## aparece: nunca se inventa un sitio.
##
## Cada dependiente recuerda cuántas veces le has hablado en esta visita (meta
## `charlas` del nodo), que es lo que hace avanzar su conversación. Al volver a
## entrar en el trayecto se monta de nuevo y empieza desde el principio.
class_name DependientesTiendas3D
extends RefCounted

const PREFIJO := "Dependiente_"


## Monta los dependientes que tengan tienda bajo [param mundo] y devuelve sus
## interactuables, para que quien los monta conecte la conversación.
static func montar(mundo: Node3D) -> Array[CompaneroInteractivo3D]:
	var salida: Array[CompaneroInteractivo3D] = []
	if mundo == null:
		return salida
	for dependiente in DependientesTiendas.todos():
		var tienda := mundo.find_child(String(dependiente["tienda"]), true, false) as Node3D
		if tienda == null:
			continue
		var anterior := tienda.get_node_or_null(PREFIJO + String(dependiente["id"]))
		if anterior != null:
			anterior.free()
		salida.append(_montar_uno(tienda, dependiente))
	return salida


## La clave que toca decir ahora a quien lleva [param charla], y cuenta la
## charla: la siguiente vez dirá lo siguiente.
static func siguiente_frase(
	charla: CompaneroInteractivo3D, jornada: Dictionary, clima: String
) -> String:
	var dependiente := DependientesTiendas.de(String(charla.get_meta("dependiente", "")))
	if dependiente.is_empty():
		return charla.clave_dialogo
	var veces := int(charla.get_meta("charlas", 0))
	charla.set_meta("charlas", veces + 1)
	return DependientesTiendas.frase(dependiente, jornada, clima, veces)


static func _montar_uno(tienda: Node3D, dependiente: Dictionary) -> CompaneroInteractivo3D:
	var id := String(dependiente["id"])
	var raiz := Node3D.new()
	raiz.name = PREFIJO + id
	raiz.position = dependiente["pos"]
	raiz.rotation.y = deg_to_rad(float(dependiente["rumbo"]))
	raiz.set_meta("dependiente", id)
	tienda.add_child(raiz)

	var cuerpo := Node3D.new()
	cuerpo.name = "Cuerpo"
	raiz.add_child(cuerpo)
	if Modelos.persona(cuerpo, String(dependiente["cuerpo"]), Color.WHITE, ""):
		var pieza := cuerpo.get_child(0) as Node3D
		# Desfase propio para que dos gestos iguales no vayan al compás.
		var desfase := float(absi(hash(id)) % 1000) / 1000.0
		AnimacionesUAL.reproducir(pieza, String(dependiente["gesto"]), desfase)

	var charla := CompaneroInteractivo3D.new()
	charla.name = "Conversacion"
	charla.position = Vector3(0.0, 0.9, 0.0)
	charla.nombre_visible = TranslationServer.translate(String(dependiente["clave"]))
	charla.clave_dialogo = String(dependiente["insiste"])
	charla.set_meta("dependiente", id)
	charla.set_meta("charlas", 0)
	raiz.add_child(charla)
	return charla
