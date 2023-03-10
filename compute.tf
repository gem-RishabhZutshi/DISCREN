resource "aws_instance" "public-webserver1" {
  ami           = data.aws_ami.dev-webservers.id
  instance_type = "t2.micro"
  key_name          = "terraform-kp"
  availability_zone = "ap-south-1a"
  vpc_security_group_ids      = [aws_security_group.public-webserver-one-sg.id]
  subnet_id                   = aws_subnet.devsubnetpublic1.id
  associate_public_ip_address = true
  user_data = <<-EOF
        #!/bin/bash
        yum update -y
        yum install httpd -y
        systemctl start httpd
        systemctl enable httpd
        echo "<html><body><h1>Welcome to DISCERN WEBSERVICE</h1></body></html>" > /var/www/html/index.html
        EOF

  tags = {
    "Name" = "PRODWebServer-1"
  }
}

resource "aws_instance" "public-webserver2" {
  ami           = data.aws_ami.dev-webservers.id
  instance_type = "t2.small"
  key_name          = "terraform-kp"
  availability_zone = "ap-south-1b"
  vpc_security_group_ids      = [aws_security_group.public-webserver-one-sg.id]
  subnet_id                   = aws_subnet.devsubnetpublic2.id
  associate_public_ip_address = true
  user_data = <<-EOF
        #!/bin/bash
        yum update -y
        yum install httpd -y
        systemctl start httpd
        systemctl enable httpd
        echo "<html><body><h1>Hi there again</h1></body></html>" > /var/www/html/index.html
        EOF

  tags = {
    "Name" = "PRODWebServer-2"
  }
}

resource "aws_lb" "dev-alb" {
    name = "dev-alb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.alb_sg.id]
    subnets = [aws_subnet.devsubnetpublic1.id, aws_subnet.devsubnetpublic2.id] 
}


resource "aws_lb_target_group" "project_tg" {
  name     = "project-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpcdev.id

  depends_on = [aws_vpc.vpcdev]
}

# Create target attachments
resource "aws_lb_target_group_attachment" "tg_attach1" {
  target_group_arn = aws_lb_target_group.project_tg.arn
  target_id        = aws_instance.public-webserver1.id
  port             = 80

  depends_on = [aws_instance.public-webserver1]
}

resource "aws_lb_target_group_attachment" "tg_attach2" {
  target_group_arn = aws_lb_target_group.project_tg.arn
  target_id        = aws_instance.public-webserver2.id
  port             = 80

  depends_on = [aws_instance.public-webserver2]
}

# Create listener
resource "aws_lb_listener" "listener_lb" {
  load_balancer_arn = aws_lb.dev-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.project_tg.arn
  }
}

