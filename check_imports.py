#!/usr/bin/env python3
"""Script to check all imports in the project"""
import os
import sys
import importlib.util

def check_file(filepath):
    """Try to compile and check a Python file"""
    errors = []
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            source = f.read()

        # Try to compile
        compile(source, filepath, 'exec')

        # Try to import (will show import errors)
        spec = importlib.util.spec_from_file_location("module", filepath)
        if spec and spec.loader:
            try:
                module = importlib.util.module_from_spec(spec)
                sys.modules['module'] = module
                spec.loader.exec_module(module)
            except Exception as e:
                errors.append(f"Import error: {e}")

    except SyntaxError as e:
        errors.append(f"Syntax error: {e}")
    except Exception as e:
        errors.append(f"Error: {e}")

    return errors

def main():
    project_root = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, project_root)

    python_files = []
    for root, dirs, files in os.walk(project_root):
        # Skip __pycache__ and other special dirs
        dirs[:] = [d for d in dirs if not d.startswith('.') and d != '__pycache__']

        for file in files:
            if file.endswith('.py') and not file.startswith('.'):
                python_files.append(os.path.join(root, file))

    all_errors = {}
    for filepath in sorted(python_files):
        relpath = os.path.relpath(filepath, project_root)
        errors = check_file(filepath)
        if errors:
            all_errors[relpath] = errors

    if all_errors:
        print("=" * 80)
        print("ERRORS FOUND:")
        print("=" * 80)
        for filepath, errors in all_errors.items():
            print(f"\n{filepath}:")
            for error in errors:
                print(f"  - {error}")
    else:
        print("No errors found!")

    return len(all_errors)

if __name__ == '__main__':
    sys.exit(main())
