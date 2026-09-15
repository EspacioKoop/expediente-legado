# Croc Riders 98

Tercera ROM original para **Game Boy Color** de la consola doméstica de SIGA-98.

`Croc Riders 98` es una carrera arcade pulp de cocodrilos moteros por una ruta **estilizada** entre El Cairo y Giza. No intenta reproducir una red viaria real: usa iconos visuales de Egipto como decorado reconocible de una carrera imposible de finales de los 90.

## Carrera

La pista tiene tres carriles y cuatro tramos visuales:

1. **Giza / Pirámides** — arranque entre siluetas de pirámides.
2. **Esfinge** — segundo checkpoint con la Esfinge y pirámides al fondo.
3. **Nilo / Cairo** — agua y skyline urbano como transición hacia la ciudad.
4. **Cairo Tower / meta** — tramo final con torre y bandera de llegada.

En pista aparecen dos rivales cocodrilo en motocicleta y tráfico/obstáculos diferenciados. Los rivales comparten la silueta del jugador pero usan otra paleta.

## Revisión visual tras playtest

La primera versión compilable resultaba difícil de leer y mostraba parpadeo. La revisión actual cambia el render de forma estructural:

- OAM se actualiza únicamente al comienzo de **VBlank**;
- los checkpoints reparten el decorado entre cuatro VBlank (tres filas de
  borrado y una de pintado); el HUD pendiente se refresca a continuación,
  sin detener el movimiento ni acumular todo el trabajo en un solo frame;
- la carrera usa sprites **8x16**, reduciendo cada cocodrilo de cuatro sprites a dos;
- el máximo normal queda en **9 sprites simultáneos por scanline**: jugador 2, llama 1, rivales 4 y obstáculo 2;
- desaparece el parpadeo voluntario durante la invulnerabilidad: el cocodrilo nunca se oculta tras recibir un golpe;
- las líneas de carril pasan al fondo y ya no consumen sprites;
- el cocodrilo se redibuja con hocico largo, ojos, cuerpo verde, depósito rojo y rueda/cola más claros;
- el tráfico rota entre **taxi**, **barrera de obra** y **autobús**, cada uno con silueta y paleta propias.

## Mecánica

- **Izquierda / Derecha**: cambiar de carril.
- **A**: gastar una carga de nitro.
- 3 escamas de resistencia (`SCALE`).
- 3 cargas de nitro.
- Un choque consume una escama y da invulnerabilidad breve, sin hacer desaparecer al sprite.
- Adelantar rivales suma puntuación.
- El turbo duplica temporalmente la velocidad del mundo.
- La distancia activa automáticamente los cuatro decorados/checkpoints.
- Al llegar a 90 unidades se muestra el trofeo; al perder las 3 escamas aparece la pantalla de choque.
- **A / Start** inicia y reinicia la carrera.

El HUD se mantiene deliberadamente compacto: `D` indica distancia, `S` puntuación, el icono de escama muestra resistencia y el icono de nitro las cargas restantes.

## Integración y persistencia

La ROM es autónoma. No guarda dinero, pistas, progreso de `Partida`, `Jornada`, sueños, archivo ni estadísticas de SIGA-98. Al salir del cartucho se pierde todo el estado de la carrera.

No incluye fotografías, logotipos, BIOS, ROMs comerciales ni recursos externos. Código, sprites y siluetas se crean en el propio repositorio bajo su licencia MIT.

## Relación con el Duat (#441)

`Croc Riders 98` y el sueño del Duat comparten deliberadamente un **vocabulario visual propio del proyecto**: pirámides, Nilo, silueta de cocodrilo y lectura gráfica de finales de los 90. La relación es estética y diegética, no una recompensa de campaña.

- jugar a `Croc Riders 98` **no** activa `semilla_onirica_duat`;
- terminar la carrera, puntuar o usar nitro **no** modifica la selección ni el resultado del sueño;
- el Duat puede reutilizar esos motivos como recuerdo cultural deformado, igual que una revista, un anuncio o un documental de 1998;
- el eco implementado en `godot/guion/sueno_duat_croc_riders.gd` es procedural y no copia tiles ni sprites de esta ROM;
- ambos sistemas pueden evolucionar por separado: el segundo pase jugable de la ROM (#600) no debe convertirse en dependencia de #441.

Esto conserva el contrato de #95: la consola sigue siendo ocio improductivo. La semilla activa del Duat continúa siendo una interacción de vigilia propia y explícita; Croc Riders aporta **memoria visual**, no gating.

## Compilar

Requiere RGBDS 1.0.x; CI usa la versión fijada por el repositorio.

```bash
make
```

Salida:

```text
build/croc_riders_98.gbc
```

La cabecera anuncia compatibilidad Game Boy Color (`0x80`).

## Pruebas de regresión

Con RGBDS disponible, ejecutar desde esta carpeta:

```bash
python3 -m venv /tmp/croc-riders-tests
/tmp/croc-riders-tests/bin/python -m pip install pyboy==2.6.1
make clean
make test PYTHON=/tmp/croc-riders-tests/bin/python
```

Las pruebas arrancan copias temporales de la ROM compilada en modos DMG y
CGB. Comprueban las celdas vacías de la portada y recorren los cambios de
etapa en las distancias 24, 46 y 68 con nitro y puntuación 99. Se instrumentan
las instrucciones de escritura a memoria del código máquina para verificar
que los accesos a OAM/VRAM con LCD encendida ocurren en VBlank. También se
comprueban el decorado final, el HUD y la finalización del trabajo pendiente.

PyBoy es solo una dependencia de pruebas, no se distribuye con la ROM.
El workflow GBC compila el cartucho; la regresión se ejecuta explícitamente
con `make test`. Estas comprobaciones no sustituyen el playtest visual ni
la prueba con mando o hardware físico.
