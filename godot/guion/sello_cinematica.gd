## Cerrar un expediente: A-7, sello y carpeta.
##
## La lógica de la acusación ya está resuelta cuando esto empieza. Esta clase
## solo declara cómo se ve el gesto administrativo de cerrar la carpeta; verla,
## saltarla o acortarla no puede cambiar el veredicto ni el careo posterior.
class_name SelloCinematica
extends RefCounted

const ID := "cierre-sello"

const PAPEL := Color("dedbd2")
const TINTA := Color("3e3e42")
const CARPETA := Color("81745f")
const BORDE := Color("50483c")
const ALERTA := Color("8a4b45")


## La escena cambia visualmente si la firma fue precipitada, pero no lo dice
## con texto: la marca queda desplazada y duplicada, como un trámite hecho con
## demasiada prisa.
static func planos_de(precipitada: bool, vistas: int = 0) -> Array:
	return Cinematica.resolver(_planos(precipitada), {}, vistas)


static func _planos(precipitada: bool) -> Array:
	return [
		{
			"tipo": "2d",
			"nombre": "a7",
			"figura": _a7(),
			"desde": Vector2(-340, 12),
			"hasta": Vector2(0, 12),
			"segundos": 0.48,
			"rotulo": "",
			"voz": "",
		},
		{
			"tipo": "2d",
			"nombre": "sello",
			"figura": _sellado(precipitada),
			"desde": Vector2(0, -46),
			"hasta": Vector2(0, 12),
			"segundos": 0.34,
			"rotulo": "",
			"voz": "",
		},
		{
			"tipo": "2d",
			"nombre": "carpeta",
			"figura": _carpeta(precipitada),
			"desde": Vector2(0, 12),
			"hasta": Vector2(310, 12),
			"segundos": 0.58,
			"rotulo": "",
			"voz": "",
		},
	]


static func _a7() -> Array:
	return [
		{"rect": Rect2(-150, -190, 300, 360), "color": PAPEL},
		{"rect": Rect2(-128, -158, 256, 14), "color": TINTA},
		{"rect": Rect2(-128, -120, 190, 9), "color": TINTA},
		{"rect": Rect2(-128, -88, 230, 9), "color": TINTA},
		{"rect": Rect2(-128, -20, 256, 2), "color": TINTA},
		{"rect": Rect2(-128, 18, 18, 18), "color": TINTA},
		{"rect": Rect2(-96, 22, 168, 8), "color": TINTA},
	]


static func _sellado(precipitada: bool) -> Array:
	var figura := _a7()
	var color := ALERTA if precipitada else TINTA
	figura.append({"rect": Rect2(-74, 72, 148, 54), "color": color})
	figura.append({"rect": Rect2(-62, 84, 124, 30), "color": PAPEL})
	if precipitada:
		# La segunda huella fuera de eje es la única diferencia narrativa.
		figura.append({"rect": Rect2(-42, 122, 118, 8), "color": ALERTA})
	return figura


static func _carpeta(precipitada: bool) -> Array:
	var figura := [
		{"rect": Rect2(-184, -204, 368, 392), "color": BORDE},
		{"rect": Rect2(-174, -194, 348, 372), "color": CARPETA},
		{"rect": Rect2(-126, -176, 252, 300), "color": PAPEL},
	]
	var marca := ALERTA if precipitada else TINTA
	figura.append({"rect": Rect2(-64, 74, 128, 42), "color": marca})
	return figura
