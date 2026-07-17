import os
import re

def fix_mojibake(text):
    # This regex looks for substrings that might be mojibake.
    # Mojibake for Arabic in UTF-8 -> CP1256 usually starts with ط (D8) or ظ (D9)
    # and has characters in the CP1256 range.
    # A simple approach: we find sequences of characters that CAN be encoded to cp1256 and then decoded as UTF-8.
    
    # Let's use a regex to match characters commonly found in this mojibake
    # ط, ظ, ¨, †, ‡, §, etc.
    # To be safe, we just try to fix words that contain ط or ظ followed by typical second bytes.
    # Actually, we can just write a function that splits the text by non-mojibake boundaries and tries to fix.
    
    # Let's find sequences of characters that are valid CP1256 and decode to valid UTF-8 Arabic
    def replace_match(m):
        try:
            return m.group(0).encode('cp1256').decode('utf-8')
        except:
            return m.group(0)

    # Unicode range for the mojibake characters created by decoding UTF-8 Arabic bytes as CP1256
    # D8 to DF -> ط, ظ, غ, ـ, ف, ق, ك, ل
    # 80 to BF -> various symbols like ¨, †, ‡, §, ©, «, ¬, ®, ¯, etc. in cp1256
    # Just match any sequence of characters that is 2 or more chars long, starting with these.
    
    # A simpler way: just try to encode the whole string word by word.
    words = []
    # Split by spaces and tags?
    # No, let's just use regex for sequences of weird characters
    # Usually they are word characters in CP1256 or symbols
    
    # Let's just find sequences of characters where ALL characters are in the cp1256 charset and can be decoded to utf-8.
    # It's safer to just try sliding windows or regex:
    fixed_text = ""
    i = 0
    while i < len(text):
        # try to find a valid utf-8 sequence that was decoded as cp1256
        # A valid UTF-8 sequence of 2 bytes is what we typically see.
        # So it corresponds to 2 characters in the mojibake string.
        # Let's try to grab up to 100 characters and see if it decodes.
        match_found = False
        for l in range(100, 1, -1):
            if i + l <= len(text):
                sub = text[i:i+l]
                try:
                    bytes_val = sub.encode('cp1256')
                    # check if it's strictly valid utf-8 and contains arabic
                    decoded = bytes_val.decode('utf-8')
                    # check if the decoding actually changed it and produced Arabic letters
                    if all('\u0600' <= c <= '\u06FF' or c.isspace() or c in '()[]{},.?' for c in decoded) and any('\u0600' <= c <= '\u06FF' for c in decoded):
                        fixed_text += decoded
                        i += l
                        match_found = True
                        break
                except:
                    pass
        if not match_found:
            fixed_text += text[i]
            i += 1
            
    return fixed_text

for root, _, files in os.walk('clean_copy'):
    for file in files:
        if file.endswith(('.html', '.css', '.js')):
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            new_content = fix_mojibake(content)
            if new_content != content:
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Fixed {path}")
