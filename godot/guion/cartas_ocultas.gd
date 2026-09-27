## Ocho de las veintidós cartas de tarot no se desbloquean por progreso: están
## escondidas como una frase concreta dentro de un documento ya existente.
##
## Port de [code]CartaOcultaService[/code]. La tabla es la misma; lo que ya no
## hace este módulo es marcar el texto (eso es de [code]Marcas[/code]).
##
## [code]frase_en[/code] es la misma frase en [code]casos.en.json[/code]: con el
## catálogo en inglés la española no aparece y la carta quedaría inalcanzable.
class_name CartasOcultas
extends RefCounted

const POR_FOLIO := {
	"ACTA-1999-014":
	{
		"frase": "cinco minutos después de la hora de registro",
		"frase_en": "five minutes after the invoice was logged",
		"carta": "la-justicia",
	},
	"OF-1990-114":
	{
		"frase": "para su valoración y trámite correspondiente",
		"frase_en": "for assessment and the corresponding procedure",
		"carta": "la-rueda",
	},
	"MEMO-1993-201":
	{
		"frase": "Preséntese el día 05/07/1993 sin excepción",
		"frase_en": "Report there on 05/07/1993 without exception",
		"carta": "el-juicio",
	},
	"F-1996-00187":
	{
		"frase": "es de color amarillo",
		"frase_en": "it is yellow",
		"carta": "la-luna",
	},
	"ACTA-2007-002":
	{
		"frase": "aproximadamente cada quince años",
		"frase_en": "approximately every fifteen years",
		"carta": "el-carro",
	},
	"FAX-1996-077":
	{
		"frase": "no corresponden a ningún alfabeto reconocido",
		"frase_en": "correspond to no recognized alphabet",
		"carta": "el-sol",
	},
	"OF-1998-077":
	{
		"frase": "no ha lugar",
		"frase_en": "no action warranted",
		"carta": "la-emperatriz",
	},
	"ACTA-1998-427B":
	{
		"frase": "No hubo testigos",
		"frase_en": "There were no witnesses",
		"carta": "la-sacerdotisa",
	},
}


static func en_folio(folio) -> Dictionary:
	if folio == null:
		return {}
	return POR_FOLIO.get(folio, {})


## La variante de la frase que aparece en [param texto]. Se decide por el
## documento que se está mostrando y no por el locale, porque [code]Contenido[/code]
## puede caer al catálogo español aunque el locale sea otro.
static func frase_en_texto(carta: Dictionary, texto: String) -> String:
	for clave in ["frase", "frase_en"]:
		var candidata := String(carta.get(clave, ""))
		if not candidata.is_empty() and texto.contains(candidata):
			return candidata
	return ""
