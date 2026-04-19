# Hosted Documentation

`ACRouting` now includes a GitHub Pages publishing workflow for the DocC catalog.

## Canonical URL

The hosted documentation is meant to live at:

- `https://acrouting.acasto.dev`

The workflow publishes the DocC site from `main`, and the site root redirects to `documentation/acrouting/`.

## Workflow

The publishing pipeline lives in:

- `.github/workflows/docs.yml`

Current behavior:

- Triggers on pushes to `main`
- Can also be started manually with `workflow_dispatch`
- Builds the package documentation with `xcodebuild docbuild`
- Transforms the `.doccarchive` for static hosting with `xcrun docc process-archive transform-for-static-hosting`
- Uploads the generated static site to GitHub Pages

## One-Time Maintainer Setup

The repository owner still needs to do these one-time GitHub and DNS steps:

1. In GitHub, open `Settings > Pages` and set the source to `GitHub Actions`.
2. In the same Pages settings, set the custom domain to `acrouting.acasto.dev`.
3. In your DNS provider for `acasto.dev`, add a `CNAME` record from `acrouting` to `antoniocasto.github.io`.
4. Verify the `acasto.dev` domain in GitHub Pages for takeover protection.
5. Once GitHub provisions the certificate, enable HTTPS in Pages settings.

## Notes

- For GitHub Pages sites published from a custom GitHub Actions workflow, the custom domain is managed in repository settings. A committed `CNAME` file is ignored and is not required.
- The generated DocC site is intentionally built for root hosting on the custom domain. Treat `https://acrouting.acasto.dev` as the supported public URL.
- Until the custom domain is configured, the deployment artifact still builds correctly, but the default project Pages URL is not the canonical access path for this setup.
