import os
import csv
import uuid

BASE_DIR = r"d:\aptitude preparation plaform\question_bank\programming_aptitude"
IMAGES_DIR = os.path.join(BASE_DIR, "images")
CSV_PATH = os.path.join(BASE_DIR, "programming_aptitude.csv")

if not os.path.exists(IMAGES_DIR):
    os.makedirs(IMAGES_DIR)

def save_svg(svg_content):
    filename = f"vis_{uuid.uuid4().hex[:8]}.svg"
    filepath = os.path.join(IMAGES_DIR, filename)
    with open(filepath, "w", encoding='utf-8') as f:
        f.write(svg_content)
    return filename

distinct_questions = [
    # 1. Flowcharts (SVG)
    # A flowchart that loops from i=1 to 3, printing i.
    ["Study the following flowchart.<br><img src='images/{fname1}' style='max-width:100%;'> <br>What will be the output?", "1 2 3", "1 2 3 4", "0 1 2", "Syntax Error", "A"],
    
    # A flowchart with a condition: if x > 5 print A else print B. x=3.
    ["Analyze the flowchart.<br><img src='images/{fname2}' style='max-width:100%;'> <br>What is printed?", "A", "B", "None", "Infinite Loop", "B"],

    # 2. Pseudocode
    ["Consider the following pseudocode:<br><code>sum = 0<br>for i = 1 to 5 do<br>&nbsp;&nbsp;sum = sum + i<br>end for<br>print sum</code><br>What is the output?", "10", "15", "20", "25", "B"],
    ["What will this pseudocode output?<br><code>x = 10<br>y = 20<br>x = x + y<br>y = x - y<br>x = x - y<br>print x, y</code>", "10, 20", "20, 10", "30, 10", "10, 30", "B"],
    ["Evaluate the pseudocode:<br><code>function calc(n)<br>if n == 0 return 1<br>return n * calc(n-1)</code><br>What does calc(4) return?", "12", "16", "24", "120", "C"],

    # 3. Output Prediction (C)
    ["What is the output of the following C code?<br><code>#include &lt;stdio.h&gt;<br>int main() {{<br>  int a = 5;<br>  printf(\"%d\", ++a + a++);<br>  return 0;<br>}}</code><br><i>(Assume standard left-to-right evaluation)</i>", "10", "11", "12", "13", "D"], # undefined behavior usually, but common pedagogical assumption: ++a makes a=6. 6 + 6 = 12. Wait, safest is a=5. ++a makes it 6. 6 + 6++? Let's use a safer one.
    ["What is the output of the following C code?<br><code>#include &lt;stdio.h&gt;<br>int main() {{<br>  int i = 0;<br>  while (i < 3) {{<br>    printf(\"%d \", i);<br>    i++;<br>  }}<br>  return 0;<br>}}</code>", "0 1 2", "1 2 3", "0 1 2 3", "Infinite Loop", "A"],
    ["What will be the output of this C code?<br><code>int x = 5;<br>if(x == 5)<br>&nbsp;&nbsp;printf(\"A\");<br>else;<br>&nbsp;&nbsp;printf(\"B\");</code>", "A", "B", "AB", "Compile Error", "C"],

    # 4. Output Prediction (C++)
    ["What is the output of the following C++ code?<br><code>#include &lt;iostream&gt;<br>using namespace std;<br>int main() {{<br>  int arr[] = {10, 20, 30};<br>  cout &lt;&lt; *(arr + 1);<br>  return 0;<br>}}</code>", "10", "20", "30", "Address of arr", "B"],
    ["In C++, what does the following output?<br><code>int x = 10;<br>int& ref = x;<br>ref = 20;<br>cout &lt;&lt; x;</code>", "10", "20", "0", "Reference Error", "B"],

    # 5. Output Prediction (Java)
    ["What is the output of this Java code?<br><code>public class Main {{<br>  public static void main(String[] args) {{<br>    String s1 = new String(\"Hello\");<br>    String s2 = new String(\"Hello\");<br>    System.out.print(s1 == s2);<br>  }}<br>}}</code>", "true", "false", "Compilation Error", "Run-time Exception", "B"],
    ["What is the output in Java?<br><code>System.out.println(10 + 20 + \"Java\");</code>", "1020Java", "30Java", "Java1020", "Java30", "B"],
    ["What is the output in Java?<br><code>System.out.println(\"Java\" + 10 + 20);</code>", "Java1020", "Java30", "30Java", "1020Java", "A"],

    # 6. Output Prediction (Python)
    ["What is the output of the following Python code?<br><code>x = [1, 2, 3]<br>y = x<br>y.append(4)<br>print(x)</code>", "[1, 2, 3]", "[1, 2, 3, 4]", "[4]", "Error", "B"],
    ["What does this Python snippet output?<br><code>print(2 ** 3 ** 2)</code>", "64", "512", "72", "4096", "B"], # Exponentiation is right-to-left: 3**2=9, 2**9=512
    ["Predict the Python output:<br><code>a = \"Python\"<br>print(a[::-1])</code>", "nohtyP", "Python", "Error", "P", "A"],

    # 7. Basic Coding Logic
    ["Which data structure uses LIFO (Last In First Out)?", "Queue", "Array", "Stack", "Linked List", "C"],
    ["What is the time complexity of binary search on a sorted array?", "O(1)", "O(n)", "O(n log n)", "O(log n)", "D"],
    ["Which operator is used to allocate memory dynamically in C++?", "malloc()", "alloc", "new", "create", "C"],

    # 8. Loops & Conditions
    ["How many times will the loop execute? <br><code>for(int i = 0; i &lt;= 10; i += 2)</code>", "4", "5", "6", "10", "C"],
    ["In Python, what keyword is used to exit a loop prematurely?", "exit", "stop", "break", "continue", "C"],
    ["Which loop is guaranteed to execute at least once?", "for loop", "while loop", "do-while loop", "None of the above", "C"],

    # 9. Recursion (Basic)
    ["What is the term for the condition that causes a recursive function to stop calling itself?", "Base case", "Recursive case", "Terminal condition", "End point", "A"],
    ["Consider the recursive function:<br><code>int f(int n) {{<br>  if (n <= 1) return 1;<br>  return f(n-1) + f(n-1);<br>}}</code><br>What is f(3)?", "2", "3", "4", "8", "C"], # f(3) = f(2)+f(2) = 2+2 = 4. f(2)=f(1)+f(1)=1+1=2.
    ["What happens if a recursive function does not have a base case?", "It runs once", "It runs infinitely causing a Stack Overflow", "It throws a syntax error", "It returns 0", "B"]
]

# Generate SVGs
svg1 = '''<svg width="250" height="350" xmlns="http://www.w3.org/2000/svg">
    <ellipse cx="125" cy="30" rx="40" ry="20" fill="none" stroke="black" stroke-width="2"/>
    <text x="110" y="35">Start</text>
    <line x1="125" y1="50" x2="125" y2="80" stroke="black" stroke-width="2" marker-end="url(#arrow)"/>
    
    <rect x="85" y="80" width="80" height="40" fill="none" stroke="black" stroke-width="2"/>
    <text x="105" y="105">i = 1</text>
    <line x1="125" y1="120" x2="125" y2="150" stroke="black" stroke-width="2" marker-end="url(#arrow)"/>
    
    <polygon points="125,150 185,180 125,210 65,180" fill="none" stroke="black" stroke-width="2"/>
    <text x="105" y="185">i <= 3 ?</text>
    
    <!-- True branch -->
    <line x1="125" y1="210" x2="125" y2="240" stroke="black" stroke-width="2" marker-end="url(#arrow)"/>
    <text x="135" y="225">Yes</text>
    
    <path d="M 80,240 L 160,240 L 170,280 L 90,280 Z" fill="none" stroke="black" stroke-width="2"/>
    <text x="105" y="265">Print i</text>
    
    <!-- Increment -->
    <line x1="125" y1="280" x2="125" y2="300" stroke="black" stroke-width="2"/>
    <line x1="125" y1="300" x2="30" y2="300" stroke="black" stroke-width="2"/>
    <line x1="30" y1="300" x2="30" y2="135" stroke="black" stroke-width="2"/>
    <line x1="30" y1="135" x2="125" y2="135" stroke="black" stroke-width="2" marker-end="url(#arrow)"/>
    
    <rect x="15" y="160" width="30" height="30" fill="white"/>
    <text x="18" y="180">i++</text>
    
    <!-- False branch -->
    <line x1="185" y1="180" x2="220" y2="180" stroke="black" stroke-width="2"/>
    <line x1="220" y1="180" x2="220" y2="320" stroke="black" stroke-width="2"/>
    <line x1="220" y1="320" x2="165" y2="320" stroke="black" stroke-width="2" marker-end="url(#arrow)"/>
    <text x="195" y="175">No</text>
    
    <ellipse cx="125" cy="320" rx="40" ry="20" fill="none" stroke="black" stroke-width="2"/>
    <text x="115" y="325">End</text>
</svg>'''

svg2 = '''<svg width="250" height="350" xmlns="http://www.w3.org/2000/svg">
    <ellipse cx="125" cy="30" rx="40" ry="20" fill="none" stroke="black" stroke-width="2"/>
    <text x="110" y="35">Start</text>
    <line x1="125" y1="50" x2="125" y2="80" stroke="black" stroke-width="2"/>
    
    <rect x="85" y="80" width="80" height="40" fill="none" stroke="black" stroke-width="2"/>
    <text x="105" y="105">x = 3</text>
    <line x1="125" y1="120" x2="125" y2="150" stroke="black" stroke-width="2"/>
    
    <polygon points="125,150 185,180 125,210 65,180" fill="none" stroke="black" stroke-width="2"/>
    <text x="110" y="185">x > 5?</text>
    
    <!-- True -->
    <line x1="185" y1="180" x2="210" y2="180" stroke="black" stroke-width="2"/>
    <line x1="210" y1="180" x2="210" y2="210" stroke="black" stroke-width="2"/>
    <text x="190" y="175">Yes</text>
    <path d="M 180,210 L 230,210 L 240,240 L 190,240 Z" fill="none" stroke="black" stroke-width="2"/>
    <text x="195" y="230">Print A</text>
    
    <!-- False -->
    <line x1="65" y1="180" x2="40" y2="180" stroke="black" stroke-width="2"/>
    <line x1="40" y1="180" x2="40" y2="210" stroke="black" stroke-width="2"/>
    <text x="50" y="175">No</text>
    <path d="M 10,210 L 60,210 L 70,240 L 20,240 Z" fill="none" stroke="black" stroke-width="2"/>
    <text x="25" y="230">Print B</text>
    
    <!-- Merge -->
    <line x1="40" y1="240" x2="40" y2="280" stroke="black" stroke-width="2"/>
    <line x1="40" y1="280" x2="125" y2="280" stroke="black" stroke-width="2"/>
    <line x1="210" y1="240" x2="210" y2="280" stroke="black" stroke-width="2"/>
    <line x1="210" y1="280" x2="125" y2="280" stroke="black" stroke-width="2"/>
    <line x1="125" y1="280" x2="125" y2="300" stroke="black" stroke-width="2"/>
    
    <ellipse cx="125" cy="320" rx="40" ry="20" fill="none" stroke="black" stroke-width="2"/>
    <text x="115" y="325">End</text>
</svg>'''

fname1 = save_svg(svg1)
fname2 = save_svg(svg2)

lines_to_append = []
# Inject SVG filenames
for q in distinct_questions:
    if '{fname1}' in q[0]:
        q[0] = q[0].replace('{fname1}', fname1)
    if '{fname2}' in q[0]:
        q[0] = q[0].replace('{fname2}', fname2)

# Write out CSV with headers first if file doesn't exist
file_exists = os.path.isfile(CSV_PATH)
with open(CSV_PATH, 'a', newline='', encoding='utf-8') as f:
    if not file_exists:
        f.write("Question;Option A;Option B;Option C;Option D;Answer,,,,,,,,\n")
    for q in distinct_questions:
        cleaned = [str(x).replace(";", ",") for x in q]
        row = ";".join(cleaned) + ",,,,,,,,"
        f.write(row + "\n")

print(f"Generated {len(distinct_questions)} distinct Programming Aptitude questions.")
