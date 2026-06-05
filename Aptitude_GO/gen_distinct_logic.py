import csv
import os

csv_path = r"d:\aptitude preparation plaform\question_bank\logical_reasoning\logical_reasoning.csv"

distinct_questions = [
    ["CUP is to COFFEE as BOWL is to ?", "DISH", "SOUP", "SPOON", "FOOD", "B"],
    ["Oasis is to Sand as Island is to ?", "River", "Sea", "Water", "Waves", "C"],
    ["Which word does NOT belong with the others?", "Inch", "Ounce", "Centimeter", "Yard", "B"],
    ["Point out the odd one.", "Tire", "Steering wheel", "Engine", "Car", "D"],
    ["Choose the odd numeral pair/group.", "8-27", "125-216", "343-512", "1009-1331", "D"],
    ["Find the next number: 2, 6, 12, 20, 30, ?", "40", "42", "44", "48", "B"],
    ["Look at this series: 5.2, 4.8, 4.4, 4, ... What number should come next?", "3", "3.3", "3.5", "3.6", "D"],
    ["What comes next in the sequence: B2CD, BCD4, B5CD, BC6D ...", "B2C2D", "BC3D", "B2C3D", "B7CD", "B"],
    ["ZA5, Y4B, XC6, W3D, ?", "E7V", "V2E", "VE5", "VE7", "D"],
    ["If in a certain language, MADRAS is coded as NBESBT, how is BOMBAY coded in that code?", "CPNCBX", "CPNCBZ", "CPOCBZ", "CQOCBZ", "B"],
    ["If PAINT is coded as 74128 and EXCEL is coded as 93596, then how would you encode ACCEPT?", "455978", "547978", "554978", "735961", "A"],
    ["Statement: All pens are frogs. All frogs are monkeys. Conclusion: I. Some pens are monkeys. II. All monkeys are pens.", "Only conclusion I follows", "Only conclusion II follows", "Both follow", "Neither follows", "A"],
    ["Statement: No door is a dog. All the dogs are cats. Conclusion: I. No door is a cat. II. No cat is a door.", "Only I follows", "Only II follows", "Both follow", "Neither conclusion follows", "D"],
    ["Which of the following is the same as Count, List, Weight?", "Compare", "Sequence", "Number", "Measure", "D"],
    ["Arrange the words given below in a meaningful sequence: 1. Police  2. Punishment  3. Crime  4. Judge  5. Judgement", "3, 1, 2, 4, 5", "1, 2, 4, 3, 5", "5, 4, 3, 2, 1", "3, 1, 4, 5, 2", "D"],
    ["Arrange in logical order: 1. Key  2. Door  3. Lock  4. Room  5. Switch on", "5, 1, 2, 4, 3", "4, 2, 1, 5, 3", "1, 3, 2, 4, 5", "1, 2, 3, 5, 4", "C"],
    ["If 'A x B' means 'A is the father of B', 'A + B' means 'A is the daughter of B' and 'A / B' means 'A is the mother of B', then what does 'P / Q + R' mean?", "P is the brother of R", "P is the father of R", "P is the mother of R", "P is the wife of R", "D"],
    ["A boy rides his bicycle Northwards, then turns left and rides 1 km and again turns left and rides 2 km. He found himself 1 km west of his starting point. How far did he ride northward initially?", "1 km", "2 km", "3 km", "5 km", "B"],
    ["One term in the number series is wrong. Find out the wrong term: 8, 13, 21, 32, 47, 63, 83", "13", "21", "32", "47", "D"],
    ["Find the wrong number in the sequence: 52, 51, 48, 43, 34, 27, 16", "27", "34", "43", "48", "B"],
    ["What is the missing letter? C, F, I, L, O, ?", "R", "S", "T", "U", "A"],
    ["ELFA, GLHA, ILJA, _____, MLNA", "OLPA", "KLMA", "LLMA", "KLLA", "B"],
    ["CMM, EOO, GQQ, _____, KUU", "GRR", "GSS", "ISS", "ITT", "C"],
    ["If 'sky' is called 'sea', 'sea' is called 'water', 'water' is called 'air', 'air' is called 'cloud' and 'cloud' is called 'river', then what do we drink when thirsty?", "Sky", "Air", "Water", "Sea", "B"],
    ["If wall is called window, window is called door, door is called floor, floor is called roof and roof is called ventilator, what will a person stand on?", "Window", "Wall", "Floor", "Roof", "D"],
    ["SCD, TEF, UGH, ____, WKL", "CMN", "UJI", "VIJ", "IJT", "C"],
    ["If A + B > C + D and B + C > A + D, then it is definite that:", "D > B", "C > D", "A > D", "B > D", "D"],
    ["Reconstruct the sentence: P: for the  Q: of the child  R: parents are responsible  S: upbringing", "RSPQ", "RSQP", "RPSQ", "RQPS", "C"],
    ["Statements: The old order changed yielding place to new. Conclusions: I. Change is the law of nature. II. Discard old ideas because they are old.", "Only conclusion I follows", "Only conclusion II follows", "Either I or II follows", "Neither I nor II follows", "A"],
    ["Choose the word which is different from the rest.", "Rigveda", "Yajurveda", "Atharvaveda", "Ayurveda", "D"],
    ["Which word is least like the others?", "Geometry", "Algebra", "Calculus", "Thermodynamics", "D"],
    ["SQUARE is to RECTANGLE as CIRCLE is to ?", "OVAL", "ELLIPSE", "RADIAN", "SPHERE", "B"],
    ["POETRY is to RHYME as PHILOSOPHY is to ?", "IMAGERY", "MUSIC", "THEORY", "BI-VALVE", "C"],
    ["Given that: 1. A is the brother of B. 2. C is the father of A. 3. D is the brother of E. 4. E is the daughter of B. Then, the uncle of D is?", "A", "B", "C", "E", "A"],
    ["A, B, C, D and E are playing a game of cards. A says to B, 'If you give me three cards, you will have as many as E has and if I give you three cards, you will have as many as D has.' A and B together have 10 cards more than what D and E together have. If B has two cards more than what C has and the total number of cards be 133, how many cards does B have?", "22", "23", "25", "35", "C"],
    ["Two trains started at the same time, one from A to B and the other from B to A. If they arrived at B and A respectively 4 hours and 9 hours after they passed each other, the ratio of the speeds of the two trains was:", "2:1", "3:2", "4:3", "5:4", "B"],
    ["If 1=3, 2=3, 3=5, 4=4, 5=4... Then 6=?", "2", "3", "4", "5", "B"],  # Length of the word spelling the number
    ["Find the missing term: 1A, 2B, 3D, 4G, ?", "5I", "5J", "5K", "5L", "C"],
    ["Sponsor is to Funding as Patron is to ?", "Money", "Support", "Charity", "Art", "B"],
    ["In a certain code, MONKEY is written as XDJMNL. How is TIGER written in that code?", "QDFHS", "SDFHS", "SHFDQ", "UJHFS", "A"],
    ["Find the odd one out.", "Ear", "Lung", "Eye", "Heart", "D"], # Heart is singular, others exist in pairs (usually).
    ["Choose the alternative which has the same relationship: Taj Mahal : India :: Pyramids : ?", "Egypt", "Dubai", "Rome", "Athens", "A"],
    ["Select the related word/letters/number:  ASTN : ZTSM :: MSUB : ?", "LRTC", "NRTB", "NTSC", "LRTA", "A"],
    ["Identify the wrong number in the following series: 2, 5, 10, 17, 26, 37, 50, 64", "50", "26", "37", "64", "D"],
    ["Find out the missing number: 1, 3, 3, 6, 7, 9, ?, 12, 21", "10", "11", "12", "13", "D"],
    ["Look at this series: J14, L16, __, P20, R22. What number should fill the blank?", "S24", "N18", "M18", "T24", "B"],
    ["Four friends in the sixth grade were sharing a pizza. They decided that the oldest friend would get the extra piece. Randy is two months older than Greg, who is three months younger than Ned. Kent is one month older than Greg. Who should get the extra piece?", "Randy", "Greg", "Ned", "Kent", "C"],
    ["What number comes next? 100, 96, 104, 88, 120, 56, ?", "184", "148", "64", "112", "A"]
]

lines_to_append = []
for q in distinct_questions:
    # Ensure text has no rogue semicolons
    cleaned = [str(x).replace(";", ",") for x in q]
    # Format: Question;Option A;Option B;Option C;Option D;Answer,,,,,,,,
    row = ";".join(cleaned) + ",,,,,,,,"
    lines_to_append.append(row)

with open(csv_path, 'a', newline='', encoding='utf-8') as f:
    for line in lines_to_append:
        f.write(line + "\n")

print(f"Appended {len(distinct_questions)} distinct paradigm logical reasoning questions.")
