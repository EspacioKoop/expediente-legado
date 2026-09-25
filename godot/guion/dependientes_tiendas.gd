## Dependientes de las tiendas del trayecto: quién atiende cada comercio y qué
## dice según el día.
##
## Contrato puro, sin geometría: la capa 3D (`DependientesTiendas3D`) pone el
## cuerpo y la conversación, esto decide la línea. Cada uno tiene su voz, y
## esa voz es el texto de sus claves; aquí solo está el orden en que habla:
##
## 1. Lo que pasa hoy. Si el día trae lluvia, nieve o niebla, lo comenta; si
##    no, y ya le has comprado algo alguna vez, te pregunta por ello.
## 2. El saludo del día, que rota con el número de día. Así cada visita en un
##    día distinto abre con otra cosa, y la misma partida siempre dice lo mismo
##    el mismo día.
## 3. Si sigues dándole conversación en la misma visita, su manera de decirte
##    que ya vale. Esa se repite: no hay una cuarta cosa que contar.
##
## Ser cliente lo deciden las compras que ya guardan `ComercioBarrio` y
## `TiendaVideojuegos`; este módulo no lleva cuenta de nada.
class_name DependientesTiendas
extends RefCounted

## Uno por comercio. `tienda` es el nodo de la calle donde se monta, `pos` y
## `rumbo` (grados, 0 mira a +Z) van en el espacio de ese nodo. `gesto` es el
## clip en bucle que lo define de lejos, antes de abrir la boca.
const DEPENDIENTES := [
	{
		# Quiosquero de toda la vida: gruñón, sabe de todo y se fía de poco.
		"id": "paco",
		"clave": "DEPEND_PACO",
		# Las claves van escritas enteras: la guarda de textos (#105) busca cada
		# una tal cual en el código, y una clave compuesta con `%` no la ve.
		"saludos":
		[
			"DEPEND_PACO_SALUDO_1",
			"DEPEND_PACO_SALUDO_2",
			"DEPEND_PACO_SALUDO_3",
			"DEPEND_PACO_SALUDO_4",
			"DEPEND_PACO_SALUDO_5",
		],
		"climas":
		{
			Clima.LLUVIA: "DEPEND_PACO_LLUVIA",
			Clima.NIEVE: "DEPEND_PACO_NIEVE",
			Clima.NIEBLA: "DEPEND_PACO_NIEBLA",
		},
		"frase_cliente": "DEPEND_PACO_CLIENTE",
		"insiste": "DEPEND_PACO_INSISTE",
		"suenos": ["DEPEND_PACO_SUENO_1", "DEPEND_PACO_SUENO_2", "DEPEND_PACO_SUENO_3"],
		"extrano": "DEPEND_PACO_SUENO_EXTRANO",
		"superficie": "quiosco",
		"tienda": "QuioscoAvenida",
		"cuerpo": "rocketbox/male_adult_07",
		"pos": Vector3(-0.55, 0.0, -1.72),
		"rumbo": -90.0,
		"gesto": "idle",
	},
	{
		# Segunda mano: dulce, sentimental y convencida de que los objetos
		# recuerdan a sus dueños. Siempre tiene algo entre las manos.
		"id": "remedios",
		"clave": "DEPEND_REMEDIOS",
		"saludos":
		[
			"DEPEND_REMEDIOS_SALUDO_1",
			"DEPEND_REMEDIOS_SALUDO_2",
			"DEPEND_REMEDIOS_SALUDO_3",
			"DEPEND_REMEDIOS_SALUDO_4",
			"DEPEND_REMEDIOS_SALUDO_5",
		],
		"climas":
		{
			Clima.LLUVIA: "DEPEND_REMEDIOS_LLUVIA",
			Clima.NIEVE: "DEPEND_REMEDIOS_NIEVE",
			Clima.NIEBLA: "DEPEND_REMEDIOS_NIEBLA",
		},
		"frase_cliente": "DEPEND_REMEDIOS_CLIENTE",
		"insiste": "DEPEND_REMEDIOS_INSISTE",
		"suenos": ["DEPEND_REMEDIOS_SUENO_1", "DEPEND_REMEDIOS_SUENO_2", "DEPEND_REMEDIOS_SUENO_3"],
		"extrano": "DEPEND_REMEDIOS_SUENO_EXTRANO",
		"superficie": "segunda_mano",
		"tienda": "ElTrastero",
		"cuerpo": "rocketbox/female_adult_14",
		"pos": Vector3(0.58, 0.0, 2.05),
		"rumbo": 90.0,
		"gesto": "coger",
	},
	{
		# Vendedor de comisión: habla en eslogan y no deja de gesticular. No
		# se queda detrás del mostrador; te sale al paso por la tienda.
		"id": "julian",
		"clave": "DEPEND_JULIAN",
		"saludos":
		[
			"DEPEND_JULIAN_SALUDO_1",
			"DEPEND_JULIAN_SALUDO_2",
			"DEPEND_JULIAN_SALUDO_3",
			"DEPEND_JULIAN_SALUDO_4",
			"DEPEND_JULIAN_SALUDO_5",
		],
		"climas":
		{
			Clima.LLUVIA: "DEPEND_JULIAN_LLUVIA",
			Clima.NIEVE: "DEPEND_JULIAN_NIEVE",
			Clima.NIEBLA: "DEPEND_JULIAN_NIEBLA",
		},
		"frase_cliente": "",
		"insiste": "DEPEND_JULIAN_INSISTE",
		"suenos": ["DEPEND_JULIAN_SUENO_1", "DEPEND_JULIAN_SUENO_2", "DEPEND_JULIAN_SUENO_3"],
		"extrano": "DEPEND_JULIAN_SUENO_EXTRANO",
		"superficie": "electrodomesticos",
		"tienda": "InteriorElectrodomesticos",
		"cuerpo": "rocketbox/male_adult_08",
		"pos": Vector3(-1.15, 0.0, -0.95),
		"rumbo": 35.0,
		"gesto": "conversar",
	},
	{
		# Dependiente de videojuegos: joven, lacónico y con cero ganas de
		# vender nada. Detrás del mostrador, trasteando con algo.
		"id": "kike",
		"clave": "DEPEND_KIKE",
		"saludos":
		[
			"DEPEND_KIKE_SALUDO_1",
			"DEPEND_KIKE_SALUDO_2",
			"DEPEND_KIKE_SALUDO_3",
			"DEPEND_KIKE_SALUDO_4",
			"DEPEND_KIKE_SALUDO_5",
		],
		"climas":
		{
			Clima.LLUVIA: "DEPEND_KIKE_LLUVIA",
			Clima.NIEVE: "DEPEND_KIKE_NIEVE",
			Clima.NIEBLA: "DEPEND_KIKE_NIEBLA",
		},
		"frase_cliente": "DEPEND_KIKE_CLIENTE",
		"insiste": "DEPEND_KIKE_INSISTE",
		"suenos": ["DEPEND_KIKE_SUENO_1", "DEPEND_KIKE_SUENO_2", "DEPEND_KIKE_SUENO_3"],
		"extrano": "DEPEND_KIKE_SUENO_EXTRANO",
		"superficie": "videojuegos",
		"tienda": "InteriorBit98",
		"cuerpo": "rocketbox/male_adult_09",
		"pos": Vector3(0.85, 0.0, -3.45),
		"rumbo": 0.0,
		"gesto": "work",
	},
]


static func todos() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	for dependiente in DEPENDIENTES:
		salida.append(dependiente)
	return salida


static func de(id: String) -> Dictionary:
	for dependiente in DEPENDIENTES:
		if String(dependiente["id"]) == id:
			return dependiente
	return {}


## Todas las claves que puede llegar a decir [param dependiente], en orden. Las
## pruebas comprueban que cada una tenga texto.
static func claves(dependiente: Dictionary) -> Array[String]:
	var salida: Array[String] = [String(dependiente["clave"])]
	for clave in dependiente["saludos"]:
		salida.append(String(clave))
	for clave in (dependiente["climas"] as Dictionary).values():
		salida.append(String(clave))
	if not String(dependiente["frase_cliente"]).is_empty():
		salida.append(String(dependiente["frase_cliente"]))
	salida.append(String(dependiente["insiste"]))
	return salida


## La clave de lo que dice [param dependiente] la vez número [param charla]
## (0 la primera) de esta visita, con el tiempo [param clima] y la partida
## [param jornada].
static func frase(
	dependiente: Dictionary, jornada: Dictionary, clima: String, charla: int
) -> String:
	var dia := maxi(int(jornada.get("dia", 1)), 1)
	var saludos: Array = dependiente["saludos"]
	var climas: Dictionary = dependiente["climas"]
	var turnos: Array[String] = []
	if climas.has(clima):
		turnos.append(String(climas[clima]))
	elif es_cliente(dependiente, jornada):
		turnos.append(String(dependiente["frase_cliente"]))
	turnos.append(String(saludos[(dia - 1) % saludos.size()]))
	turnos.append(String(dependiente["insiste"]))
	return turnos[clampi(charla, 0, turnos.size() - 1)]


## Si ya le has comprado algo alguna vez. Solo cuenta en las tiendas que
## venden (en Electrodomésticos no se compra nada, así que ahí nunca).
static func es_cliente(dependiente: Dictionary, jornada: Dictionary) -> bool:
	if String(dependiente.get("frase_cliente", "")).is_empty():
		return false
	var superficie := String(dependiente["superficie"])
	if superficie == "videojuegos":
		return not TiendaVideojuegos.compras(jornada).is_empty()
	for id_item in ComercioBarrio.compras(jornada):
		for entrada in ComercioBarrio.CATALOGO:
			if String(entrada["id"]) == id_item and String(entrada["superficie"]) == superficie:
				return true
	return false
