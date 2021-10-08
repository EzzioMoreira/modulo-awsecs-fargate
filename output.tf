output "load_balancer_ip" {
  value = aws_lb.main.dns_name
}