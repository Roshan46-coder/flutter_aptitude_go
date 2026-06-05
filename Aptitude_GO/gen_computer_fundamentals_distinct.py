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
    # 1. Operating Systems - Deep Concepts
    ["Which of the following is NOT one of the four necessary conditions for Deadlock to occur?", "Mutual Exclusion", "Hold and Wait", "No Preemption", "Context Switching", "D"],
    ["What is the primary difference between Paging and Segmentation in OS memory management?", "Paging divides memory into fixed-size blocks, Segmentation divides it into variable-size blocks based on logical division.", "Paging is faster but uses more CPU, Segmentation is slower but saves CPU.", "Paging requires TLB, Segmentation does not.", "Paging causes external fragmentation, Segmentation causes internal fragmentation.", "A"],
    ["Which file system structure is responsible for storing metadata about a file (like permissions, ownership, and disk block addresses) in Unix-like systems?", "Boot Block", "Super Block", "Inode", "FAT Table", "C"],
    ["In the context of multithreading, what does the 'Many-to-One' model imply?", "Many user-level threads mapped to one kernel thread", "Many kernel threads mapped to one user thread", "Thread pooling across multiple CPUs", "A single thread servicing many concurrent requests asynchronously", "A"],
    ["What is 'Spooling' in an Operating System?", "Simultaneous Peripheral Operations On-Line", "Synchronous Process Output Off-Loading", "System Paging Object-Oriented Library", "Sequential Peripheral Ordering Output Logic", "A"],

    # 2. Database Management Systems (DBMS) - Query / Indexing
    ["Which type of SQL Join returns all rows from the left table, and the matched rows from the right table?", "INNER JOIN", "LEFT OUTER JOIN", "RIGHT OUTER JOIN", "FULL OUTER JOIN", "B"],
    ["Which transaction isolation level prevents 'Dirty Reads' but allows 'Non-Repeatable Reads'?", "Read Uncommitted", "Read Committed", "Repeatable Read", "Serializable", "B"],
    ["Why is a B+ tree preferred over a standard Binary Search Tree for database indexing?", "B+ trees are fully balanced and all data pointers are stored in leaf nodes, minimizing disk I/O.", "B+ trees do not require pointers.", "Binary search trees cannot store string data.", "B+ trees have an O(1) search time complexity.", "A"],
    ["In an Entity-Relationship (ER) diagram, what does a double diamond represent?", "A weak entity set", "A multi-valued attribute", "An identifying relationship", "A derived attribute", "C"],
    ["What does the 'Consistency' property in ACID guarantees?", "Data is never lost after a crash.", "Transactions execute in isolation.", "The database smoothly transitions from one valid state to another.", "All operations of a transaction execute or none do.", "C"],

    # 3. Computer Networks - Protocols / Security
    ["Which transport protocol provides reliable, ordered, and error-checked delivery of a stream of bytes?", "UDP", "TCP", "ICMP", "IP", "B"],
    ["What is the primary function of the Address Resolution Protocol (ARP)?", "Mapping IP addresses to MAC addresses", "Mapping domain names to IP addresses", "Translating private IP addresses to public.", "Establishing TCP connections optimally", "A"],
    ["In CIDR notation, what does the subnet mask /24 correspond to in decimal format?", "255.0.0.0", "255.255.0.0", "255.255.255.0", "255.255.255.255", "C"],
    ["Which of the following routing protocols uses the Link-State routing algorithm? (e.g. Dijkstra's shortest path)", "RIP", "EIGRP", "OSPF", "BGP", "C"],
    ["In Asymmetric Key Cryptography (Public-Key), if Alice wants to send a secure message to Bob, which key does she use to encrypt the message?", "Alice's Public Key", "Alice's Private Key", "Bob's Public Key", "Bob's Private Key", "C"],

    # 4. OOP Concepts - Design / Principles
    ["In object-oriented design, what is the 'SOLID' principle that states a class should have only one reason to change?", "Single Responsibility Principle", "Open-Closed Principle", "Liskov Substitution Principle", "Dependency Inversion Principle", "A"],
    ["What is the primary distinction between 'Composition' and 'Aggregation'?", "Composition implies a strong 'part-of' lifecycle dependency; Aggregation implies a weak 'has-a' relationship.", "Composition uses interfaces; Aggregation uses abstract classes.", "Composition allows multiple inheritance; Aggregation does not.", "Composition is dynamic; Aggregation is static at compile-time.", "A"],
    ["Which Java keyword is used to prevent a class from being subclassed (inherited)?", "static", "final", "const", "sealed", "B"],
    ["What is 'Duck Typing' in dynamically typed languages like Python?", "Type checking based on object behavior (methods/properties) rather than explicit inheritance.", "Casting an object aggressively until it matches the required type.", "A design pattern for creating mock objects in unit tests.", "Enforcing strict type hints at compilation time.", "A"],
    ["What happens when a C++ class inherits virtually from a base class? (e.g. class A : virtual public Base)", "It prevents the Diamond Problem by ensuring only one instance of the base class is inherited.", "It makes all methods of that class automatically abstract.", "It restricts the class to single inheritance only.", "It allows the class to bypass all access modifiers.", "A"],

    # 5. Data Structures / Algorithms - Graphs / Trees / Hashing
    ["Which data structure is most optimally used to implement Dijkstra's shortest path algorithm?", "Stack", "Queue", "Min-Priority Queue", "Linked List", "C"],
    ["In a complete binary tree represented as an array (1-indexed), the left child of a node at index 'i' is located at?", "2*i", "2*i + 1", "i/2", "i*i", "A"],
    ["What is 'Double Hashing' used for?", "Encryption of passwords within the database.", "Resolving hash collisions by applying a second hash function to calculate the probe sequence.", "Creating a secondary index for faster database lookups.", "Combining two different hashing algorithms for security.", "B"],
    ["Which tree traversal visits the nodes in the order: Left Subtree, Root, Right Subtree?", "Pre-order", "In-order", "Post-order", "Level-order", "B"],
    ["Dynamic Programming is distinguishable from Divide and Conquer primarily because Dynamic Programming:", "Uses recursion while Divide and Conquer only uses iteration.", "Solves problems by breaking them into overlapping subproblems and memoizing results.", "Is generally slower and less memory efficient.", "Cannot be applied to optimization problems.", "B"],

    # 6. Software Engineering / Architecture
    ["Which UML diagram is a structural diagram that shows the system's objects, their attributes, operations, and relationships?", "Use Case Diagram", "Sequence Diagram", "Activity Diagram", "Class Diagram", "D"],
    ["In the MVC (Model-View-Controller) architecture, which component manages the data logic and rules of the application?", "Model", "View", "Controller", "Dispatcher", "A"],
    ["Which Software Design Pattern ensures that only a single instance of a class exists throughout the application?", "Factory Method", "Observer", "Singleton", "Decorator", "C"],
    ["What is the defining characteristic of a 'White-Box' testing approach?", "The tester has access to the internal source code and logic of the software.", "The tester treats the application as a black box and only inputs data to check against expected outputs.", "The test focuses exclusively on UI/UX components.", "The test is conducted by end-users in a beta environment.", "A"],
    ["In Computer Architecture, what is a 'Pipeline Stall' (or Bubble)?", "A jump instruction skipping cycles.", "A delay in execution to resolve a data, structural, or control hazard.", "The OS taking over the CPU for an interrupt.", "Overheating of the CPU cache.", "B"],
    ["What is the main difference between RISC and CISC architectures?", "RISC uses fewer, simpler instructions that execute in one cycle; CISC uses complex instructions that execute over multiple cycles.", "CISC processors lack hardware cache.", "RISC processors are only used in mobile devices.", "CISC requires more RAM to operate efficiently.", "A"]
]

# Add Visual/SVG Distinct Questions
svg4 = '''<svg width="350" height="200" xmlns="http://www.w3.org/2000/svg">
    <!-- Graph Adjacency representation concept -->
    <circle cx="50" cy="50" r="20" fill="white" stroke="black" stroke-width="2"/>
    <text x="45" y="55">0</text>
    <circle cx="150" cy="50" r="20" fill="white" stroke="black" stroke-width="2"/>
    <text x="145" y="55">1</text>
    <circle cx="100" cy="150" r="20" fill="white" stroke="black" stroke-width="2"/>
    <text x="95" y="155">2</text>
    
    <line x1="70" y1="50" x2="130" y2="50" stroke="black" stroke-width="2"/>
    <line x1="60" y1="67" x2="90" y2="133" stroke="black" stroke-width="2"/>
    <line x1="140" y1="67" x2="110" y2="133" stroke="black" stroke-width="2"/>
    
    <text x="200" y="50" font-family="monospace">
        <tspan x="200" dy="0">0: [1, 2]</tspan>
        <tspan x="200" dy="20">1: [0, 2]</tspan>
        <tspan x="200" dy="20">2: [0, 1]</tspan>
    </text>
</svg>'''
fname4 = save_svg(svg4)
text4 = f"Observe the visual representation of a data structure.<br><img src='images/{fname4}' style='max-width:100%;'><br>The right side of the image depicts what type of graph representation?"
distinct_questions.append([text4, "Adjacency Matrix", "Adjacency List", "Incidence Matrix", "Edge List", "B"])

svg5 = '''<svg width="400" height="150" xmlns="http://www.w3.org/2000/svg">
    <rect x="10" y="30" width="80" height="60" fill="lightblue" stroke="black"/>
    <text x="35" y="55" font-weight="bold">App</text>
    <text x="25" y="75" font-size="12">Process</text>
    
    <path d="M 90,60 L 140,60" fill="none" stroke="black" stroke-width="2" marker-end="url(#arrow)"/>
    
    <rect x="150" y="30" width="100" height="60" fill="lightgreen" stroke="black"/>
    <text x="175" y="55" font-weight="bold">Socket</text>
    <text x="160" y="75" font-size="12">(Port 80)</text>
    
    <path d="M 250,60 L 300,60" fill="none" stroke="black" stroke-width="2" marker-end="url(#arrow)"/>
    
    <rect x="310" y="30" width="80" height="60" fill="lightyellow" stroke="black"/>
    <text x="325" y="55" font-weight="bold">TCP</text>
    <text x="320" y="75" font-size="12">Layer 4</text>
    
    <defs>
        <marker id="arrow" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">
        <path d="M0,0 L0,6 L9,3 z" fill="black" />
        </marker>
    </defs>
</svg>'''
fname5 = save_svg(svg5)
text5 = f"Review the following network interaction diagram.<br><img src='images/{fname5}' style='max-width:100%;'><br>What serves as the software interface connecting the Application layer process to the Transport layer protocols (like TCP) via a specific port?"
distinct_questions.append([text5, "IP Data Packet", "Network Interface Card", "Socket", "Subnet Mask", "C"])

svg6 = '''<svg width="350" height="150" xmlns="http://www.w3.org/2000/svg">
    <!-- Deadlock visual -->
    <circle cx="80" cy="50" r="30" fill="white" stroke="blue" stroke-width="3"/>
    <text x="75" y="55">P1</text>
    
    <rect x="230" y="30" width="50" height="40" fill="white" stroke="red" stroke-width="3"/>
    <text x="240" y="55">R1</text>
    
    <circle cx="255" cy="120" r="30" fill="white" stroke="blue" stroke-width="3"/>
    <text x="245" y="125">P2</text>
    
    <rect x="55" y="100" width="50" height="40" fill="white" stroke="red" stroke-width="3"/>
    <text x="65" y="125">R2</text>
    
    <path d="M 110,50 L 220,50" fill="none" stroke="black" stroke-width="2" marker-end="url(#arrow)"/>
    <text x="140" y="40" font-size="12">Requests</text>
    
    <path d="M 230,70 L 100,110" fill="none" stroke="black" stroke-width="2" marker-end="url(#arrow)"/>
    <text x="140" y="105" font-size="12">Holds</text>
    
    <path d="M 240,120 L 110,120" fill="none" stroke="black" stroke-width="2" marker-end="url(#arrow)"/>
    <text x="145" y="135" font-size="12">Requests</text>

    <path d="M 70,100 L 70,80" fill="none" stroke="black" stroke-width="2" marker-end="url(#arrow)"/>
    <text x="80" y="90" font-size="12">Holds</text>
    
    <defs>
        <marker id="arrow" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">
        <path d="M0,0 L0,6 L9,3 z" fill="black" />
        </marker>
    </defs>
</svg>'''
fname6 = save_svg(svg6)
text6 = f"Consider the Resource Allocation Graph below where P1/P2 are processes and R1/R2 are distinct resources.<br><img src='images/{fname6}' style='max-width:100%;'><br>What system state does this cyclic dependency clearly illustrate?"
distinct_questions.append([text6, "Starvation", "Deadlock", "Race Condition", "Paging Fault", "B"])


file_exists = os.path.isfile(CSV_PATH)
with open(CSV_PATH, 'a', newline='', encoding='utf-8') as f:
    if not file_exists:
        f.write("Question;Option A;Option B;Option C;Option D;Answer,,,,,,,,\n")
    for q in distinct_questions:
        cleaned = [str(x).replace(";", ",") for x in q]
        row = ";".join(cleaned) + ",,,,,,,,"
        f.write(row + "\n")

print(f"Generated {len(distinct_questions)} extra distinct conceptual CF questions.")
