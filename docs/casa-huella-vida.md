# Huellas de vida en casa (#96)

La casa comunica hechos de la vida laboral sin convertirlos en un panel de estado. Esta vertical consume únicamente datos que ya existen en `Jornada` y `CasaEstadoAmbiental`.

## Comida propia

`comida_propia.dias_sin_comer` se reduce a dos señales discretas:

- `comido`: aparecen alimentos modestos sobre la cocina;
- `sin_comer`: queda un envoltorio vacío.

No hay barra de hambre, porcentaje ni degradación inventada. El renderer no cobra ni modifica `dias_sin_comer`.

## Alquiler

`Jornada.alquiler` conserva ahora `ultimo_estado` junto al vencimiento real:

- `pagado`: queda un recibo con marca de pago;
- `impago`: queda un aviso más agresivo;
- sin vencimientos resueltos: no aparece ningún papel.

Los guardados antiguos completan `ultimo_estado` a vacío. `CasaEstadoAmbiental` solo infiere un resultado antiguo cuando el histórico es inequívoco.

## Vueltas

La `vuelta` persistida se materializa como una carpeta física por vida laboral ya completada. Vuelta 1 no deja carpeta; vuelta 4 deja tres. No existe contador, etiqueta ni número visible: la pila crece porque existen esas vueltas.

## Arquitectura

`CasaHuellaVida3D` es presentación pura. La monta `dia_acumulacion_casa_app.gd` junto a `CasaAcumulacion3D` y `CasaConsecuencias3D`, usando una firma conjunta para refrescar solo cuando cambian hechos reales.

La capa no toca inventario, dinero, comida, alquiler ni número de vuelta.
