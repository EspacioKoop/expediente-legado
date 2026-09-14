## La Ventanilla de Reclamaciones: quién se presenta y qué queda de la racha.
##
## La lógica de a quién puedes atender, separada de la pantalla que lo pinta.
## Los reclamantes salen del corcho —personas y comités que ya conoces— así que
## investigar y a quién te enfrentas están atados: es la regla de #48.
##
## Con una excepción deliberada: **siempre hay un reclamante de oficio**. Sin
## él, una partida recién empezada abriría la Ventanilla vacía, que es
## indistinguible de una Ventanilla rota. Y el de oficio no es un relleno
## cualquiera: es el expediente sin nombre, que es exactamente lo que un
## sistema como este produce cuando no tiene a nadie a quien llamar.
class_name Ventanilla
extends RefCounted

## Sus textos son CLAVES de traducción, igual que los del resto del código. Los
## reclamantes de verdad vienen de `casos.json`, que todavía no está traducido y
## trae el texto tal cual: quien los pinta pasa los dos por `tr()`, que devuelve
## intacto lo que no es una clave. Esa costura se cierra cuando el catálogo pase
## por su propia tarjeta.
const DE_OFICIO := {
	"id": "reclamante-de-oficio",
	"nombre": "OFICIO_NOMBRE",
	"tipo": "PERSONA",
	"resumen": "OFICIO_RESUMEN",
	"ataques":
	[
		"OFICIO_ATAQUE_1",
		"OFICIO_ATAQUE_2",
		"OFICIO_ATAQUE_3",
		"OFICIO_ATAQUE_4",
	],
	"de_oficio": true,
}


## Los reclamantes disponibles, el de oficio siempre el último: los que has
## descubierto van primero porque son los que significan algo.
static func disponibles(contenido: Contenido, descubiertas: Array) -> Array:
	var lista := contenido.reclamantes(descubiertas).duplicate()
	lista.append(DE_OFICIO)
	return lista


## Cierra una reclamación: actualiza la racha y dice qué logros se han ganado.
##
## La racha en curso es efímera (no se guarda) y la mejor marca es lo único que
## sobrevive a la partida — es la meta-progresión de la Ventanilla.
static func cerrar(estado: Dictionary, racha: int, gano: bool) -> Dictionary:
	var resultado := Prometeo.actualizar_racha(
		racha, int(estado.get("coliseo_racha_mejor", 0)), gano
	)
	estado["coliseo_racha_mejor"] = resultado["mejor"]

	var logros := []
	for hito in [[3, "ventanilla-tres"], [5, "funcionario-del-mes"], [10, "ventanilla-inagotable"]]:
		if resultado["racha"] >= hito[0]:
			logros.append(hito[1])
	resultado["logros"] = logros
	return resultado
