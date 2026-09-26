from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
DIA_APP = ROOT / "godot" / "guion" / "dia_app.gd"


def _funcion(nombre: str, fuente: str) -> str:
    patron = rf"(?ms)^func {re.escape(nombre)}\([^\n]*\).*?(?=^func |\Z)"
    match = re.search(patron, fuente)
    if match is None:
        raise AssertionError(f"no se encontró {nombre}")
    return match.group(0)


class TestEstadoPuesto1451(unittest.TestCase):
    def test_estado_se_activa_solo_durante_siga(self) -> None:
        fuente = DIA_APP.read_text(encoding="utf-8")
        abrir = _funcion("_abrir_expediente", fuente)
        cerrar = _funcion("_cerrar_expediente", fuente)

        self.assertIn('_nomina.text = tr("DIA_EN_EL_PUESTO")', abrir)
        self.assertIn('_nomina.text = ""', cerrar)

        limpiar = cerrar.index('_nomina.text = ""')
        reasignar = cerrar.index('if int(jornada.get("vuelta", 1)) != vuelta_antes:')
        self.assertLess(
            limpiar,
            reasignar,
            "el estado del puesto debe limpiarse también antes de una reasignación",
        )


if __name__ == "__main__":
    unittest.main()
