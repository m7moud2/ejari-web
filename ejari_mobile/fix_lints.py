import re
import os
import subprocess

def get_lints():
    result = subprocess.run(['flutter', 'analyze'], capture_output=True, text=True)
    lines = result.stdout.split('\n') + result.stderr.split('\n')
    issues = []
    for line in lines:
        if '•' in line and 'lib/' in line:
            parts = line.split('•')
            if len(parts) >= 3:
                desc = parts[1].strip()
                loc = parts[2].strip()
                loc_parts = loc.split(':')
                if len(loc_parts) >= 3:
                    file_path = loc_parts[0].strip()
                    line_num = int(loc_parts[1].strip())
                    col_num = int(loc_parts[2].strip())
                    rule = parts[3].strip() if len(parts) > 3 else ''
                    issues.append({'file': file_path, 'line': line_num, 'desc': desc, 'rule': rule})
    return issues

def fix_lints():
    issues = get_lints()
    for issue in issues:
        file_path = issue['file']
        line_idx = issue['line'] - 1
        rule = issue['rule']
        
        if not os.path.exists(file_path):
            continue
            
        with open(file_path, 'r') as f:
            lines = f.readlines()
            
        if line_idx >= len(lines):
            continue
            
        line = lines[line_idx]
        
        if rule == 'unused_local_variable' or rule == 'unused_field':
            if 'final ' in line and '=' in line:
                # Remove final var =
                var_name = line.split('final ')[1].split('=')[0].strip()
                lines[line_idx] = line.replace(f'final {var_name} =', '')
            elif 'String ' in line or 'int ' in line or 'bool ' in line or 'List' in line or 'Map' in line:
                lines[line_idx] = '// ' + line
            elif line.strip().startswith('_') and not '=' in line:
                lines[line_idx] = '// ' + line
                
        elif rule == 'empty_catches':
            # Add a comment inside empty catch
            if 'catch' in line and '{}' in line.replace(' ', ''):
                lines[line_idx] = line.replace('{}', '{ /* ignored */ }')
                
        elif rule == 'constant_identifier_names':
            if 'COMMISSION_RENT' in line:
                lines[line_idx] = line.replace('COMMISSION_RENT', 'commissionRent')
            if 'COMMISSION_SALE' in line:
                lines[line_idx] = line.replace('COMMISSION_SALE', 'commissionSale')
                
        elif rule == 'use_build_context_synchronously':
            # Insert if (!mounted) return; before this line if it's not there
            # We must find the indentation of the current line
            indent = len(line) - len(line.lstrip())
            if '!mounted' not in lines[line_idx - 1]:
                lines.insert(line_idx, ' ' * indent + 'if (!mounted) return;\n')
                
        with open(file_path, 'w') as f:
            f.writelines(lines)

if __name__ == '__main__':
    fix_lints()
