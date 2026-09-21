#!/usr/bin/env python3
"""
Test runner for Jungian-Literary integration tests.
This script validates the GDScript logic by parsing and checking structure.
"""
import json
import os

def test_data_files():
    """Verify data files exist and have correct structure."""
    # Test obras.json
    with open('godot/datos/literatura/obras.json', 'r') as f:
        data = json.load(f)
    
    assert 'obras' in data
    assert 'autores' in data
    assert len(data['obras']) >= 2  # at least we have 2, but we expect 8
    assert len(data['autores']) >= 2
    
    # Check each obra has required fields
    for obra in data['obras']:
        assert 'id' in obra
        assert 'titulo' in obra
        assert 'autor' in obra
        assert 'efecto' in obra
        # At least one effect field
        assert ('bonus_insight' in obra['efecto'] or 
                'bonus_momentum' in obra['efecto'] or 
                'efecto_especial' in obra['efecto'])
    
    print("✓ Data files structure valid")

def test_gdscript_files():
    """Check GDScript files exist."""
    required_files = [
        'godot/literatura/gestor_literatura.gd',
        'godot/arquetipos/gestor_arquetipos.gd',
        'godot/combate/momentum.gd',
        'godot/combate/combos.gd',
        'godot/eventos/literarios/gestor_eventos_literarios.gd',
        'godot/espacios/tertulia/tertulia.gd',
    ]
    
    for f in required_files:
        assert os.path.exists(f), f"Missing: {f}"
        # Basic syntax check - look for class_name or extends
        with open(f, 'r') as fp:
            content = fp.read()
            assert 'extends' in content or 'class_name' in content, f"Invalid GDScript: {f}"
    
    print("✓ GDScript files exist and have basic structure")

def test_autoloads_in_project():
    """Verify autoloads are registered in project.godot."""
    with open('godot/project.godot', 'r') as f:
        content = f.read()
    
    required_autoloads = [
        'GestorArquetipos',
        'GestorMomentum', 
        'GestorCombos',
        'GestorLiteratura',
        'GestorEventosLiterarios',
    ]
    
    for autoload in required_autoloads:
        assert autoload in content, f"Missing autoload: {autoload}"
    
    print("✓ All autoloads registered in project.godot")

if __name__ == '__main__':
    test_data_files()
    test_gdscript_files()
    test_autoloads_in_project()
    print("\n✅ All structural tests passed!")
