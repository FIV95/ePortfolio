## Milestone Two Narrative — Software Design & Engineering

*CS 499 · Module 3 · Milestone 2 · May 2026*

### 1. Describe the artifact

**SysKin** is a command-line tool that helps Linux administrators and sysadmins manage and understand system services and their configuration files. It started as a basic hash table project from my CS 300 course (`original_hash_table.cpp`).

SysKin lets administrators scan for services across the system, manually add entries with multiple config paths, search using partial matching, and keep everything persistently saved. The original academic version was created in CS 300. I began transforming it into a real utility at the start of CS 499 and enhanced it through Module Three.

### 2. Justify inclusion

I picked this artifact because it gave me the best chance to show real growth from academic code to something genuinely useful. The original hash table was fine for class but was not something I could show an employer. I wanted a practical DevOps tool that sysadmins could use in daily work.

Administrators often struggle to track services and where config files live, especially across large systems. SysKin solves that by combining service discovery, rich data storage, and fast search in one lightweight tool.

#### Key improvements

- Converted from C++ to clean, modular C — separate files for hash table, storage, scanner, and CLI
- Added JSON persistence so service data survives program restarts (`~/.syskin/services.json`)
- Built a full CLI: `add`, `lookup` (partial search), `list`, `delete`, `scan`, `--help`
- Improved the core hash table with FNV-1a hashing and dynamic resizing
- Added support for multiple config paths per service (primary + `--extra` paths) — useful for nginx, apache, and similar services
- Makefile with `make`, `make test`, `make debug`, and `make clean` targets

These changes turned a simple academic exercise into a tool that helps real sysadmins work more efficiently.

### 3. Course outcomes — planned vs. met

| Outcome | Progress |
|---------|----------|
| Outcome 4 — Techniques & tools | **Met** — modular C, Makefile, JSON persistence, Linux integration |
| Outcome 3 — Design solutions | **Met** — layered architecture with separated concerns |
| Outcome 2 — Communication | **Met** — README, help text, code review video |
| Outcome 1 — Collaboration | Partial — readable modules; fuller coverage in DB artifact |
| Outcome 5 — Security | Partial — defensive C practices; deeper security in Tech Shop |

I still planned to complete the Databases category and finalize reflective narratives, but this artifact already demonstrates meaningful software engineering growth.

### 4. Reflect on the enhancement process

This project has been one of the most valuable learning experiences in the program. I learned how important clean modular design becomes once a project grows beyond a single file. Programming in C is meticulous — planning is key, and one small change can ripple across statically typed modules.

#### What I learned

- Interface design between modules matters as much as implementation
- Persistence forces you to think about data lifecycle (what survives a `scan` vs. what the user added manually)
- Build and test targets are not optional for credible software

#### Challenges

- Making the `scan` feature work **without erasing extra paths** users added manually — several iterations and careful testing
- Porting STL-heavy C++ to explicit C memory management
- Writing help text and CLI parsing that feels natural to an operator, not a grader

I intend to keep running Valgrind as I refine the project toward final submission. Overall, I feel my choice to pursue SysKin for software engineering was the right one for my DevOps career direction.