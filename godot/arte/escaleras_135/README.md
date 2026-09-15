# Escaleras #135 — vestuario fotorealista

Capa artística original para el tránsito **planta 4 → portal** de `#135`.

## Dirección visual

Edificio institucional de finales de los 90: hormigón/yeso pintado envejecido,
terrazo, metal pintado con desconchones, luz fluorescente cálida, puertas
cortafuegos, señalética española, radiadores, cuadros eléctricos y extintores.

## Integración

- `escaleras_135_arte.tscn`: capa visual instanciada por
  `guion/escaleras_3d_app.gd`.
- `escaleras_135_arte.gd`: viste la geometría existente y genera utilería sin
  colisiones.
- `texturas/*.svg`: mapas originales de albedo, normal y roughness para pared pintada, terrazo y metal envejecido. Se rasterizan al importar en Godot y mantienen el pack completamente versionable como texto.
- `materiales/*.tres`: materiales Godot que combinan esos mapas PBR.
- `senaletica/*.svg`: placas de plantas 4/3/2/1/PB, salida e incendio.

La capa **no** crea `StaticBody3D` ni `CollisionShape3D`, por lo que no puede
reintroducir el atasco de navegación de `#562`. Tampoco toca `Jornada`, guardado,
economía ni estado del sueño.

## Sustitución futura

Las primitivas de puerta, barandilla, radiador, extintor y cuadro eléctrico son
deliberadamente baratas en polígonos. Pueden reemplazarse uno a uno por GLB sin
cambiar el contrato de la escena ni la ruta.
