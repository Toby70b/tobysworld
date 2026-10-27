# Architecture map: brief for Claude Code

## Goal

`cloud-architecture.html` is a self-contained page that draws an interactive map of my personal AWS infrastructure. Everything on the map comes from the YAML block embedded at the bottom of the file (`<script type="text/yaml" id="architecture">`).

Your job is to read the repos in this folder, work out what infrastructure is **actually deployed**, and update that YAML so the map is accurate. Do not redesign the page.

## Folder layout

```
./cloud-architecture.html   the page (YAML embedded at the bottom)
./<repo-a>/                 cloned personal repos, one per project
./<repo-b>/
```

## Output

1. Update the embedded YAML in `cloud-architecture.html`.
2. Write the same YAML to `./architecture.yaml` so it can be hosted alongside the page later. The two must stay identical.
3. Leave `data-yaml-src=""` on the `<html>` tag unchanged. I'll set it when I host the page.
4. Finish with a short report covering:
   - what you added, changed and removed;
   - every edge you inferred rather than read directly, and why;
   - anything you weren't sure counts as deployed.

## Scope rules

- **Personal repos only.** Nothing from my employer's codebases.
- **Deployed only.** A resource defined in Terraform counts as deployed if it's applied.
  - If you can run `terraform state list` in a repo, use it.
  - If you can't, treat the resources defined in Terraform as deployed, but list them in the report for me to confirm.
- **Not deployed yet (leave out unless the code proves otherwise):**
  - Steam wishlist budget tool
  - Lambda error-alerting pipeline
  - Typesense on ECS for the Steam search tool
- **Leave out plumbing that adds noise:**
  - IAM roles and policies
  - log groups
  - Terraform state buckets and lock tables
  - Lambda layers
  - Route 53 records (mention them in the zone's `description` instead)
- **Dead-letter queues:** don't draw them as nodes. Mention them in the parent queue's `description`.

## YAML schema

```yaml
title: Cloud architecture
owner: Toby

projects:
  - id: steam-search            # kebab-case, letters/digits/hyphens only (used as a URL #hash)
    name: Steam game search
    colour: "#3A6FD8"           # keep existing colours; pick distinct ones for new projects
    repo: https://github.com/...
    description: One sentence on what the project does for the user.

resources:
  - id: catalog-fetcher         # unique, kebab-case
    type: lambda                # see type list below
    name: Catalogue fetcher     # short human name, not the AWS resource name
    projects: [steam-search]    # one or more project ids; the first decides which band it sits in
    description: What it does, in one or two plain sentences.
    kind: ""                    # optional: overrides the type label under the icon
    status: deployed            # optional: deployed | planned (planned is drawn dashed)
    col: 3                      # optional: force a column; only use if the auto layout is wrong

connections:
  - { from: catalog-fetcher, to: games-table, label: writes }
```

### Conventions

- Connections run in the direction data or control flows. Labels are a short verb: `invokes`, `writes`, `reads`, `stream`, `subscribes`, `triggers`, `stores`, `downloads`, `serves from`, `routes to`.
- External services (third-party APIs, CDNs, Claude API, GitHub) use `type: external`. Tag them with each project that calls them.
- A resource shared by several projects lists all of them in `projects`.
- Use British spelling in names and descriptions. Use ’ for apostrophes in visible text.

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
| `ecs` | `aws_ecs_service` |
| `api-gateway` | `aws_api_gateway_rest_api`, `aws_apigatewayv2_api` |
| `cloudwatch-logs` | only when a log group is wired into a flow (e.g. a subscription filter) |
| `external` | third-party APIs found in code or config |
| `github` | GitHub Actions or repos that take part in a flow |

### Adding a new type

If you need a type that isn't listed (for example ALB, Secrets Manager, ECR or Step Functions), add it in two places in the page's script:

- an entry in `TYPES`, with its `label` and a `cat` from: `compute`, `storage`, `database`, `integration`, `network`, `mgmt`, `external`;
- a simple white-stroke glyph in `GLYPHS`, drawn on a 24×24 viewBox in the same style as the existing ones.

Don't change anything else in the rendering code.

## Where edges come from

| Source | Edge |
|---|---|
| Scheduler / event rule targets (`aws_scheduler_schedule.target`, `aws_cloudwatch_event_target`) | schedule → target, `invokes` |
| `aws_lambda_event_source_mapping` | SQS queue or DynamoDB stream → function, `triggers` / `stream` |
| `aws_sns_topic_subscription` | topic → endpoint, `subscribes` |
| `aws_s3_bucket_notification` | bucket → target, `notifies` |
| `aws_pipes_pipe` | source → target, with the hop labelled |
| CloudFront `origin` blocks | distribution → S3 bucket or load balancer, `serves from` |
| Route 53 alias records | zone → CloudFront or load balancer, `routes to` |
| IAM policy actions plus Lambda env vars naming a table, bucket or topic | function → resource. Label by action: `PutItem`/`PutObject`/`Publish` → `writes` / `stores` / `publishes`; `GetItem`/`Query`/`GetObject` → `reads` |
| HTTP clients and base URLs in Lambda/app code (e.g. `api.steampowered.com`, Steam CDN hosts, `api.anthropic.com`) | function → external, with a label for what it fetches |

Call out every IAM-derived or code-derived edge in the report, because they're inferences.

## What's in the YAML now (seeded by hand, needs checking)

Steam game search:

```
schedule → catalogue Lambda → Steam Web API + games table (DynamoDB)
games table → (stream) → SNS → SQS → artwork Lambda → Steam CDN + S3
```

- **Known gap:** how the DynamoDB stream reaches SNS. It could be a dispatcher Lambda, an EventBridge Pipe, or something else. Replace the direct `games-table → game-events` edge with whatever is really there.

Personal domain:

- Route 53 hosted zone only.

## Checks before you finish

- The YAML parses. Every `from`/`to` and project tag refers to an existing id.
- Open the page and confirm there's no "need attention" notice under the map.
- No resource ids or names that expose account IDs, ARNs or secrets.
