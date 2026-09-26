import csv
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
TEXTOS = ROOT / "godot" / "datos" / "textos.csv"


class TestTextosCsvFormato(unittest.TestCase):
    def test_cada_fila_tiene_clave_y_texto(self) -> None:
        errores = []
        with TEXTOS.open(encoding="utf-8-sig", newline="") as archivo:
            for numero, fila in enumerate(csv.reader(archivo), start=1):
                if not fila or (len(fila) == 1 and not fila[0].strip()):
                    continue
                if len(fila) != 2:
                    clave = fila[0] if fila else "<sin clave>"
                    errores.append(
                        f"linea {numero}: {clave} tiene {len(fila)} columnas"
                    )

        self.assertEqual(
            [],
            errores,
            "textos.csv debe mantener exactamente dos columnas (clave, es); "
            "las comas dentro del texto deben ir entrecomilladas",
        )


if __name__ == "__main__":
    unittest.main()
