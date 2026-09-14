# Cómo colaborar en SIGA-98 · Expediente Legado

Este proyecto combina colaboración humana y agentes. El objetivo no es maximizar cambios simultáneos, sino avanzar sin pisar trabajo ajeno y sin afirmar más de lo que se ha probado.

Las reglas operativas completas están en [AGENTS.md](AGENTS.md). La prioridad vigente está en el [plan maestro #181](https://github.com/EspacioKoop/expediente-legado/issues/181) y las reservas en [#182](https://github.com/EspacioKoop/expediente-legado/issues/182).

## Regla de oro: nunca se trabaja directamente sobre `main`

Todo cambio entra mediante rama + Pull Request.

Ramas:

- `feature/NN-slug-corto` para funcionalidad;
- `fix/NN-slug-corto` para correcciones;
- `docs/NN-slug-corto` para documentación.

`NN` es el issue asociado. Si no existe issue, créalo antes de empezar.

Antes de modificar archivos compartidos —y, para agentes, antes de cualquier edición— publica un `CLAIM` en #182 con issue, agente, rama, archivos y objetivo. Relee las reservas después de publicarlo. Una reserva anterior activa gana; no resuelvas un solape por tu cuenta.

## Flujo de entrega

1. Actualiza contexto: `main`, issue, comentarios, PR relacionadas, #181 y #182.
2. Reserva las rutas reales del corte.
3. Trabaja en rama propia y mantén el alcance pequeño.
4. Añade pruebas de comportamiento cuando corresponda.
5. Ejecuta los gates locales.
6. Abre PR contra `main` y describe qué cubre y qué deja fuera.
7. Registra `PR_READY` en #182 con SHA, pruebas y límites.
8. Espera CI y revisión. `PR_READY` no autoriza merge.
9. La integración requiere autorización explícita de @eGurucharri.
10. Tras integrar, verifica el remoto y publica `RELEASE` en #182.

No uses `Closes #N` en una entrega parcial. Usa `Refs #N` y deja explícito qué falta.

## Mensajes de commit

En español, con prefijo y referencia al issue cuando aplique:

```text
feat: relacionar folios desde el visor (#286)
fix: usar la fase real trayecto en la calle (#277)
docs: actualizar el punto de control (#354)
```

## Gates de calidad

### Godot

Desde la raíz:

```bash
python3 scripts/verificar_godot.py
python3 -m unittest discover -s scripts -p 'test_*.py'
gdlint godot
gdformat --check --diff godot
```

Usa la versión/línea indicada en `.godot-version`. El verificador importa recursos, ejecuta suite y recorrido, arranca el juego con datos temporales y falla ante errores aunque Godot termine con código cero.

`godot/pruebas/minimo.txt` fija un mínimo de comprobaciones. No se reduce para hacer pasar una entrega.

### Backend y web legado

Desde `backend/`:

```bash
mvn test
mvn checkstyle:check pmd:check spotbugs:check
npm test
```

Los E2E de navegador requieren la aplicación levantada y se ejecutan de forma explícita, por ejemplo:

```bash
mvn test -Dtest=AutenticacionE2E,ModalesFocoE2E,MapaConexionesE2E \
    -De2e.baseUrl=http://localhost:1998
```

La CI sobre el SHA del PR es la referencia final. Una ejecución local anterior no sustituye al workflow remoto.

## Qué significa “validado”

Sé específico:

- **CI verde**: pruebas automatizadas y análisis configurados han pasado.
- **Alpha exportada**: se ha generado el artefacto correspondiente.
- **Validación visual**: alguien ha mirado el comportamiento real.
- **Mando físico**: se ha probado con hardware, no solo con eventos sintéticos.
- **Playthrough**: se ha recorrido una partida real, no una batería de funciones aisladas.

No uses una de estas expresiones para significar otra.

## Cambios de documentación

Actualiza documentación en el mismo PR cuando cambie una regla estable del repositorio:

- `README.md` para estado/arquitectura/setup;
- `AGENTS.md` para flujo de agentes, reservas y trampas;
- `CONTRIBUTING.md` para ramas, gates o revisión;
- `ROADMAP.md` para fases de fondo;
- #181 para prioridad operativa vigente;
- `docs/paridad-expedientes.md` cuando cambie la clasificación legado → Godot del núcleo SIGA.

No conviertas README/ROADMAP en una copia de la lista de issues. Los criterios específicos siguen viviendo en cada issue.

## Assets y licencias

Los binarios distribuidos deben seguir `.gitattributes`, Git LFS cuando corresponda y `godot/assets/procedencia.json`.

Cada asset externo necesita procedencia verificable: autor, fuente, licencia compatible con distribución comercial y `sha256`. “Gratis” no es una licencia.

No añadas un puntero LFS si no puedes subir también el objeto al almacén LFS. No inventes hashes ni fichas para desbloquear CI.

## Entorno de la versión web legado

```bash
cp .env.example .env
docker compose up --build
```

- App: http://localhost:1998
- Adminer: http://localhost:1999

Nunca comitees `.env`, secretos, datos personales, partidas personales ni rutas privadas.

## Convenciones de test/código

- Todo cambio de comportamiento lleva regresión proporcional al riesgo.
- Evita tests rígidos sobre detalles accidentales de arquitectura. Si una capacidad depende de herencia, prueba el contrato necesario y no una relación directa que pueda volverse transitiva.
- En Java, los dobles existentes usan `java.lang.reflect.Proxy`; no introduzcas Mockito solo para un caso aislado.
- Los `*E2E` se excluyen del `mvn test` normal por convención de nombre, no porque estén deshabilitados.
- GDScript debe pasar `gdlint` y `gdformat`; una variable estática no se nombra como constante solo por vivir a nivel de clase.

## Zonas sensibles

- **Casos confidenciales**: valida acceso al caso y pertenencia de cualquier entidad hija.
- **Progreso/persistencia**: no dupliques fuentes de verdad para facilitar una UI.
- **`textos.csv`**: no asumas orden global ni reordenes eliminando bloques especiales.
- **Fases**: usa los nombres canónicos de `Jornada`; la calle del recorrido se llama `trayecto`.
- **Entrada**: usa acciones semánticas y `PreferenciasSiga`, no teclas hardcodeadas.
- **Sueño**: progresa por objetivos; no recuperes la salida física invisible como ruta normal.
- **Investigación**: relaciones, anexos y recompensas solo pueden afirmar datos catalogados/ya conocidos.
