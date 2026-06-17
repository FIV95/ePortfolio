## Milestone Three Narrative — Algorithms & Data Structures

*CS 499 · Module 4 · Milestone 3 · May 2026*

### 1. Describe the artifact

The artifact for the Algorithms and Data Structures category is the same core project as my Software Design and Engineering enhancement: **SysKin**, a command-line tool for Linux service discovery and management. The original academic hash table was created in CS 300; I refined the algorithmic core throughout Modules 2–4.

The data structure stores rich `ServiceInfo` records: service name, primary config path, optional extra paths, description, and status. Every `lookup`, `list`, `add`, `delete`, and `scan` operation depends on the hash table's correctness and performance.

### 2. Justify inclusion

I selected this artifact for the Algorithms category because it gave me the clearest opportunity to demonstrate meaningful growth in algorithmic thinking, optimization, and design trade-offs — areas I wanted to strengthen before pursuing DevOps and systems administration roles.

The original CS 300 version used a very simple **sum-of-characters hash** with separate chaining and no resizing. That was sufficient for a classroom exercise but would not perform well with real-world data.

**Key algorithmic improvements:**

| Improvement | Detail |
|-------------|--------|
| FNV-1a hash | Replaced naïve sum-of-characters hash for better distribution and lower collisions |
| Dynamic resize | Load factor threshold 0.7, double capacity, full rehash — amortized O(1) insert/lookup |
| Partial search | `hashtable_search` — case-insensitive substring match for `lookup` command |
| Deletion | `hashtable_delete` with correct `ServiceInfo` and chain cleanup |
| Complexity docs | Time/space documented in source comments for every major operation |
| Unit tests | Resize behavior explicitly verified (`new capacity: 64` in test output) |

These changes turned a basic academic hash table into a production-quality data structure that is both efficient and practical for a growing service registry.

### 3. Course outcomes — planned vs. met

This enhancement strongly addresses **Outcome 3**: *Design and evaluate computing solutions using algorithmic principles while managing trade-offs.*

| Outcome | Progress |
|---------|----------|
| Outcome 3 — Design & algorithms | **Met** — hash selection, resize strategy, documented O(n) search trade-off |
| Outcome 4 — Techniques & tools | **Met** — FNV-1a, modular C, unit tests, Valgrind |
| Outcome 2 — Communication | **Met** — complexity comments, narrative, code review |
| Outcome 1 — Collaboration | Partial — covered in code review + DB artifact |
| Outcome 5 — Security | Partial — memory safety; security depth in Tech Shop |

I plan to tie all five outcomes together in this professional self-assessment and across the database milestone.

### 4. Reflect on the enhancement process

Working on the algorithmic side of SysKin has been one of the most valuable parts of the capstone.

**What I learned:**

- Choosing the right hash function for the problem domain matters — FNV-1a made a noticeable difference in distribution
- **Amortized analysis** clicked for me: occasional O(n) resize still yields O(1) average insert cost over many operations
- Algorithmic improvement is not abstract — it shows up in test output and operator experience

**Challenges:**

- Balancing functionality with efficiency — partial-match search requires O(n) scan; I documented why that trade-off is acceptable for interactive CLI use
- Memory safety during resize and delete while preserving user-added `extra_paths` during `scan`
- Getting comfortable with **Valgrind** — powerful but took time to interpret leak reports

Overall, this enhancement gave me much greater confidence in analyzing, optimizing, and justifying algorithmic decisions — skills essential in DevOps and systems administration roles. I am proud of how far this artifact has come from a simple classroom exercise to a practical, efficient tool.