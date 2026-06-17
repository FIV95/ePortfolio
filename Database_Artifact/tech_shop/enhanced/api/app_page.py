from fastapi.responses import HTMLResponse


def render_app_page() -> HTMLResponse:
    html = f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="utf-8">
        <title>Tech Repair Shop</title>
        <style>
            body {{ font-family: system-ui, sans-serif; margin: 0; background: #f6f8fb; color: #1a1a1a; }}
            header {{ background: #0b5fff; color: white; padding: 1rem 1.5rem; }}
            main {{ max-width: 1100px; margin: 1.5rem auto; padding: 0 1rem 2rem; }}
            .card {{ background: white; border-radius: 10px; padding: 1.25rem; margin-bottom: 1rem;
                      box-shadow: 0 1px 4px rgba(0,0,0,.08); }}
            label {{ display: block; margin-bottom: 0.35rem; font-weight: 600; }}
            select, button, textarea {{ font: inherit; }}
            select, button {{ padding: 0.55rem 0.8rem; border-radius: 6px; border: 1px solid #ccc; }}
            button {{ background: #0b5fff; color: white; border: none; cursor: pointer; }}
            button.secondary {{ background: #eef3ff; color: #0b5fff; }}
            button.tab {{ background: #eef3ff; color: #0b5fff; margin-right: 0.35rem; }}
            button.tab.active {{ background: #0b5fff; color: white; }}
            table {{ width: 100%; border-collapse: collapse; }}
            th, td {{ padding: 0.65rem; border-bottom: 1px solid #eee; text-align: left; vertical-align: top; }}
            th {{ background: #f8faff; }}
            tr.clickable {{ cursor: pointer; }}
            tr.clickable:hover {{ background: #f0f6ff; }}
            tr.selected {{ background: #e8f0ff; }}
            .badge {{ display: inline-block; padding: 0.15rem 0.5rem; border-radius: 999px; font-size: 0.85rem;
                       background: #eef3ff; }}
            .cards {{ display: flex; gap: 1rem; flex-wrap: wrap; margin-top: 0.75rem; }}
            .stat {{ background: #f8faff; border-radius: 8px; padding: 0.85rem 1rem; min-width: 140px; }}
            .stat strong {{ display: block; font-size: 1.35rem; margin-top: 0.2rem; }}
            .hidden {{ display: none; }}
            .muted {{ color: #666; }}
            .error {{ color: #b00020; }}
            #detail pre {{ white-space: pre-wrap; background: #f8f8f8; padding: 0.75rem; border-radius: 6px; }}
        </style>
    </head>
    <body>
        <header>
            <h1 style="margin:0;">Tech Repair Shop</h1>
            <p style="margin:0.35rem 0 0; opacity:.9;">No SQL needed — pick an account, view repairs, read notes.</p>
        </header>
        <main>
            <section class="card" id="login-card">
                <h2 style="margin-top:0;">Sign in</h2>
                <p class="muted">Pick a role type, then choose a user. Password fills in automatically.</p>
                <label for="role-type">Role</label>
                <select id="role-type" style="width:100%; max-width:360px; margin-bottom:0.75rem;">
                    <option value="">Loading roles...</option>
                </select>
                <p class="muted" id="role-description" style="margin:0 0 0.75rem;"></p>
                <label for="account">User</label>
                <select id="account" style="width:100%; max-width:360px; margin-bottom:0.75rem;" disabled>
                    <option value="">Select a role first</option>
                </select>
                <button id="login-btn" disabled>Sign in</button>
                <span id="login-error" class="error"></span>
            </section>

            <section class="card hidden" id="role-panel">
                <h2 id="role-panel-title" style="margin-top:0;"></h2>
                <p class="muted hidden" id="role-panel-message"></p>
                <div class="cards" id="role-panel-cards"></div>
                <div id="role-panel-extra"></div>
            </section>

            <section class="card hidden" id="dashboard">
                <div style="display:flex; justify-content:space-between; align-items:center; gap:1rem; flex-wrap:wrap;">
                    <div>
                        <h2 style="margin:0;" id="dashboard-title">Repairs</h2>
                        <p class="muted" id="welcome-text" style="margin:0.35rem 0 0;"></p>
                    </div>
                    <div>
                        <span id="view-tabs" class="hidden">
                            <button class="tab active" id="tab-repairs">Repairs</button>
                            <button class="tab" id="tab-customers">Customers</button>
                        </span>
                        <button class="secondary hidden" id="repair-scope-btn" style="margin-left:0.5rem;"></button>
                        <button class="secondary" id="logout-btn" style="margin-left:0.5rem;">Sign out</button>
                    </div>
                </div>
                <div id="tech-bucket-tabs" class="hidden" style="margin-top:0.75rem;">
                    <button class="tab active" data-bucket="queue">Work queue</button>
                    <button class="tab" data-bucket="holding">Holding baton</button>
                    <button class="tab" data-bucket="available">Available</button>
                    <button class="tab" data-bucket="my_open">My open</button>
                    <button class="tab" data-bucket="my_closed">My closed</button>
                </div>
                <p class="muted" id="repairs-hint" style="margin-top:0.75rem;">Click a row to see full details and notes.</p>
                <table id="repairs-table">
                    <thead>
                        <tr id="repairs-head-row">
                            <th>ID</th><th>Status</th><th id="baton-col" class="hidden">Baton</th>
                            <th>Customer</th><th>Device</th>
                            <th>Issue</th><th>Cost</th><th>Notes</th>
                        </tr>
                    </thead>
                    <tbody id="repairs-body"></tbody>
                </table>
                <table id="customers-table" class="hidden">
                    <thead>
                        <tr>
                            <th>Name</th><th>Email</th><th>Phone</th><th>Loyalty pts</th>
                        </tr>
                    </thead>
                    <tbody id="customers-body"></tbody>
                </table>
            </section>

            <section class="card hidden" id="detail">
                <button class="secondary" id="close-detail">← Back to list</button>
                <h2 id="detail-title" style="margin-top:1rem;"></h2>
                <div id="detail-body"></div>
                <div id="baton-panel" style="margin:1rem 0;"></div>
                <h3>Notes</h3>
                <div id="notes-list" class="muted">No notes yet.</div>
                <div id="note-form">
                    <h3>Add a note</h3>
                    <textarea id="note-text" rows="3" style="width:100%; margin-bottom:0.5rem;"
                        placeholder="Type an update for this repair..."></textarea>
                    <select id="note-type" style="margin-right:0.5rem;">
                        <option>GENERAL</option><option>PROGRESS</option><option>CUSTOMER</option>
                        <option>PARTS</option><option>RESOLUTION</option>
                    </select>
                    <button id="add-note-btn">Save note</button>
                    <span id="note-error" class="error"></span>
                </div>
                <p class="muted hidden" id="note-locked-msg">Claim the baton to add notes on this repair.</p>
            </section>
        </main>
        <script>
            let token = localStorage.getItem('trs_token') || '';
            let selectedRepairId = null;
            let currentRole = '';
            let roleGroups = [];
            let repairScope = 'all';
            let repairBucket = 'queue';

            const TECH_BUCKET_HINTS = {{
                queue: 'Tickets you hold plus open tickets available to claim.',
                holding: 'Repairs you are actively working (you hold the baton).',
                available: 'Open repairs with no baton — grab one to start.',
                my_open: 'Open repairs you have worked on before.',
                my_closed: 'Closed repairs you have worked on before.',
            }};

            const $ = (id) => document.getElementById(id);

            async function api(path, options = {{}}) {{
                const res = await fetch(path, {{
                    ...options,
                    headers: {{
                        'Content-Type': 'application/json',
                        ...(token ? {{ Authorization: 'Bearer ' + token }} : {{}}),
                        ...(options.headers || {{}}),
                    }},
                }});
                const data = await res.json().catch(() => ({{}}));
                if (!res.ok) throw new Error(data.message || data.detail || 'Request failed');
                return data;
            }}

            function show(el) {{ el.classList.remove('hidden'); }}
            function hide(el) {{ el.classList.add('hidden'); }}

            function renderCards(cards) {{
                $('role-panel-cards').innerHTML = (cards || []).map((c) => `
                    <div class="stat"><span class="muted">${{c.label}}</span><strong>${{c.value}}</strong></div>
                `).join('');
            }}

            async function loadRoleOverview() {{
                const data = await api('/quick/role-overview');
                currentRole = data.role;
                $('role-panel-title').textContent = data.title;
                const msg = $('role-panel-message');
                if (data.message) {{
                    msg.textContent = data.message;
                    show(msg);
                }} else {{
                    hide(msg);
                }}
                renderCards(data.cards);
                const extra = $('role-panel-extra');
                extra.innerHTML = '';

                if (data.role === 'auditor' && data.items?.length) {{
                    extra.innerHTML = `
                        <h3 style="margin-top:1rem;">Latest changes</h3>
                        <table>
                            <tr><th>When</th><th>Table</th><th>Action</th><th>By</th></tr>
                            ${{data.items.map(i => `
                                <tr>
                                    <td>${{i.changed_at || '—'}}</td>
                                    <td>${{i.table_name}}</td>
                                    <td>${{i.action_type}}</td>
                                    <td>${{i.changed_by || '—'}}</td>
                                </tr>`).join('')}}
                        </table>
                        <p class="muted" style="margin-top:0.5rem;">These are the five most recent database changes.</p>`;
                }}

                if (data.role === 'admin') {{
                    extra.innerHTML = `
                        <button class="secondary" id="show-revenue-btn" style="margin-top:0.75rem;">Show monthly revenue</button>
                        <div id="revenue-panel" class="hidden" style="margin-top:0.75rem;"></div>`;
                    $('show-revenue-btn').onclick = async () => {{
                        const rev = await api('/quick/monthly-revenue');
                        const panel = $('revenue-panel');
                        panel.innerHTML = rev.results?.length
                            ? `<table><tr><th>Month</th><th>Repairs</th><th>Revenue</th></tr>
                                ${{rev.results.slice(0, 6).map(r => `
                                    <tr><td>${{r.month}}</td><td>${{r.repair_count}}</td><td>$${{r.total_revenue}}</td></tr>
                                `).join('')}}</table>`
                            : '<span class="muted">No revenue data yet.</span>';
                        show(panel);
                    }};
                }}

                if (data.role === 'customer_service') {{
                    show($('view-tabs'));
                }} else {{
                    hide($('view-tabs'));
                }}
                show($('role-panel'));
            }}

            function setTechBucket(bucket) {{
                repairBucket = bucket;
                document.querySelectorAll('#tech-bucket-tabs .tab').forEach((btn) => {{
                    btn.classList.toggle('active', btn.dataset.bucket === bucket);
                }});
                const titles = {{
                    queue: 'Work queue',
                    holding: 'Holding baton',
                    available: 'Available to claim',
                    my_open: 'My open history',
                    my_closed: 'My closed history',
                }};
                $('dashboard-title').textContent = titles[bucket] || 'Repairs';
                $('repairs-hint').textContent =
                    (TECH_BUCKET_HINTS[bucket] || '') + ' Click a row for details.';
                loadRepairs();
            }}

            function updateRepairScopeUi() {{
                const btn = $('repair-scope-btn');
                const bucketTabs = $('tech-bucket-tabs');
                const batonCol = $('baton-col');
                if (currentRole === 'tech') {{
                    hide(btn);
                    show(bucketTabs);
                    show(batonCol);
                    setTechBucket(repairBucket);
                    return;
                }}
                hide(bucketTabs);
                hide(batonCol);
                if (currentRole === 'customer_service') {{
                    show(btn);
                    if (repairScope === 'all') {{
                        $('dashboard-title').textContent = 'Repairs';
                        $('repairs-hint').textContent =
                            'All shop repairs. Click a row for details and notes.';
                        btn.textContent = 'Show open only';
                    }} else {{
                        $('dashboard-title').textContent = 'Open repairs';
                        $('repairs-hint').textContent =
                            'Repairs that still need attention. Click a row for details and notes.';
                        btn.textContent = 'Show all repairs';
                    }}
                }} else {{
                    hide(btn);
                    $('dashboard-title').textContent = 'Repairs';
                    $('repairs-hint').textContent = 'Click a row to see full details and notes.';
                }}
            }}

            function configureRepairScope(role) {{
                currentRole = role;
                if (role === 'tech') {{
                    repairBucket = 'queue';
                }} else if (role === 'customer_service') {{
                    repairScope = 'all';
                }} else {{
                    repairScope = 'all';
                }}
                updateRepairScopeUi();
            }}

            function showRepairsView() {{
                $('tab-repairs').classList.add('active');
                $('tab-customers').classList.remove('active');
                show($('repairs-table'));
                hide($('customers-table'));
                updateRepairScopeUi();
            }}

            function showCustomersView() {{
                $('tab-customers').classList.add('active');
                $('tab-repairs').classList.remove('active');
                $('dashboard-title').textContent = 'Customers';
                hide($('repairs-table'));
                show($('customers-table'));
                hide($('repairs-hint'));
                loadCustomers();
            }}

            function populateRoleTypes() {{
                const roleSelect = $('role-type');
                roleSelect.innerHTML = '<option value="">Select a role...</option>';
                roleGroups.forEach((group) => {{
                    const opt = document.createElement('option');
                    opt.value = group.role_key;
                    opt.textContent = group.label;
                    roleSelect.appendChild(opt);
                }});
                roleSelect.disabled = false;
            }}

            function populateUsers(roleKey) {{
                const accountSelect = $('account');
                const loginBtn = $('login-btn');
                const group = roleGroups.find((g) => g.role_key === roleKey);
                accountSelect.innerHTML = '';
                $('role-description').textContent = group ? group.description : '';

                if (!group || !group.accounts.length) {{
                    accountSelect.innerHTML = '<option value="">No users for this role</option>';
                    accountSelect.disabled = true;
                    loginBtn.disabled = true;
                    return;
                }}

                group.accounts.forEach((account) => {{
                    const opt = document.createElement('option');
                    opt.value = account.username + '|' + account.password;
                    opt.textContent = account.display_name + ' (' + account.username + ')';
                    accountSelect.appendChild(opt);
                }});
                accountSelect.disabled = false;
                loginBtn.disabled = false;
            }}

            async function loadLoginOptions() {{
                try {{
                    const data = await api('/auth/demo-accounts');
                    roleGroups = data.role_groups || [];
                    populateRoleTypes();
                    if (roleGroups.length) {{
                        $('role-type').value = roleGroups[0].role_key;
                        populateUsers(roleGroups[0].role_key);
                    }}
                }} catch (err) {{
                    $('login-error').textContent = 'Could not load demo accounts.';
                }}
            }}

            async function login() {{
                const [username, password] = $('account').value.split('|');
                if (!username || !password) {{
                    $('login-error').textContent = 'Pick a role and user first.';
                    return;
                }}
                $('login-error').textContent = '';
                try {{
                    const data = await api('/auth/login', {{
                        method: 'POST',
                        body: JSON.stringify({{ username, password }}),
                    }});
                    token = data.access_token;
                    localStorage.setItem('trs_token', token);
                    const group = roleGroups.find((g) => g.role_key === data.user.role);
                    const roleLabel = group ? group.label : data.user.role;
                    $('welcome-text').textContent = 'Signed in as ' + data.user.username + ' (' + roleLabel + ')';
                    hide($('login-card'));
                    show($('dashboard'));
                    configureRepairScope(data.user.role);
                    showRepairsView();
                    await loadRoleOverview();
                    await loadRepairs();
                }} catch (err) {{
                    $('login-error').textContent = err.message;
                }}
            }}

            function logout() {{
                token = '';
                currentRole = '';
                localStorage.removeItem('trs_token');
                hide($('role-panel'));
                hide($('dashboard'));
                hide($('detail'));
                hide($('view-tabs'));
                show($('login-card'));
            }}

            function repairsEndpoint() {{
                if (currentRole === 'tech') {{
                    return '/quick/repairs?bucket=' + repairBucket;
                }}
                if (repairScope === 'active') {{
                    return '/quick/open-repairs';
                }}
                return '/quick/repairs';
            }}

            function batonCell(r) {{
                if (r.baton_available) return '<span class="badge">Available</span>';
                if (r.baton_holder) return '<span class="badge">' + r.baton_holder + '</span>';
                return '<span class="muted">—</span>';
            }}

            async function loadRepairs() {{
                const data = await api(repairsEndpoint());
                const tbody = $('repairs-body');
                const colSpan = currentRole === 'tech' ? 8 : 7;
                tbody.innerHTML = '';
                if (!data.results.length) {{
                    tbody.innerHTML = '<tr><td colspan="' + colSpan + '" class="muted">No repairs to show.</td></tr>';
                    return;
                }}
                data.results.forEach((r) => {{
                    const repairId = r.repair_id ?? r.id;
                    const tr = document.createElement('tr');
                    tr.className = 'clickable';
                    const batonTd = currentRole === 'tech' ? '<td>' + batonCell(r) + '</td>' : '';
                    tr.innerHTML =
                        '<td><strong>#' + repairId + '</strong></td>' +
                        '<td><span class="badge">' + r.status + '</span></td>' +
                        batonTd +
                        '<td>' + (r.customer_name || '—') + '</td>' +
                        '<td>' + (r.device || '—') + '</td>' +
                        '<td>' + (r.issue_description || '—') + '</td>' +
                        '<td>$' + (r.total_cost ?? '0.00') + '</td>' +
                        '<td>' + (r.note_count ?? 0) + '</td>';
                    tr.onclick = () => openDetail(repairId);
                    tbody.appendChild(tr);
                }});
            }}

            function toggleRepairScope() {{
                repairScope = repairScope === 'active' ? 'all' : 'active';
                updateRepairScopeUi();
                if (currentRole !== 'tech') loadRepairs();
            }}

            async function claimBaton(repairId) {{
                await api('/repairs/' + repairId + '/baton/claim', {{ method: 'POST' }});
                await openDetail(repairId);
                await loadRepairs();
            }}

            async function dropBaton(repairId) {{
                await api('/repairs/' + repairId + '/baton/drop', {{ method: 'POST' }});
                await openDetail(repairId);
                await loadRepairs();
            }}

            async function loadCustomers() {{
                const data = await api('/quick/customers');
                const tbody = $('customers-body');
                tbody.innerHTML = '';
                data.results.forEach((c) => {{
                    const tr = document.createElement('tr');
                    tr.innerHTML = `
                        <td>${{c.first_name}} ${{c.last_name}}</td>
                        <td>${{c.email || '—'}}</td>
                        <td>${{c.phone || '—'}}</td>
                        <td>${{c.loyalty_points ?? 0}}</td>`;
                    tbody.appendChild(tr);
                }});
            }}

            function renderBatonPanel(repairId, baton) {{
                const panel = $('baton-panel');
                if (!baton) {{ panel.innerHTML = ''; return; }}
                let html = '<p><strong>Baton:</strong> ';
                if (baton.i_hold_baton) html += 'You are working this ticket';
                else if (baton.available) html += 'Available — no one is working it';
                else html += (baton.holder || 'Another technician') + ' is working it';
                if (baton.claimed_at) html += ' <span class="muted">(since ' + baton.claimed_at + ')</span>';
                html += '</p><div>';
                if (baton.can_claim) {{
                    html += '<button id="claim-baton-btn">Grab baton</button> ';
                }}
                if (baton.can_drop) {{
                    html += '<button class="secondary" id="drop-baton-btn">Drop baton</button>';
                }}
                html += '</div>';
                panel.innerHTML = html;
                if (baton.can_claim) $('claim-baton-btn').onclick = () => claimBaton(repairId);
                if (baton.can_drop) $('drop-baton-btn').onclick = () => dropBaton(repairId);
            }}

            async function openDetail(repairId) {{
                selectedRepairId = repairId;
                const data = await api('/quick/repairs/' + repairId);
                const r = data.repair;
                const baton = data.baton || {{}};
                $('detail-title').textContent = 'Repair #' + repairId;
                $('detail-body').innerHTML = `
                    <p><strong>Status:</strong> ${{r.status}} &nbsp; <strong>Priority:</strong> ${{r.priority || '—'}}</p>
                    <p><strong>Customer:</strong> ${{r.customer_name || '—'}}</p>
                    <p><strong>Device:</strong> ${{r.device || '—'}}</p>
                    <p><strong>Issue:</strong> ${{r.issue_description || '—'}}</p>
                    <p><strong>Assigned tech:</strong> ${{r.technician || '—'}}</p>
                    <p><strong>Cost:</strong> $${{r.total_cost ?? '0.00'}}</p>`;
                renderBatonPanel(repairId, baton);
                const notes = data.notes || [];
                $('notes-list').innerHTML = notes.length
                    ? notes.map(n => `<div style="margin-bottom:0.75rem;"><strong>${{n.note_type}}</strong> — ${{n.note_text}}
                        <div class="muted">${{n.created_by || ''}} · ${{n.created_at || ''}}</div></div>`).join('')
                    : '<span class="muted">No notes yet.</span>';
                if (baton.can_add_note) {{
                    show($('note-form'));
                    hide($('note-locked-msg'));
                }} else {{
                    hide($('note-form'));
                    show($('note-locked-msg'));
                }}
                hide($('role-panel'));
                hide($('dashboard'));
                show($('detail'));
            }}

            async function addNote() {{
                $('note-error').textContent = '';
                try {{
                    await api('/repairs/' + selectedRepairId + '/notes', {{
                        method: 'POST',
                        body: JSON.stringify({{
                            note_text: $('note-text').value,
                            note_type: $('note-type').value,
                        }}),
                    }});
                    $('note-text').value = '';
                    await openDetail(selectedRepairId);
                }} catch (err) {{
                    $('note-error').textContent = err.message;
                }}
            }}

            $('role-type').onchange = () => populateUsers($('role-type').value);
            $('repair-scope-btn').onclick = toggleRepairScope;
            document.querySelectorAll('#tech-bucket-tabs .tab').forEach((btn) => {{
                btn.onclick = () => setTechBucket(btn.dataset.bucket);
            }});
            $('login-btn').onclick = login;
            $('logout-btn').onclick = logout;
            loadLoginOptions();
            $('close-detail').onclick = () => {{
                hide($('detail'));
                show($('role-panel'));
                show($('dashboard'));
                if (currentRole === 'customer_service' && $('tab-customers').classList.contains('active')) {{
                    showCustomersView();
                }} else {{
                    showRepairsView();
                }}
            }};
            $('add-note-btn').onclick = addNote;
            $('tab-repairs').onclick = showRepairsView;
            $('tab-customers').onclick = showCustomersView;

            if (token) {{
                hide($('login-card'));
                show($('dashboard'));
                api('/auth/me').then(async (u) => {{
                    $('welcome-text').textContent = 'Signed in as ' + u.username + ' (' + u.role + ')';
                    configureRepairScope(u.role);
                    showRepairsView();
                    await loadRoleOverview();
                    return loadRepairs();
                }}).catch(logout);
            }}
        </script>
    </body>
    </html>
    """
    return HTMLResponse(content=html)