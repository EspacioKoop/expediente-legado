# Propuesta de integración Jungiana y Mitológica (sin ROMs)

## Resumen
Se propone introducir elementos de psicología analítica (Jung) y mitologías como expansiones nuevas bajo #931–#937, sin usar ROMs, reutilizando patrones técnicos del legado.

## Opciones Jungianas
1. **Arquetipos como habilidades desbloqueables** – Cada arquetipo (Sombra, Anima/Animus, Self, Persona) se desbloquea mediante interacción documental significativa (diario, sueño). Al activarse otorga habilidades pasivas/activas de combate.
2. **Proceso de individuación** – Árbol de progreso donde el jugador integra la Sombra; nodos requieren rituales específicos (derrotar tipo de enemigo, usar carta de Tarot, superar reto de habilidad). Completar el árbol desbloquea forma final con estadísticas mejoradas y nuevo conjunto de movimientos hack‑and‑slash.
3. **Sueños y simbolismo onírico** – Dominio sueño (#935) genera eventos oníricos que presentan conflictos internos; resultados afectan estado de vigilia (bonus/penalizaciones temporales) y desbloquean técnicas de combate.
4. **Diálogos y comunidad** – NPCs mentores jungianos cuyo diálogo otorga puntos de “insight” gastables en mejoras de habilidad de combate.

## Mitologías y religiones (sin ROMs)
- **Espacios sagrados y rituales** – Zonas templos/altares donde realizar rituales (mini‑juego de timing o combinación de cartas) para recibir bendiciones temporales.
- **Calendario de festividades** – Eventos temporales con desafíos hack‑and‑slash temáticos y recompensas exclusivas.
- **Material cultural** – Libros, artefactos y música que otorgan conocimiento de mitología, desbloqueando runas/glifos para modificar armas (efectos elementales, vida robada, etc.).

## Cómo dar más vidilla al hack‑and‑slash
- **Combos y finishers** desencadenados por acumulación de insight/favor mitológico.
- **Sistema de momentum**: medidor que aumenta mientras se evita daño; al máximo permite ataque devastador.
- **Registro de logros basado en idempotencia y procedencia**: cada acción de combate significativa genera entrada que desbloquea contenido narrativo o habilidades pasivas.
- **Separación de dominios**: todo lo nuevo vive bajo #931–#937, reutilizando solo patrones técnicos.

## Próximos pasos (tareas concretas)
1. Definir esquema JSON para arquetipos y bendiciones en `godot/datos/`.
2. Crear escenas Godot para arquetipos (ej. `godot/arquetipos/sombra.gd`).
3. Implementar sistema de momentum en `godot/combate/momentum.gd`.
4. Diseñar árbol de individuación como recurso Godot (`godot/progresion/individuacion.tres`).
5. Añadir eventos oníricos y su manejo en `godot/suenos/oniro.gd`.
6. Crear mini‑juego de ritual para espacios sagrados (`godot/rituales/ritual_gd`).
7. Implementar barra de insight y menú de habilidades.
8. Escribir pruebas unitarias para desbloqueo de arquetipos y efectos de combate.
9. Actualizar documentación en `docs/jungian_mitologia_propuesta/` con especificaciones técnicas.
