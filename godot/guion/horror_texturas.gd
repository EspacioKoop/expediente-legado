## Biblioteca runtime del Horror Texture Pack de Screaming Brain Studios (#231).
##
## Este módulo NO carga el pack por obligación: planifica una piel onírica y
## solo aplica cada pieza si el objeto LFS existe. Así el juego conserva su
## fallback procedural en un checkout sin binarios, mientras el mismo contrato
## se activa automáticamente cuando se importe el lote 128x128 auditado.
##
## La intensidad no inventa contenido. Las manchas se apoyan únicamente en
## carteles que ya nacieron de #87 y se colocan por debajo/lateralmente para no
## tapar el texto. Stain 01-05 nunca aparecen aquí: 01-03 son sangre explícita
## y 04-05 tienen una lectura orgánica demasiado ambigua para automatizarlas.
class_name HorrorTexturas
extends RefCounted

const RAIZ := "res://assets/texturas/horror_sbs/128x128/"
const NIVEL_MIN := 1
const NIVEL_MAX := 3

const PERFIL_POR_IDENTIDAD := {
	"escuela": "escuela",
	"castillo": "castillo",
	"desierto": "desierto",
	"montana": "montana",
}

const PERFIL_POR_FORMA := {
	"escalera": "archivo",
	"gilgamesh": "castillo",
}

const PERFILES := {
	"archivo":
	{
		"muro": "Metal/Horror_Metal_06",
		"suelo": "Misc/Horror_Misc_13",
		"escala": 1.35,
		"manchas":
		[
			"Stains/Horror_Stain_10",
			"Stains/Horror_Stain_11",
			"Stains/Horror_Stain_12",
		],
	},
	"escuela":
	{
		"muro": "Wall/Horror_Wall_09",
		"suelo": "Floor/Horror_Floor_12",
		"escala": 1.20,
		"manchas":
		[
			"Stains/Horror_Stain_07",
			"Stains/Horror_Stain_10",
			"Stains/Horror_Stain_13",
		],
	},
	"castillo":
	{
		"muro": "Brick/Horror_Brick_11",
		"suelo": "Stone/Horror_Stone_07",
		"escala": 1.10,
		"manchas":
		[
			"Stains/Horror_Stain_13",
			"Stains/Horror_Stain_14",
			"Stains/Horror_Stain_10",
		],
	},
	"desierto":
	{
		"muro": "Wall/Horror_Wall_05",
		"suelo": "Stone/Horror_Stone_13",
		"escala": 1.45,
		"manchas":
		[
			"Stains/Horror_Stain_15",
			"Stains/Horror_Stain_13",
			"Stains/Horror_Stain_14",
		],
	},
	"montana":
	{
		"muro": "Stone/Horror_Stone_14",
		"suelo": "Stone/Horror_Stone_10",
		"escala": 1.55,
		"manchas":
		[
			"Stains/Horror_Stain_15",
			"Stains/Horror_Stain_14",
			"Stains/Horror_Stain_13",
		],
	},
}


## Ruta estable del PNG 128x128 generado por el importador de #973.
static func ruta(identificador: String) -> String:
	return RAIZ + identificador + "-128x128.png"


## El perfil lo decide primero la identidad final del sueño y solo después la
## forma base. Esto evita que, por ejemplo, una montaña siga usando la piel de
## un embudo genérico una vez que #284 ya la convirtió en otra cosa.
static func perfil_de(espacio: Dictionary, forma_id: String) -> String:
	var identidad := String(espacio.get("identidad_onirica", ""))
	if PERFIL_POR_IDENTIDAD.has(identidad):
		return String(PERFIL_POR_IDENTIDAD[identidad])
	if PERFIL_POR_FORMA.has(forma_id):
		return String(PERFIL_POR_FORMA[forma_id])
	return "archivo"


## Escala visual dentro de una noche.
##
## Con tres salas: 1 -> 2 -> 3. Una noche de una sola escena queda en 2 para no
## convertir una variante corta en clímax automático. Si en la sala aparece un
## acusado retable, se sube un grado: el contenido ya autorizado es el que hace
## que el espacio se vuelva más agresivo, no una tirada arbitraria.
static func nivel_para_noche(
	total_escenas: int, escenas_restantes: int, espacio: Dictionary = {}
) -> int:
	var total := maxi(total_escenas, 1)
	var restantes := clampi(escenas_restantes, 1, total)
	var nivel := 2
	if total > 1:
		var indice := clampi(total - restantes, 0, total - 1)
		var progreso := float(indice) / float(total - 1)
		nivel = clampi(1 + int(round(progreso * 2.0)), NIVEL_MIN, NIVEL_MAX)

	for figura in espacio.get("figuras", []):
		if typeof(figura) != TYPE_DICTIONARY:
			continue
		if not String(figura.get("duelo", "")).is_empty():
			nivel = mini(nivel + 1, NIVEL_MAX)
			break
	return nivel


## Plan puro: no toca ResourceLoader ni el espacio recibido. Sirve para que la
## selección sea comprobable incluso antes de que el lote LFS exista.
static func planificar(espacio: Dictionary, forma_id: String, nivel: int) -> Dictionary:
	var nivel_seguro := clampi(nivel, NIVEL_MIN, NIVEL_MAX)
	var perfil_id := perfil_de(espacio, forma_id)
	var perfil: Dictionary = PERFILES[perfil_id]
	var plan := {
		"perfil": perfil_id,
		"nivel": nivel_seguro,
		"escala_textura": float(perfil["escala"]) * (1.0 + 0.18 * float(nivel_seguro - 1)),
		"textura_muro": ruta(String(perfil["muro"])),
	}

	# El primer grado conserva el suelo conocido. En el segundo el material ya
	# invade la habitación entera y en el tercero las manchas son más visibles.
	if nivel_seguro >= 2:
		plan["textura_suelo"] = ruta(String(perfil["suelo"]))

	var carteles: Array = espacio.get("carteles", [])
	var manchas: Array = perfil.get("manchas", [])
	var cantidad := mini(nivel_seguro, mini(carteles.size(), manchas.size()))
	var decals := []
	for i in cantidad:
		var cartel: Dictionary = carteles[i]
		var giro := float(cartel.get("giro", 0.0))
		var lateral := Vector3(cos(giro), 0.0, -sin(giro))
		var lado := 1.0 if i % 2 == 0 else -1.0
		var posicion := (
			Vector3(cartel.get("pos", Vector3.ZERO))
			+ lateral * 0.62 * lado
			+ Vector3(0.0, 0.62 + 0.14 * float(i), 0.0)
		)
		decals.append(
			{
				"ruta": ruta(String(manchas[i])),
				"pos": posicion,
				"rot": Vector3(0.0, giro, 0.0),
				"ancho": 0.9 + 0.24 * float(nivel_seguro) + 0.08 * float(i),
				"opacidad": 0.14 + 0.10 * float(nivel_seguro),
				"separacion": 0.006 + 0.001 * float(i),
			}
		)
	plan["decals"] = decals
	return plan


## Aplica únicamente piezas que ya existen como recursos importados.
## Si no hay ni una, devuelve el espacio original sin añadir metadatos ni avisos.
static func aplicar(espacio: Dictionary, forma_id: String, nivel: int) -> Dictionary:
	var plan := planificar(espacio, forma_id, nivel)
	var resultado := espacio.duplicate(true)
	var aplicado := false

	for clave in ["textura_muro", "textura_suelo"]:
		var candidata := String(plan.get(clave, ""))
		if candidata.is_empty() or not ResourceLoader.exists(candidata):
			continue
		resultado[clave] = candidata
		aplicado = true

	var decals_nuevos := []
	for entrada in plan.get("decals", []):
		var ruta_decal := String(entrada.get("ruta", ""))
		if ruta_decal.is_empty() or not ResourceLoader.exists(ruta_decal):
			continue
		decals_nuevos.append(entrada)

	if not decals_nuevos.is_empty():
		var decals: Array = resultado.get("decals", []).duplicate(true)
		decals.append_array(decals_nuevos)
		resultado["decals"] = decals
		aplicado = true

	if not aplicado:
		return espacio

	resultado["escala_textura"] = float(plan["escala_textura"])
	resultado["horror_perfil"] = String(plan["perfil"])
	resultado["horror_nivel"] = int(plan["nivel"])
	return resultado
