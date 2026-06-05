import csv
import os

csv_path = r"d:\aptitude preparation plaform\question_bank\logical_reasoning\logical_reasoning.csv"
temp_path = csv_path + ".tmp"

seen_questions = set()
unique_rows = []

print(f"Reading from {csv_path}...")
try:
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.reader(f, delimiter=';')
        for row in reader:
            if not row:
                continue
            question_text = row[0].strip()
            
            if question_text not in seen_questions:
                seen_questions.add(question_text)
                unique_rows.append(row)

    with open(temp_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f, delimiter=';')
        for row in unique_rows:
            writer.writerow(row)

    os.replace(temp_path, csv_path)
    print(f"Found {len(unique_rows)} unique questions/rows.")
    print("Duplicates removed and file saved.")
except Exception as e:
    print(f"Error: {e}")
