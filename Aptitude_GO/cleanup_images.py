import os
import hashlib

csv_path = r"d:\aptitude preparation plaform\question_bank\logical_reasoning\logical_reasoning.csv"
images_dir = r"d:\aptitude preparation plaform\question_bank\logical_reasoning\images"

# 1. Hash all images and find duplicates
hash_to_primary = {}
file_to_primary = {}

print("Hashing images...")
for filename in os.listdir(images_dir):
    if not filename.endswith('.svg'): continue
    filepath = os.path.join(images_dir, filename)
    with open(filepath, 'rb') as f:
        content = f.read()
    h = hashlib.md5(content).hexdigest()
    
    if h not in hash_to_primary:
        hash_to_primary[h] = filename
    
    file_to_primary[filename] = hash_to_primary[h]

# 2. Update CSV to replace duplicate image references with primary ones
print("Updating CSV references...")
with open(csv_path, 'r', encoding='utf-8') as f:
    csv_content = f.read()

for orig, primary in file_to_primary.items():
    if orig != primary:
        csv_content = csv_content.replace(orig, primary)
        
with open(csv_path, 'w', encoding='utf-8') as f:
    f.write(csv_content)

# 3. Delete redundant image files
print("Deleting redundant image files...")
deleted = 0
for orig, primary in file_to_primary.items():
    if orig != primary:
        filepath = os.path.join(images_dir, orig)
        if os.path.exists(filepath):
            try:
                os.remove(filepath)
                deleted += 1
            except Exception as e:
                print(f"Failed to delete {orig}: {e}")

print(f"Deleted {deleted} redundant image files. CSV updated to point to primary uniqueness.")
