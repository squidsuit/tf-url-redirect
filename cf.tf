locals {
  target_origin_id = aws_s3_bucket.ssbucket["fqdn"].id
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.ssbucket["fqdn"].website_endpoint
    origin_id   = aws_s3_bucket.ssbucket["fqdn"].id

    custom_origin_config {
      http_port = "80"
      https_port = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = [ "TLSv1.2" ]
        }
    }

  enabled             = true
  is_ipv6_enabled     = true

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.logbucket.bucket_domain_name
    prefix          = "log/"
  }

  aliases = [ "${var.domain_name}", "www.${var.domain_name}" ]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.target_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.cert-validation.certificate_arn
    ssl_support_method = "sni-only"
  }
}