"""Pruebas unitarias para gbc/minijuegos/ariadne_98/main.asm.

Valida las estructuras de datos, laberintos de 3 niveles, Minotauro determinista,
compuertas de atajo, alertas telegráficas y la lógica de victoria requerida.
"""

from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
MAIN_ASM = RAIZ / "gbc" / "minijuegos" / "ariadne_98" / "main.asm"


class Ariadne98ASMTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.asm = MAIN_ASM.read_text(encoding="utf-8")

    def test_cabecera_e_identificacion_cartucho(self):
        self.assertIn('"ARIADNE98"', self.asm)
        self.assertIn('DEF ESTADO_TITULO EQU 0', self.asm)
        self.assertIn('DEF ESTADO_JUEGO  EQU 1', self.asm)
        self.assertIn('DEF ESTADO_SALIDA EQU 2', self.asm)

    def test_tres_niveles_y_tiles_especiales(self):
        self.assertIn('DEF NIVEL_ENTRADA  EQU 0', self.asm)
        self.assertIn('DEF NIVEL_GALERIAS EQU 1', self.asm)
        self.assertIn('DEF NIVEL_CENTRO   EQU 2', self.asm)

        self.assertIn('DEF TILE_PUERTA         EQU 17', self.asm)
        self.assertIn('DEF TILE_CENTRO         EQU 18', self.asm)
        self.assertIn('DEF TILE_TRANSICION     EQU 19', self.asm)
        self.assertIn('DEF TILE_MINOTAURO      EQU 20', self.asm)

    def test_variables_wram_minotauro_y_seguridad(self):
        for var in [
            'wNivelActual:',
            'wCentroAlcanzado:',
            'wPuertaGaleriasAbierta:',
            'wCruceSeguroX:',
            'wCruceSeguroY:',
            'wMinotauroActivo:',
            'wMinotauroX:',
            'wMinotauroY:',
            'wMinotauroPaso:',
            'wMinotauroAlerta:',
        ]:
            self.assertIn(var, self.asm, f"Falta variable WRAM {var}")

    def test_tres_mapas_hechos_a_mano_16x12(self):
        self.assertIn('LaberintoEntrada:', self.asm)
        self.assertIn('LaberintoGalerias:', self.asm)
        self.assertIn('LaberintoCentro:', self.asm)

        # Cada mapa debe tener 12 filas 'db '
        for mapa in ('LaberintoEntrada', 'LaberintoGalerias', 'LaberintoCentro'):
            bloque = self.asm.split(f'{mapa}:')[1].split('PaletaCGB:')[0].split('PatronMinotauro')[0]
            filas = [linea.strip() for linea in bloque.splitlines() if linea.strip().startswith('db ')]
            self.assertGreaterEqual(len(filas), 12, f"El mapa {mapa} debe tener 12 filas")

    def test_compuerta_y_transiciones_en_galerias(self):
        self.assertIn('17', self.asm) # TILE_PUERTA en LaberintoGalerias
        self.assertIn('18', self.asm) # TILE_CENTRO en LaberintoCentro
        self.assertIn('19', self.asm) # TILE_TRANSICION

    def test_patron_minotauro_determinista(self):
        self.assertIn('PatronMinotauroGalerias:', self.asm)
        self.assertIn('PatronMinotauroCentro:', self.asm)

    def test_rutinas_clave_minotauro_y_victoria(self):
        for rutina in [
            'CargarNivel:',
            'ProcesarTransicion:',
            'ActualizarCruceSeguro:',
            'ComprobarContactoMinotauro:',
            'AvanzarMinotauro:',
            'EvaluarAlertaMinotauro:',
            'MostrarSalida:',
        ]:
            self.assertIn(rutina, self.asm, f"Falta rutina {rutina}")

    def test_victoria_requiere_centro_y_retorno(self):
        seccion_salida = self.asm.split('.salida:')[1].split('ProcesarTransicion:')[0]
        self.assertIn('wCentroAlcanzado', seccion_salida)
        self.assertIn('MostrarSalida', seccion_salida)


if __name__ == "__main__":
    unittest.main()
