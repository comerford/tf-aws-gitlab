resource "aws_instance" "gitlab_host" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    user = "ubuntu"
    # this should be the equivalent private key used in key_name below
    # and allow you to connect to the hosts once they are spun up
    private_key = "${file(var.private_key_path)}"
  }

  instance_type = "${var.instance_size}"

  # Recent Bitnami AMI in the region
  ami = "${lookup(var.amazon_amis, var.aws_region)}"

  # The name of our SSH keypair
  key_name = "${var.host_key_name}"

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.gitlab_host_SG.id}"]

  #
  subnet_id = "${var.host_subnet}"
  associate_public_ip_address = false
  # set the relevant tags
  tags = {
    Name = "gitlab_host"
    Owner = "${var.tag_Owner}"
  }
  # We run a remote provisioner on the instance after creating it
  # This is simple so is OK in terraform, but would be more appropriate
  # in a proper config management tool like chef/puppet/etc.
  provisioner "remote-exec" {
    inline = [
        "mkdir -p ~/conf"
    ]
  }
  provisioner "file" {
        source = "conf/"
        destination = "~/conf"
  }
  # Installation instructions snaffled from https://about.gitlab.com/downloads/#ubuntu1404
  # Note that the SSL cert/key files are empty in the repo intentionally
  # for this to work, and start gitlab, the key must be present and correct
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get -y upgrade",
      "sudo bash /home/ubuntu/conf/script.deb.sh",
      "sudo apt-get -y install gitlab-ce",
      "sudo cp ~/conf/gitlab.rb /etc/gitlab/gitlab.rb",
      "sudo cp ~/conf/gitlab_example_com.* /etc/gitlab/ssl/"
      "sudo gitlab-ctl reconfigure"
    ]
  }
}
# host security group, no external access - that will be on the ELB SG
resource "aws_security_group" "gitlab_host_SG" {
  name        = "gitlab_host"
  description = "Rules for Gitlab host access"
  vpc_id      = "${var.account_vpc}"

  # SSH access from Internal IPs and this SG
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.0.2.0/24"]
    self = true
  }
  # HTTP access from Internal IPs and this SG
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["192.0.2.0/24"]
    self        = true
  }
  # HTTPS access from Internal IPs and this SG
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["192.0.2.0/24"]
    self        = true
  }
  # next few rules allow access from the ELB SG
  # can't mix CIDR and SGs, so repeating a lot of the above

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = ["${aws_security_group.gitlab_ELB_SG.id}"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    security_groups = ["${aws_security_group.gitlab_ELB_SG.id}"]
  }
  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Separate SG for ELB
resource "aws_security_group" "gitlab_ELB_SG" {
  name        = "gitlab_ELB_SG"
  description = "Rules for Gitlab ELB"
  vpc_id      = "${var.account_vpc}"

  # HTTP access from our whitelist
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${split(",", var.elb_whitelist)}"]
  }
  # HTTPS access from the whitelist
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${split(",", var.elb_whitelist)}"]
  }
  # outbound access to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a new external facing ELB to point at the instance
resource "aws_elb" "gitlab-elb" {
  name = "gitlab-elb"
  subnets = ["${var.elb_subnet}"]
  #
  security_groups = ["${aws_security_group.gitlab_ELB_SG.id}"]
# this requires a valid bucket policy for the ELB to write to the bucket
# http://docs.aws.amazon.com/ElasticLoadBalancing/latest/DeveloperGuide/enable-access-logs.html#attach-bucket-policy
  access_logs {
    bucket = "${var.bucket_name}"
    bucket_prefix = "ELBAccessLogs"
    interval = 60
  }
# Listen on HTTP
  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
# Listen on SSL
  listener {
    instance_port = 443
    instance_protocol = "https"
    lb_port = 443
    lb_protocol = "https"
    ssl_certificate_id = "${var.elb_ssl_cert}"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "TCP:443"
    interval = 30
  }

  instances = ["${aws_instance.gitlab_host.id}"]
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400

  tags {
    Name = "gitlab_elb"
    Owner = "${var.tag_Owner}"
  }
}
# now an S3 bucket to store our ELB access logs
# see http://docs.aws.amazon.com/ElasticLoadBalancing/latest/DeveloperGuide/enable-access-logs.html
resource "aws_s3_bucket" "gitlab-example-com" {
    bucket = "${var.bucket_name}"
    acl = "private"
    policy = "${file("bucket_policy.json")}"
    tags {
      Owner = "${var.tag_Owner}"
    }
}
