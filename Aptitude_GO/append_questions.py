import os

new_questions = [
"A bag contains 6 black and 8 white balls. One ball is drawn at random. What is the probability that the ball drawn is white?;3/7;4/7;1/8;3/8;B,,,,,,,,",
"What is the remainder when 17^200 is divided by 18?;1;17;16;0;A,,,,,,,,",
"If 15 men can reap a field in 35 days, then in how many days can 21 men reap the same field?;20;25;30;35;B,,,,,,,,",
"A vendor bought toffees at 6 for a rupee. How many for a rupee must he sell to gain 20%?;3;4;5;6;C,,,,,,,,",
"In what ratio must water be mixed with milk to gain 16 2/3% on selling the mixture at cost price?;1:6;6:1;2:3;4:3;A,,,,,,,,",
"The difference between simple interest and compound interest on Rs. 1200 for one year at 10% per annum reckoned half-yearly is:;Rs. 2.50;Rs. 3;Rs. 3.75;Rs. 4;B,,,,,,,,",
"The angle between the minute hand and the hour hand of a clock when the time is 8:30 is:;80º;75º;60º;105º;B,,,,,,,,",
"What was the day of the week on 28th May, 2006?;Thursday;Friday;Saturday;Sunday;D,,,,,,,,",
"A completes a work in 12 days, B in 15 days. They work together for 4 days, then A leaves. How many more days will B take to finish?;7;8;9;10;A,,,,,,,,",
"If the radius of a circle is increased by 50%, its area is increased by:;125%;100%;75%;50%;A,,,,,,,,",
"A sum of money doubles itself at compound interest in 15 years. It will become eight times itself in:;30 years;40 years;45 years;60 years;C,,,,,,,,",
"The speed of a boat in still water is 15 km/hr and the rate of current is 3 km/hr. The distance travelled downstream in 12 minutes is:;1.2 km;1.8 km;2.4 km;3.6 km;D,,,,,,,,",
"Two numbers are 20% and 50% more than a third number respectively. The ratio of the two numbers is:;2:5;3:5;4:5;6:7;C,,,,,,,,",
"The average of first 50 odd natural numbers is:;50;51;52;49;A,,,,,,,,",
"A fruit seller had some apples. He sells 40% apples and still has 420 apples. Originally, he had:;588 apples;600 apples;672 apples;700 apples;D,,,,,,,,",
"Which of the following is not a leap year?;700;800;1200;2000;A,,,,,,,,",
"Look at this series: 2, 1, (1/2), (1/4), ... What number should come next?;(1/3);(1/8);(2/8);(1/16);B,,,,,,,,",
"SCD, TEF, UGH, ____, WKL;CMN;UJI;VIJ;IJT;C,,,,,,,,",
"Odometer is to mileage as compass is to:;speed;hiking;needle;direction;D,,,,,,,,",
"Pointing to a photograph of a boy Suresh said, 'He is the son of the only son of my mother.' How is Suresh related to that boy?;Brother;Uncle;Cousin;Father;D,,,,,,,,",
"If A + B means A is the brother of B; A x B means A is the husband of B; A - B means A is the mother of B and A % B means A is the father of B, which of the following relations shows that Q is the grandmother of T?;Q - P + R % T;Q x P + R - T;Q - P % R + T;None of these;A,,,,,,,,",
"Choose the word which is different from the rest.;Curd;Butter;Oil;Cheese;C,,,,,,,,",
"In a certain code language, '134' means 'good and tasty'; '478' means 'see good pictures' and '729' means 'pictures are faint'. Which of the following digits stands for 'see'?;9;2;1;8;D,,,,,,,,",
"If Z = 52 and ACT = 48, then BAT will be equal to:;39;41;44;46;D,,,,,,,,",
"Find the odd one out: 3, 5, 11, 14, 17, 21;14;11;21;3;A,,,,,,,,",
"A man covers half of his journey at 6 km/h and the remaining half at 3 km/h. His average speed is:;4 km/h;4.5 km/h;5 km/h;3 km/h;A,,,,,,,,",
"If a pipe can fill a tank in 10 hours and a leak can empty it in 15 hours, how long will it take to fill the tank if both are open?;20 hours;25 hours;30 hours;35 hours;C,,,,,,,,",
"The sum of the digits of a two-digit number is 15 and the difference between the digits is 3. What is the two-digit number?;69;96;Cannot be determined;None of these;C,,,,,,,,",
"A starts business with Rs. 3500 and after 5 months, B joins with A as his partner. After a year, the profit is divided in the ratio 2 : 3. What is B's contribution in the capital?;Rs. 7500;Rs. 8000;Rs. 8500;Rs. 9000;D,,,,,,,,",
"What is the smallest prime number?;0;1;2;3;C,,,,,,,,",
"How many terms are there in the G.P. 3, 6, 12, 24, ..., 384?;8;9;10;11;A,,,,,,,,",
"An observer 2 m tall is 10 * sqrt(3) m away from a tower. The angle of elevation from his eye to the top of the tower is 30 degrees. The height of the tower is:;12 m;14 m;10 m;20 m;A,,,,,,,,",
"Insert the missing number: 16, 33, 65, 131, 261, (...);523;521;613;721;A,,,,,,,,",
"Elated is to despondent as enlightened is to:;aware;ignorant;miserable;tolerant;B,,,,,,,,",
"Which word does NOT belong with the others?;parsley;basil;dill;mayonnaise;D,,,,,,,,",
"Find the odd man out: 396, 462, 572, 427, 671, 264;396;427;671;264;B,,,,,,,,",
"A man goes to his office from his house at a speed of 3 km/hr and returns at a speed of 2 km/hr. If he takes 5 hours in going and coming, the distance between his house and office is:;3 km;4 km;5 km;6 km;D,,,,,,,,",
"What least number must be added to 1056 so that the sum is completely divisible by 23?;2;3;18;21;B,,,,,,,,",
"If the length of a rectangle is halved and its breadth is tripled, what is the percentage change in its area?;25% increase;50% increase;50% decrease;75% decrease;B,,,,,,,,",
"If 5 men or 9 women can do a piece of work in 19 days, then in how many days will 3 men and 6 women do the same work?;10;12;15;18;C,,,,,,,,",
"A mixture of 150 liters of wine and water contains 20% water. How much more water should be added so that water becomes 25% of the new mixture?;10 liters;15 liters;20 liters;25 liters;A,,,,,,,,",
"Find the simple interest on Rs. 68,000 at 16 2/3 % per annum for 9 months.;Rs. 8500;Rs. 9000;Rs. 9500;Rs. 10000;A,,,,,,,,",
"A sum of money placed at compound interest doubles itself in 5 years. It will amount to eight times itself at the same rate of interest in:;10 years;15 years;20 years;25 years;B,,,,,,,,",
"How many times are the hands of a clock at a right angle in a day?;22;24;44;48;C,,,,,,,,",
"On what dates of April 2001 did Wednesday fall?;1st 8th 15th 22nd 29th;2nd 9th 16th 23rd 30th;3rd 10th 17th 24th;4th 11th 18th 25th;D,,,,,,,,",
"Out of 7 consonants and 4 vowels, how many words of 3 consonants and 2 vowels can be formed?;210;1050;25200;21400;C,,,,,,,,",
"What is the probability of getting a sum 9 from two throws of a dice?;1/6;1/8;1/9;1/12;C,,,,,,,,",
"The true discount on a bill due 9 months hence at 16% per annum is Rs. 189. The amount of the bill is:;Rs. 1389;Rs. 1764;Rs. 1575;Rs. 2268;B,,,,,,,,",
"Which of the following numbers is completely divisible by 99?;3572404;135792;913464;114345;D,,,,,,,,",
"Find the greatest number that will divide 43, 91 and 183 so as to leave the same remainder in each case.;4;7;9;13;A,,,,,,,,",
"What is the value of 100 + 50 * 2?;200;300;250;150;A,,,,,,,,",
"In a certain code, COMPUTER is written as RFUVQNPC. How is MEDICINE written in the same code?;MFEDJJOE;EOJDEJFM;MFEJDJOE;EOJDJEFM;D,,,,,,,,",
"Three numbers are in the ratio 1:2:3 and their HCF is 12. The numbers are:;12 24 36;11 22 33;12 24 32;5 10 15;A,,,,,,,,",
"A takes twice as much time as B or thrice as much time as C to finish a piece of work. Working together, they can finish the work in 2 days. B can do the work alone in:;4 days;6 days;8 days;12 days;B,,,,,,,,",
"A train 125 m long passes a man, running at 5 km/hr in the same direction in which the train is going, in 10 seconds. The speed of the train is:;45 km/hr;50 km/hr;54 km/hr;55 km/hr;B,,,,,,,,",
"A trader mixes 26 kg of rice at Rs. 20 per kg with 30 kg of rice of other variety at Rs. 36 per kg and sells the mixture at Rs. 30 per kg. His profit percent is:;No profit no loss;5%;8%;10%;5%;B,,,,,,,,",
"If the true discount on sum due 2 years hence at 14% per annum be Rs. 168, the sum due is:;Rs. 768;Rs. 968;Rs. 1960;Rs. 2400;A,,,,,,,,",
"Pipe A can fill a tank in 5 hours, pipe B in 10 hours and pipe C in 30 hours. If all the pipes are open, in how many hours will the tank be filled?;2;2.5;3;3.5;C,,,,,,,,",
"Find the odd one out: 8, 27, 64, 100, 125, 216, 343;27;100;125;343;B,,,,,,,,",
"A boat can travel with a speed of 13 km/hr in still water. If the speed of the stream is 4 km/hr, find the time taken by the boat to go 68 km downstream.;2 hours;3 hours;4 hours;5 hours;C,,,,,,,,"
]

csv_path = r"d:\aptitude preparation plaform\question_bank\clean_general_aptitude_dataset\clean_general_aptitude_dataset.csv"

# Make sure it ends with a newline before appending
try:
    with open(csv_path, "r", encoding="utf-8") as f:
        content = f.read()
        needs_newline = not content.endswith('\n')
except Exception as e:
    needs_newline = False
    print("Error reading:", e)

with open(csv_path, "a", encoding="utf-8") as f:
    if needs_newline:
        f.write("\n")
    for q in new_questions:
        f.write(q + "\n")

print(f"Successfully appended {len(new_questions)} questions to the dataset.")
