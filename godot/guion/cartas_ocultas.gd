## Ocho de las veintidós cartas de tarot no se desbloquean por progreso: están
## escondidas como una frase concreta dentro de un documento ya existente.
##
## Port de [code]CartaOcultaService[/code]. La tabla es la misma; lo que ya no
## hace este módulo es marcar el texto (eso es de [code]Marcas[/code]).
class_name CartasOcultas
extends RefCounted

const POR_FOLIO := {
	"ACTA-1999-014":
	{"frase": "cinco minutos después de la hora de registro", "carta": "la-justicia"},
	"OF-1990-114": {"frase": "para su valoración y trámite correspondiente", "carta": "la-rueda"},
	"MEMO-1993-201": {"frase": "Preséntese el día 05/07/1993 sin excepción", "carta": "el-juicio"},
	"F-1996-00187": {"frase": "es de color amarillo", "carta": "la-luna"},
	"ACTA-2007-002": {"frase": "aproximadamente cada quince años", "carta": "el-carro"},
	"FAX-1996-077": {"frase": "no corresponden a ningún alfabeto reconocido", "carta": "el-sol"},
	"OF-1998-077": {"frase": "no ha lugar", "carta": "la-emperatriz"},
	"ACTA-1998-427B": {"frase": "No hubo testigos", "carta": "la-sacerdotisa"},
}


static func en_folio(folio) -> Dictionary:
	if folio == null:
		return {}
	return POR_FOLIO.get(folio, {})
