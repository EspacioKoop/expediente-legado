# Rotación del registro de reservas

El registro activo se elige en `.github/reservas-registro.json`. El histórico
`#182` permanece en `read`; los eventos nuevos solo se escriben en `active`.
El barrido programado de `reservas.yml` consulta cada seis horas el número de
comentarios del issue activo. A los **2000** deja un aviso en Actions; a los
**2300** lo marca urgente. El bloqueo se observó al superar 2500 comentarios
en #182 (#1712). No se cambia automáticamente el registro: el corte necesita
un PR revisado para que todos los consumidores pasen juntos al nuevo número.

## Procedimiento antes de llegar al límite

1. Crear un issue nuevo para el registro, enlazar el anterior como histórico y
   anotar fecha e ID de corte. No publicar todavía eventos de coordinación allí.
2. Reservar los archivos de configuración, workflows y documentación en el
   registro aún activo. Preparar un PR que ponga el nuevo número como `active`
   y lo añada al final de `read`, conservando todos los registros anteriores.
3. Auditar los consumidores que aún mencionen el número anterior, incluidos
   `AGENTS.md`, `CONTRIBUTING.md`, los workflows, los scripts y la sala de mando.
   Actualizar las instrucciones de **escritura** al nuevo activo; mantener la
   lectura del histórico durante la transición. Revisar las reservas vigentes
   antes de fusionar para no pisar trabajo.
4. Probar `scripts/test_gestionar_reservas_rollover.py`, los tests de los
   consumidores modificados y CI del PR. Fusionar solo con autorización humana.
5. Tras el merge, publicar un `CLAIM` de prueba en el nuevo registro, releerlo
   mediante el lector canónico y publicar su `RELEASE`. Comprobar que el barrido
   programado sigue viendo las reservas anteriores al corte y que ya no escribe
   en el registro agotado.

Si la API de GitHub falla al consultar el contador, el aviso informa del fallo
sin impedir el barrido de leases. La rotación es una operación explícita, no
una consecuencia automática del contador.
