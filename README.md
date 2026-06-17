# CS 499 ePortfolio

**Student:** Lawrence Francis  
**Institution:** Southern New Hampshire University  
**Course:** CS 499 — Computer Science Capstone

This repository contains my capstone artifacts, milestone narratives, and code review recordings for SNHU's ePortfolio assessment.

---

## Repository layout

| Path | Contents |
|------|----------|
| `Software_Engineering_&_DSA_Artifact/syskin/` | C service registry CLI — software engineering & data structures artifact |
| `Database_Artifact/tech_shop/` | PostgreSQL tech repair shop database with ops scripts and FastAPI web UI |
| `Narritives/` | Milestone narrative documents (Word / ODT) |
| `Lawrence_Francis_CS499_*_code_review.mp4` | Recorded code review walkthroughs |

---

## Software Engineering & DSA — Syskin

A POSIX C application that scans systemd unit files and stores discovered services in a hash table backed by JSON persistence.

**Requirements:** `gcc`, `make`

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

**Requirements:** PostgreSQL, Python 3.10+

```bash
cd Database_Artifact/tech_shop
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt

cd enhanced/ops
./setup_environment.sh --db tech_shop --fresh --skip-roles
./verify_environment.sh --db tech_shop

cd ../api
uvicorn main:app --reload
```

Open **http://127.0.0.1:8000/app** after starting the server. See `Database_Artifact/tech_shop/README.md` for full documentation, demo accounts, and schema details.

---

## Cloning on a new machine

```bash
git clone https://github.com/FIV95/ePortfolio.git
cd ePortfolio
```

All paths in this repo are relative — no hardcoded home-directory references in build scripts or project code. Configure database connection settings in `Database_Artifact/tech_shop/enhanced/ops/backup_config.env` for your local PostgreSQL instance.