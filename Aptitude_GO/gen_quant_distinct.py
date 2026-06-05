import csv
import os
import uuid

BASE_DIR = r"d:\aptitude preparation plaform\question_bank\quantitative_aptitude"
IMAGES_DIR = os.path.join(BASE_DIR, "images")
CSV_PATH = os.path.join(BASE_DIR, "quantitative_aptitude.csv")

if not os.path.exists(IMAGES_DIR):
    os.makedirs(IMAGES_DIR)

def save_svg(svg_content):
    filename = f"vis_{uuid.uuid4().hex[:8]}.svg"
    filepath = os.path.join(IMAGES_DIR, filename)
    with open(filepath, "w", encoding='utf-8') as f:
        f.write(svg_content)
    return filename

distinct_questions = [
    # 1. Number system
    ["If a number is divisible by both 11 and 13, then it must be necessarily divisible by:", "(11+13)", "(13-11)", "(11*13)", "None of these", "C"],
    ["What least number must be added to 1056 so that the sum is completely divisible by 23?", "2", "3", "18", "21", "2"],
    ["The sum of four consecutive even numbers is 284. What would be the smallest number?", "66", "68", "72", "74", "68"],
    ["If the number 517*324 is completely divisible by 3, then the smallest whole number in place of * will be:", "0", "1", "2", "None of these", "2"],
    
    # 2. Percentages
    ["If A's salary is 20% less than B's salary, by how much percent is B's salary more than A's?", "20%", "24%", "25%", "30%", "C"],
    ["A student has to obtain 33% of the total marks to pass. He got 125 marks and failed by 40 marks. The maximum marks are:", "300", "500", "800", "1000", "B"],
    ["The population of a town increased from 1,75,000 to 2,62,500 in a decade. The average percent increase of population per year is:", "4.37%", "5%", "6%", "8.75%", "5%"],
    ["In an election between two candidates, one got 55% of the total valid votes, 20% of the votes were invalid. If the total number of votes was 7500, the number of valid votes that the other candidate got was:", "2700", "2900", "3000", "3100", "A"],

    # 3. Profit & loss
    ["Alfred buys an old scooter for Rs. 4700 and spends Rs. 800 on its repairs. If he sells the scooter for Rs. 5800, his gain percent is:", "4.5%", "5.45%", "10%", "12%", "5.45%"],
    ["The cost price of 20 articles is the same as the selling price of x articles. If the profit is 25%, then the value of x is:", "15", "16", "18", "25", "B"],
    ["A vendor bought toffees at 6 for a rupee. How many for a rupee must he sell to gain 20%?", "3", "4", "5", "6", "5"],
    ["A shopkeeper expects a gain of 22.5% on his cost price. If in a week, his sale was of Rs. 392, what was his profit?", "Rs. 18.20", "Rs. 70", "Rs. 72", "Rs. 88.25", "72"],

    # 4. Simple & compound interest
    ["A sum of money at simple interest amounts to Rs. 815 in 3 years and to Rs. 854 in 4 years. The sum is:", "Rs. 650", "Rs. 690", "Rs. 698", "Rs. 700", "C"],
    ["Mr. Thomas invested an amount of Rs. 13,900 divided in two different schemes A and B at the simple interest rate of 14% p.a. and 11% p.a. respectively. If the total amount of simple interest earned in 2 years be Rs. 3508, what was the amount invested in Scheme B?", "Rs. 6400", "Rs. 6500", "Rs. 7200", "Rs. 7500", "Rs. 6400"],
    ["If the simple interest on a sum of money for 2 years at 5% per annum is Rs. 50, what is the compound interest on the same at the same rate and for the same time?", "Rs. 51.25", "Rs. 52", "Rs. 54.25", "Rs. 60", "Rs. 51.25"],
    ["The difference between simple interest and compound interest on Rs. 1200 for one year at 10% per annum reckoned half-yearly is:", "Rs. 2.50", "Rs. 3", "Rs. 3.75", "Rs. 4", "Rs. 3"],

    # 5. Ratio & proportion
    ["A and B together have Rs. 1210. If 4/15 of A's amount is equal to 2/5 of B's amount, how much amount does B have?", "Rs. 460", "Rs. 484", "Rs. 550", "Rs. 664", "Rs. 484"],
    ["Two numbers are respectively 20% and 50% more than a third number. The ratio of the two numbers is:", "2:5", "3:5", "4:5", "6:7", "4:5"],
    ["A sum of money is to be distributed among A, B, C, D in the proportion of 5:2:4:3. If C gets Rs. 1000 more than D, what is B's share?", "Rs. 500", "Rs. 1500", "Rs. 2000", "None of these", "Rs. 2000"],
    ["Seats for Mathematics, Physics and Biology in a school are in the ratio 5:7:8. There is a proposal to increase these seats by 40%, 50% and 75% respectively. What will be the ratio of increased seats?", "2:3:4", "6:7:8", "6:8:9", "None of these", "2:3:4"],

    # 6. Averages
    ["In the first 10 overs of a cricket game, the run rate was only 3.2. What should be the run rate in the remaining 40 overs to reach the target of 282 runs?", "6.25", "6.5", "6.75", "7", "6.25"],
    ["A family consists of two grandparents, two parents and three grandchildren. The average age of the grandparents is 67 years, that of the parents is 35 years and that of the grandchildren is 6 years. What is the average age of the family?", "28 4/7 years", "31 5/7 years", "32 1/7 years", "None of these", "31 5/7 years"],
    ["The average of 20 numbers is zero. Of them, at the most, how many may be greater than zero?", "0", "1", "10", "19", "19"],
    ["The captain of a cricket team of 11 members is 26 years old and the wicket keeper is 3 years older. If the ages of these two are excluded, the average age of the remaining players is one year less than the average age of the whole team. What is the average age of the team?", "23 years", "24 years", "25 years", "None of these", "23 years"],

    # 7. Time & work
    ["A, B and C can do a piece of work in 20, 30 and 60 days respectively. In how many days can A do the work if he is assisted by B and C on every third day?", "12 days", "15 days", "16 days", "18 days", "15 days"],
    ["A alone can do a piece of work in 6 days and B alone in 8 days. A and B undertook to do it for Rs. 3200. With the help of C, they completed the work in 3 days. How much is to be paid to C?", "Rs. 375", "Rs. 400", "Rs. 600", "Rs. 800", "Rs. 400"],
    ["If 6 men and 8 boys can do a piece of work in 10 days while 26 men and 48 boys can do the same in 2 days, the time taken by 15 men and 20 boys in doing the same type of work will be:", "4 days", "5 days", "6 days", "7 days", "4 days"],

    # 8. Time, speed & distance
    ["A train running at the speed of 60 km/hr crosses a pole in 9 seconds. What is the length of the train?", "120 metres", "180 metres", "324 metres", "150 metres", "150 metres"],
    ["A train 125 m long passes a man, running at 5 km/hr in the same direction in which the train is going, in 10 seconds. The speed of the train is:", "45 km/hr", "50 km/hr", "54 km/hr", "55 km/hr", "50 km/hr"],
    ["The length of the bridge, which a train 130 metres long and travelling at 45 km/hr can cross in 30 seconds, is:", "200 m", "225 m", "245 m", "250 m", "245 m"],

    # 9. Permutation & combination
    ["From a group of 7 men and 6 women, five persons are to be selected to form a committee so that at least 3 men are there on the committee. In how many ways can it be done?", "564", "645", "735", "756", "756"],
    ["In how many different ways can the letters of the word 'LEADING' be arranged in such a way that the vowels always come together?", "360", "480", "720", "5040", "720"],
    ["Out of 7 consonants and 4 vowels, how many words of 3 consonants and 2 vowels can be formed?", "210", "1050", "25200", "21400", "25200"],

    # 10. Probability
    ["Two dice are tossed. The probability that the total score is a prime number is:", "1/6", "5/12", "1/2", "7/9", "5/12"],
    ["A card is drawn from a pack of 52 cards. The probability of getting a queen of club or a king of heart is:", "1/13", "2/13", "1/26", "1/52", "1/26"],
    ["One card is drawn at random from a pack of 52 cards. What is the probability that the card drawn is a face card (Jack, Queen and King only)?", "1/13", "3/13", "1/4", "9/52", "3/13"],

    # 11. Algebra
    ["Determine the value of x if: log2 (x - 3) + log2 (x - 2) = 1", "4", "3", "5", "6", "4"],
    ["If x + y = 5 and xy = 6, find the value of x^3 + y^3.", "35", "45", "65", "125", "35"],
    ["The roots of the quadratic equation x^2 - 5x + 6 = 0 are:", "(2,3)", "(-2,-3)", "(1,6)", "(-1,-6)", "(2,3)"]
]

# 12. Geometry & mensuration (With SVGs)
geom_svg_1 = f'''<svg width="300" height="200" xmlns="http://www.w3.org/2000/svg">
    <circle cx="150" cy="100" r="80" fill="none" stroke="black" stroke-width="2"/>
    <polygon points="150,20 80,140 220,140" fill="none" stroke="blue" stroke-width="2"/>
    <text x="145" y="15" font-family="sans-serif">A</text>
    <text x="65" y="155" font-family="sans-serif">B</text>
    <text x="225" y="155" font-family="sans-serif">C</text>
    <circle cx="150" cy="100" r="3" fill="red"/>
    <text x="155" y="95" fill="red">O</text>
    <line x1="80" y1="140" x2="150" y2="100" stroke="gray" stroke-dasharray="4"/>
    <line x1="220" y1="140" x2="150" y2="100" stroke="gray" stroke-dasharray="4"/>
    <path d="M 130 110 A 30 30 0 0 0 170 110" fill="none" stroke="black"/>
    <text x="135" y="135" font-size="12">100°</text>
</svg>'''
fname_g1 = save_svg(geom_svg_1)
text_g1 = f"In the given figure, O is the center of the circle. If angle BOC = 100°, what is the measure of angle BAC?<br><img src='images/{fname_g1}' style='max-width:100%;'>"
distinct_questions.append([text_g1, "40°", "50°", "80°", "100°", "50°"])

geom_svg_2 = f'''<svg width="250" height="200" xmlns="http://www.w3.org/2000/svg">
    <rect x="50" y="50" width="150" height="100" fill="none" stroke="black" stroke-width="2"/>
    <line x1="50" y1="50" x2="200" y2="150" stroke="blue" stroke-dasharray="5"/>
    <text x="120" y="40">15 cm</text>
    <text x="15" y="105">8 cm</text>
    <text x="120" y="95" fill="blue" transform="rotate(33, 120, 95)">d = ?</text>
</svg>'''
fname_g2 = save_svg(geom_svg_2)
text_g2 = f"Find the length of the diagonal of a rectangle whose sides are 15 cm and 8 cm.<br><img src='images/{fname_g2}' style='max-width:100%;'>"
distinct_questions.append([text_g2, "17 cm", "20 cm", "23 cm", "120 cm", "17 cm"])

geom_svg_3 = f'''<svg width="250" height="200" xmlns="http://www.w3.org/2000/svg">
    <polygon points="125,20 50,150 200,150" fill="none" stroke="black" stroke-width="2"/>
    <line x1="125" y1="20" x2="125" y2="150" stroke="red" stroke-dasharray="4"/>
    <rect x="125" y="140" width="10" height="10" fill="none" stroke="black"/>
    <text x="135" y="90" fill="red">h</text>
    <text x="120" y="170">base = 24 cm</text>
    <text x="10" y="20">Area = 120 cm²</text>
</svg>'''
fname_g3 = save_svg(geom_svg_3)
text_g3 = f"The area of a triangle is 120 cm² and its base is 24 cm. What is its height?<br><img src='images/{fname_g3}' style='max-width:100%;'>"
distinct_questions.append([text_g3, "5 cm", "10 cm", "12 cm", "20 cm", "10 cm"])

# 13. Data interpretation (tables, graphs) (With SVGs)
di_svg_1 = f'''<svg width="400" height="250" xmlns="http://www.w3.org/2000/svg">
    <text x="150" y="20" font-weight="bold">Sales Data (in 1000s)</text>
    <line x1="50" y1="200" x2="350" y2="200" stroke="black" stroke-width="2"/>
    <line x1="50" y1="200" x2="50" y2="40" stroke="black" stroke-width="2"/>
    <!-- Y axis labels -->
    <text x="25" y="200">0</text>
    <text x="20" y="150">50</text>
    <text x="15" y="100">100</text>
    <text x="15" y="50">150</text>
    <!-- Bars -->
    <rect x="70" y="120" width="40" height="80" fill="steelblue"/>
    <text x="75" y="110">80</text>
    <text x="75" y="220">2018</text>
    
    <rect x="140" y="90" width="40" height="110" fill="steelblue"/>
    <text x="140" y="80">110</text>
    <text x="145" y="220">2019</text>
    
    <rect x="210" y="40" width="40" height="160" fill="steelblue"/>
    <text x="210" y="30">160</text>
    <text x="215" y="220">2020</text>
    
    <rect x="280" y="100" width="40" height="100" fill="steelblue"/>
    <text x="280" y="90">100</text>
    <text x="285" y="220">2021</text>
</svg>'''
fname_di1 = save_svg(di_svg_1)
text_di1 = f"Study the bar chart showing sales data.<br>What is the percentage increase in sales from 2018 to 2020?<br><img src='images/{fname_di1}' style='max-width:100%;'>"
distinct_questions.append([text_di1, "50%", "80%", "100%", "200%", "100%"])

di_svg_2 = f'''<svg width="400" height="300" xmlns="http://www.w3.org/2000/svg">
    <text x="10" y="20" font-weight="bold">Percentage of Students in Different Streams (Total = 2000)</text>
    <!-- Pie Chart approximation -->
    <circle cx="200" cy="150" r="100" fill="none" stroke="black" stroke-width="2"/>
    <!-- Wedges (lines joining center to edge) -->
    <line x1="200" y1="150" x2="200" y2="50" stroke="black" stroke-width="1"/>
    <line x1="200" y1="150" x2="286.6" y2="200" stroke="black" stroke-width="1"/>
    <line x1="200" y1="150" x2="113.4" y2="200" stroke="black" stroke-width="1"/>
    <line x1="200" y1="150" x2="100" y2="150" stroke="black" stroke-width="1"/>
    
    <text x="230" y="120">Science</text>
    <text x="240" y="140">35%</text>
    
    <text x="150" y="210">Arts</text>
    <text x="155" y="225">25%</text>
    
    <text x="120" y="120">Comm</text>
    <text x="125" y="135">30%</text>
    
    <text x="190" y="90">IT 10%</text>
</svg>'''
fname_di2 = save_svg(di_svg_2)
text_di2 = f"Study the pie chart carefully.<br>How many more students are in the Science stream compared to the Arts stream?<br><img src='images/{fname_di2}' style='max-width:100%;'>"
distinct_questions.append([text_di2, "100", "200", "500", "700", "200"])


lines_to_append = []
for q in distinct_questions:
    cleaned = [str(x).replace(";", ",") for x in q]
    row = ";".join(cleaned) + ",,,,,,,,"
    lines_to_append.append(row)

with open(CSV_PATH, 'a', newline='', encoding='utf-8') as f:
    for line in lines_to_append:
        f.write(line + "\n")

print(f"Appended {len(distinct_questions)} distinct quantitative questions.")
