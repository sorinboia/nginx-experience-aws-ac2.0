
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
  ami                  = "ami-09356619876445425"
  #iam_instance_profile = aws_iam_instance_profile.iam_nginx_profile.id
  instance_type        = "t2.2xlarge"
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
      wget https://sorinnginx.s3.eu-central-1.amazonaws.com/controller-installer-3.15-6.0.tar.gz -O /home/ubuntu/controller.tar.gz
      tar zxvf /home/ubuntu/controller.tar.gz -C /home/ubuntu/
      host_ip=$(curl -s ifconfig.me)
      export HOME=/home/ubuntu
      runuser -l ubuntu -c 'host_ip=$(curl -s ifconfig.me) && /home/ubuntu/controller-installer/install.sh -n --accept-license --smtp-host $host_ip --smtp-port 25 --smtp-authentication false --smtp-use-tls false --noreply-address no-reply@sorin.nginx --fqdn $host_ip --organization-name nginx1 --admin-firstname NGINX --admin-lastname Admin --admin-email admin@nginx.com --admin-password Admin2021 --self-signed-cert --auto-install-docker --configdb-volume-type local --tsdb-volume-type local'
      curl -k -c cookie.txt -X POST --url "https://$host_ip/api/v1/platform/login" --header 'Content-Type: application/json' --data '{"credentials": {"type": "BASIC","username": "admin@nginx.com","password": "Admin2021"}}'
      curl -k -b cookie.txt -c cookie.txt --header "Content-Type: application/json" --request POST --url "https://$host_ip/api/v1/platform/license-file" --data '{"content":"TUlNRS1WZXJzaW9uOiAxLjAKQ29udGVudC1UeXBlOiBtdWx0aXBhcnQvc2lnbmVkOyBwcm90b2NvbD0iYXBwbGljYXRpb24veC1wa2NzNy1zaWduYXR1cmUiOyBtaWNhbGc9InNoYS0yNTYiOyBib3VuZGFyeT0iLS0tLUQ4OUVGMzEzM0EyMDc2NkI1MDIxNDgyMjZDMjgyNEY1IgoKVGhpcyBpcyBhbiBTL01JTUUgc2lnbmVkIG1lc3NhZ2UKCi0tLS0tLUQ4OUVGMzEzM0EyMDc2NkI1MDIxNDgyMjZDMjgyNEY1Cld3b2dJQ0FnZXdvZ0lDQWdJQ0FnSUNKbGVIQnBjbmtpT2lBaU1qQXlNUzB3TlMwd04xUXdPRG93TVRvek1DNDJOVFl5TmpkYUlpd2cKQ2lBZ0lDQWdJQ0FnSW14cGJXbDBjeUk2SURJd0xDQUtJQ0FnSUNBZ0lDQWljSEp2WkhWamRDSTZJQ0pPUjBsT1dDQkRiMjUwY205cwpiR1Z5SUV4dllXUWdRbUZzWVc1amFXNW5JaXdnQ2lBZ0lDQWdJQ0FnSW5ObGNtbGhiQ0k2SURNME1Ua3NJQW9nSUNBZ0lDQWdJQ0p6CmRXSnpZM0pwY0hScGIyNGlPaUFpVkRBd01ERXdPVEUyTkNJc0lBb2dJQ0FnSUNBZ0lDSjBlWEJsSWpvZ0luUnlhV0ZzSWl3Z0NpQWcKSUNBZ0lDQWdJblpsY25OcGIyNGlPaUF4Q2lBZ0lDQjlMQ0FLSUNBZ0lIc0tJQ0FnSUNBZ0lDQWlaWGh3YVhKNUlqb2dJakl3TWpFdApNRFV0TURkVU1EZzZNREU2TXpBdU5qVTFPVFUyV2lJc0lBb2dJQ0FnSUNBZ0lDSnNhVzFwZEhNaU9pQTVPVGs1T1N3Z0NpQWdJQ0FnCklDQWdJbXhwYldsMGMxOWhjR2xmWTJGc2JITWlPaUF4TURBd01EQXdNREF3TENBS0lDQWdJQ0FnSUNBaWNISnZaSFZqZENJNklDSk8KUjBsT1dDQkRiMjUwY205c2JHVnlJRUZRU1NCTllXNWhaMlZ0Wlc1MElpd2dDaUFnSUNBZ0lDQWdJbk5sY21saGJDSTZJRE0wTVRrcwpJQW9nSUNBZ0lDQWdJQ0p6ZFdKelkzSnBjSFJwYjI0aU9pQWlWREF3TURFd09URTJOQ0lzSUFvZ0lDQWdJQ0FnSUNKMGVYQmxJam9nCkluUnlhV0ZzSWl3Z0NpQWdJQ0FnSUNBZ0luWmxjbk5wYjI0aU9pQXhDaUFnSUNCOUNsMD0KCi0tLS0tLUQ4OUVGMzEzM0EyMDc2NkI1MDIxNDgyMjZDMjgyNEY1CkNvbnRlbnQtVHlwZTogYXBwbGljYXRpb24veC1wa2NzNy1zaWduYXR1cmU7IG5hbWU9InNtaW1lLnA3cyIKQ29udGVudC1UcmFuc2Zlci1FbmNvZGluZzogYmFzZTY0CkNvbnRlbnQtRGlzcG9zaXRpb246IGF0dGFjaG1lbnQ7IGZpbGVuYW1lPSJzbWltZS5wN3MiCgpNSUlGdkFZSktvWklodmNOQVFjQ29JSUZyVENDQmFrQ0FRRXhEekFOQmdsZ2hrZ0JaUU1FQWdFRkFEQUxCZ2txCmhraUc5dzBCQndHZ2dnTXpNSUlETHpDQ0FoZWdBd0lCQWdJSkFJTXpwWFFIcFN5YU1BMEdDU3FHU0liM0RRRUIKQ3dVQU1DNHhFakFRQmdOVkJBb01DVTVIU1U1WUlFbHVZekVZTUJZR0ExVUVBd3dQUTI5dWRISnZiR3hsY2lCRApRU0F4TUI0WERURTRNRFV4TVRFeU1UTTFNVm9YRFRJeU1EVXhNREV5TVRNMU1Wb3dMakVTTUJBR0ExVUVDZ3dKClRrZEpUbGdnU1c1ak1SZ3dGZ1lEVlFRRERBOURiMjUwY205c2JHVnlJRU5CSURFd2dnRWlNQTBHQ1NxR1NJYjMKRFFFQkFRVUFBNElCRHdBd2dnRUtBb0lCQVFEUlZjUkcxbldLVDJPL3NycjZZZnNNZzdFQ3lwR2hyaDNyRHNGZApFdXBLNVFkUTdNUi8zSGtiOTREWTh4OUxjSWQ1VWNmcVcxWll1c3hnWkZObHg5b3BtWWZpbmZpc1docXJldVlKCk1qcFVPNkgvNS8vWVE2TmxXTktBR0Myano2TGxHRCtXMDJqQVMzZEdQYzNFeU4vYWc3eVVzWEptSmV2RVQrdTAKcWxRcjRBcFlqdmdXU3Y0bWlXQmNqZjFtMTNzNUZUMGF1bCsxRUl6SFFYS2orbGFHTEhNS3NhRnQxR2gvcTB5WgpoS015cmlwWUxEakdRZU1Rb3N4NWxhQUFnSjdOM0xueFFuelJpQTZDdDlCRmJvcC8wRjdUNnY2NEFxQlBHbjRCCm16b2xDdmVzWWdpaytqdUNEbE1PRk1sVXhycVN6MUF2UWVQczhnWXFvYUFydFNjVEFnTUJBQUdqVURCT01CMEcKQTFVZERnUVdCQlFTYVdHbVdxc21Nc3N4V3ArWGpsemt3eW44WFRBZkJnTlZIU01FR0RBV2dCUVNhV0dtV3FzbQpNc3N4V3ArWGpsemt3eW44WFRBTUJnTlZIUk1FQlRBREFRSC9NQTBHQ1NxR1NJYjNEUUVCQ3dVQUE0SUJBUUNwCjd6YUQxTnZNMURURVB6a0NObzhCMG1QOGQxNEt1ZXlhWXBWL213TUtrQWtzbEx2cHcxOWovOXdaeDhGbTJaRk4KVE5CVFJiL21wSHRmTlBDUEpZMTNjbWVRSjZHUE1BNXhsZy9JTHdJYnNPN2xKejRsRmxYWWFNamgrK0d2RU8vawpYRWwvTlVGdE5xbXJiNHN6WEoyU2hicjJKMWgwelRGbmsydzFYM3BWcGlrMlZOakpmN3VUNnQ1VE5aV3BESEZ0CktXNGFmSXh3RTV1c1VxSzhEQXdicktrMUZCK3hLTVdOcFRLWDF5czZOK0ZmZVV5YzZIdVozSkZXM0I2WE0zKzkKTDlyZUpsaTJUUWtib2lCTVBJcUtkUkZUWi9sZGE0dHdNbmlERUY5WWRNN3pCdHpWZnhUaWY3UXlid2lndy9QMQpoVElGUWlpM1BJakt2Q3Jkd0ZCZk1ZSUNUVENDQWtrQ0FRRXdPekF1TVJJd0VBWURWUVFLREFsT1IwbE9XQ0JKCmJtTXhHREFXQmdOVkJBTU1EME52Ym5SeWIyeHNaWElnUTBFZ01RSUpBSU16cFhRSHBTeWFNQTBHQ1dDR1NBRmwKQXdRQ0FRVUFvSUhrTUJnR0NTcUdTSWIzRFFFSkF6RUxCZ2txaGtpRzl3MEJCd0V3SEFZSktvWklodmNOQVFrRgpNUThYRFRJeE1EUXdOekE0TURFek1Gb3dMd1lKS29aSWh2Y05BUWtFTVNJRUlJdEl1VithV2hpNUlNL1ZZdGNDClcrUk5CV2lLTnhkMW5mR29ja0srZ3NiYU1Ia0dDU3FHU0liM0RRRUpEekZzTUdvd0N3WUpZSVpJQVdVREJBRXEKTUFzR0NXQ0dTQUZsQXdRQkZqQUxCZ2xnaGtnQlpRTUVBUUl3Q2dZSUtvWklodmNOQXdjd0RnWUlLb1pJaHZjTgpBd0lDQWdDQU1BMEdDQ3FHU0liM0RRTUNBZ0ZBTUFjR0JTc09Bd0lITUEwR0NDcUdTSWIzRFFNQ0FnRW9NQTBHCkNTcUdTSWIzRFFFQkFRVUFCSUlCQUI2cjhZSi9oMVJ0blFwZUVhVkF5ejZLNmdzWVdWb2RQV1ZrZW1wT0tOQTcKcmJxblFZeTlMUlV2LzFwdnBJYU5BZHZJNzRPWjNiZkpBUGgyb2wzc0hmMzhwN0pPS2xZbGUxRm83MjkzUCtUOAp4a2FMQmRpdVNzUzAvTHdybHBGODFpcWNsWTczSHk5R3FBcWFUWTh0dy9RYkR0ZkZORkhtY1RoT3RzVDdTN2VmCkVwWDFNdnUwUnZ4WXdIWC85dXNEcWFPa0Zab1dZR3dEb3F3MngvQzI3MkZ4cWVsNXo1Y2lIL2htZ3JKS3hWOGIKdFRRYlZlVzAwQjBRZHBtZ0xsTjl5NVkzdnBoYldzVVA1YVR3cGFwWHUzZ1VqY20wb0FlYmJCM0pRNlplWGliUgpyaWhnd3ZOcDQybWtqWDh6S0pqVkFjcmRROVkwc1FLNEk4V24xUEV5S2hJPQoKLS0tLS0tRDg5RUYzMTMzQTIwNzY2QjUwMjE0ODIyNkMyODI0RjUtLQoK"}'
    EOF

  tags = {
    Name = "controller"
    Nginx = "nginx experience ${random_id.random-string.dec}"
  }
}
