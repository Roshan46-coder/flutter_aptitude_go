import csv
import os

csv_path = r"d:\aptitude preparation plaform\question_bank\verbal_ability\verbal_ability.csv"

distinct_questions = [
    # Reading Comprehension (Short passage with inference)
    ["Read the passage and answer: The new regulations were ostensibly designed to protect the environment, but industry leaders argued they would cripple economic growth without offering tangible ecological benefits. What does 'ostensibly' most likely imply?", "Genuinely", "Supposedly", "Effectively", "Permanently", "B"],
    ["Passage: Despite his affable nature, the manager was known to be a martinet when it came to adhering to company policies. What is a 'martinet'?", "A friendly companion", "A strict disciplinarian", "A careless worker", "A generous leader", "B"],

    # Sentence Correction & Grammar
    ["Identify the correct sentence.", "She is one of the girls who has won the prize.", "She is one of the girls who have won the prize.", "She is the one of the girls who have won the prize.", "She is one of the girl who has won the prize.", "B"],
    ["Which part of the sentence has an error? 'Hardly had he left the room (A) / than the telephone began (B) / to ring loudly (C).' / No error (D)", "A", "B", "C", "D", "B"],  # 'when' instead of 'than'
    ["Select the alternative that best substitutes the underlined part: The man *to who I sold* my house was a cheat.", "to whom I sell", "to who I sell", "to whom I sold", "No improvement", "C"],
    ["Fill in the blanks: The committee ______ divided in ______ opinion.", "is, its", "are, their", "is, their", "are, its", "B"],
    ["Find the error: 'He is addicted to smoke.'", "He is", "addicted to", "smoke", "No error", "C"], # should be 'smoking'

    # Advanced Vocabulary & Synonyms/Antonyms
    ["Synonym of 'EPHEMERAL'", "Eternal", "Transient", "Pervasive", "Tangible", "B"],
    ["Antonym of 'LUCID'", "Clear", "Obscure", "Rational", "Vivid", "B"],
    ["Choose the word closest in meaning to 'MELLIFLUOUS'.", "Harsh", "Sweet-sounding", "Loud", "Chaotic", "B"],
    ["Antonym of 'OBDURATE'", "Stubborn", "Flexible", "Yielding", "Callous", "C"],
    ["Synonym of 'PERSPICACIOUS'", "Dull", "Astute", "Ignorant", "Careless", "B"],
    ["Choose the word that means 'A state of temporary disuse or suspension'.", "Abeyance", "Abundance", "Abhorrence", "Absolution", "A"],

    # Idioms & Phrases
    ["What is the meaning of the idiom: 'To beat around the bush'?", "To search thoroughly", "To avoid the main topic", "To trim a garden", "To make a loud noise", "B"],
    ["Meaning of: 'A wild goose chase'", "A successful hunt", "A foolish and hopeless pursuit", "A fast race", "A sudden realization", "B"],
    ["Meaning of: 'To bite the bullet'", "To get wounded in war", "To endure a painful situation bravely", "To eat something hard", "To be aggressive", "B"],
    ["Meaning of: 'Once in a blue moon'", "Very rarely", "Always", "Every night", "During an eclipse", "A"],
    ["Meaning of the phrase 'To throw in the towel'", "To clear up a mess", "To surrender or give in", "To go swimming", "To win quickly", "B"],

    # Analogies (Complex relationships)
    ["INDIGENT : WEALTH ::", "Contented : Happiness", "Aristocratic : Stature", "Smug : Complacency", "Emaciated : Nourishment", "D"], # Lacking relationship
    ["OSTRICH : BIRD ::", "Frog : Toad", "Whale : Mammal", "Snake : Reptile", "Lion : Cat", "B"],  # Anomaly but true classification
    ["CACOPHONY : SOUND ::", "Glare : Light", "Glimmer : Sight", "Stench : Smell", "Taste : Flavor", "A"], # Overwhelming/harsh form of sensory input
    ["ENTOMOLOGY : INSECTS ::", "Etymology : Words", "Ornithology : Fossils", "Phycology : Fungi", "Oncology : Bones", "A"],

    # Paragraph Jumbles (Logical Ordering)
    ["Arrange correctly: P: Because of this  Q: The weather was bad  R: We decided to stay home  S: And watch a movie", "QRPS", "QPRS", "PQRS", "RQPS", "B"],
    ["Arrange to form a logical paragraph: P. However, the rise of the internet changed everything. Q. In the past, news was consumed primarily via newspapers. R. Today, people get real-time updates on their phones. S. This shift has severely disrupted traditional print media.", "QPRS", "PQRS", "RQSP", "QSRP", "A"],
    ["Sequence the sentences: P: It was a cold and dreary night. Q: I heard a strange knock at the door. R: Gathering my courage, I walked towards the hallway. S: When I opened it, there was no one there.", "PQRS", "PRQS", "RQSP", "SPQR", "A"],

    # Word Substitution / One Word Equivalents
    ["A person who is indifferent to pleasure or pain is a:", "Stoic", "Cynic", "Ascetic", "Epicurean", "A"],
    ["A government by the wealthy is called:", "Democracy", "Plutocracy", "Autocracy", "Aristocracy", "B"],
    ["A speech delivered without any previous preparation:", "Extempore", "Maiden", "Elocution", "Valedictory", "A"],
    ["A disease that spreads over a large area or the whole world:", "Endemic", "Epidemic", "Pandemic", "Sporadic", "C"],

    # Prepositions and Phrasal Verbs
    ["He congratulated her ______ her success.", "for", "on", "at", "about", "B"],
    ["She takes ______ her mother.", "after", "down", "off", "up", "A"], # Resembles
    ["The meeting was called ______ due to the rain.", "out", "on", "off", "for", "C"],
    ["You must dispense ______ his services.", "of", "with", "from", "at", "B"],

    # Active / Passive Voice
    ["Change to passive: 'They are painting the house.'", "The house is painted by them.", "The house is being painted by them.", "The house has been painted.", "The house was painted.", "B"],
    ["Change to active: 'Let the door be shut.'", "Shut the door.", "You should shut the door.", "The door is to be shut.", "Please shut the door.", "A"],

    # Direct / Indirect Speech
    ["He said, 'I am reading a book.'", "He said that he is reading a book.", "He said that he was reading a book.", "He said that I am reading a book.", "He says that he was reading a book.", "B"],
    ["She said, 'Did you see that?'", "She asked if I had seen that.", "She asked if I saw that.", "She asked if you had seen this.", "She asked that did I see that.", "A"],
    
    # Cloze Test / Fill in the blanks (Contextual)
    ["The judge was ______ by the lack of evidence and dismissed the case.", "elated", "unconvinced", "enthralled", "vindicated", "B"],
    ["Despite the heavy downpour, the team remained ______ and completed the match.", "apathetic", "resolute", "fickle", "indecisive", "B"],
    ["The scientist's theory was so ______ that only a few peers could grasp it.", "lucid", "esoteric", "mundane", "rudimentary", "B"],
    ["Her ______ handling of the negotiation saved the company millions.", "clumsy", "inept", "adroit", "frivolous", "C"],

    # Odd Word Out (Thematic)
    ["Find the odd word out based on meaning.", "Abundant", "Copious", "Plentiful", "Sparse", "D"],
    ["Find the odd word out.", "Garrulous", "Loquacious", "Voluble", "Taciturn", "D"],
    ["Find the odd word out.", "Sycophant", "Flatterer", "Toady", "Rebel", "D"]
]

lines_to_append = []
for q in distinct_questions:
    cleaned = [str(x).replace(";", ",") for x in q]
    row = ";".join(cleaned) + ",,,,,,,,"
    lines_to_append.append(row)

with open(csv_path, 'a', newline='', encoding='utf-8') as f:
    for line in lines_to_append:
        f.write(line + "\n")

print(f"Appended {len(distinct_questions)} distinct Verbal Ability questions.")
