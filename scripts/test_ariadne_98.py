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

    def _mapa(self, nombre):
        bloque = self.asm.split(f"{nombre}:", 1)[1].split("\n\n", 1)[0]
        filas = [
            [int(valor) for valor in linea.strip()[3:].split(",")]
            for linea in bloque.splitlines()
            if linea.strip().startswith("db ")
        ]
        self.assertEqual(len(filas), 12, f"{nombre}: altura invalida")
        self.assertTrue(all(len(fila) == 16 for fila in filas), nombre)
        return filas

    @staticmethod
    def _conectado(mapa, origen, destino, puerta_abierta=False):
        pendientes = [origen]
        visitados = {origen}
        for x, y in pendientes:
            if (x, y) == destino:
                return True
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < 16 and 0 <= ny < 12):
                    continue
                tile = mapa[ny][nx]
                if tile == 1 or (tile == 17 and not puerta_abierta):
                    continue
                if (nx, ny) not in visitados:
                    visitados.add((nx, ny))
                    pendientes.append((nx, ny))
        return False

    def test_laberintos_tienen_rutas_reales_de_ida_y_vuelta(self):
        entrada = self._mapa("LaberintoEntrada")
        galerias = self._mapa("LaberintoGalerias")
        centro = self._mapa("LaberintoCentro")

        # Antes del fix, Entrada (1,1) y la transicion (14,1)
        # estaban en componentes inconexas: la partida no avanzaba a L2.
        self.assertEqual(entrada[1][14], 19)
        self.assertEqual(entrada[10][14], 3)
        self.assertTrue(
            self._conectado(entrada, (1, 1), (14, 1)),
            "Entrada debe permitir alcanzar Galerias sin trucos",
        )
        self.assertTrue(
            self._conectado(entrada, (14, 1), (14, 10)),
            "al regresar del Centro, la salida debe ser alcanzable",
        )

        # No depende de abrir prematuramente la compuerta del Centro.
        self.assertEqual(galerias[1][1], 19)
        self.assertEqual(galerias[10][14], 19)
        self.assertTrue(
            self._conectado(galerias, (1, 1), (14, 10)),
            "Galerias debe ser soluble con su compuerta cerrada",
        )
        self.assertTrue(
            self._conectado(galerias, (14, 10), (1, 1)),
            "Galerias permite volver a Entrada despues del Centro",
        )

        self.assertEqual(centro[1][1], 19)
        self.assertEqual(centro[10][14], 18)
        self.assertTrue(
            self._conectado(centro, (1, 1), (14, 10)),
            "el altar es alcanzable sin atravesar muros",
        )
        self.assertTrue(
            self._conectado(centro, (14, 10), (1, 1)),
            "tras tocar el altar se puede regresar al portal",
        )

    def test_contacto_no_procesa_tile_tras_retorno_a_cruce_seguro(self):
        movimiento = self.asm.split("IntentarMover:", 1)[1].split(
            "IncrementarPasos:", 1
        )[0]
        contacto = self.asm.split("ComprobarContactoMinotauro:", 1)[1].split(
            "ReiniciarMinotauro:", 1
        )[0]

        # El choque se conserva en la pila mientras se redibuja el laberinto.
        self.assertIn("call ComprobarContactoMinotauro\n    ;", movimiento)
        self.assertIn("push af\n\n    call ActualizarCruceSeguro", movimiento)
        self.assertIn("pop bc ; B=1", movimiento)
        self.assertIn("pop af ; Tile original", movimiento)
        self.assertIn("bit 0, b\n    ret nz", movimiento)
        self.assertLess(
            movimiento.index("bit 0, b"),
            movimiento.index("cp TILE_TRANSICION"),
        )
        self.assertLess(
            movimiento.index("bit 0, b"),
            movimiento.index("cp TILE_CENTRO"),
        )
        self.assertLess(
            movimiento.index("bit 0, b"),
            movimiento.index("cp TILE_SALIDA"),
        )

        # Tanto el Minotauro inactivo como los dos ejes no coincidentes
        # devuelven cero; solo la teletransportación devuelve uno.
        self.assertEqual(contacto.count("jr nz, .sin_contacto"), 2)
        self.assertIn("jr z, .sin_contacto", contacto)
        self.assertIn("call DibujarJugador\n    ld a, 1\n    ret", contacto)
        self.assertIn(".sin_contacto:\n    xor a\n    ret", contacto)

    def test_victoria_requiere_centro_y_retorno(self):
        seccion_salida = self.asm.split('.salida:')[1].split('ProcesarTransicion:')[0]
        self.assertIn('wCentroAlcanzado', seccion_salida)
        self.assertIn('MostrarSalida', seccion_salida)


if __name__ == "__main__":
    unittest.main()
