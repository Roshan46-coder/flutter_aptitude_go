import json
data = json.load(open(r'D:\college\5th sem first project\aptitude_go_flutter\assets\question_bank.json', encoding='utf-8'))
f = open(r'D:\college\5th sem first project\image_check_output.txt', 'w', encoding='utf-8')
found = 0
for cat, qs in data.items():
    for q in qs:
        t = q.get('text', '').lower()
        if any(x in t for x in ['svg', '.png', '.jpg', '.gif', '<img', 'figure', 'diagram', 'image']):
            f.write(f'Category: {cat}, Question ID: {q["id"]}\n')
            f.write(f'Text: {q["text"][:300]}\n\n')
            found += 1
            if found >= 20:
                break
    if found >= 20:
        break
f.write(f'\nTotal found with image refs: {found}\n')
f.close()
print(f'Found {found} questions with image references. Check image_check_output.txt')
