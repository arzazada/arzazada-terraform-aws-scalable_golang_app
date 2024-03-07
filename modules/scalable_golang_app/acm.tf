# ACM Certificate
resource "aws_acm_certificate" "sga_acm" {
  domain_name       = "${var.project_name}.${var.domain}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "project_records" {
  for_each = {
    for dvo in aws_acm_certificate.sga_acm.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.project_hosted_zone.id
}

resource "aws_acm_certificate_validation" "project_ssl_validation" {
  certificate_arn         = aws_acm_certificate.sga_acm.arn
  validation_record_fqdns = [for record in aws_route53_record.project_records : record.fqdn]
}