import os
import re

directory = '/Users/mahmoudabdelkawy/ejari-web1/ejari_mobile/lib/screens'
for filename in os.listdir(directory):
    if not filename.endswith('.dart'):
        continue
    filepath = os.path.join(directory, filename)
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # We want to find _buildDetailRow and modify the second Text to be wrapped in Expanded
    if '_buildDetailRow(String label, String' in content:
        # A simple replacement if it matches the standard pattern
        new_content = re.sub(
            r'(Widget _buildDetailRow.*?\s+children: \[\s+Text\([\s\S]*?\),\s+)(Text\([\s\S]*?\),)(\s+\])',
            r'\1Expanded(child: \2),\3',
            content
        )
        if new_content != content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f'Fixed {filename}')
