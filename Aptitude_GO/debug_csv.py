import csv
import sys

def clean_text(text):
    if not text: return ""
    return text.strip().strip(',').strip()

def debug_csv(file_path):
    print(f"Debugging {file_path}...")
    with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
        first_line = f.readline()
        print(f"First line raw: {first_line.strip()}")
        
    delimiter = ';' if ';' in first_line else ','
    print(f"Using delimiter: '{delimiter}'")
    
    with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
        reader = csv.DictReader(f, delimiter=delimiter, restval='')
        headers = reader.fieldnames
        print(f"Headers: {headers}")
        
        # Map headers
        header_map = {}
        for h in headers:
            clean_h = clean_text(h)
            if 'Question' in clean_h: header_map[h] = 'Question'
            elif 'Option A' in clean_h: header_map[h] = 'Option A'
            elif 'Option B' in clean_h: header_map[h] = 'Option B'
            elif 'Option C' in clean_h: header_map[h] = 'Option C'
            elif 'Option D' in clean_h: header_map[h] = 'Option D'
            elif 'Answer' in clean_h: header_map[h] = 'Answer'
            else: header_map[h] = clean_h
        
        print("Header Map:")
        for k, v in header_map.items():
            print(f"  '{k}' -> '{v}'")

        # Scan first 5 rows
        for i, row in enumerate(reader):
            if i > 5: break
            
            def get_val(target_key):
                for k, v in row.items():
                    if header_map.get(k) == target_key:
                        return v
                return None

            ans_raw = get_val('Answer')
            ans_clean = clean_text(ans_raw)
            print(f"Row {i+1}: Raw Answer='{ans_raw}' -> Clean='{ans_clean}'")
            if not ans_clean:
                print(f"  FULL ROW: {row}")

if __name__ == "__main__":
    debug_csv(r"C:\Users\ROSHAN\Desktop\data_set\clean_general_aptitude_dataset.csv")
