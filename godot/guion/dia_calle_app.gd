## Corrección visual del trayecto (#277).
##
## La calle no puede construirse como una habitación: la declaración antigua
## reutilizaba el rectángulo interior de Espacio3D y acababa con techo y cuatro
## muros perimetrales, de modo que el exterior se leía como un pasillo.
##
## Esta capa mantiene el contrato de Jornada y recompone únicamente la geometría
## de `calle`: planta vacía para no levantar envolvente interior, calzada/aceras
## como bultos bajos, fachadas discontinuas y un único escaparate de televisores
## 3D. Las seis superficies `Pantalla` dispersas desaparecen.
extends "res://guion/dia_onboarding_app.gd"


func _espacio_de(fase: String) -> Dictionary:
	var espacio: Dictionary = super._espacio_de(fase)
	if fase != "calle":
		return espacio

	# Una planta vacía evita que Espacio3D trate la calle como una habitación:
	# no hay techo ni muros automáticos. El suelo y las fachadas se declaran
	# explícitamente debajo, igual que cualquier otro volumen del catálogo.
	espacio.erase("suelo")
	espacio["planta"] = []
	espacio.erase("pantallas")
	espacio["bultos"] = _bultos_calle()
	espacio["ventanas"] = _ventanas_calle()
	return espacio


func _bultos_calle() -> Array:
	return [
		# Calzada y dos aceras: la sección transversal ya no es la de un pasillo.
		{
			"pos": Vector3(0, -0.10, 0),
			"tam": Vector3(8.0, 0.20, 34.0),
			"color": Color(0.20, 0.20, 0.22),
			"textura": "asfalto",
		},
		{
			"pos": Vector3(-4.8, 0.02, 0),
			"tam": Vector3(1.6, 0.24, 34.0),
			"color": Color(0.38, 0.37, 0.36),
		},
		{
			"pos": Vector3(4.8, 0.02, 0),
			"tam": Vector3(1.6, 0.24, 34.0),
			"color": Color(0.38, 0.37, 0.36),
		},
		# Fachadas discontinuas, con distintas alturas y retranqueos. Dejan cielo
		# visible entre edificios y rompen la lectura de corredor uniforme.
		{
			"pos": Vector3(-6.3, 2.1, -11.5),
			"tam": Vector3(2.2, 4.2, 7.0),
			"color": Color(0.31, 0.27, 0.25),
		},
		{
			"pos": Vector3(-6.7, 2.8, 9.0),
			"tam": Vector3(2.4, 5.6, 10.0),
			"color": Color(0.27, 0.28, 0.31),
		},
		{
			"pos": Vector3(6.5, 2.5, -8.5),
			"tam": Vector3(2.0, 5.0, 9.0),
			"color": Color(0.30, 0.29, 0.27),
		},
		{
			"pos": Vector3(6.8, 1.9, 8.5),
			"tam": Vector3(2.5, 3.8, 9.0),
			"color": Color(0.26, 0.25, 0.27),
		},
		# Tienda de electrodomésticos: fondo y marco dejan un hueco real entre
		# fachada y cristal, de modo que las televisiones son visibles dentro del
		# escaparate y no un dibujo pegado por fuera.
		{
			"pos": Vector3(-6.65, 1.70, -1.5),
			"tam": Vector3(0.35, 3.40, 7.0),
			"color": Color(0.24, 0.22, 0.21),
		},
		{
			"pos": Vector3(-5.58, 0.35, -1.5),
			"tam": Vector3(0.22, 0.70, 7.0),
			"color": Color(0.18, 0.17, 0.18),
		},
		{
			"pos": Vector3(-5.58, 2.85, -1.5),
			"tam": Vector3(0.22, 0.55, 7.0),
			"color": Color(0.18, 0.17, 0.18),
		},
		{
			"pos": Vector3(-5.58, 1.60, -4.9),
			"tam": Vector3(0.22, 2.0, 0.22),
			"color": Color(0.18, 0.17, 0.18),
		},
		{
			"pos": Vector3(-5.58, 1.60, 1.9),
			"tam": Vector3(0.22, 2.0, 0.22),
			"color": Color(0.18, 0.17, 0.18),
		},
		# Tres televisores juntos y a diferentes alturas: un escaparate, no seis
		# monitores arbitrarios repartidos por la calle.
		{
			"pos": Vector3(-5.95, 0.82, -3.25),
			"tam": Vector3(0.78, 0.68, 0.58),
			"color": Color(0.38, 0.34, 0.30),
			"modelo": "televisionVintage",
		},
		{
			"pos": Vector3(-5.92, 0.86, -1.45),
			"tam": Vector3(0.92, 0.78, 0.66),
			"color": Color(0.34, 0.32, 0.30),
			"modelo": "televisionVintage",
		},
		{
			"pos": Vector3(-5.98, 1.45, 0.30),
			"tam": Vector3(0.72, 0.62, 0.54),
			"color": Color(0.40, 0.36, 0.31),
			"modelo": "televisionVintage",
		},
		{
			"pos": Vector3(-5.98, 0.42, 0.30),
			"tam": Vector3(1.05, 0.18, 0.80),
			"color": Color(0.25, 0.22, 0.20),
		},
		# Portal de destino: marco alto y separado del resto de fachadas para que
		# desde el spawn exista una composición clara hacia casa.
		{
			"pos": Vector3(-1.15, 1.55, 15.8),
			"tam": Vector3(0.45, 3.1, 0.55),
			"color": Color(0.42, 0.38, 0.32),
		},
		{
			"pos": Vector3(1.15, 1.55, 15.8),
			"tam": Vector3(0.45, 3.1, 0.55),
			"color": Color(0.42, 0.38, 0.32),
		},
		{
			"pos": Vector3(0, 2.95, 15.8),
			"tam": Vector3(2.75, 0.35, 0.55),
			"color": Color(0.42, 0.38, 0.32),
		},
	]


func _ventanas_calle() -> Array:
	return [
		# Un solo paño de escaparate agrupa visualmente los televisores.
		{
			"pos": Vector3(-5.70, 1.62, -1.5),
			"tam": Vector3(0.08, 2.0, 6.45),
			"color": Color(0.12, 0.16, 0.22),
		},
		# Ventanas domésticas puntuales: repetición irregular, no paneles de TV.
		{
			"pos": Vector3(5.42, 1.85, -10.0),
			"tam": Vector3(0.08, 1.05, 1.35),
			"color": Color(0.13, 0.15, 0.18),
		},
		{
			"pos": Vector3(5.72, 1.55, 8.8),
			"tam": Vector3(0.08, 0.90, 1.15),
			"color": Color(0.16, 0.13, 0.10),
		},
	]
