# Croc Riders 98

Tercera ROM original para **Game Boy Color** de la consola doméstica de SIGA-98.

`Croc Riders 98` es una carrera arcade pulp de cocodrilos moteros por una ruta **estilizada** entre El Cairo y Giza. No intenta reproducir una red viaria real: usa iconos visuales de Egipto como decorado reconocible de una carrera imposible de finales de los 90.

## Carrera

La pista tiene tres carriles y cuatro tramos visuales:

1. **Giza / Pirámides** — arranque entre siluetas de pirámides.
2. **Esfinge** — segundo checkpoint con la Esfinge y pirámides al fondo.
3. **Nilo / Cairo** — agua y skyline urbano como transición hacia la ciudad.
4. **Cairo Tower / meta** — tramo final con torre y bandera de llegada.

En pista aparecen dos rivales cocodrilo en motocicleta y tráfico/obstáculos. Los rivales comparten la silueta del jugador pero usan otra paleta, como en un cartucho portátil de la época.

## Mecánica

- **Izquierda / Derecha**: cambiar de carril.
- **A**: gastar una carga de nitro.
- 3 escamas de resistencia (`SCALE`).
- 3 cargas de nitro.
- Un choque consume una escama y da invulnerabilidad breve.
- Adelantar rivales suma puntuación.
- El turbo duplica temporalmente la velocidad del mundo.
- La distancia activa automáticamente los cuatro decorados/checkpoints.
- Al llegar a 90 unidades se muestra el trofeo; al perder las 3 escamas aparece la pantalla de choque.
- **A / Start** inicia y reinicia la carrera.

El HUD se mantiene deliberadamente compacto: `D` indica distancia, `S` puntuación, el icono de escama muestra resistencia y el icono de nitro las cargas restantes.

## Integración y persistencia

La ROM es autónoma. No guarda dinero, pistas, progreso de `Partida`, `Jornada`, sueños, archivo ni estadísticas de SIGA-98. Al salir del cartucho se pierde todo el estado de la carrera.

No incluye fotografías, logotipos, BIOS, ROMs comerciales ni recursos externos. Código, sprites y siluetas se crean en el propio repositorio bajo su licencia MIT.

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
