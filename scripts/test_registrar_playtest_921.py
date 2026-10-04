import unittest

from scripts import registrar_playtest_921 as registro


def _rellenar_caso(caso: dict, doctrina: str | None = None) -> None:
    if doctrina is not None:
        caso["doctrina"] = doctrina
    caso.update(
        {
            "comprension": 4,
            "decision_tactica": 4,
            "coste_ventana": 3,
            "utilidad": 4,
            "frecuencia": "2 usos / 3 intentos / 2 cargas",
            "dominante": "no",
            "feedback": "señal legible",
            "incidencias": "ninguna",
        }
    )


def _registro_completo(mando: bool = False) -> dict:
    datos = registro.plantilla()
    datos["sesion"].update(
        {
            "fecha": "2026-10-04",
            "build_sha": "abc123",
            "plataforma": "Linux",
            "resolucion": "1920x1080",
            "probador": "humano",
            "mando_disponible": mando,
            "motivo_sin_mando": "" if mando else "mando no disponible",
        }
    )
    for codigo in registro.CASOS_OBLIGATORIOS:
        _rellenar_caso(datos["casos"][codigo])
    datos["casos"]["R1"]["ritual_tag"] = "control_espacio"
    datos["casos"]["R2"]["ritual_tag"] = "telegraph"
    datos["casos"]["M1"]["reduccion_movimiento"] = True
    if mando:
        _rellenar_caso(datos["casos"]["G1"], "Asamblea")
        datos["casos"]["G1"]["entrada"] = "mando físico"
    return datos


class RegistrarPlaytest921Test(unittest.TestCase):
    def test_matriz_completa_solo_declara_completitud(self) -> None:
        datos = _registro_completo()
        evaluacion = registro.evaluar(datos)
        self.assertEqual(evaluacion["estado"], "completo")
        self.assertEqual(evaluacion["errores"], [])
        informe = registro.generar_markdown(datos, evaluacion)
        self.assertIn("Estado de completitud: **completo**", informe)
        self.assertIn("no aprueba balance", informe)
        self.assertNotIn("PASS", informe)

    def test_rechaza_datos_humanos_incompletos(self) -> None:
        datos = _registro_completo()
        datos["sesion"]["build_sha"] = ""
        datos["casos"]["A2"]["feedback"] = ""
        datos["casos"]["A4"]["utilidad"] = 6
        evaluacion = registro.evaluar(datos)
        self.assertEqual(evaluacion["estado"], "pendiente_datos")
        self.assertIn("sesion.build_sha: obligatorio", evaluacion["errores"])
        self.assertIn("A2.feedback: requiere respuesta humana", evaluacion["errores"])
        self.assertIn("A4.utilidad: debe ser entero 1..5", evaluacion["errores"])

    def test_exige_dos_tags_rituales_distintos(self) -> None:
        datos = _registro_completo()
        datos["casos"]["R2"]["ritual_tag"] = datos["casos"]["R1"]["ritual_tag"]
        evaluacion = registro.evaluar(datos)
        self.assertIn(
            "R1/R2: deben cubrir dos tags rituales distintos",
            evaluacion["errores"],
        )

    def test_mando_puede_quedar_pendiente_solo_con_motivo(self) -> None:
        datos = _registro_completo()
        datos["sesion"]["motivo_sin_mando"] = ""
        evaluacion = registro.evaluar(datos)
        self.assertIn(
            "sesion.motivo_sin_mando: obligatorio cuando G1 no se ejecuta",
            evaluacion["errores"],
        )

        datos["sesion"]["motivo_sin_mando"] = "sin hardware"
        evaluacion = registro.evaluar(datos)
        self.assertEqual(evaluacion["estado"], "completo")

    def test_si_hay_mando_g1_es_obligatorio_y_fisico(self) -> None:
        datos = _registro_completo(mando=True)
        self.assertEqual(registro.evaluar(datos)["estado"], "completo")

        datos["casos"]["G1"]["entrada"] = "teclado/ratón"
        evaluacion = registro.evaluar(datos)
        self.assertIn("G1.entrada: debe registrar mando físico", evaluacion["errores"])

    def test_informe_conserva_tags_y_observaciones(self) -> None:
        datos = _registro_completo()
        datos["casos"]["R1"]["comentario"] = "cruce situacional"
        evaluacion = registro.evaluar(datos)
        informe = registro.generar_markdown(datos, evaluacion)
        self.assertIn("control_espacio", informe)
        self.assertIn("telegraph", informe)
        self.assertIn("cruce situacional", informe)
        self.assertIn("Build/SHA: abc123", informe)


if __name__ == "__main__":
    unittest.main()
