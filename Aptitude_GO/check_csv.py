import csv

with open('question_bank/clean_general_aptitude_dataset.csv', 'r', encoding='utf-8-sig') as f:
    reader = csv.DictReader(f)
    
    # Get headers
    headers = reader.fieldnames
    print(f"Headers: {headers}\n")
    
    # Show first 2 rows
    for i, row in enumerate(reader):
        if i >= 2:
            break
        print(f"Row {i+1}:")
        for key, val in row.items():
            print(f"  {key}: {val[:50] if val else 'None'}...")
        print()
