#!/usr/bin/env python3
"""Check Python syntax and imports without running code"""
import os
import sys
import ast
import importlib.util

# Install mock modules first
import mock_modules

# Disable environment validation
os.environ['CHECK_ENV_VARS'] = 'false'

def check_syntax(filepath):
    """Check Python file syntax"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            source = f.read()
        ast.parse(source)
        return None
    except SyntaxError as e:
        return f"Syntax error at line {e.lineno}: {e.msg}"
    except Exception as e:
        return f"Error: {str(e)}"

def check_imports(filepath):
    """Try to import the module"""
    try:
        spec = importlib.util.spec_from_file_location("testmodule", filepath)
        if spec and spec.loader:
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
        return None
    except Exception as e:
        return f"Import error: {str(e)}"

def main():
    project_root = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, project_root)

    python_files = []
    for root, dirs, files in os.walk(project_root):
        dirs[:] = [d for d in dirs if not d.startswith('.') and d != '__pycache__' and d != 'logs' and d != 'supabase']
        for file in files:
            if file.endswith('.py') and not file.startswith('.') and file not in ['check_imports.py', 'check_syntax.py', 'mock_modules.py']:
                python_files.append(os.path.join(root, file))

    errors = {}
    for filepath in sorted(python_files):
        relpath = os.path.relpath(filepath, project_root)

        # Check syntax
        syntax_error = check_syntax(filepath)
        if syntax_error:
            errors.setdefault(relpath, []).append(syntax_error)
            continue

        # Check imports
        import_error = check_imports(filepath)
        if import_error:
            errors.setdefault(relpath, []).append(import_error)

    if errors:
        print("=" * 80)
        print("ERRORS FOUND:")
        print("=" * 80)
        for filepath, file_errors in errors.items():
            print(f"\n{filepath}:")
            for error in file_errors:
                print(f"  ❌ {error}")
    else:
        print("=" * 80)
        print("✅ NO ERRORS FOUND! All files are syntactically correct.")
        print("=" * 80)

    return len(errors)

if __name__ == '__main__':
    exit_code = main()
    print(f"\nTotal files with errors: {exit_code}")
    sys.exit(exit_code)
