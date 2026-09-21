# World Mythology Overview

Compiled from multiple sources to support worldbuilding in Expediente Legado.

## Sources Integrated

1. **mythologies.wiki** - 31 traditions with interactive family trees
2. **Archetypal Context Protocol (ACP)** - 580 archetypes mapped across 8 spectral axes and 22 primordial meta-archetypes from 17 pantheons
3. **Mythos Atlas** - Pantheons of ancient civilizations with knowledge graphs
4. **Comparative mythology scholarship** - Shared motifs, diffusion vs independent invention

## Key Patterns for Game Design

### Cross-Cultural Motifs
- **Creation from Chaos/Water** - Nearly universal (Nun, Ginnungagap, chaos waters)
- **Flood Narratives** - Over 500 cultures, test case for diffusion/independence
- **Dying and Reviving God** - Osiris, Dionysus, Jesus, Quetzalcoatl parallels
- **World Tree/Axis Mundi** - Yggdrasil, Mount Meru, World Pillar, etc.
- **Trickster Figures** - Loki, Coyote, Anansi, Hermes, Maui
- **Underworld Journeys** - Orpheus, Inanna, Hero Twins, Aeneas
- **Solar Barque/Sky Father** - Ra, Odin, Zeus, Jade Emperor, Ahura Mazda

### Structural Elements
- **Pantheon Organization** - Often reflects societal structure (bureaucratic, tribal, monarchic)
- **Cosmic Order vs Chaos** - Ma'at, Rta, Dharma, Asha vs Isfet, Druj, Hundun
- **Fate/Destiny Concepts** - Moira, Wyrd, Orlog, Karma, Siyaa
- **Sacred Kingship** - Divine mandate, ritual sacrifice, dying king motifs

### Functional Archetypes (ACP Primordials)
Each deity/hero instantiates one or more primordial archetypes with weights:
- Creator/Order (Genesis/Building)
- Destroyer/Chaos (Ending/Transformation)
- Preserver (Stasis)
- Trickster (Active/Receptive, Individual)
- Hero (Active, Stasis-Transformation)
- Self (Individual-Collective)
- Great Mother/Father (Collective, Ascent/Descent)
- Divine Child (New beginnings)
- Lover (Connection)
- Warrior (Conflict, Protection)
- Magician (Transformation, Hidden knowledge)
- Sovereign (Order, Law)
- Maiden/Crone/Wise Elder (Life stages)
- Psychopomp (Transition, Death)
- Healer (Restoration)
- Rebel/Outcast (Challenge to order)
- Ancestor (Lineage, Memory)
- Monster/Twin (Shadow, Duality)

### Spectral Axes for Stat Mapping
Each archetype has coordinates 0.0-1.0 on:
1. Order (0) ↔ Chaos (1)
2. Creation (0) ↔ Destruction (1)
3. Light (0) ↔ Shadow (1)
4. Active (0) ↔ Receptive (1)
5. Individual (0) ↔ Collective (1)
6. Ascent (0) ↔ Descent (1)
7. Stasis (0) ↔ Transformation (1)
8. Voluntary (0) ↔ Fated (1)

These can map to personality traits, moral alignments, or magical affinities.

## Applying to Expediente Legado

### Character Creation
- Assign primordial weights to define core motivations
- Use spectral coordinates for trait sliders (e.g., Law/Chaos, Light/Dark)
- Relationship types define faction alliances/rivalries

### Worldbuilding
- Pantheons reflect societal values (e.g., Egyptian Ma'at = order-maintenance)
- Myths as procedural generators: flood cycles, hero trials, underworld descents
- Cultural echoes allow syncretism mechanics (e.g., Serapis-style fusion)

### Narrative Design
- Hero's Journey maps to EVOLUTION relationships
- Shadow archetypes = SHADOW or POLAR_OPPOSITE
- Transformation arcs = change along spectral axes

## File Structure
- `overview.md` - This file
- `traditions/` - Markdown files per tradition (deities, creatures, cosmology)
- `archetypes/` - JSON-LD files from ACP (optional import)
- `relationships.md` - ACP relationship types for dynamics
- `spectral-axes.md` - Detailed axis explanations

## Next Steps
1. Extract specific pantheon data from sources into `traditions/`
2. Convert ACP archetypes to usable game data (JSON)
3. Design systems that use primordial weights and spectral coordinates
4. Create mythic event templates based on shared motifs

*Last updated: $(date)*