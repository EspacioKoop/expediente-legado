## Entrada al sueño: la primera sala se descubre desde dentro (#74, #395).
##
## La noche, el mapa y la primera sala ya están calculados y MONTADOS cuando
## esta pieza se reproduce. Desde #395 no dibuja una habitación de rectángulos:
## rueda en la sala onírica real que el jugador va a pisar, encadenada a la cama
## de `SuenoCinematica`, de modo que casa→sueño se lee como una sola secuencia.
##
## Aprovecha lo que la sala ya trae —entrada, figuras, carteles con frases de lo
## leído y el resplandor de la salida— sin añadir geometría ni elegir contenido.
## Tampoco modifica la jornada: saltarla o verla entera deja el mismo estado.
class_name EntradaSuenoCinematica
extends RefCounted

const ID := "entrada-sueno"

## Altura de los ojos del caminante sobre el suelo de la sala.
const OJOS := 1.6

## Si la sala no trae nada a lo que mirar, se mira hacia delante (-z), que es
## hacia donde se entra cuando el sitio no declara rumbo.
const DELANTE := Vector3(0, 0, -6)


## [param espacio] es el diccionario de la sala ya montada (`Sueno.espacio`).
## Sin él los planos siguen siendo válidos alrededor del origen, para pruebas y
## llamantes antiguos.
static func planos_de(folios_leidos: Array, vistas: int = 0, espacio: Dictionary = {}) -> Array:
	var conocidos := []
	for folio in folios_leidos:
		if folio is String and not folio.is_empty() and not conocidos.has(folio):
			conocidos.append(folio)
			if conocidos.size() == 3:
				break
	var rodaje := Cinematica.resolver(planos(espacio), {}, vistas)
	if not conocidos.is_empty():
		rodaje[1]["rotulo"] = conocidos[0]
	return rodaje


## Tres planos: llegar, reconocer lo leído y quedarse a la altura de los ojos.
## Todos declaran cámara fija y mira: con reducción de movimiento comunican lo
## mismo porque el reproductor solo quita el avance.
static func planos(espacio: Dictionary = {}) -> Array:
	var entrada: Vector3 = espacio.get("entrada", Vector3.ZERO)
	var foco := foco_de(espacio)
	var detalle := detalle_de(espacio)
	var hacia := foco - entrada
	hacia.y = 0.0
	if hacia.length() < 0.5:
		hacia = DELANTE
	var atras := -hacia.normalized()
	return [
		{
			# Llegada: desde encima y detrás del umbral se ve la sala entera y
			# el primer encuentro; el sueño ya es un sitio, no una tarjeta.
			"tipo": "3d",
			"nombre": "llegada",
			"camara": entrada + atras * 2.2 + Vector3(0, 2.6, 0),
			"mira": foco + Vector3(0, 0.6, 0),
			"segundos": 2.0,
		},
		{
			# Lo leído: la cámara se acerca a un cartel de la sala (frases que
			# salen de los folios del día) o, si no hay, a la primera figura.
			"tipo": "3d",
			"nombre": "leido",
			"camara": entrada.lerp(detalle, 0.55) + Vector3(0, 1.9, 0),
			"mira": detalle + Vector3(0, 1.2, 0),
			"segundos": 2.2,
		},
		{
			# Remate a la altura de los ojos del caminante y mirando al mismo
			# encuentro: devolver el control no es un corte de cámara.
			"tipo": "3d",
			"nombre": "mirada",
			"camara": entrada + Vector3(0, OJOS, 0),
			"mira": foco + Vector3(0, 1.1, 0),
			"segundos": 1.6,
		},
	]


## El primer encuentro: la figura puesta delante de la entrada o, en una sala
## vacía, el resplandor de la salida que invita a buscarla.
static func foco_de(espacio: Dictionary) -> Vector3:
	var entrada: Vector3 = espacio.get("entrada", Vector3.ZERO)
	var figuras: Array = espacio.get("figuras", [])
	if not figuras.is_empty():
		return Vector3(figuras[0].get("pos", entrada + DELANTE))
	var salidas: Array = espacio.get("salidas", [])
	if not salidas.is_empty():
		var pos: Vector3 = salidas[0].get("pos", entrada + DELANTE)
		return Vector3(pos.x, entrada.y, pos.z)
	return entrada + DELANTE


## Lo que representa lo leído dentro de la sala: el cartel más cercano a la
## entrada. Sin carteles, el mismo foco del primer plano.
static func detalle_de(espacio: Dictionary) -> Vector3:
	var entrada: Vector3 = espacio.get("entrada", Vector3.ZERO)
	var carteles: Array = espacio.get("carteles", [])
	var mejor := foco_de(espacio)
	var distancia := INF
	for cartel in carteles:
		var pos: Vector3 = cartel.get("pos", mejor)
		var d := entrada.distance_to(pos)
		if d < distancia:
			distancia = d
			mejor = Vector3(pos.x, entrada.y, pos.z)
	return mejor
