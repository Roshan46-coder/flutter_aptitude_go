import os
import re
from django.core.management.base import BaseCommand
from django.utils.text import slugify
from tests.models import Category, Question, Option

class Command(BaseCommand):
    help = 'Import all company-level questions from the internal question_bank folder'

    def handle(self, *args, **options):
        base_path = os.path.join('question_bank', 'company_level_question')
        if not os.path.exists(base_path):
            # Fallback for environments where question_bank is not at root
            base_path = os.path.join(os.getcwd(), 'question_bank', 'company_level_question')
            if not os.path.exists(base_path):
                self.stderr.write(self.style.ERROR(f"Directory {base_path} not found."))
                return

        # 1. Import Coding Problems (Accenture, Cognizant, TCS, TCS - NINJA, Wipro)
        coding_companies = [
            ('Accenture', 'accenture'),
            ('Cognizant', 'cognizant'),
            ('TCS', 'tcs'),
            ('TCS - NINJA', 'tcs-ninja'),
            ('Wipro Elite NLTH', 'wipro-elite-nlth')
        ]
        
        for name, slug in coding_companies:
            self.import_coding(base_path, name, slug)

        # 2. Import TATA ELXSI (MCQs)
        self.import_tata_elxsi(base_path)

        self.stdout.write(self.style.SUCCESS('Successfully synchronized company questions!'))

    def import_coding(self, base_path, company_name, slug):
        company_path = os.path.join(base_path, company_name)
        if not os.path.exists(company_path):
            return

        category, _ = Category.objects.get_or_create(
            slug=slug,
            defaults={'name': company_name}
        )
        
        count = 0
        for q_folder in os.listdir(company_path):
            q_path = os.path.join(company_path, q_folder)
            if not os.path.isdir(q_path): continue
            
            prob_file = os.path.join(q_path, 'Problem Statement.txt')
            if os.path.exists(prob_file):
                with open(prob_file, 'r', encoding='utf-8', errors='ignore') as f:
                    text = f.read().strip()
                
                if text:
                    code_solution = ""
                    for file in os.listdir(q_path):
                        if file.endswith(('.java', '.cpp', '.c')):
                            with open(os.path.join(q_path, file), 'r', encoding='utf-8', errors='ignore') as f:
                                code_solution = f.read().strip()
                            break
                    
                    q, created = Question.objects.get_or_create(
                        category=category,
                        text=text,
                        defaults={'explanation': code_solution}
                    )
                    if created:
                        Option.objects.get_or_create(question=q, text="Code Solution Available", is_correct=True)
                        count += 1
        
        if count > 0:
            self.stdout.write(f"Imported {count} new coding questions for {company_name}")

    def import_tata_elxsi(self, base_path):
        folder_path = os.path.join(base_path, 'TATA ELXSI')
        if not os.path.exists(folder_path): return

        category, _ = Category.objects.get_or_create(
            slug='tata-elxsi',
            defaults={'name': 'TATA ELXSI', 'description': 'Analytical, Technical & Verbal questions from TATA ELXSI interviews'}
        )

        files = ['Analytical.txt', 'Technical.txt', 'Verbal.txt']
        total_created = 0
        
        for file_name in files:
            file_path = os.path.join(folder_path, file_name)
            if not os.path.exists(file_path): continue
            
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()

            # Robust split logic from previous proven script
            lines = content.split('\n')
            current_block = []
            
            for line in lines:
                stripped = line.strip()
                is_q_start = bool(re.match(r'^Q?\s*\d+\s*[\)\.]', stripped))
                
                if is_q_start:
                    if current_block:
                        if self.process_mcq_block(current_block, category):
                            total_created += 1
                    current_block = [stripped]
                elif current_block:
                    current_block.append(stripped)
            
            if current_block:
                if self.process_mcq_block(current_block, category):
                    total_created += 1
        
        if total_created > 0:
            self.stdout.write(f"Imported {total_created} new MCQs for TATA ELXSI")

    def process_mcq_block(self, block, category):
        question_lines = []
        option_lines = []
        answer_line = None
        explanation_lines = []
        in_explanation = False
        in_options = False
        
        for line in block:
            stripped = line.strip()
            if not stripped: continue
            
            # Detect Answer
            ans_match = re.match(r'^(?:Ans|Answer)\s*[:=]\s*(.+)', stripped, re.IGNORECASE)
            if ans_match:
                answer_line = ans_match.group(1).strip()
                continue
            
            # Detect Explanation
            if re.match(r'^Explanation\s*:?\s*$', stripped, re.IGNORECASE):
                in_explanation = True
                continue
            if in_explanation:
                explanation_lines.append(stripped)
                continue
            
            # Detect <correct>
            if '<correct>' in stripped:
                clean = stripped.replace('<correct>', '').strip()
                option_lines.append((clean, True))
                in_options = True
                continue
            
            # Detect options
            if re.match(r'^[\(\s]*([a-eA-E1-5])[\)\.\s]+(.+)', stripped):
                option_lines.append((stripped, False))
                in_options = True
                continue
                
            if not in_options:
                question_lines.append(stripped)
        
        q_text = ' '.join(question_lines).strip()
        if not q_text or len(q_text) < 10 or not option_lines:
            return False
            
        # Create Question
        q, created = Question.objects.get_or_create(
            category=category,
            text=q_text,
            defaults={'explanation': '\n'.join(explanation_lines).strip()}
        )
        
        if created:
            # Handle correct option mapping if we had an Answer line
            for i, (opt_raw, is_marked) in enumerate(option_lines):
                # Simple extraction
                opt_match = re.match(r'^[\(\s]*([a-eA-E1-5])[\)\.\s]+(.+)', opt_raw)
                opt_text = opt_match.group(2).strip() if opt_match else opt_raw
                
                # If marked with <correct> it's easy
                is_correct = is_marked
                
                # If we have an answer line like "Ans: a"
                if answer_line and not any(o[1] for o in option_lines):
                    ans_clean = answer_line.lower()
                    if f"({chr(97+i)})" in ans_clean or f"{chr(97+i)})" in ans_clean or f"{chr(97+i)}." in ans_clean or (len(ans_clean)==1 and ans_clean == chr(97+i)):
                        is_correct = True
                
                # Fallback: if first item and none correct, mark first
                if i == 0 and not is_correct and not any(o[1] for o in option_lines) and not answer_line:
                    is_correct = True
                    
                Option.objects.create(question=q, text=opt_text, is_correct=is_correct)
            return True
        return False
