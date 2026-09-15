# MYRMIDON 98

ROM original para **Game Boy / Game Boy Color** asociada a la familia de Aquiles de #438.

El objetivo no es ganar por fuerza bruta. El rival recorre un ciclo visible de guardias y parece ignorar cualquier golpe. El jugador tiene que **leer el patrón completo**, identificar la apertura y acertar el punto vulnerable en la zona baja.

## Mecánica

- **B (mantener):** observar. Hay que sostenerlo durante un ciclo completo de cuatro fases.
- **Arriba / Abajo:** mover la mira entre cabeza, torso y zona baja.
- **A:** atacar.
- **A / Start:** empezar o reiniciar tras ganar.

Cuando el ciclo ya ha sido leído aparece un ojo de confirmación. Durante la cuarta fase desaparece el escudo y se hace visible durante un instante la marca vulnerable del talón.

Un ataque solo cuenta si se cumplen a la vez las tres condiciones:

1. el patrón se ha observado completo;
2. la mira está en la zona baja;
3. el rival está en la fase abierta.

Atacar antes de tiempo, a otra altura o sin haber observado **borra la lectura**. No es rentable aporrear A hasta acertar. Tres impactos válidos completan el duelo y, después de cada uno, el ciclo se acelera.

## Lenguaje visual

La ROM usa pixel-art propio y muy contenido:

- escudo rojo móvil = guardia activa;
- mira verde = zona seleccionada;
- ojo cian = patrón comprendido;
- estrella amarilla = vulnerabilidad visible;
- marca diagonal roja = ataque rebotado;
- tres corazones/marcas = impactos válidos dentro de esta partida.

No hay flash de pantalla ni sacudida. La lectura depende de posición, ritmo y cambios de iconografía.

## Relación con #438

La ROM ensaya en pequeño la gramática del sueño de Aquiles: **presencia aparentemente invulnerable → observación deliberada → vulnerabilidad puntual → transformación/derrota**.

Este corte hace jugable la ROM, pero no conecta todavía su victoria con `semilla_onirica_aquiles`. Si se usa como contraparte de vigilia, el contrato correcto es registrar la semilla **al completar deliberadamente el duelo**, nunca al comprar, insertar o arrancar el cartucho.

## Integración y persistencia

`MYRMIDON 98` es autónoma. No guarda dinero, pistas, expedientes, puntuaciones persistentes ni progreso de `Partida`/`Jornada`. Al salir del cartucho se pierde todo su estado.

No incluye BIOS, dumps, ROMs comerciales, logotipos ni recursos externos. Código y pixel-art nacen en este repositorio bajo su licencia MIT.

## Compilar

Requiere RGBDS 1.0.x; CI usa la versión fijada por el repositorio.

```bash
make
```

Salida:

```text
build/aquiles_98.gbc
```

La cabecera es `MYRMIDON98` y la ROM declara compatibilidad dual Game Boy / Game Boy Color (`0x80`).

## Regresión

```bash
make test
```

La prueba compila la ROM y valida tamaño mínimo, cabecera CGB y varias invariantes del contrato de juego. El workflow GBC compila además el cartucho junto al resto de ROMs propias.

El test automático no sustituye un playtest visual con emulador o hardware real.
