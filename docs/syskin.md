---
layout: default
title: SysKin
permalink: /syskin/
description: "Software Engineering and Algorithms & Data Structures artifact — persistent Linux service registry"
---

<div class="container" markdown="1">

# SysKin — Persistent Linux Service Knowledge Base

<div class="tag-row">
  <span class="tag">Software Design & Engineering</span>
  <span class="tag">Algorithms & Data Structures</span>
</div>

SysKin is a POSIX **C command-line utility** that scans systemd unit files, stores discovered services in a hash table, and persists everything to JSON. One artifact, two enhancement categories — modular software engineering *and* a production-quality hash table.

<p>
  <a href="{{ site.repo_url }}/tree/main/Software_Engineering_%26_DSA_Artifact/syskin">View source in repository</a>
  ·
  <a href="{{ site.baseurl }}/code-review/">Code review video</a>
</p>

## What problem does it solve?

Linux administrators constantly need to answer: *what services are on this machine, and where do their config files live?* Scattered unit files under `/usr/lib/systemd/system`, manually edited paths, and services added outside a formal CMDB make that harder than it sounds.

SysKin gives one operator at a terminal a **persistent, searchable registry** — scan once, lookup by partial name later, add manual entries with extra config paths, and trust that data survives reboots via JSON persistence.

## Before → After

| Dimension | Original (CS 300) | Enhanced (SysKin) |
|-----------|-------------------|-------------------|
| Language / structure | Single C++ file | Modular C: `hashtable`, `storage`, `scanner`, `cli` |
| Hash function | Sum of characters | FNV-1a 32-bit |
| Resizing | Fixed bucket count | Dynamic resize at 0.7 load factor |
| Persistence | None | `~/.syskin/services.json` |
| Domain | Course catalog loader | Linux service registry + scanner |
| Testing | Manual | `make test` unit suites |
| Operations | Academic menu | CLI: `scan`, `lookup`, `add`, `delete`, `list` |

## In action

</div>

{% capture syskin_help %}SysKin v0.8 - Persistent Linux Service Knowledge Base

Commands:
  list                          List all known services
  lookup <name>                 Find service details (partial match)
  add <name> <config_path> "<desc>" [status] [--extra <path1> ...]
  delete <name>                 Remove service
  scan                          Auto-discover ALL services from systemd
  --help                        Show this help{% endcapture %}
{% include terminal-frame.html title="syskin — help" content=syskin_help %}

{% capture syskin_test %}$ make test
=== SysKin Storage + Persistence Unit Tests ===
✓ Load on missing file → empty table
✓ Save successful
✓ Reloaded and lookup successful
✅ All storage + persistence tests passed!

=== SysKin HashTable Unit Tests ===
✓ Create successful
✓ Insert successful
✓ Lookup successful
✓ Resizing test passed (new capacity: 64)
✅ All basic tests passed!{% endcapture %}
{% include terminal-frame.html title="make test" content=syskin_test %}

<div class="container" markdown="1">

## Complexity analysis

| Operation | Average case | Worst case | Notes |
|-----------|--------------|------------|-------|
| `hashtable_insert` | O(1) | O(n) | Amortized O(1) with resize at 0.7 load factor |
| `hashtable_lookup` | O(1) | O(n) | Separate chaining; degrades if hash clusters |
| `hashtable_delete` | O(1) | O(n) | Unlinks node; frees `ServiceInfo` fields |
| `hashtable_search` | O(n) | O(n) | Substring scan — intentional trade-off for CLI usability |
| `hashtable_resize` | — | O(n) | Triggered at load factor > 0.7; doubles capacity |

## Software engineering — module breakdown

| Module | Responsibility |
|--------|----------------|
| `hashtable.c` / `hashtable.h` | Core data structure — insert, lookup, delete, search, resize, introspection |
| `storage.c` | Serialize/deserialize hash table to `~/.syskin/services.json` |
| `scanner.c` | Walk systemd unit directories; populate table from `.service` files |
| `cli.c` | Parse commands, print help, wire user input to storage + table |
| `syskin.c` | Entry point — load persisted data, dispatch CLI, save on exit |

<div class="callout" markdown="1">

**Scan merge semantics:** the hardest SE challenge was making `scan` discover new services *without wiping* manually added `--extra` config paths. That required careful merge logic and several test iterations — not a one-line fix.

</div>

## Code spotlight {#fnv1a}

### Original hash — CS 300

```cpp
size_t hashKey(const string& key) const {
    // Simple sum-of-characters hash.
    unsigned long sum = 0;
    for (unsigned char ch : key) {
        sum += ch;
    }
    return sum % buckets_.size();
}
```

### Enhanced hash — FNV-1a with dynamic resize

```c
static uint32_t fnv1a_hash(const char *str) {
    uint32_t hash = 0x811C9DC5u;
    while (*str) {
        hash ^= (uint32_t)(*str++);
        hash *= 0x01000193u;
    }
    return hash;
}

static bool hashtable_resize(HashTable *ht) {
    if (hashtable_load_factor(ht) <= 0.7f) return true;
    size_t new_capacity = ht->capacity * 2;
    /* rehash all entries into new bucket array */
    ...
}
```

<div class="callout" markdown="1">

**Trade-off:** partial-match `lookup` uses an **O(n)** scan because substring search cannot use the hash index. I documented and accepted that cost for interactive admin usability.

</div>

### Public API surface

```c
HashTable *hashtable_create(size_t initial_capacity);
bool  hashtable_insert(HashTable *ht, const char *name, const ServiceInfo *info);
ServiceInfo *hashtable_lookup(const HashTable *ht, const char *name);
bool  hashtable_delete(HashTable *ht, const char *name);
void hashtable_search(const HashTable *ht, const char *query, ...);
float get_hashtable_load_factor(const HashTable *ht);
```

## Project layout

| Path | Purpose |
|------|---------|
| `src/hashtable.c` | FNV-1a hash table with resize, delete, search |
| `src/storage.c` | JSON persistence layer |
| `src/scanner.c` | systemd unit file discovery |
| `src/cli.c` | Command parsing and help text |
| `original_artifact/` | Original CS 300 C++ hash table |
| `tests/` | Unit tests for hash table and storage |

## Original artifact

The CS 300 submission lives in the repository for before/after comparison:

- [original_hash_table.cpp]({{ site.repo_url }}/blob/main/Software_Engineering_%26_DSA_Artifact/syskin/original_artifact/original_hash_table.cpp) — single-file C++ advising assistant with sum-of-characters hash
- [test.csv]({{ site.repo_url }}/blob/main/Software_Engineering_%26_DSA_Artifact/syskin/original_artifact/test.csv) — original course data file

## Run it locally

```bash
cd Software_Engineering_&_DSA_Artifact/syskin
make
make test
./syskin scan
./syskin lookup ssh
```

---

## Narratives

{% include_relative _narratives/milestone-two-se.md %}

{% include_relative _narratives/milestone-three-dsa.md %}

</div>