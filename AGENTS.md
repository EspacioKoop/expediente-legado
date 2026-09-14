# AGENTS.md — instrucciones para agentes

Este repositorio adopta las [Normas Platino](https://github.com/EspacioKoop/normas_platino): cooperación autónoma entre agentes, sin colisiones ni pérdida de trabajo. Autonomía no significa permiso ilimitado ni integración sin autorización.

El flujo humano sigue en [CONTRIBUTING.md](CONTRIBUTING.md), el contexto en [README.md](README.md) y las fases en [ROADMAP.md](ROADMAP.md). Si dos instrucciones se contradicen, no improvises: detén solo el alcance afectado y coordina con @eGurucharri.

## Fuentes de verdad, antes de tocar nada

| Qué | Dónde |
| --- | --- |
| Prioridad y punto de control | [Plan maestro #181](https://github.com/EspacioKoop/expediente-legado/issues/181) |
| Reservas activas | [Registro único #182](https://github.com/EspacioKoop/expediente-legado/issues/182) |
| Fases y versiones | [ROADMAP.md](ROADMAP.md) |
| Flujo de ramas y gates | [CONTRIBUTING.md](CONTRIBUTING.md) |
| Estado general | [README.md](README.md) |
| Paridad legado → Godot | [docs/paridad-expedientes.md](docs/paridad-expedientes.md) |

Lee también el issue concreto, sus comentarios, PRs relacionadas, reviews y CI. En este proyecto una decisión que evita duplicar trabajo suele estar en un comentario posterior al cuerpo original.

## Ciclo obligatorio

1. Comprueba `main`, PR abiertos, issue, comentarios, plan maestro y reservas.
2. Elige un pendiente prioritario **libre**. No abras un segundo corte si ya hay una PR activa que cubre el mismo hueco.
3. Antes de modificar archivos publica en #182:

   ```text
   CLAIM issue=#N agent=<nombre> branch=<rama> files=<rutas> goal=<objetivo>
   ```

4. Relee inmediatamente #182. Gana la reserva activa anterior por fecha de GitHub; en empate, el comentario con ID menor. Si hay solape, no edites.
5. Trabaja en rama propia desde `main` actualizado: `feature/NN-slug`, `fix/NN-slug` o `docs/NN-slug`.
6. Mantén el corte pequeño. Un paraguas como #279/#282/#283 se ejecuta por verticales, no con una reescritura total.
7. Añade regresión ejecutable cuando cambie comportamiento. La inspección textual puede complementar, no sustituir, una prueba del contrato real cuando Godot pueda ejecutarlo.
8. Pasa las pruebas canónicas y revisa el diff final.
9. Abre PR a `main` y registra en #182:

   ```text
   PR_READY issue=#N pr=#M sha=<sha> pruebas=<qué pasó> limites=<qué no cubre>
   ```

10. `PR_READY` mantiene la reserva y **no autoriza merge**. Integra solo con autorización explícita de @eGurucharri y los gates exigidos en verde.
11. Verifica el resultado remoto y publica `RELEASE`. Si pausas, deja SHA, estado y siguiente paso; el silencio no caduca la reserva.

Usa `Closes #N` solo si el PR satisface el issue entero. Para entregas parciales, `Refs #N` y explica lo que queda.

## Archivos compartidos

Reserva expresamente los archivos compartidos enumerados en #182. Entre ellos están:

- `README.md`, `AGENTS.md`, `CONTRIBUTING.md`, `ROADMAP.md`;
- `godot/datos/textos.csv`, `godot/datos/casos.json`;
- `godot/pruebas/pruebas.gd`, los módulos que invoca y `godot/pruebas/minimo.txt`;
- `scripts/verificar_godot.py`.

Una reserva de un issue no concede automáticamente todos los archivos que ese issue podría necesitar. Declara las rutas reales del corte.

## Prohibido

- push directo a `main`;
- force-push o reescritura de historia compartida;
- merge sin autorización de @eGurucharri;
- rebajar pruebas para poner verde un cambio;
- publicar tokens, contraseñas, datos personales, partidas personales o rutas privadas;
- inventar procedencia, licencias, hashes, hechos de expedientes o resultados de playtest;
- decir que algo está validado visualmente o con mando si solo pasó CI headless.

Si una herramienta escribe por error en `main`, revierte inmediatamente sin force-push, deja constancia en #182 y continúa únicamente desde una rama propia.

## Pruebas canónicas

Desde la raíz:

```bash
python3 scripts/verificar_godot.py
python3 -m unittest discover -s scripts -p 'test_*.py'
gdlint godot
gdformat --check --diff godot
```

Desde `backend/`:

```bash
mvn test
mvn checkstyle:check pmd:check spotbugs:check
npm test
```

Usa la línea de Godot declarada en `.godot-version`. La referencia final es el workflow sobre el SHA del PR, no una ejecución local anterior.

`godot/pruebas/minimo.txt` protege el mínimo de la suite principal. Reducirlo exige explicar qué comprobaciones desaparecen y por qué.

## Trampas conocidas

Estas ya han provocado fallos reales.

- **Nombres de fase**: `Jornada` usa `archivo`, `trayecto`, `casa`, `sueño`. La calle del recorrido es `trayecto`; comprobar `fase == "calle"` deja el hook muerto aunque el código visual exista.
- **Cadena `dia_*`**: muchas capacidades se integran por herencia. No escribas tests que exijan que una clase herede *directamente* de una base si el contrato solo necesita herencia transitiva.
- **`PackedVector*Array` y `const`**: Godot 4.7 no acepta todas las construcciones dinámicas de `PackedVector2Array(...)` dentro de expresiones `const`. Usa estado estático de solo lectura por API cuando corresponda.
- **GDScript lint**: una variable `static var` no es una constante; `gdlint` exige nombre de variable, no MAYÚSCULAS de constante.
- **`.uid`**: el repo versiona el `.uid` de cada guion. Si creas un `.gd`, incluye su `.uid` cuando Godot lo genere/requiera.
- **`godot/datos/textos.csv`**: el bloque `ARCHIVO_*` no debe perderse por una reordenación ingenua. Inserta sin asumir que todo el fichero está ordenado.
- **Texto visible**: interfaz y guion usan claves de traducción; no hardcodees cadenas visibles en GDScript salvo contratos deliberadamente literales, como frases que deben coincidir con el documento.
- **Partidas**: `Partida.guardar()` devuelve éxito/fallo. Compruébalo. El disco persiste estado; no lo uses como bus entre pantallas.
- **Cinemáticas**: guarda el estado antes de una cinemática saltables si el hallazgo debe persistir. Usa el reproductor/contrato común, no un ritmo paralelo.
- **Interacción**: usa acciones semánticas (`interactuar`, `cancelar`, etc.) y `PreferenciasSiga`; no hardcodees `E`, Escape o botones de mando en sistemas nuevos.
- **Audio**: `Sonido` = efectos puntuales; `Musica` = momentos dramáticos; ambiente continuo = #119. No mezcles responsabilidades para resolver un sonido concreto.
- **Sueño**: la progresión normal desde #281 es por objetivos oníricos. No reintroduzcas una salida física invisible como requisito de terminación.
- **Investigación**: combinar, anotar, examinar anexos o recompensar un puzzle no puede inventar hechos. Consume únicamente datos catalogados y conocidos por el jugador.
- **Assets**: los binarios se rigen por `.gitattributes`, Git LFS y `godot/assets/procedencia.json`. No crees un puntero LFS si no puedes subir también el objeto al almacén LFS.

## Convenciones de código

- Comentarios y nombres en español, coherentes con el código existente.
- Explica *por qué* cuando el motivo no sea obvio; evita narrar literalmente la línea siguiente.
- GDScript con tabuladores y orden de definiciones aceptado por `gdlint`.
- Java sin Mockito en las pruebas existentes: los dobles usan `java.lang.reflect.Proxy`.
- Checkstyle, PMD y SpotBugs son gates, no sugerencias.
- Prefiere contratos puros/standalone antes de tocar rutas compartidas; integra después en un segundo corte si eso reduce conflictos.

## Puntos delicados del dominio

- **Acceso a casos**: valida acceso al caso y pertenencia de entidades hijas; un `casoId` de ruta no basta.
- **Sembrado**: cada caso debe fijar todos sus campos requeridos; compara con casos hermanos.
- **Progreso**: no dupliques una fuente de verdad para pistas, historias, economía o sueño porque una UI necesite mostrarla.
- **Investigación SIGA**: la auditoría versionada está en `docs/paridad-expedientes.md`; actualízala cuando un corte cambie realmente la clasificación legado → Godot.
- **Playtest**: #271/#272/#273/#280/#281/#113 contienen gates humanos. No abras más código sobre ellos sin un fallo reproducible nuevo cuando el plan maestro los marque como validación.

## Archivos que no se versionan

- `CLAUDE.md` es local y está ignorado.
- `.env`, `target/`, `node_modules/`, `dist/.cache/`, `dist/salida/` no se comitean.
- Trabaja con `.env.example` y datos sintéticos; nunca con secretos o partidas personales.
