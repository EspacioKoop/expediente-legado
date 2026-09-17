# Guía para contribuciones de agentes IA al Expediente Legado

Este documento resume cómo los agentes de IA pueden contribuir al proyecto **Expediente Legado** respetando sus convenciones, flujos de trabajo y normas de cooperación (Normas Platino). Está pensado como un complemento rápido a `AGENTS.md` y `CONTRIBUTING.md`.

## Antes de tocar nada

1. **Fuentes de verdad** (consultar en orden):
   - Prioridad y punto de control: [Plan maestro #181](https://github.com/EspacioKoop/expediente-legado/issues/181)
   - Reservas activas: [Registro único #182](https://github.com/EspacioKoop/expediente-legado/issues/182)
   - Fases y versiones: [`ROADMAP.md`](ROADMAP.md)
   - Flujo de ramas y gates: [`CONTRIBUTING.md`](CONTRIBUTING.md)
   - Estado general: [`README.md`](README.md)
   - Paridad legado → Godot: [`docs/paridad-expedientes.md`](docs/paridad-expedientes.md)

2. **Leer el issue concreto**, sus comentarios, PRs relacionadas y reviews. En este proyecto, las decisiones que evitan duplicar trabajo suelen quedar en comentarios posteriores al cuerpo original.

## Ciclo obligatorio para agentes IA

1. **Comprobar `main`, PR abiertos, issue, comentarios, plan maestro y reservas.**
2. **Elegir un pendiente prioritario libre**. No abrir un segundo corte si ya hay una PR activa que cubre el mismo hueco.
3. **Publicar un CLAIM en #182** antes de modificar archivos:

   ```text
   CLAIM issue=#N agent=<nombre> branch=<rama> files=<rutas> goal=<objetivo> lease=48h
   ```

4. **Releer inmediatamente #182**. Se gana la reserva activa anterior por fecha de GitHub; en empate, el comentario con ID menor. Si hay solape, no editar.
5. **Trabajar en rama propia desde `main` actualizado**: `feature/NN-slug`, `fix/NN-slug` o `docs/NN-slug`.
6. **Mantener el corte pequeño**. Trabajar por verticales, no con una reescritura total de un paraguas grande.
7. **Añadir regresión ejecutable** cuando cambie comportamiento (test de contrato real si Godot lo permite).
8. **Pasar las pruebas canónicas** y revisar el diff final.
9. **Abrir PR a `main`** y registrar en #182:

   ```text
   PR_READY issue=#N pr=#M sha=<sha> pruebas=<qué pasó> limites=<qué no cubre>
   ```

10. `PR_READY` mantiene la reserva pero **no autoriza merge**. Integrar solo con autorización explícita de @eGurucharri y los gates exigidos en verde.
11. Si se abandona antes de abrir PR, publicar `RELEASE issue=#N motivo=abandonado`. Tras cerrar o fusionar una PR no publicar un `RELEASE` duplicado (el workflow lo hace idempotente).

## Archivos compartidos (declarar explícitamente en el CLAIM)

Los siguientes archivos son considerados compartidos y deben reservarse expresamente en #182 si se van a tocar:

- `README.md`, `AGENTS.md`, `CONTRIBUTING.md`, `ROADMAP.md`
- `godot/datos/textos.csv`, `godot/datos/casos.json`
- `godot/pruebas/pruebas.gd` y los módulos que invoca
- `godot/pruebas/minimo.txt`
- `scripts/verificar_godot.py`

Una reserva de un issue no concede automáticamente acceso a estos archivos; deben listarse en `files=<rutas>` del CLAIM.

## Prohibido (recordatorio clave)

- **Push directo a `main`**.
- **Force-push o reescritura de historia compartida**.
- **Merge sin autorización de @eGurucharri**.
- **Rebajar pruebas para poner verde un cambio**.
- **Publicar tokens, contraseñas, datos personales, partidas personales o rutas privadas**.
- **Inventar procedencia, licencias, hashes, hechos de expedientes o resultados de playtest**.
- **Decir que algo está validado visualmente o con mando si solo pasó CI headless**.

## GDScript: preflight obligatorio

Si se modifica cualquier archivo `*.gd`, ejecutar **antes de abrir o dar por listo el PR**:

```bash
bash scripts/check_gdscript.sh
```

Este script aplica `gdformat`, luego `gdlint`, suite Python y un `gdformat --check --diff` final. En CI exige que el GDScript ya llegue formateado. La versión canónica es `gdtoolkit==4.3.4`.

Reglas para evitar falsos fallos:
- No escribir tests que dependan de espacios, saltos de línea o encadenamientos exactos que `gdformat` pueda reescribir.
- Si un test Python inspecciona una llamada GDScript, usar una regex tolerante a whitespace o una prueba del comportamiento/contrato.
- Si el preflight local modifica un `.gd`, revisar y conservar ese formato antes de ejecutar el resto de validaciones o crear el commit.
- No omitir este paso porque el cambio parezca documental o pequeño: si toca `*.gd`, el preflight es obligatorio.

## Pruebas canónicas

Desde la raíz:
```bash
bash scripts/check_gdscript.sh
python3 scripts/verificar_godot.py
```

Desde `backend/` (si aplica):
```bash
mvn test
mvn checkstyle:check pmd:check spotbugs:check
npm test
```

Usar la línea de Godot declarada en `.godot-version`. La referencia final es el workflow sobre el SHA del PR, no una ejecución local anterior.

`godot/pruebas/minimo.txt` protege el mínimo de la suite principal; reducirlo exige explicar qué comprobaciones desaparecen y por qué.

## Puntos delicados del dominio (recordatorio)

- **Acceso a casos confidenciales** (`CasoController`): validar acceso al caso *y* pertenencia de la entidad hija (sospechoso/pista) a ese caso. Un `casoId` público en la ruta no debe permitir operar sobre entidades de otro caso.
- **Sembrado** (`config/DataSeeder`): cada caso debe fijar sus campos completos (título, descripción, `anioSuceso`, estado). Al añadir/editar un caso, compararlo con los hermanos para no dejar campos sin poblar.
- **Progreso** (`ProgresoService` / `ResumenJuegoService`): fuente de verdad del progreso; cargar las pistas por lotes (`pistasPorCaso` / `findByCasoIdIn`) en vez de una consulta por caso, y mantener los totales independientes del rol salvo donde el diseño lo pida.
- **Cache Thymeleaf**: desactivada en dev (`application.yml`) y activada en el build repartido (`application-standalone.yml`). No desactivarla globalmente.
- **Archivos .uid**: antes de `git pull`, eliminar cualquier archivo `.uid` huérfano en `godot/` que pueda bloquear la fusión por cambios en el árbol de trabajo.

## Trabajo paralelo con agentes

Ver `docs/TRABAJO_PARALELO_AGENTES.md` (si existe) para:
- Mapa de áreas con comando de prueba
- Puntos de colisión (archivos tocados por muchos cambios)
- Cómo dividir issues en unidades verticales y fusionables

## Investigación de recursos externos

Cuando se requiera investigar herramientas, sistemas o assets externos para incorporarlos al proyecto:
1. Confirmar lista de URLs/repositorios con el usuario.
2. Verificar cada licencia con fuente oficial (`web_extract` o `gh api repos/.../license`).
3. Clasificar por riesgo de integración: `port`, `adaptador`, `solo referencia`, `descartar`.
4. Redactar el issue con tabla de evaluación y propuestas concretas.
5. Crear el issue en el repositorio objetivo usando `gh issue create -R <OWNER>/<REPO>`.

**Pitfalls**: no afirmar licencias de memoria; no abrir tarjetas de implementación desde un issue de investigación; antes de `git pull`, eliminar archivos `.uid` huérfanos; verificar siempre el remote canónico en `AGENTS.md` o `.git/config`.

---
*Este documento es una guía resumida. Para el detalle completo, consultar `AGENTS.md`, `CONTRIBUTING.md` y la documentación vinculada.*