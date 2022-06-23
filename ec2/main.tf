locals {
    postgres-userdata = <<USERDATA
#!/bin/bash
set -x
exec > >(tee /var/log/user-data.log|logger -t user-data ) 2>&1
yum -y update
yum install -y nfs-utils unzip curl jq
mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${aws_efs_file_system.dale-terraform-test-efs-volume.dns_name}:/  /path/to/mount/location
echo ${aws_efs_file_system.dale-terraform-test-efs-volume.dns_name}:/ /efs/postgres nfs4 nofail,defaults,_netdev 0 0 >> /etc/fstab
USERDATA
}


data "aws_subnet" "Default_subnet_a" {
  id = "subnet-id-a"
}


data "aws_subnet" "Default_subnet_b" {
  id = "subnet-id-b"
}


data "aws_subnet" "Default_subnet_c" {
  id = "subnet-id-c"
}


resource "aws_launch_template" "postgres_launch_template" {
  name_prefix   = "postgres"
  image_id      = "ami-id"
  instance_type = "t3.2xlarge"
  vpc_security_group_ids = [data.aws_security_group.example_security_group.id]
  key_name = "ssh-keyname"
  user_data = "${base64encode(local.postgres-userdata)}"


  tags = {
  Name = "Dale_Postgres_Cluster_Testing"
  }


  depends_on = [
  aws_efs_file_system.dale-terraform-test-efs-volume,
  aws_efs_mount_target.dale-terraform-mount-target_a,
  aws_efs_mount_target.dale-terraform-mount-target_b,
  aws_efs_mount_target.dale-terraform-mount-target_c
  ]


}


resource "aws_autoscaling_group" "postgres" {
  vpc_zone_identifier = [data.aws_subnet.Default_subnet_a.id,
                         data.aws_subnet.Default_subnet_b.id,
                         data.aws_subnet.Default_subnet_c.id ]
  desired_capacity   = 1
  max_size           = 1    
  min_size           = 1

  launch_template {
    id      = aws_launch_template.postgres_launch_template.id
    version = "$Latest"
  }
}


resource "aws_efs_file_system" "dale-terraform-test-efs-volume" {
  creation_token = "dale-terraform-test-efs-volume"

  tags = {
    Name = "dale-terraform-test-efs-volume"
  }
}

 
resource "aws_efs_mount_target" "dale-terraform-mount-target_a" {
   file_system_id  =  aws_efs_file_system.dale-terraform-test-efs-volume.id
   subnet_id = data.aws_subnet.Default_subnet_a.id
   security_groups = [data.aws_security_group.example_security_group.id]
 }


resource "aws_efs_mount_target" "dale-terraform-mount-target_b" {
   file_system_id  =  aws_efs_file_system.dale-terraform-test-efs-volume.id
   subnet_id = data.aws_subnet.Default_subnet_b.id
   security_groups = [data.aws_security_group.example_security_group.id]
 }


resource "aws_efs_mount_target" "dale-terraform-mount-target_c" {
   file_system_id  =  aws_efs_file_system.dale-terraform-test-efs-volume.id
   subnet_id = data.aws_subnet.Default_subnet_c.id
   security_groups = [data.aws_security_group.example_security_group.id]
 }


data "aws_security_group" "example_security_group" {
  id =  "sg-id" 
  vpc_id = data.aws_vpc.Defualt_vpc.id
}


data "aws_vpc" "Defualt_vpc" {
  id = "vpc-id"
}