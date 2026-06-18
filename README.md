# CS 499 ePortfolio

**Student:** Lawrence Francis  
**Institution:** Southern New Hampshire University  
**Course:** CS 499 — Computer Science Capstone

**Live portfolio:** [https://fiv95.github.io/ePortfolio/](https://fiv95.github.io/ePortfolio/)

This repository contains my capstone artifacts, milestone narratives, and code review recordings for SNHU's ePortfolio assessment. The published GitHub Pages site in [`docs/`](docs/) presents the self-assessment, code reviews, enhanced artifacts, and narratives in a navigable visual format.

---

## Repository layout

| Path | Contents |
|------|----------|
| `Software_Engineering_&_DSA_Artifact/syskin/` | C service registry CLI — software engineering & data structures artifact |
| `Database_Artifact/tech_shop/` | PostgreSQL tech repair shop database with ops scripts and FastAPI web UI |
| `docs/` | GitHub Pages site (Jekyll) — self-assessment, artifacts, narratives |
| `Narratives/` | Milestone narrative documents (Word / ODT) for LMS submission |
| `Lawrence_Francis_CS499_*_code_review.mp4` | Recorded code review walkthroughs |

---

## First-time setup (any machine)

```bash
git clone https://github.com/FIV95/ePortfolio.git
cd ePortfolio
```

Local config files are not committed. Copy the examples and edit for your PostgreSQL user:

```bash
cp Database_Artifact/tech_shop/enhanced/ops/backup_config.env.example \
   Database_Artifact/tech_shop/enhanced/ops/backup_config.env

cp Database_Artifact/tech_shop/enhanced/api/.env.example \
   Database_Artifact/tech_shop/enhanced/api/.env
```

**macOS (Homebrew PostgreSQL):** if `psql` is not on your PATH, set `PG_BIN_DIR` in `backup_config.env`:

```bash
PG_BIN_DIR=/opt/homebrew/opt/postgresql@17/bin
```

**Linux / Arch:** leave `PG_BIN_DIR` empty and ensure `psql` is installed (`postgresql` package).

---

## Software Engineering & DSA — SysKin

A POSIX C application that scans systemd unit files and stores discovered services in a hash table backed by JSON persistence.

**Requirements:** `gcc`, `make`, Linux with systemd unit files under `/usr/lib/systemd/system`

```bash
cd "Software_Engineering_&_DSA_Artifact/syskin"
make          # build
make test     # run unit tests
make clean    # remove build artifacts
./syskin      # run the CLI
```

Data is stored at `~/.syskin/services.json` (portable across machines via the home directory).

---

## Database — Tech Repair Shop

A normalized PostgreSQL schema with security hardening, audit logging, baton workflow, and a role-scoped FastAPI front end.

**Requirements:** PostgreSQL 17+, Python 3.10+

```bash
cd Database_Artifact/tech_shop
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt

cd enhanced/ops
./setup_environment.sh --db tech_shop --fresh --skip-roles
./verify_environment.sh --db tech_shop

cd ../api
uvicorn main:app --reload
```

Open **http://127.0.0.1:8000/app** after starting the server. See `Database_Artifact/tech_shop/README.md` for full documentation, demo accounts, and schema details.

---

## Working across machines

This repo is designed to move between Linux and macOS:

- All build and ops scripts use **relative paths** — no hardcoded home directories.
- `backup_config.env` and `enhanced/api/.env` are **gitignored** — create them locally on each machine from the `.example` files.
- Build artifacts (`*.o`, binaries, `venv/`, DB backups) are gitignored.

After pulling on a new machine: copy the example configs, run `make test` in syskin, and `./verify_environment.sh` for the database.