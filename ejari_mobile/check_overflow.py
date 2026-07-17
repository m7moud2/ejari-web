import os
import re

directory = '/Users/mahmoudabdelkawy/ejari-web1/ejari_mobile/lib/screens'
for filename in os.listdir(directory):
    if not filename.endswith('.dart'):
        continue
    filepath = os.path.join(directory, filename)
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Very naive approach: Just find instances of Row( and then see if there's Expanded/Flexible inside.
    # It's better to look for common overflow patterns manually or just do a quick heuristic.
    # Actually, a common overflow is when Text has no overflow: TextOverflow.ellipsis
    
    lines = content.split('\n')
    for i, line in enumerate(lines):
        if 'Text(' in line and ('\'' not in line or '${' in line or ']' in line) and 'overflow:' not in line and 'Expanded(' not in lines[max(0, i-2):i+1] and 'Flexible(' not in lines[max(0, i-2):i+1]:
            # Print potentially problematic dynamic texts without overflow handling
            pass
