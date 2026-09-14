from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "godot" / "guion" / "incidentes_conducta.gd"


class IncidentesConductaContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = SOURCE.read_text(encoding="utf-8")

    def test_exposes_reusable_incident_api(self):
        for token in [
            "class_name IncidentesConducta",
            "static func registrar_incidente(",
            'const CLAVE_HISTORIAL := "incidentes_conducta"',
            'const GOLPE_PARED := "golpe_pared"',
        ]:
            self.assertIn(token, self.source)

    def test_office_result_can_end_day_and_fire_on_recurrence(self):
        for token in [
            'if lugar != OFICINA:',
            'return _resultado(false, "huir", true, false, true)',
            'return _resultado(true, "huir", true, reincidencia, true)',
            'if dia_anterior > 0 and dia_anterior < dia:',
            "reincidencia = true",
        ]:
            self.assertIn(token, self.source)

    def test_same_day_is_idempotent(self):
        self.assertIn("if dia_anterior == dia:", self.source)
        self.assertIn('return _resultado(false, "huir", true, false, true)', self.source)

    def test_home_and_dream_do_not_create_labour_consequences(self):
        self.assertIn('return _resultado(false, "onirica", false, false, false)', self.source)
        self.assertIn('return _resultado(false, "marca_opcional", false, false, false)', self.source)

    def test_module_cannot_grant_economic_advantages(self):
        for forbidden in [
            '"dinero"',
            '"acciones"',
            "Jornada.gastar",
            "Jornada.gastar_accion",
            "POR_EXPEDIENTE",
            "BASE_DIARIA",
        ]:
            self.assertNotIn(forbidden, self.source)


if __name__ == "__main__":
    unittest.main()
