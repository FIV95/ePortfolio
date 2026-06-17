---
layout: default
title: Code Reviews
permalink: /code-review/
description: "Informal code review walkthrough videos for SysKin and Tech Repair Shop"
---

<div class="container" markdown="1">

# Informal Code Reviews

After identifying my artifacts but **before** completing enhancements, I recorded walkthrough videos for peers and a technical manager. The rubric requires these reviews to cover existing functionality, code analysis, and planned enhancements aligned to all five course outcomes.

<p class="muted"><a href="{{ site.baseurl }}/">← Back to Professional Self-Assessment</a> (read that first)</p>

<div class="callout">
<strong>Audience:</strong> peers and technical managers. Explain how the code works and <em>why</em> planned enhancements matter — not just what will change. These reviews set the foundation for the enhanced artifacts on the following pages.
</div>

## What each review must address

| Rubric area | What I covered |
|-------------|----------------|
| **Existing functionality** | Walk through features and behavior of the code <em>before</em> enhancements |
| **Code analysis** | Structure, logic, efficiency, security, testing, commenting, documentation — targeted improvements |
| **Enhancement plan** | Planned changes across software engineering, algorithms, and databases; skills demonstrated; course outcome alignment |

---

## SysKin — Software Engineering & DSA Artifact

{% include video-embed.html
  title="Lawrence Francis — SysKin Code Review"
  description="Walkthrough of the original CS 300 hash table and planned modular C redesign with DSA improvements."
  filename="Lawrence_Francis_CS499_DSA_SE_Artifact_code_review.mp4"
%}

### Existing functionality

The original **CS 300 Advising Assistant** used a hash table with separate chaining to load course records from CSV. Menu options included load, print all (alphanumeric sort), print one course, and exit. The hash function summed character values — simple and adequate for classroom scale.

### Code analysis — areas for improvement

<ul class="checklist">
  <li><strong>Structure</strong> — single monolithic C++ file; hard to test or extend</li>
  <li><strong>Hash quality</strong> — sum-of-characters produces poor distribution for real keys</li>
  <li><strong>No resize</strong> — fixed bucket count; performance degrades as data grows</li>
  <li><strong>No persistence</strong> — data lost on exit</li>
  <li><strong>Limited testing</strong> — manual verification only</li>
  <li><strong>Domain mismatch</strong> — academic course catalog, not an operations tool</li>
</ul>

### Planned enhancements

<ul class="checklist">
  <li>Refactor to <strong>modular C</strong> — hashtable, storage, scanner, CLI</li>
  <li><strong>FNV-1a</strong> hash + dynamic resize at 0.7 load factor</li>
  <li><strong>JSON persistence</strong> at <code>~/.syskin/services.json</code></li>
  <li><strong>systemd scanner</strong> — discover services from unit files</li>
  <li>CLI commands: <code>scan</code>, <code>lookup</code>, <code>add</code>, <code>delete</code>, <code>list</code></li>
  <li><strong>Unit tests</strong> via <code>make test</code>; Valgrind for memory safety</li>
</ul>

<div class="outcome-row">
  <span class="outcome-tag">Outcome 1 · Code review as collaboration</span>
  <span class="outcome-tag">Outcome 2 · Oral communication</span>
  <span class="outcome-tag">Outcome 3 · Algorithmic trade-offs</span>
  <span class="outcome-tag">Outcome 4 · SDLC & testing</span>
  <span class="outcome-tag">Outcome 5 · Memory safety</span>
</div>

<p><strong>Enhanced artifact:</strong> <a href="{{ site.baseurl }}/syskin/">View SysKin page →</a></p>

---

## Tech Repair Shop — Database Artifact

{% include video-embed.html
  title="Lawrence Francis — Tech Repair Shop Code Review"
  description="Walkthrough of the baseline repair-shop schema and planned security, ops, and baton enhancements."
  filename="Lawrence_Francis_CS499_Database_Artifact_code_Review.mp4"
%}

### Existing functionality

The original **Tech Repair Shop** baseline included six normalized tables (customer, device, technician, repair_order, part_used), seed data, indexes, `updated_at`/`closed_at` triggers, three database roles, and twelve demonstration queries covering joins, aggregation, and reporting.

### Code analysis — areas for improvement

<ul class="issue-list">
  <li><strong>Security</strong> — simple role grants; no RLS, no encryption, plaintext-era assumptions</li>
  <li><strong>Scale</strong> — ten seed tickets; not representative of shop operations</li>
  <li><strong>No audit trail</strong> — changes not tracked for compliance or troubleshooting</li>
  <li><strong>No ops tooling</strong> — no migrate, verify, backup, or restore scripts</li>
  <li><strong>Workflow</strong> — static technician assignment; no coordination rules</li>
  <li><strong>Accessibility</strong> — SQL-only access limits front-desk and technician usability</li>
</ul>

### Planned enhancements

<ul class="checklist">
  <li><strong>Security hardening</strong> — bcrypt, pgcrypto encryption, RLS, four login roles</li>
  <li><strong>Audit logging</strong> — JSONB change snapshots on critical tables</li>
  <li><strong>Baton workflow</strong> — one active tech per ticket; claim/drop functions in SQL</li>
  <li><strong>Ops automation</strong> — migrate, verify, backup, restore, maintenance scripts</li>
  <li><strong>Rich sample data</strong> — realistic shop dataset for demo and testing</li>
  <li><strong>Thin /app UI</strong> — role-scoped FastAPI front end respecting DB roles</li>
</ul>

<div class="outcome-row">
  <span class="outcome-tag">Outcome 1 · Multi-role collaboration</span>
  <span class="outcome-tag">Outcome 2 · Stakeholder communication</span>
  <span class="outcome-tag">Outcome 3 · DB-layer design decisions</span>
  <span class="outcome-tag">Outcome 4 · Ops tooling & automation</span>
  <span class="outcome-tag">Outcome 5 · Security gap analysis</span>
</div>

<p><strong>Enhanced artifact:</strong> <a href="{{ site.baseurl }}/tech-shop/">View Tech Repair Shop page →</a></p>

---

<p class="muted">Continue to the enhanced artifacts: <a href="{{ site.baseurl }}/syskin/">SysKin</a> · <a href="{{ site.baseurl }}/tech-shop/">Tech Repair Shop</a></p>

</div>