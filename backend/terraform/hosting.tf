resource "aws_s3_bucket" "report_site" {
  bucket = "${var.project_name}-report-site"
}

resource "aws_s3_bucket_public_access_block" "report_site" {
  bucket                  = aws_s3_bucket.report_site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "report_oac" {
  name                              = "${var.project_name}-report-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "report_site" {
  enabled             = true
  default_root_object = "report.html"
  comment              = "${var.project_name} - back office de reportes"

  origin {
    domain_name              = aws_s3_bucket.report_site.bucket_regional_domain_name
    origin_id                = "report-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.report_oac.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "report-s3-origin"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

data "aws_iam_policy_document" "report_site_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.report_site.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.report_site.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "report_site" {
  bucket = aws_s3_bucket.report_site.id
  policy = data.aws_iam_policy_document.report_site_policy.json
}

resource "aws_s3_object" "report_html" {
  bucket       = aws_s3_bucket.report_site.id
  key          = "report.html"
  source       = "${path.module}/../report.html"
  etag         = filemd5("${path.module}/../report.html")
  content_type = "text/html"
}

output "report_site_url" {
  description = "URL pública (vía CloudFront) de la página de reportes"
  value       = "https://${aws_cloudfront_distribution.report_site.domain_name}/report.html"
}
