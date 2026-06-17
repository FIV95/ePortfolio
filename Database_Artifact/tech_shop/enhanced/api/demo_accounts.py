"""Demo shop accounts seeded in the database (original/seed_data.sql)."""

DEMO_ROLE_GROUPS = [
    {
        "role_key": "customer_service",
        "label": "Customer Service",
        "description": "Front desk — all repairs and customers, full contact info, can add notes.",
        "accounts": [
            {
                "username": "cs_jordan",
                "password": "cs123",
                "display_name": "Jordan",
            },
        ],
    },
    {
        "role_key": "tech",
        "label": "Technician",
        "description": "Baton-based repairs — claim a ticket, work it, drop it when done.",
        "accounts": [
            {
                "username": "tech_tom",
                "password": "pass123",
                "display_name": "Tom Miller",
            },
            {
                "username": "tech_sara",
                "password": "pass123",
                "display_name": "Sara Lee",
            },
            {
                "username": "tech_jake",
                "password": "pass123",
                "display_name": "Jake Wong",
            },
        ],
    },
    {
        "role_key": "admin",
        "label": "Administrator",
        "description": "Shop overview stats — all repairs, revenue, maintenance status.",
        "accounts": [
            {
                "username": "admin_mary",
                "password": "admin123",
                "display_name": "Mary",
            },
        ],
    },
    {
        "role_key": "auditor",
        "label": "Auditor",
        "description": "Read-only plus recent database change history.",
        "accounts": [
            {
                "username": "audit_alex",
                "password": "audit123",
                "display_name": "Alex",
            },
        ],
    },
]

DEMO_ACCOUNTS = [
    {
        "username": account["username"],
        "password": account["password"],
        "role": group["label"].lower() if group["role_key"] != "customer_service" else "customer service",
        "role_key": group["role_key"],
        "display_name": account["display_name"],
        "description": group["description"],
    }
    for group in DEMO_ROLE_GROUPS
    for account in group["accounts"]
]

RECOMMENDED_FIRST_STEPS = [
    "Open http://127.0.0.1:8000/app",
    "Pick a role type, then choose a user — password fills in automatically.",
    "Browse repairs, claim batons (technicians), or view customers (front desk).",
]