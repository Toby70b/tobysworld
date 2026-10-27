# Architecture map: brief for Claude Code

## Goal

`site/cloud-architecture.html` draws an interactive map of my personal AWS
infrastructure. Everything on it comes from `site/architecture.yaml`.

Your job is to work out what infrastructure is **actually deployed** and keep
that YAML accurate. Do not redesign the page.

This brief covers two ways of being asked:

- **By hand** — I point you at one or more repos and ask you to reconcile the map.
- **From CI** — a push to a repo's Terraform fires a workflow here, and the
  changed repo is checked out at `./_source`. Same job, narrower scope: update
  the map to match what changed, and open a PR.

## Repo layout

```
site/cloud-architecture.html   the page; YAML and icons are baked in
site/architecture.yaml         the source of truth for the map
scripts/sync_page.py           copies the YAML into the page
scripts/check_architecture.py  validates; exits non-zero
scripts/build_icons.py         inlines assets/icons/*.svg into the page
assets/icons/                  official AWS artwork + SOURCES.md
terraform/                     hosting for this site; not described by the map
```

## Output

1. Edit `site/architecture.yaml`. Never hand-edit the copy embedded in the page.
2. Run `python scripts/sync_page.py`.
3. Run `python scripts/check_architecture.py`. It must pass.
4. Finish with a short report covering:
   - what you added, changed and removed;
   - every edge you inferred rather than read directly, and why;
   - anything you weren't sure counts as deployed.

Leave `data-yaml-src=""` on the `<html>` tag alone.

## Scope rules

- **Personal repos only.** Nothing from my employer's codebases. Check private
  repos too — `gh repo list` without `--visibility public` — because the map has
  been wrong before by only looking at public ones.
- **Deployed only.** A resource defined in Terraform counts as deployed if it's
  applied.
  - If you can run `terraform state list` in a repo, use it.
  - If you can't, treat the resources defined in Terraform as deployed, but list
    them in the report for me to confirm.
  - DNS is a decent free check: if a stack's record doesn't resolve, it probably
    hasn't been applied.
- **Not deployed yet (leave out unless the code proves otherwise):**
  - Steam wishlist budget tool (`wishlist-basket` — the Terraform directory is empty)
  - Lambda error-alerting pipeline (`aws-projects/lambda-error-reporter`)
  - Typesense on ECS for the Steam search tool
  - Anything from the old Steam Group Game Checker (`SGGC_WS`, `SGGC_UI`,
    `sggc-aws-lambda`). Its domain no longer resolves.
- **Leave out plumbing that adds noise:**
  - IAM roles and policies
  - log groups
  - Terraform state buckets and lock tables
  - Lambda layers
  - Route 53 records (mention them in the zone's `description` instead)
  - ACM certificates, origin access controls, bucket policies, public access
    blocks, response headers policies
- **Dead-letter queues:** don't draw them as nodes. Mention them in the parent
  queue's `description`.

## YAML schema

```yaml
title: Cloud architecture
owner: Toby

projects:
  - id: game-repository          # kebab-case, letters/digits/hyphens only (used as a URL #hash)
    name: Steam game repository
    colour: "#3A6FD8"            # keep existing colours; pick distinct ones for new projects
    repo: https://github.com/...
    description: One sentence on what the project does for the user.

resources:
  - id: games-import             # unique, kebab-case
    type: lambda                 # see type list below
    name: Games import           # short human name, not the AWS resource name
    projects: [game-repository]  # one or more project ids; the first decides which band it sits in
    description: What it does, in one or two plain sentences.
    kind: ""                     # optional: overrides the type label under the icon
    status: deployed             # optional: deployed | planned (planned is drawn dashed)
    col: 3                       # optional: force a column; only use if the auto layout is wrong

connections:
  - { from: games-import, to: games-table, label: writes }
```

### Conventions

- Connections run in the direction data or control flows. Labels are a short
  verb: `invokes`, `writes`, `reads`, `updates`, `stream`, `publishes`,
  `subscribes`, `triggers`, `stores`, `downloads`, `serves from`, `routes to`.
- External services (third-party APIs, CDNs, GitHub) use `type: external`.
  Steam uses `type: steam`. Tag them with each project that calls them.
- A resource shared by several projects lists all of them in `projects`. This is
  how a cross-repo seam gets drawn — see the SNS topic below.
- Use British spelling in names and descriptions. Use ’ for apostrophes in
  visible text.
- Don't put account IDs, ARNs or secrets in ids, names or descriptions. Domain
  names are fine.

## Supported types

| YAML `type` | Terraform resources |
|---|---|
| `eventbridge-schedule` | `aws_scheduler_schedule`, `aws_cloudwatch_event_rule` with `schedule_expression` |
| `lambda` | `aws_lambda_function` |
| `s3` | `aws_s3_bucket` |
| `dynamodb` | `aws_dynamodb_table` |
| `sqs` | `aws_sqs_queue` |
| `sns` | `aws_sns_topic` |
| `cloudfront` | `aws_cloudfront_distribution` |
| `route53` | `aws_route53_zone` |
| `ssm-parameter` | `aws_ssm_parameter` |
| `ecs` | `aws_ecs_service` |
| `api-gateway` | `aws_api_gateway_rest_api`, `aws_apigatewayv2_api` |
| `cloudwatch-logs` | only when a log group is wired into a flow (e.g. a subscription filter) |
| `steam` | Steam's API or CDN |
| `external` | other third-party APIs found in code or config |
| `github` | GitHub Actions or repos that take part in a flow |

### Adding a new type

Always add an entry to `TYPES` in the page's script, with its `label` and a
`cat` from: `compute`, `storage`, `database`, `integration`, `network`, `mgmt`,
`external`.

Then give it artwork, by one of two routes:

- **An AWS service** — take the 64px SVG from the official AWS Architecture
  Icons package, save it as `assets/icons/<type>.svg`, and run
  `python scripts/build_icons.py`. The filename stem must equal the YAML `type`
  exactly, or the lookup silently misses. Don't hand-draw AWS icons, and don't
  edit the generated `ICONS` map in the page. See `assets/icons/SOURCES.md`.
- **Anything else** — add a white-stroke glyph to `GLYPHS`, on a 24×24 viewBox
  in the same style as the existing ones. It renders on a category-coloured tile.

`check_architecture.py` fails if a type has artwork in neither map, so a
misnamed file breaks the build rather than rendering a grey box.

Don't change anything else in the rendering code.

## Where edges come from

| Source | Edge |
|---|---|
| Scheduler / event rule targets (`aws_scheduler_schedule.target`, `aws_cloudwatch_event_target`) | schedule → target, `invokes` |
| `aws_lambda_event_source_mapping` | SQS queue or DynamoDB stream → function, `triggers` / `stream` |
| `aws_sns_topic_subscription` | topic → endpoint, `subscribes`. Often crosses repos — the topic is declared in one and read with a `data` source in another |
| `aws_s3_bucket_notification` | bucket → target, `notifies` |
| `aws_pipes_pipe` | source → target, with the hop labelled |
| CloudFront `origin` blocks | distribution → S3 bucket or load balancer, `serves from` |
| Route 53 alias records | zone → CloudFront or load balancer, `routes to` |
| IAM policy actions plus Lambda env vars naming a table, bucket, topic or parameter | function → resource. Label by action: `PutItem`/`PutObject`/`Publish` → `writes` / `stores` / `publishes`; `GetItem`/`Query`/`GetObject` → `reads`; both → `updates` |
| HTTP clients and base URLs in Lambda/app code (e.g. `api.steampowered.com`, Steam CDN hosts) | function → external, with a label for what it fetches |

Call out every IAM-derived or code-derived edge in the report, because they're
inferences.

## What's on the map now

Four projects, nineteen resources.

**Steam game repository** (`game-repository`) — a scheduled import pulls changed
Steam apps into DynamoDB; the table's stream feeds a publisher Lambda that fans
changes out to SNS; a second schedule exports the table to S3 nightly. Two SSM
parameters hold the API key and the import watermark.

**Does it have fall damage** (`fall-damage`) — subscribes to that SNS topic over
SQS, downloads each game's capsule art from Steam's CDN, stores it in S3 and
serves it from CloudFront at `cdn.tobypeel.com`.

**Personal domain** (`personal-domain`) — the `tobypeel.com` zone, with a
wildcard certificate both CloudFront distributions share.

**Architecture map** (`architecture-map`) — this page, on S3 behind CloudFront at
`architecture.tobypeel.com`.

The SNS topic `game-events` is the seam: declared in `game-repository`, consumed
by `fall-damage`, and tagged with both so the edge is drawn across the boundary.

## Checks before you finish

- `python scripts/check_architecture.py` passes. It covers the YAML parsing,
  every `from`/`to` and project tag, missing artwork, and whether the embedded
  copy is in sync.
- No resource ids or names that expose account IDs, ARNs or secrets.
- If you added a type, the icon actually renders — a grey box means the filename
  didn't match.
