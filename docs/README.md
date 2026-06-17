# GitHub Pages site

Jekyll-powered ePortfolio published from this folder.

## Enable GitHub Pages

1. Push `docs/` to `main` on [FIV95/ePortfolio](https://github.com/FIV95/ePortfolio)
2. Repository **Settings → Pages**
3. Source: **Deploy from branch** → `main` → **`/docs`**
4. Live URL: **https://fiv95.github.io/ePortfolio/**

## Local preview (optional)

```bash
cd docs
bundle install
bundle exec jekyll serve --baseurl "" 
```

Open http://127.0.0.1:4000/ (use `--baseurl "/ePortfolio"` to mirror production paths).

## Site map

| Page | File |
|------|------|
| Self-assessment | `index.md` |
| Code reviews | `code-review.md` |
| SysKin artifact | `syskin.md` |
| Tech Repair Shop | `tech-shop.md` |
| Milestone narratives | `_narratives/*.md` (included into artifact pages) |