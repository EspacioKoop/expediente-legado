## Convierte los segmentos de [code]Marcas[/code] en BBCode para un
## RichTextLabel. Es el equivalente del HTML que emitían los servicios Java, y
## el único sitio del port que sabe cómo se ve una marca.
##
## El escapado también cambia de sitio: en HTML el peligro era [code]<[/code] y
## se escapaba en cada servicio; aquí es [code][[/code], y se escapa UNA vez,
## solo en el texto plano — nunca en el marcado que este módulo genera.
class_name BBCode
extends RefCounted


## Un corchete literal en el texto de un expediente abriría una etiqueta.
static func escapar(texto: String) -> String:
	return texto.replace("[", "[lb]")


static func render(segmentos: Array) -> String:
	var salida := ""
	for segmento in segmentos:
		var texto: String = escapar(segmento["texto"])
		match segmento["tipo"]:
			"pista":
				salida += (
					"[url=pista:%s][color=#0000aa][u]%s[/u][/color][/url]"
					% [segmento["meta"]["pista"], texto]
				)
			"pista_vista":
				salida += "[bgcolor=#c8c800]%s[/bgcolor]" % texto
			"carta":
				salida += (
					"[url=carta:%s][color=#0000aa][u]%s[/u][/color][/url]"
					% [segmento["meta"]["carta"], texto]
				)
			"concepto":
				salida += (
					"[url=concepto:%s][color=#0000aa][u]%s[/u][/color][/url]"
					% [segmento["meta"]["nombre"], texto]
				)
			"concepto_pendiente":
				# Se lee, no lleva a ninguna parte: un expediente no localizado.
				salida += "[color=#808080]%s[/color]" % texto
			_:
				salida += texto
	return salida
