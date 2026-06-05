import csv
import os

csv_path = r"d:\aptitude preparation plaform\question_bank\clean_general_aptitude_dataset\clean_general_aptitude_dataset.csv"
temp_path = csv_path + ".tmp"

seen_questions = set()
unique_rows = []

print(f"Reading from {csv_path}...")

with open(csv_path, 'r', encoding='utf-8') as f:
    for line in f:
        # We manually split by ';' because standard CSV parser might struggle with the trailing commas if inconsistent
        parts = line.strip().split(';')
        if len(parts) > 0:
            question = parts[0].strip().lower()
            if question not in seen_questions and question != "":
                seen_questions.add(question)
                unique_rows.append(line.strip())

print(f"Found {len(unique_rows)} unique questions/rows.")

with open(temp_path, 'w', encoding='utf-8') as f:
    for row in unique_rows:
        f.write(row + "\n")

# Replace original file
os.replace(temp_path, csv_path)

print("Duplicates removed and file saved.")
