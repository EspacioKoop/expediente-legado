from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
DIA_APP = ROOT / "godot" / "guion" / "dia_app.gd"
DIA_EXPEDIENTE_APP = ROOT / "godot" / "guion" / "dia_expediente_app.gd"


def _funcion(nombre: str, fuente: str) -> str:
    patron = rf"(?ms)^func {re.escape(nombre)}\([^\n]*\).*?(?=^func |\Z)"
    match = re.search(patron, fuente)
    if match is None:
        raise AssertionError(f"no se encontró {nombre}")
    return match.group(0)


def _normalizar_accesos(fuente: str) -> str:
    """Tolera el salto de línea que gdformat introduce antes de '. metodo('."""
    return re.sub(r"\s*\.\s*", ".", fuente)


class TestEstadoPuesto1451(unittest.TestCase):
    def test_estado_se_activa_solo_durante_siga(self) -> None:
        fuente = DIA_APP.read_text(encoding="utf-8")
        presentacion = DIA_EXPEDIENTE_APP.read_text(encoding="utf-8")
        abrir = _normalizar_accesos(_funcion("_abrir_expediente", fuente))
        cerrar = _normalizar_accesos(_funcion("_cerrar_expediente", fuente))

        self.assertIn("DIA_EXPEDIENTE_APP.abrir(", abrir)
        self.assertIn("DIA_EXPEDIENTE_APP.cerrar(", cerrar)
        self.assertIn('traducir.call("DIA_EN_EL_PUESTO")', presentacion)
        self.assertIn('nomina.text = ""', presentacion)

        limpiar = cerrar.index("DIA_EXPEDIENTE_APP.cerrar(")
        reasignar = cerrar.index('if int(jornada.get("vuelta", 1)) != vuelta_antes:')
        self.assertLess(
            limpiar,
            reasignar,
            "el estado del puesto debe limpiarse también antes de una reasignación",
        )


if __name__ == "__main__":
    unittest.main()
