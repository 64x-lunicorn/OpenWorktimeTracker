# OpenWorktimeTracker Documentation

Documentation site for OpenWorktimeTracker, built with [Astro](https://astro.build) and [Starlight](https://starlight.astro.build).

## Development

```bash
cd docs
npm install
npm run dev        # Start dev server at localhost:4321
npm run build      # Build production site to ./dist/
npm run preview    # Preview production build locally
```

## Structure

```
src/content/docs/
  getting-started/   -- Installation guide
  features/          -- Feature overview, data format
  architecture/      -- State machine, CI/CD, system overview
  configuration/     -- Settings reference
  development/       -- Build instructions, contributing guide
```

## Deployment

The site is automatically deployed to GitHub Pages via the `docs.yml` GitHub Actions workflow on pushes to `main` that affect the `docs/` directory.
