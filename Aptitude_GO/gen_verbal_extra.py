import csv
import os

csv_path = r"d:\aptitude preparation plaform\question_bank\verbal_ability\verbal_ability.csv"

distinct_questions = [
    # 1. Critical Reasoning (Verbal Logic)
    ["Statement: The government has decided to increase the prices of petroleum products. <br>Assumption I: The price of essential commodities will go up. <br>Assumption II: There will be a nationwide strike. <br>Which of the assumptions is implicit?", "Only Assumption I is implicit", "Only Assumption II is implicit", "Both Assumption I and II are implicit", "Neither Assumption I nor II is implicit", "A"],
    ["Statement: All students in the class are bright. Rahul is not bright. <br>Conclusion: Rahul is not a student of the class. <br>Is the conclusion valid?", "Yes, absolutely valid", "No, invalid", "May or may not be valid", "Irrelevant to the statement", "A"],
    ["Statement: 'You are hereby appointed as a programmer with a probation period of one year.' - A letter of appointment. <br>Assumption I: The performance of an individual generally is not known at the time of appointment. <br>Assumption II: Generally an individual tries to prove his worth in the probation period.", "Only I is implicit", "Only II is implicit", "Both I and II are implicit", "Neither I nor II is implicit", "C"],
    ["The price of gold has increased globally. Therefore, the sales of gold jewelry in the local market will decrease. <br>Which of the following, if true, would most severely weaken this argument?", "Local consumers buy gold primarily as a long-term investment, regardless of short-term price fluctuations.", "The global production of gold has also increased.", "Silver is becoming a popular alternative to gold.", "Local jewelers are offering discounts on making charges.", "A"],
    
    # 2. Error Spotting
    ["Spot the error in the sentence: 'The team of scientists (A) / are discussing the results (B) / of the recent experiment (C) / in the laboratory (D).'", "A", "B", "C", "D", "B"], # 'team' is singular, so it should be 'is discussing'
    ["Spot the error: 'None of the students (A) / have finished (B) / their assignments (C) / on time (D).'", "A", "B", "C", "D", "B"], # 'None' takes singular verb 'has'
    ["Spot the error: 'He is one of those writers (A) / who has won (B) / the Nobel Prize (C) / for literature (D).'", "A", "B", "C", "D", "B"], # 'who have won'
    ["Spot the error: 'Despite of the heavy rain (A) / he decided to (B) / go out for a walk (C) / in the park (D).'", "A", "B", "C", "D", "A"], # 'Despite the heavy rain' (no 'of')

    # 3. Reading Comprehension
    ["Passage: The industrial revolution brought about massive changes in societal structures. As agrarian societies transitioned to urban centers, the traditional family unit evolved. Children, once farmhands, became factory workers, leading to new labor laws. <br>What was a direct consequence of the transition to urban centers mentioned in the passage?", "An increase in agricultural productivity", "The evolution of the traditional family unit", "A decrease in the need for child labor", "The immediate abolition of factories", "B"],
    ["Passage: Marie Curie's groundbreaking research on radioactivity not only earned her two Nobel Prizes but also paved the way for modern medical treatments like radiation therapy. However, prolonged exposure to radioactive materials ultimately caused her fatal illness. <br>Which of the following describes the paradox of Marie Curie's life as presented in the passage?", "She won two Nobel Prizes but lived in poverty.", "Her discoveries cured others but caused her own death.", "She studied physics but made breakthroughs in medicine.", "She was famous globally but unknown in her home country.", "B"],
    ["Passage: E-commerce has fundamentally altered retail. Brick-and-mortar stores are forced to adopt omnichannel strategies, integrating their physical presence with online storefronts to survive the digital onslaught. <br>What does an 'omnichannel strategy' likely involve based on the passage?", "Focusing solely on online sales", "Closing all physical stores", "Combining physical and online retail presence", "Ignoring e-commerce trends", "C"],
    
    # 4. Fill in the blanks (Contextual)
    ["The politician's speech was so ______ that it managed to offend both his supporters and his opponents.", "conciliatory", "inflammatory", "diplomatic", "ambiguous", "B"],
    ["The company decided to ______ its operations in the region due to the ongoing political instability.", "expand", "curtail", "bolster", "initiate", "B"],
    
    # 5. Grammar (Modifiers/Parallelism)
    ["Choose the grammatically correct sentence.", "Running down the street, my hat blew off.", "While running down the street, my hat blew off.", "As I was running down the street, my hat blew off.", "To run down the street, my hat blew off.", "C"],
    ["Choose the sentence with correct parallelism.", "She likes to hike, swim, and riding a bicycle.", "She likes hiking, swimming, and to ride a bicycle.", "She likes to hike, to swim, and ride a bicycle.", "She likes hiking, swimming, and riding a bicycle.", "D"]
]

lines_to_append = []
for q in distinct_questions:
    cleaned = [str(x).replace(";", ",") for x in q]
    row = ";".join(cleaned) + ",,,,,,,,"
    lines_to_append.append(row)

with open(csv_path, 'a', newline='', encoding='utf-8') as f:
    for line in lines_to_append:
        f.write(line + "\n")

print(f"Appended {len(distinct_questions)} extra Verbal Ability questions for missing topics.")
