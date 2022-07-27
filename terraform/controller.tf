
resource "aws_iam_role" "web_iam_role" {
  name               = "web_iam_role-${random_id.random-string.dec}"
  tags = {
    Nginx = "nginx experience ${random_id.random-string.dec}"
  }
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "iam_nginx_profile" {
  name = "web_instance_profile-${random_id.random-string.dec}"
  role = aws_iam_role.web_iam_role.id
}

resource "aws_iam_role_policy" "web_iam_role_policy" {
  name   = "web_iam_role_policy-${random_id.random-string.dec}"
  role   = aws_iam_role.web_iam_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::sorinnginx"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": ["arn:aws:s3:::sorinnginx/*"]
    }
  ]
}
EOF
}







resource "aws_instance" "controller" {
  ami                  = "ami-0f5b07b31937d4275"
  #iam_instance_profile = aws_iam_instance_profile.iam_nginx_profile.id
  instance_type        = "t3.2xlarge"
  root_block_device {
    volume_size = "80"
  }
  associate_public_ip_address = true
  availability_zone           = var.aws_az
  subnet_id                   = aws_subnet.public-subnet.id
  vpc_security_group_ids      = [aws_security_group.sgweb.id]
  key_name                    = aws_key_pair.main.id

  user_data = <<-EOF
      #!/bin/bash
      apt-get update
      swapoff -a
      ufw disable
      apt-get install jq socat conntrack -y
      wget https://sorinnginx.s3.eu-central-1.amazonaws.com/apim-controller-installer-3.19.4.tar.gz -O /home/ubuntu/controller.tar.gz
      tar zxvf /home/ubuntu/controller.tar.gz -C /home/ubuntu/
      host_ip=$(curl -s ifconfig.me)
      export HOME=/home/ubuntu
      runuser -l ubuntu -c 'host_ip=$(curl -s ifconfig.me) && /home/ubuntu/controller-installer/install.sh -n --accept-license --smtp-host $host_ip --smtp-port 25 --smtp-authentication false --smtp-use-tls false --noreply-address no-reply@sorin.nginx --fqdn $host_ip --organization-name nginx1 --admin-firstname NGINX --admin-lastname Admin --admin-email admin@nginx.com --admin-password Admin2021 --self-signed-cert --auto-install-docker --configdb-volume-type local --tsdb-volume-type local'
      curl -k -c cookie.txt -X POST --url "https://$host_ip/api/v1/platform/login" --header 'Content-Type: application/json' --data '{"credentials": {"type": "BASIC","username": "admin@nginx.com","password": "Admin2021"}}'
      curl -k -b cookie.txt -c cookie.txt --header "Content-Type: application/json" --request POST --url "https://$host_ip/api/v1/platform/license-file" --data '{"content":"TUlNRS1WZXJzaW9uOiAxLjAKQ29udGVudC1UeXBlOiBtdWx0aXBhcnQvc2lnbmVkOyBwcm90b2NvbD0iYXBwbGljYXRpb24veC1wa2NzNy1zaWduYXR1cmUiOyBtaWNhbGc9InNoYS0yNTYiOyBib3VuZGFyeT0iLS0tLTAxQkY1MzFCNEE5MjU2MEFEMjBDRDFENUNGOTI3NjhCIgoKVGhpcyBpcyBhbiBTL01JTUUgc2lnbmVkIG1lc3NhZ2UKCi0tLS0tLTAxQkY1MzFCNEE5MjU2MEFEMjBDRDFENUNGOTI3NjhCCld3b2dJQ0FnZXdvZ0lDQWdJQ0FnSUNKbGVIQnBjbmtpT2lBaU1qQXlNaTB3T0MweU5sUXhORG8xTmpvd05TNHdPREV4T0RsYUlpd2cKQ2lBZ0lDQWdJQ0FnSW14cGJXbDBjeUk2SURJd0xDQUtJQ0FnSUNBZ0lDQWljSEp2WkhWamRDSTZJQ0pPUjBsT1dDQkRiMjUwY205cwpiR1Z5SUV4dllXUWdRbUZzWVc1amFXNW5JaXdnQ2lBZ0lDQWdJQ0FnSW5ObGNtbGhiQ0k2SURReE9ESXNJQW9nSUNBZ0lDQWdJQ0p6CmRXSnpZM0pwY0hScGIyNGlPaUFpVkRBd01ERXlORFEyTWlJc0lBb2dJQ0FnSUNBZ0lDSjBlWEJsSWpvZ0luUnlhV0ZzSWl3Z0NpQWcKSUNBZ0lDQWdJblpsY25OcGIyNGlPaUF4Q2lBZ0lDQjlMQ0FLSUNBZ0lIc0tJQ0FnSUNBZ0lDQWlaWGh3YVhKNUlqb2dJakl3TWpJdApNRGd0TWpaVU1UUTZOVFk2TURVdU1EZ3dPVE01V2lJc0lBb2dJQ0FnSUNBZ0lDSnNhVzFwZEhNaU9pQTVPVGs1T1N3Z0NpQWdJQ0FnCklDQWdJbXhwYldsMGMxOWhjR2xmWTJGc2JITWlPaUF5TURBd01EQXdNQ3dnQ2lBZ0lDQWdJQ0FnSW5CeWIyUjFZM1FpT2lBaVRrZEoKVGxnZ1EyOXVkSEp2Ykd4bGNpQkJVRWtnVFdGdVlXZGxiV1Z1ZENJc0lBb2dJQ0FnSUNBZ0lDSnpaWEpwWVd3aU9pQTBNVGd5TENBSwpJQ0FnSUNBZ0lDQWljM1ZpYzJOeWFYQjBhVzl1SWpvZ0lsUXdNREF4TWpRME5qSWlMQ0FLSUNBZ0lDQWdJQ0FpZEhsd1pTSTZJQ0owCmNtbGhiQ0lzSUFvZ0lDQWdJQ0FnSUNKMlpYSnphVzl1SWpvZ01Rb2dJQ0FnZlFwZAoKLS0tLS0tMDFCRjUzMUI0QTkyNTYwQUQyMENEMUQ1Q0Y5Mjc2OEIKQ29udGVudC1UeXBlOiBhcHBsaWNhdGlvbi94LXBrY3M3LXNpZ25hdHVyZTsgbmFtZT0ic21pbWUucDdzIgpDb250ZW50LVRyYW5zZmVyLUVuY29kaW5nOiBiYXNlNjQKQ29udGVudC1EaXNwb3NpdGlvbjogYXR0YWNobWVudDsgZmlsZW5hbWU9InNtaW1lLnA3cyIKCk1JSUZ2QVlKS29aSWh2Y05BUWNDb0lJRnJUQ0NCYWtDQVFFeER6QU5CZ2xnaGtnQlpRTUVBZ0VGQURBTEJna3EKaGtpRzl3MEJCd0dnZ2dNek1JSURMekNDQWhlZ0F3SUJBZ0lKQUlNenBYUUhwU3lhTUEwR0NTcUdTSWIzRFFFQgpDd1VBTUM0eEVqQVFCZ05WQkFvTUNVNUhTVTVZSUVsdVl6RVlNQllHQTFVRUF3d1BRMjl1ZEhKdmJHeGxjaUJEClFTQXhNQjRYRFRFNE1EVXhNVEV5TVRNMU1Wb1hEVEl5TURVeE1ERXlNVE0xTVZvd0xqRVNNQkFHQTFVRUNnd0oKVGtkSlRsZ2dTVzVqTVJnd0ZnWURWUVFEREE5RGIyNTBjbTlzYkdWeUlFTkJJREV3Z2dFaU1BMEdDU3FHU0liMwpEUUVCQVFVQUE0SUJEd0F3Z2dFS0FvSUJBUURSVmNSRzFuV0tUMk8vc3JyNllmc01nN0VDeXBHaHJoM3JEc0ZkCkV1cEs1UWRRN01SLzNIa2I5NERZOHg5TGNJZDVVY2ZxVzFaWXVzeGdaRk5seDlvcG1ZZmluZmlzV2hxcmV1WUoKTWpwVU82SC81Ly9ZUTZObFdOS0FHQzJqejZMbEdEK1cwMmpBUzNkR1BjM0V5Ti9hZzd5VXNYSm1KZXZFVCt1MApxbFFyNEFwWWp2Z1dTdjRtaVdCY2pmMW0xM3M1RlQwYXVsKzFFSXpIUVhLaitsYUdMSE1Lc2FGdDFHaC9xMHlaCmhLTXlyaXBZTERqR1FlTVFvc3g1bGFBQWdKN04zTG54UW56UmlBNkN0OUJGYm9wLzBGN1Q2djY0QXFCUEduNEIKbXpvbEN2ZXNZZ2lrK2p1Q0RsTU9GTWxVeHJxU3oxQXZRZVBzOGdZcW9hQXJ0U2NUQWdNQkFBR2pVREJPTUIwRwpBMVVkRGdRV0JCUVNhV0dtV3FzbU1zc3hXcCtYamx6a3d5bjhYVEFmQmdOVkhTTUVHREFXZ0JRU2FXR21XcXNtCk1zc3hXcCtYamx6a3d5bjhYVEFNQmdOVkhSTUVCVEFEQVFIL01BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQ3AKN3phRDFOdk0xRFRFUHprQ05vOEIwbVA4ZDE0S3VleWFZcFYvbXdNS2tBa3NsTHZwdzE5ai85d1p4OEZtMlpGTgpUTkJUUmIvbXBIdGZOUENQSlkxM2NtZVFKNkdQTUE1eGxnL0lMd0lic083bEp6NGxGbFhZYU1qaCsrR3ZFTy9rClhFbC9OVUZ0TnFtcmI0c3pYSjJTaGJyMkoxaDB6VEZuazJ3MVgzcFZwaWsyVk5qSmY3dVQ2dDVUTlpXcERIRnQKS1c0YWZJeHdFNXVzVXFLOERBd2JyS2sxRkIreEtNV05wVEtYMXlzNk4rRmZlVXljNkh1WjNKRlczQjZYTTMrOQpMOXJlSmxpMlRRa2JvaUJNUElxS2RSRlRaL2xkYTR0d01uaURFRjlZZE03ekJ0elZmeFRpZjdReWJ3aWd3L1AxCmhUSUZRaWkzUElqS3ZDcmR3RkJmTVlJQ1RUQ0NBa2tDQVFFd096QXVNUkl3RUFZRFZRUUtEQWxPUjBsT1dDQkoKYm1NeEdEQVdCZ05WQkFNTUQwTnZiblJ5YjJ4c1pYSWdRMEVnTVFJSkFJTXpwWFFIcFN5YU1BMEdDV0NHU0FGbApBd1FDQVFVQW9JSGtNQmdHQ1NxR1NJYjNEUUVKQXpFTEJna3Foa2lHOXcwQkJ3RXdIQVlKS29aSWh2Y05BUWtGCk1ROFhEVEl5TURjeU56RTBOVFl3TlZvd0x3WUpLb1pJaHZjTkFRa0VNU0lFSUNqN2tHK0ozZG1UWWVUb2xxeTYKSXVkckVWLzlOOUNxei93R2MvTWRLcHJxTUhrR0NTcUdTSWIzRFFFSkR6RnNNR293Q3dZSllJWklBV1VEQkFFcQpNQXNHQ1dDR1NBRmxBd1FCRmpBTEJnbGdoa2dCWlFNRUFRSXdDZ1lJS29aSWh2Y05Bd2N3RGdZSUtvWklodmNOCkF3SUNBZ0NBTUEwR0NDcUdTSWIzRFFNQ0FnRkFNQWNHQlNzT0F3SUhNQTBHQ0NxR1NJYjNEUU1DQWdFb01BMEcKQ1NxR1NJYjNEUUVCQVFVQUJJSUJBSURQYmJsMTlEeDMvVUlCRGh1Uy9MMU1nNVhmcDd1WkRBZVBaQWdMQ1N4VAplUUd4VlE1b25oVUxiSW9IdEliTFduZUp1a1pZWVJXZU5hZ3RZSGRlaitUUEp4cnVNT3FvVUdodmtYZEJhQkpHClB1WmtCVVNkczQzeW50emFROUlzS29pcCtvYytmRFVXTWtkZlp5NldENHNQdXd1eVU0cEhDRC9scnZtbVJHancKeU5waWQ0UHBkQ0RNOGc2Zm9tTC9NbHJHWVY1OC93Nk1taVNVekFMczM2bGllK01qT2tWaVdhbWxMckNub0lGWApvaE9na1pqYk5mQUtveXZaeVpMWjcvR25WTk14MndmTFdaMitMVWViUVBVRE1CaVB3RlBkeUU3VkVJRHJnWk11CndlMWlIV1dHRmZGNXIyMlFqaTYxMFdnSFlTSlN3Zll0N1NWeDJ0UGE3NVk9CgotLS0tLS0wMUJGNTMxQjRBOTI1NjBBRDIwQ0QxRDVDRjkyNzY4Qi0tCgo="}'
    EOF

  tags = {
    Name = "controller"
    Nginx = "nginx experience ${random_id.random-string.dec}"
  }
}
