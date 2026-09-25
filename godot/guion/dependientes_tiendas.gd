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

const SALUDOS := 5
const CLIMAS := {
	Clima.LLUVIA: "LLUVIA",
	Clima.NIEVE: "NIEVE",
	Clima.NIEBLA: "NIEBLA",
}

## Uno por comercio. `tienda` es el nodo de la calle donde se monta, `pos` y
## `rumbo` (grados, 0 mira a +Z) van en el espacio de ese nodo. `gesto` es el
## clip en bucle que lo define de lejos, antes de abrir la boca.
const DEPENDIENTES := [
	{
		# Quiosquero de toda la vida: gruñón, sabe de todo y se fía de poco.
		"id": "paco",
		"clave": "DEPEND_PACO",
		"superficie": "quiosco",
		"tienda": "QuioscoAvenida",
		"cuerpo": "rocketbox/male_adult_07",
		"pos": Vector3(-0.55, 0.0, -1.72),
		"rumbo": -90.0,
		"gesto": "idle",
		"cliente": true,
	},
	{
		# Segunda mano: dulce, sentimental y convencida de que los objetos
		# recuerdan a sus dueños. Siempre tiene algo entre las manos.
		"id": "remedios",
		"clave": "DEPEND_REMEDIOS",
		"superficie": "segunda_mano",
		"tienda": "ElTrastero",
		"cuerpo": "rocketbox/female_adult_14",
		"pos": Vector3(0.58, 0.0, 2.05),
		"rumbo": 90.0,
		"gesto": "coger",
		"cliente": true,
	},
	{
		# Vendedor de comisión: habla en eslogan y no deja de gesticular. No
		# se queda detrás del mostrador; te sale al paso por la tienda.
		"id": "julian",
		"clave": "DEPEND_JULIAN",
		"superficie": "electrodomesticos",
		"tienda": "InteriorElectrodomesticos",
		"cuerpo": "rocketbox/male_adult_08",
		"pos": Vector3(-1.15, 0.0, -0.95),
		"rumbo": 35.0,
		"gesto": "conversar",
		"cliente": false,
	},
	{
		# Dependiente de videojuegos: joven, lacónico y con cero ganas de
		# vender nada. Detrás del mostrador, trasteando con algo.
		"id": "kike",
		"clave": "DEPEND_KIKE",
		"superficie": "videojuegos",
		"tienda": "InteriorBit98",
		"cuerpo": "rocketbox/male_adult_09",
		"pos": Vector3(0.85, 0.0, -3.45),
		"rumbo": 0.0,
		"gesto": "work",
		"cliente": true,
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
	var base := String(dependiente["clave"])
	var salida: Array[String] = [base]
	for n in range(1, SALUDOS + 1):
		salida.append("%s_SALUDO_%d" % [base, n])
	for sufijo in CLIMAS.values():
		salida.append("%s_%s" % [base, sufijo])
	if bool(dependiente.get("cliente", false)):
		salida.append("%s_CLIENTE" % base)
	salida.append("%s_INSISTE" % base)
	return salida


## La clave de lo que dice [param dependiente] la vez número [param charla]
## (0 la primera) de esta visita, con el tiempo [param clima] y la partida
## [param jornada].
static func frase(
	dependiente: Dictionary, jornada: Dictionary, clima: String, charla: int
) -> String:
	var base := String(dependiente["clave"])
	var dia := maxi(int(jornada.get("dia", 1)), 1)
	var turnos: Array[String] = []
	if CLIMAS.has(clima):
		turnos.append("%s_%s" % [base, CLIMAS[clima]])
	elif es_cliente(dependiente, jornada):
		turnos.append("%s_CLIENTE" % base)
	turnos.append("%s_SALUDO_%d" % [base, (dia - 1) % SALUDOS + 1])
	turnos.append("%s_INSISTE" % base)
	return turnos[clampi(charla, 0, turnos.size() - 1)]


## Si ya le has comprado algo alguna vez. Solo cuenta en las tiendas que
## venden (en Electrodomésticos no se compra nada, así que ahí nunca).
static func es_cliente(dependiente: Dictionary, jornada: Dictionary) -> bool:
	if not bool(dependiente.get("cliente", false)):
		return false
	var superficie := String(dependiente["superficie"])
	if superficie == "videojuegos":
		return not TiendaVideojuegos.compras(jornada).is_empty()
	for id_item in ComercioBarrio.compras(jornada):
		for entrada in ComercioBarrio.CATALOGO:
			if String(entrada["id"]) == id_item and String(entrada["superficie"]) == superficie:
				return true
	return false
