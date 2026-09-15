## Cerrar un expediente: A-7, sello y carpeta.
##
## La lógica de la acusación ya está resuelta cuando esto empieza. Esta clase
## solo declara cómo se ve el gesto administrativo de cerrar la carpeta; verla,
## saltarla o acortarla no puede cambiar el veredicto ni el careo posterior.
##
## Desde #395 rueda en 3D sobre la mesa del archivo (`MesaCinematica`): el
## formulario, el sello de goma y la carpeta son piezas del decorado y la
## cámara se acerca al golpe.
class_name SelloCinematica
extends RefCounted

const ID := "cierre-sello"

const PAPEL := Color("dedbd2")
const TINTA := Color("3e3e42")
const CARPETA := Color("81745f")
const BORDE := Color("50483c")
const ALERTA := Color("8a4b45")
const MANGO := Color("6b4a33")

## Dónde está el formulario en la mesa.
const A7 := Vector3(0.1, 0.75, 0.15)


## La escena cambia visualmente si la firma fue precipitada, pero no lo dice
## con texto: la marca queda desplazada y duplicada, como un trámite hecho con
## demasiada prisa.
static func planos_de(precipitada: bool, vistas: int = 0) -> Array:
	return Cinematica.resolver(planos(precipitada), {}, vistas)


static func planos(precipitada: bool) -> Array:
	var mira := A7 + Vector3(0, 0.03, 0)
	return [
		{
			# El A-7 sobre la mesa, con el sello en el aire.
			"tipo": "3d",
			"nombre": "a7",
			"decorado": MesaCinematica.con(_a7() + _sello(0.22)),
			"camara": Vector3(0.95, 1.4, 1.0),
			"mira": mira,
			"segundos": 0.9,
		},
		{
			# El golpe, de cerca.
			"tipo": "3d",
			"nombre": "sello",
			"decorado": MesaCinematica.con(_a7() + _sello(0.0) + _marca(precipitada, 0.012)),
			"camara": Vector3(0.45, 1.05, 0.62),
			"mira": mira,
			"segundos": 0.7,
		},
		{
			# La carpeta cerrada con la marca en la tapa; el sello, a un lado.
			"tipo": "3d",
			"nombre": "carpeta",
			"decorado":
			MesaCinematica.con(_carpeta() + _marca(precipitada, 0.034) + _sello_apartado()),
			"camara": Vector3(-0.1, 1.55, 1.15),
			"mira": mira,
			"segundos": 1.0,
		},
	]


static func _a7() -> Array:
	var piezas := [MesaCinematica.pieza(A7.x, A7.z, Vector3(0.30, 0.004, 0.42), PAPEL)]
	for i in 4:
		piezas.append(
			MesaCinematica.pieza(
				A7.x - 0.02 * float(i % 2),
				A7.z - 0.15 + 0.06 * i,
				Vector3(0.22 - 0.04 * float(i % 2), 0.002, 0.012),
				TINTA,
				0.004
			)
		)
	return piezas


## El sello de goma sobre el recuadro de firma, a [param altura] del papel.
static func _sello(altura: float) -> Array:
	return [
		MesaCinematica.pieza(A7.x, A7.z + 0.1, Vector3(0.14, 0.035, 0.08), TINTA, 0.004 + altura),
		MesaCinematica.pieza(A7.x, A7.z + 0.1, Vector3(0.05, 0.12, 0.05), MANGO, 0.039 + altura),
	]


static func _sello_apartado() -> Array:
	return [
		MesaCinematica.pieza(0.55, 0.35, Vector3(0.14, 0.035, 0.08), TINTA),
		MesaCinematica.pieza(0.55, 0.35, Vector3(0.05, 0.12, 0.05), MANGO, 0.035),
	]


static func _marca(precipitada: bool, altura: float) -> Array:
	var color := ALERTA if precipitada else TINTA
	var marcas := [
		MesaCinematica.pieza(A7.x, A7.z + 0.1, Vector3(0.13, 0.002, 0.07), color, altura)
	]
	if precipitada:
		# La segunda huella fuera de eje es la única diferencia narrativa.
		marcas.append(
			MesaCinematica.pieza(
				A7.x + 0.03, A7.z + 0.16, Vector3(0.12, 0.002, 0.014), ALERTA, altura
			)
		)
	return marcas


static func _carpeta() -> Array:
	return [
		MesaCinematica.pieza(A7.x, A7.z, Vector3(0.38, 0.03, 0.5), BORDE),
		MesaCinematica.pieza(A7.x, A7.z, Vector3(0.36, 0.004, 0.48), CARPETA, 0.03),
	]
