# GitHub Actions publishes site/ straight to the bucket, so Terraform owns the
# bucket and the distribution but not the objects inside. This is the role the
# workflow assumes. Nothing long-lived is stored in the repository: GitHub mints
# a short-lived OIDC token per run and STS exchanges it for temporary keys.

# An account may hold only ONE provider per URL. If another stack creates this
# first, replace the resource with:
#   data "aws_iam_openid_connect_provider" "github" {
#     url = "https://token.actions.githubusercontent.com"
#   }
# and update the references below.
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # AWS no longer validates thumbprints for this provider and populates the
  # field itself — emptying it here only makes every future plan want to
  # remove what AWS puts back. Hand the field to AWS and stop looking at it.
  lifecycle {
    ignore_changes = [thumbprint_list]
  }
}

resource "aws_iam_role" "github_deploy" {
  name        = "github-deploy-architecture-map"
  description = "Lets the architecture map repository publish the site and invalidate its CDN."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }

      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"

          # Pinned to one repository AND one branch. Without the ref, any
          # branch in the repo could assume it — including a branch opened by
          # a pull request. StringEquals rather than StringLike, so there is
          # no wildcard to get wrong.
          #
          # The prefix carries numeric owner and repo IDs because this repo has
          # immutable subject claims on; the readable "repo:owner/name" form
          # never matches and fails with "Not authorized to perform
          # sts:AssumeRoleWithWebIdentity".
          "token.actions.githubusercontent.com:sub" = "${var.github_subject_prefix}:ref:refs/heads/main"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "github_deploy" {
  name = "publish-architecture-map"
  role = aws_iam_role.github_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Write the objects. No read: the workflow never needs to fetch them.
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:DeleteObject"]
        Resource = "${aws_s3_bucket.software_arch_map.arn}/*"
      },
      {
        # `aws s3 sync --delete` lists the bucket to work out what to remove.
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.software_arch_map.arn
      },
      {
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation"]
        Resource = aws_cloudfront_distribution.s3_software_arch_distribution.arn
      }
    ]
  })
}
