resource "aws_security_group" "aws-elb" {
    name = "${var.aws_cluster_name}-securitygroup-elb"
    vpc_id = "${var.aws_vpc_id}"

    tags = "${merge(var.default_tags, map(
      "Name", "${var.aws_cluster_name}-securitygroup-elb"
    ))}"
}


resource "aws_security_group_rule" "aws-allow-web-access" {
    type = "ingress"
    from_port = "${var.aws_elb_port}"
    to_port = "${var.aws_elb_port}"
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.aws-elb.id}"
}

resource "aws_security_group_rule" "aws-allow-web-egress" {
    type = "egress"
    from_port = 0
    to_port = 65535
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.aws-elb.id}"
}


# Create a new AWS ELB for web site.
resource "aws_elb" "aws-elb-web" {
  name = "elb-${var.aws_cluster_name}"
  subnets = ["${var.aws_subnet_ids_public}"]
  security_groups = ["${aws_security_group.aws-elb.id}"]

  listener {
    instance_port = "${var.web_node_port}"
    instance_protocol = "http"
    lb_port = "${var.aws_elb_port}"
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "TCP:${var.web_node_port}"
    interval = 30
  }

  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400

  tags = "${merge(var.default_tags, map(
    "Name", "${var.aws_cluster_name}-elb-web"
  ))}"
}
