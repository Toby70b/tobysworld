# Icon provenance

These files are inlined into `site/cloud-architecture.html` by
`scripts/build_icons.py`. Nothing here is served — the page carries the artwork
in its own source so it stays a single self-contained file.

## AWS (9 files)

From the official **AWS Architecture Icons** asset package, 31 July 2026
release, downloaded from <https://aws.amazon.com/architecture/icons/>:

```
Icon-package_07312026.5846e92413caa21490223536cc97f1269e44fa92.zip
```

Each file is the 64px service icon from `Architecture-Service-Icons_07312026/`,
taken unmodified apart from stripping the XML declaration, the `<title>` and the
fixed `width`/`height` so the page can size them. They carry AWS's own
category-coloured background, which is why the map's tiles match AWS's palette.

AWS states on that page that customers and partners may use the assets to create
architecture diagrams, which is what this is.

| File | Package source |
|---|---|
| `lambda.svg` | `Arch_Compute/64/Arch_AWS-Lambda_64.svg` |
| `s3.svg` | `Arch_Storage/64/Arch_Amazon-Simple-Storage-Service_64.svg` |
| `dynamodb.svg` | `Arch_Databases/64/Arch_Amazon-DynamoDB_64.svg` |
| `sqs.svg` | `Arch_Application-Integration/64/Arch_Amazon-Simple-Queue-Service_64.svg` |
| `sns.svg` | `Arch_Application-Integration/64/Arch_Amazon-Simple-Notification-Service_64.svg` |
| `eventbridge-schedule.svg` | `Arch_Application-Integration/64/Arch_Amazon-EventBridge_64.svg` |
| `cloudfront.svg` | `Arch_Networking-Content-Delivery/64/Arch_Amazon-CloudFront_64.svg` |
| `route53.svg` | `Arch_Networking-Content-Delivery/64/Arch_Amazon-Route-53_64.svg` |
| `ssm-parameter.svg` | `Arch_Management-Tools/64/Arch_AWS-Systems-Manager_64.svg` |

`ssm-parameter.svg` is the Systems Manager service icon — the package has no
Parameter Store icon in this style, and the resource-level icons are a different
visual language that would sit badly next to these.

## Steam

Deliberately **not** here. Valve publishes its branding guidance for partners at
<https://partner.steamgames.com/doc/marketing/branding>, which asks for approved
artwork used standalone and not combined with other elements, and it publishes no
diagram icon set the way AWS does. Dropping their mark into a grid of service
tiles is the case that guidance asks you to avoid.

So the Steam nodes use an original line glyph, kept with the other hand-drawn
fallbacks in the page's `GLYPHS` map, on a category-coloured tile. The page's
footer names Valve's trademark and says the icon is an original drawing.

## Refreshing

AWS ships a new package quarterly. To take one:

1. Download the current package from the AWS icons page.
2. Replace the nine files above, keeping these filenames (they map to the YAML
   `type` values).
3. `python scripts/build_icons.py`
4. `python scripts/check_architecture.py`
