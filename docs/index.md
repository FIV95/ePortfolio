---
layout: default
title: Professional Self-Assessment
permalink: /
description: "Professional self-assessment — formal introduction to Lawrence Francis, CS 499 ePortfolio"
---

<section class="hero">
  <div class="container">
    <p class="hero-eyebrow">CS 499 Capstone · Read This First</p>
    <h1>Professional Self-Assessment</h1>
    <p class="lede">
      <strong>Lawrence Francis</strong> · Southern New Hampshire University · Bachelor of Science in Computer Science · CS 499 — Computer Science Capstone · June 2026
    </p>
    <div class="meta-row">
      <span class="chip">1 · Professional Self-Assessment ← you are here</span>
      <span class="chip">2 · <a href="{{ site.baseurl }}/code-review/">Code Reviews</a></span>
      <span class="chip">3 · <a href="{{ site.baseurl }}/syskin/">SysKin</a></span>
      <span class="chip">4 · <a href="{{ site.baseurl }}/tech-shop/">Tech Shop</a></span>
    </div>
  </div>
</section>

<div class="container">

## Introduction

Completing the Bachelor of Science in Computer Science at Southern New Hampshire University has been a deliberate progression from learning foundational concepts to producing work I would confidently show an employer. My capstone ePortfolio is not simply a collection of assignments completed for a grade. It is evidence of how I think, build, document, secure, and improve software and systems over time.

I am positioning myself for roles in DevOps engineering and systems administration. These fields require reliable tools, secure infrastructure, clear documentation, and the ability to make complex systems understandable for the people who use and maintain them. The two enhanced artifacts in this portfolio, SysKin and the Tech Repair Shop database, reflect that direction from different angles. SysKin is a lightweight systems utility designed for Linux administrators, while the Tech Repair Shop is an operations-focused PostgreSQL environment with security, workflow rules, automation, and role-based access built into its design.

This self-assessment introduces who I am as a computer science professional, summarizes the skills I developed throughout the program, and explains how my artifacts work together to demonstrate the full range of my capabilities.

## How the Program and ePortfolio Shaped My Professional Identity

### Collaborating in a Team Environment

Software is rarely built in isolation, and one of the most practical lessons I took from the computer science program is that collaboration is not only about writing code with other people. It is also about creating work that other people can read, review, maintain, and trust.

In CS 499, I approached my code review videos as presentations for peers and a technical manager. The code review process was challenging because I was returning to older artifacts that I had not examined in some time. That experience showed me the importance of self-assessing my own work and documenting design decisions clearly. It also helped me see how much I have grown. Earlier versions of my work did not always include the level of commenting, structure, or explanation that I now recognize as necessary for professional software development.

My database enhancement reinforced a different side of collaboration. The Tech Repair Shop project is designed for multiple staff roles, including customer service representatives, technicians, administrators, and auditors. These users depend on the same data, but they should not all have the same level of access or authority. Building separate, role-appropriate experiences on top of a controlled database taught me that good system design is a form of team support. When access rules are clear and enforced at the correct layer, teams can work in parallel without creating confusion, data conflicts, or security gaps.

Across earlier coursework, group-oriented projects and structured review cycles pushed me to write code that someone else could follow. That habit carried directly into my capstone. SysKin is split into focused modules with tests, and the database project includes README documentation, an entity relationship diagram, and scripts that allow another administrator to reproduce the environment without guessing. I want to be the kind of engineer whose work makes the next person's job easier, not harder.

### Communicating with Stakeholders

Technical skill only creates value when it can be communicated to the right audience in the right format. That was true in my capstone and throughout the program.

For SysKin, I wrote for two audiences at once: reviewers who care about software structure and future employers who care about whether the tool solves a real operations problem. The command-line interface, help text, and repository documentation explain the tool in plain terms. SysKin can scan services, store configuration paths, search by partial name, and persist data between sessions. At the same time, the implementation details remain available for technical readers who want to inspect the hash table design, file structure, memory management, or test coverage.

For the Tech Repair Shop, communication mattered even more because not every stakeholder speaks SQL. The database remains the primary artifact, but the FastAPI application layer gives front-desk and technician users a readable way to interact with repairs, customers, and baton status. I kept that layer intentionally thin so the enhancement stayed focused on database competence rather than becoming a large application project. That decision was also a communication choice: demonstrate the business value of the database without hiding the technical core of the project.

My milestone narratives, README files, and code review videos are all part of the same skill set. They translate implementation work into evidence of judgment. An employer does not only need to know that I enabled row-level security. They also need to see that I can explain why technician visibility is tied to baton state, what problems appeared when policies were first drafted too aggressively, and how I corrected them. Professional communication, in my view, is the bridge between correct code and trusted systems.

### Data Structures and Algorithms

Algorithms and data structures were an area where I needed to show meaningful growth. In CS 300, I built a hash table for an advising-assistant project that was appropriate for the classroom. It used separate chaining, basic insertion and lookup, and a simple hash function that summed character values. It worked for the assignment, but it was not something I would rely on in a production-style tool.

SysKin gave me the opportunity to close that gap with intention. I replaced the original hash function with FNV-1a, added dynamic resizing based on load factor, implemented deletion with correct memory management, and built partial-match search for cases where a user remembers only part of a service name. I documented time and space complexity for the major operations and supported the resizing behavior with unit tests.

One of the most important lessons I took from this work is that algorithmic improvement is not abstract. Changing the hash function improved distribution. Adding resizing helped the structure remain useful as the number of entries grew. Accepting an O(n) scan for substring search was a conscious trade-off because interactive lookup usability mattered more than theoretical purity for that specific command. I would not describe myself as naturally gifted in algorithm analysis, but I now understand the deeper point: every design choice has a cost. Rarely does software have a one-size-fits-all answer. A strong software engineer must evaluate the advantages, limitations, and trade-offs of each approach.

This is the kind of thinking I expect to use in systems work. Operators care about predictable performance and reliable behavior under growing data sets. A service registry that degrades as entries accumulate is not a useful operations tool. The enhanced SysKin artifact shows that I can analyze a data-structure problem, choose appropriate techniques, justify trade-offs, and verify behavior through testing.

### Software Engineering and Databases

Software engineering and databases form the backbone of my portfolio and directly support the career path I am pursuing.

On the software engineering side, SysKin represents a full redesign rather than a small patch. I moved from a single-file academic C++ program to a modular C application with separate components for the hash table, persistent storage, command-line interface, and service scanner. I added a Makefile, debug and test targets, and a persistence layer that stores service metadata in JSON under the user's home directory. The result is a small but credible software project with clear boundaries, repeatable builds, and testable units. This structure reflects what I learned across software development, testing, and advanced programming coursework: systems become more maintainable when responsibilities are separated and verified incrementally.

On the database side, the Tech Repair Shop project shows a different kind of maturity. I began with an academic schema containing customers, devices, technicians, repair orders, parts, and supporting scripts. I then extended it into a system a small business could realistically operate. The enhanced version adds repair notes, baton history, audit logging, maintenance logging, and role-based application accounts. It includes bcrypt password hashing, pgcrypto encryption for sensitive customer data, row-level security policies, and audit triggers on critical tables. It also includes operational tooling for migration, verification, backup, restore, maintenance, and automated security tests.

What I am most proud of in the database enhancement is not one specific feature. It is the decision-making process behind where logic should live. The baton workflow, which allows only one technician to actively hold a repair at a time, could have been handled only in application code. Instead, I implemented it in the database with functions, policies, and triggers because that is where enforcement is strongest and most durable. That mindset will matter in infrastructure and platform work, where the strongest guarantees are the ones that survive multiple clients, scripts, and future maintainers.

### Security

Security was not a separate topic by the end of the program. It became a design habit.

In SysKin, security appears through careful C programming practices: explicit memory management, testing with Valgrind, and defensive handling of user input and file operations. Systems tools run close to the operating environment, so sloppy memory behavior or unvalidated assumptions can become real failures. Improving SysKin taught me that secure coding is not only about adding authentication or encryption. It is also about preventing avoidable defects through disciplined implementation.

In the Tech Repair Shop, security is more visible and central. I removed reliance on plaintext credentials, encrypted address data at rest, masked contact information where appropriate, and used PostgreSQL roles and row-level security to ensure technicians only see repairs they are allowed to work on. Audit logging gives administrators and auditors a trail of meaningful changes. Security tests verify that valid credentials are accepted, invalid credentials are rejected, and role boundaries behave as expected.

A lesson I will carry into industry is that security is strongest when it is designed into the system early and enforced consistently. A polished user interface cannot compensate for weak data access rules. Likewise, a fast command-line tool is not professional if it leaks memory or corrupts persisted data. My portfolio demonstrates both layers of that thinking.

## How My Artifacts Fit Together

Although this ePortfolio includes enhancements in three required categories — software design and engineering, algorithms and data structures, and databases — I chose to pursue those categories through two artifacts rather than three separate projects. That decision gave me depth instead of surface coverage.

SysKin carries two categories at once. The software engineering enhancement shows that I can take academic code and refactor it into a maintainable, useful utility with persistence, scanning, and a complete command-line interface. The algorithms and data structures enhancement shows that I can analyze performance characteristics, improve core data-structure behavior, and defend design trade-offs with testing and documentation. Together, those enhancements tell a coherent story about growth in low-level systems programming, which supports automation, troubleshooting, and day-to-day administration.

The Tech Repair Shop carries the database category and complements SysKin by showing that I can also think at the persistence, policy, and operations layer. Where SysKin is a focused tool for one operator at a terminal, the database project models how an organization stores sensitive data, separates duties, records change history, and keeps systems maintainable over time. The FastAPI application layer makes that work approachable without making the database secondary.

Viewed together, the artifacts show a useful professional combination. I can build software close to the operating environment. I can reason about algorithmic efficiency and correctness. I can design and harden data systems with realistic security and workflow rules. I can also document, test, and operationalize my work so others can use it.

That combination is the core of my employability argument. I am not presenting myself as someone who only writes application code or someone who only runs scripts. I am presenting myself as someone who can move between layers — application, data, and operations — and make disciplined decisions at each one.

### Explore the artifacts

<div class="card-grid">
  <a class="artifact-card" href="{{ site.baseurl }}/code-review/">
    <h3>Code Review Videos</h3>
    <p>Informal walkthroughs — existing functionality, code analysis, and enhancement plans.</p>
  </a>
  <a class="artifact-card" href="{{ site.baseurl }}/syskin/">
    <h3>SysKin</h3>
    <p>Software engineering + algorithms — modular C service registry for Linux administrators.</p>
    <div class="tag-row">
      <span class="tag">Software Engineering</span>
      <span class="tag">Algorithms & DSA</span>
    </div>
  </a>
  <a class="artifact-card" href="{{ site.baseurl }}/tech-shop/">
    <h3>Tech Repair Shop</h3>
    <p>Databases — secure PostgreSQL with baton workflow, audit logging, and ops automation.</p>
    <div class="tag-row"><span class="tag">Databases</span></div>
  </a>
</div>

## Strengths, Goals, and Readiness for the Field

If I were sitting across from a hiring manager, the message I would want this portfolio to support is straightforward: I build things that are useful, explainable, testable, and maintainable.

My strongest strengths are systems thinking, practical improvement, documentation, verification, and security awareness. Systems thinking helps me look for the right layer to solve a problem, whether that means changing a hash table resize strategy, enforcing a SQL policy, or writing an operations script. Practical improvement is shown through both artifacts, which began as coursework and were enhanced into work I would voluntarily show in an interview. Documentation and verification are also central to my work because I do not treat testing, README quality, or review preparation as optional finishing steps. They are part of the deliverable. Finally, security awareness helps me anticipate misuse, leakage, and maintenance failures instead of assuming ideal conditions.

My near-term professional goal is to join a team where I can contribute to infrastructure, platform, or systems operations work while continuing to deepen my skills in automation, monitoring, and secure deployment practices. Longer term, I want to be trusted with production systems where reliability and clarity matter more than novelty.

This capstone helped shape that goal by forcing me to connect classroom foundations to professional standards. I entered the program needing to learn how the pieces fit. I am leaving it with evidence that I can integrate them.

## Closing Reflection

The ePortfolio process itself was one of the most valuable parts of CS 499. It required me to look at older work without disowning it, identify honest weaknesses, improve the work methodically, and explain the improvement in language that matters to employers and collaborators. That is different from passing a single module assignment. It is the skill of presenting a career narrative supported by real artifacts.

I am proud of the distance between my original CS 300 hash table and the current SysKin utility. I am equally proud of the distance between my first repair-shop schema and the secure, auditable, role-aware database system I am submitting now. Neither artifact is finished in the abstract sense. Both are the kind of projects I would continue improving in industry. However, both demonstrate the standard of work I intend to bring with me.

**This portfolio is my introduction. The artifacts that follow are the proof.**

</div>