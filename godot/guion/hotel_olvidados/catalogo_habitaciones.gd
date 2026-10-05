class_name CatalogoHabitaciones

# Catálogo de las 4 habitaciones/microhistorias del hotel.
# Cada entrada contiene:
# - motivo: la razón o tema central de la habitación
# - visual: descripción visual
# - sonido: pista sonora
# - indicio: elemento clave para resolver la pista
# - salida: acción o condición para salir de la habitación

const CATALOGO = [
	{
		"motivo": "Baño fantasma",
		"visual": "Azulejos agrietados y vapor que se evapora sin agua",
		"sonido": "Goteo constante que se vuelve un susurro",
		"indicio": "Una llave oxidada flotando en el aire",
		"salida": "Recoger la llave y usarla en la puerta del espejo"
	},
	{
		"motivo": "Biblioteca silenciosa",
		"visual": "Estanterías que se estiran hasta el techo, libros que susurran",
		"sonido": "Un leve crujido cada vez que se abre un libro",
		"indicio": "Un libro titulado 'El fin del sueño' que está fuera de lugar",
		"salida": "Leer el libro para revelar la puerta oculta"
	},
	{
		"motivo": "Comedor de sombras",
		"visual": "Mesa larga con sombras alargadas que se mueven sin luz",
		"sonido": "Cuchillos que chocan lejanamente",
		"indicio": "Una vela sin llama que emite un leve hum",
		"salida": "Encender la vela usando el espejo roto"
	},
	{
		"motivo": "Suite del tiempo",
		"visual": "Relojes marcando distintas horas simultáneamente",
		"sonido": "Tic‑tac que se acelera y desacelera",
		"indicio": "Un cronómetro que se detiene al ritmo del latido del corazón",
		"salida": "Sincronizar los relojes con el cronómetro"
	}
]


# Devuelve todo el catálogo.
func obtener_catalogo() -> Array:
	return CATALOGO


# Devuelve la habitación en el índice dado (0‑based).
func obtener_habitacion(indice: int) -> Dictionary:
	if indice >= 0 and indice < CATALOGO.size():
		return CATALOGO[indice]
	push_error("Índice de habitación fuera de rango: %d" % indice)
	return {}
