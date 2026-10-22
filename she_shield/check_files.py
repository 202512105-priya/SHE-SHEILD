import os

def check_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            if "<truncated" in content:
                return "Contains truncation artifact ('<truncated ...>')"
            
            lines = content.split('\n')
            first_line = lines[0] if lines else ""
            if first_line.startswith(" ") or first_line.startswith("\t"):
                if "import " not in first_line and "class " not in first_line:
                    return f"Starts abruptly: '{first_line.strip()}'"
            
            # For pubspec
            if filepath.endswith("pubspec.yaml"):
                if "dependencies:" not in content:
                    return "Missing 'dependencies:' section"
                    
    except Exception as e:
        return f"Error reading: {e}"
    
    return None

broken_files = []
for root, dirs, files in os.walk('.'):
    for file in files:
        if file.endswith('.dart') or file == 'pubspec.yaml':
            filepath = os.path.join(root, file)
            issue = check_file(filepath)
            if issue:
                broken_files.append((filepath, issue))

for f, issue in broken_files:
    print(f"- {f}: {issue}")

