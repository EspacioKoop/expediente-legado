from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import registrar_cata_119 as cata  # noqa: E402


def fuente(decision="promover", **cambios):
    datos = {
        "decision": decision,
        "nivel_adecuado": True,
        "loop_limpio": True,
        "fatiga_aceptable": True,
        "legibilidad": True,
        "observacion": "",
    }
    datos.update(cambios)
    return datos


BASE = {
    "fecha": "2026-09-28T21:10:00+02:00",
    "participante": "oyente-119",
    "plataforma": "Linux / auriculares",
    "artifact": "Cata ambientes 119 #3",
    "build_ref": "41d1bc92",
    "fuentes": {
        "fluorescente_archivo": fuente(),
        "teclado_oficina": fuente("iterar"),
        "calle_nocturna": fuente("descartar"),
        "sueno_onirico": fuente(),
    },
}


class RegistrarCata119Test(unittest.TestCase):
    def test_clasifica_decisiones(self):
        resultado = cata.evaluar_cata(BASE)
        self.assertTrue(resultado["cata_completa"])
        self.assertEqual(
            resultado["promover"], ["fluorescente_archivo", "sueno_onirico"]
        )
        self.assertEqual(resultado["iterar"], ["teclado_oficina"])
        self.assertEqual(resultado["descartar"], ["calle_nocturna"])

    def test_promover_con_un_check_fallido_se_convierte_en_iteracion(self):
        datos = dict(BASE)
        datos["fuentes"] = dict(BASE["fuentes"])
        datos["fuentes"]["fluorescente_archivo"] = fuente(
            "promover", fatiga_aceptable=False
        )
        resultado = cata.evaluar_cata(datos)
        self.assertNotIn("fluorescente_archivo", resultado["promover"])
        self.assertIn("fluorescente_archivo", resultado["iterar"])

    def test_decision_desconocida_deja_cata_incompleta(self):
        datos = dict(BASE)
        datos["fuentes"] = dict(BASE["fuentes"])
        datos["fuentes"]["sueno_onirico"] = fuente("quizas")
        self.assertFalse(cata.evaluar_cata(datos)["cata_completa"])

    def test_informe_no_confunde_cata_con_promocion_runtime(self):
        informe = cata.render_markdown(BASE)
        self.assertIn("promover: fluorescente_archivo, sueno_onirico", informe)
        self.assertIn("promoción a runtime, procedencia/hash", informe)
        self.assertIn("CI no sustituye esta escucha humana", informe)


if __name__ == "__main__":
    unittest.main()
