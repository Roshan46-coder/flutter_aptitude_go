import os
import csv
import uuid

BASE_DIR = r"d:\aptitude preparation plaform\question_bank\computer_fundamentals"
IMAGES_DIR = os.path.join(BASE_DIR, "images")
CSV_PATH = os.path.join(BASE_DIR, "computer_fundamentals.csv")

if not os.path.exists(IMAGES_DIR):
    os.makedirs(IMAGES_DIR)

def save_svg(svg_content):
    filename = f"vis_{uuid.uuid4().hex[:8]}.svg"
    filepath = os.path.join(IMAGES_DIR, filename)
    with open(filepath, "w", encoding='utf-8') as f:
        f.write(svg_content)
    return filename

distinct_questions = [
    # 1. Operating Systems
    ["What is the primary function of an Operating System?", "To provide a user interface", "To manage system resources (CPU, Memory, I/O)", "To run application programs", "All of the above", "D"],
    ["Which algorithm is used to resolve the Dining Philosophers problem?", "Round Robin", "Monitor / Semaphores", "Shortest Job First", "Banker's Algorithm", "B"],
    ["What does 'Thrashing' indicate in an operating system?", "High CPU utilization", "High I/O waiting time", "Excessive page faulting causing low CPU utilization", "A crashed process", "C"],
    ["Which of the following describes a 'Zombie Process'?", "A process that has completed execution but still has an entry in the process table", "A process that is currently running in the background", "A process waiting for I/O", "A process that is in an infinite loop", "A"],

    # 2. Database Management Systems (DBMS)
    ["What is the purpose of the 'ACID' properties in a DBMS?", "To ensure data redundancy", "To ensure reliable processing of database transactions", "To speed up query execution", "To manage user access permissions", "B"],
    ["Which normal form ensures that there is no transitive dependency for non-prime attributes?", "First Normal Form (1NF)", "Second Normal Form (2NF)", "Third Normal Form (3NF)", "Boyce-Codd Normal Form (BCNF)", "C"],
    ["What is a 'Primary Key' constraint?", "Ensures that a column has unique and non-null values", "Allows null values but must be unique", "Establishes a relationship between two tables", "Restricts the domain of a column", "A"],
    ["In SQL, the TRUNCATE command is an example of which type of statement?", "DML (Data Manipulation Language)", "DDL (Data Definition Language)", "DCL (Data Control Language)", "TCL (Transaction Control Language)", "B"],

    # 3. Computer Networks
    ["Which layer of the OSI model is responsible for reliable end-to-end data delivery?", "Network Layer", "Data Link Layer", "Transport Layer", "Application Layer", "C"],
    ["What does IP fragmentation handle?", "Dividing a packet into smaller fragments to pass through a link with a smaller MTU", "Encapsulating data into a TCP segment", "Assigning IP addresses to hosts", "Translating domain names to IP addresses", "A"],
    ["Which protocol is used by web browsers to establish a secure connection with a web server?", "HTTP", "FTP", "HTTPS (SSL/TLS)", "SMTP", "C"],
    ["What is the standard port number for the DNS service?", "21", "25", "53", "80", "C"],

    # 4. OOP Concepts
    ["Which OOP principle is implemented by using access modifiers (private, public, protected)?", "Inheritance", "Polymorphism", "Encapsulation", "Abstraction", "C"],
    ["What is 'Method Overloading'?", "Two or more methods in the same class with the same name but different parameters", "A subclass providing a specific implementation for a method defined in its superclass", "Multiple variables sharing the same name", "Hiding internal implementation details", "A"],
    ["Which relationship does Inheritance generally represent?", "Has-A relationship", "Is-A relationship", "Uses-A relationship", "Part-Of relationship", "B"],
    ["Can a Java abstract class be instantiated directly using the 'new' keyword?", "Yes, always", "Only if it has no abstract methods", "No, it cannot be instantiated directly", "Yes, but only by its subclasses", "C"],

    # 5. Data Structures (Basic)
    ["Which data structure is based on the LIFO (Last In First Out) principle?", "Queue", "Stack", "Linked List", "Tree", "B"],
    ["What is the worst-case time complexity of accessing an element in an unsorted Unlinked List by index?", "O(1)", "O(log n)", "O(n)", "O(n^2)", "C"],
    ["In a complete binary tree with 'N' nodes, what is the height of the tree?", "O(N)", "O(N log N)", "O(log N)", "O(1)", "C"],
    ["Which search algorithm requires the array to be sorted beforehand?", "Linear Search", "Binary Search", "Breadth-First Search", "Depth-First Search", "B"],

    # 6. Software Engineering Basics
    ["Which software development lifecycle (SDLC) model is purely sequential and requires strict documentation at each phase?", "Agile Model", "Spiral Model", "Waterfall Model", "V-Model", "C"],
    ["What does 'Coupling' refer to in software engineering?", "The internal cohesion of a single module", "The degree of interdependence between software modules", "The process of linking a database", "The process of code compilation", "B"],
    ["Which testing phase ensures that individual units of the software work correctly?", "System Testing", "Integration Testing", "Unit Testing", "Acceptance Testing", "C"],
    ["In Agile methodology, what is a 'Sprint'?", "A bug-fixing session", "A continuous delivery pipeline", "A time-boxed iteration of software development usually lasting 1-4 weeks", "A team meeting to discuss architecture", "C"],
    
    # 7. Architecture/Hardware Basics
    ["Which memory component acts as a high-speed buffer between the CPU and main memory?", "Hard Drive", "ROM", "Cache Memory", "Virtual Memory", "C"]
]

# Add SVG Questions
svg1 = '''<svg width="350" height="200" xmlns="http://www.w3.org/2000/svg">
    <!-- Relational Schema Diagram -->
    <rect x="20" y="20" width="100" height="80" fill="#f0f0f0" stroke="black" stroke-width="2"/>
    <text x="30" y="40" font-weight="bold">Employee</text>
    <line x1="20" y1="50" x2="120" y2="50" stroke="black"/>
    <text x="30" y="70" text-decoration="underline">EmpID</text>
    <text x="30" y="90">DeptID (FK)</text>
    
    <rect x="200" y="20" width="100" height="80" fill="#f0f0f0" stroke="black" stroke-width="2"/>
    <text x="210" y="40" font-weight="bold">Department</text>
    <line x1="200" y1="50" x2="300" y2="50" stroke="black"/>
    <text x="210" y="70" text-decoration="underline">DeptID</text>
    <text x="210" y="90">DeptName</text>
    
    <path d="M 120,85 L 200,65" fill="none" stroke="blue" stroke-width="2" marker-end="url(#arrow)"/>
    
    <defs>
        <marker id="arrow" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">
        <path d="M0,0 L0,6 L9,3 z" fill="blue" />
        </marker>
    </defs>
</svg>'''
fname1 = save_svg(svg1)
text1 = f"Observe the relational schema diagram:<br><img src='images/{fname1}' style='max-width:100%;'><br>What does the arrow from 'DeptID (FK)' in the Employee table to 'DeptID' in the Department table represent?"
distinct_questions.append([text1, "A One-to-One relationship", "A Foreign Key acting as a Referential Integrity constraint", "A Primary Key constraint on the Employee table", "A Join Query output", "B"])


svg2 = '''<svg width="400" height="150" xmlns="http://www.w3.org/2000/svg">
    <!-- OSI Model simplified view -->
    <rect x="20" y="30" width="60" height="40" fill="#ccffcc" stroke="black"/>
    <text x="25" y="55">Src Host</text>
    <line x1="80" y1="50" x2="160" y2="50" stroke="black" stroke-width="2"/>
    <circle cx="180" cy="50" r="20" fill="#ffcccc" stroke="black"/>
    <text x="175" y="55">R1</text>
    <line x1="200" y1="50" x2="280" y2="50" stroke="black" stroke-width="2"/>
    <rect x="280" y="30" width="60" height="40" fill="#ccffcc" stroke="black"/>
    <text x="282" y="55">Dst Host</text>
    <line x1="180" y1="70" x2="180" y2="100" stroke="gray" stroke-dasharray="4"/>
    <text x="140" y="115" font-size="12">Operates up to Layer 3</text>
</svg>'''
fname2 = save_svg(svg2)
text2 = f"Consider the network topology with a device labeled R1:<br><img src='images/{fname2}' style='max-width:100%;'><br>If R1 operates up to Layer 3 of the OSI model, what type of network device is R1 most likely to be?"
distinct_questions.append([text2, "Hub", "Switch", "Router", "Bridge", "C"])

svg3 = '''<svg width="300" height="200" xmlns="http://www.w3.org/2000/svg">
    <!-- Stack Push/Pop -->
    <text x="100" y="20" font-weight="bold">Stack Operations</text>
    <path d="M 120,180 L 120,60 M 180,180 L 180,60 M 120,180 L 180,180" fill="none" stroke="black" stroke-width="3"/>
    <rect x="125" y="140" width="50" height="30" fill="lightblue" stroke="black"/>
    <text x="145" y="160">A</text>
    <rect x="125" y="100" width="50" height="30" fill="lightblue" stroke="black"/>
    <text x="145" y="120">B</text>
    
    <path d="M 60,60 C 60,30 110,30 135,55" fill="none" stroke="green" stroke-width="2" marker-end="url(#arrowG)"/>
    <text x="50" y="45" fill="green">Push(C)</text>
    
    <path d="M 165,55 C 190,30 240,30 240,60" fill="none" stroke="red" stroke-width="2" marker-end="url(#arrowR)"/>
    <text x="210" y="45" fill="red">Pop()</text>
    
    <defs>
        <marker id="arrowG" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">
        <path d="M0,0 L0,6 L9,3 z" fill="green" />
        </marker>
        <marker id="arrowR" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">
        <path d="M0,0 L0,6 L9,3 z" fill="red" />
        </marker>
    </defs>
</svg>'''
fname3 = save_svg(svg3)
text3 = f"Analyze the stack diagram. The operations Push(C) followed by Pop() are performed sequentially.<br><img src='images/{fname3}' style='max-width:100%;'><br>After these operations, which element is at the top of the stack?"
distinct_questions.append([text3, "A", "B", "C", "Empty Stack", "B"])


file_exists = os.path.isfile(CSV_PATH)
with open(CSV_PATH, 'a', newline='', encoding='utf-8') as f:
    if not file_exists:
        f.write("Question;Option A;Option B;Option C;Option D;Answer,,,,,,,,\n")
    for q in distinct_questions:
        cleaned = [str(x).replace(";", ",") for x in q]
        row = ";".join(cleaned) + ",,,,,,,,"
        f.write(row + "\n")

print(f"Generated {len(distinct_questions)} distinct Computer Fundamentals questions.")
