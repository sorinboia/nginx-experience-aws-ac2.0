
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
      wget https://sorinnginx.s3.eu-central-1.amazonaws.com/controller-installer-3.15-6.0.tar.gz -O /home/ubuntu/controller.tar.gz
      tar zxvf /home/ubuntu/controller.tar.gz -C /home/ubuntu/
      host_ip=$(curl -s ifconfig.me)
      export HOME=/home/ubuntu
      runuser -l ubuntu -c 'host_ip=$(curl -s ifconfig.me) && /home/ubuntu/controller-installer/install.sh -n --accept-license --smtp-host $host_ip --smtp-port 25 --smtp-authentication false --smtp-use-tls false --noreply-address no-reply@sorin.nginx --fqdn $host_ip --organization-name nginx1 --admin-firstname NGINX --admin-lastname Admin --admin-email admin@nginx.com --admin-password Admin2021 --self-signed-cert --auto-install-docker --configdb-volume-type local --tsdb-volume-type local'
      curl -k -c cookie.txt -X POST --url "https://$host_ip/api/v1/platform/login" --header 'Content-Type: application/json' --data '{"credentials": {"type": "BASIC","username": "admin@nginx.com","password": "Admin2021"}}'
      curl -k -b cookie.txt -c cookie.txt --header "Content-Type: application/json" --request POST --url "https://$host_ip/api/v1/platform/license-file" --data '{"content":"TUlNRS1WZXJzaW9uOiAxLjAKQ29udGVudC1UeXBlOiBtdWx0aXBhcnQvc2lnbmVkOyBwcm90b2NvbD0iYXBwbGljYXRpb24veC1wa2NzNy1zaWduYXR1cmUiOyBtaWNhbGc9InNoYS0yNTYiOyBib3VuZGFyeT0iLS0tLUE1NTJEQTM3QjExRDdCMDc5MUIwNDQ4MkJFRDc3MkQwIgoKVGhpcyBpcyBhbiBTL01JTUUgc2lnbmVkIG1lc3NhZ2UKCi0tLS0tLUE1NTJEQTM3QjExRDdCMDc5MUIwNDQ4MkJFRDc3MkQwCld3b2dJQ0FnZXdvZ0lDQWdJQ0FnSUNKbGVIQnBjbmtpT2lBaU1qQXlNUzB4TVMweU1WUXhNam96TURvek1DNDNPVGMzTnpCYUlpd2cKQ2lBZ0lDQWdJQ0FnSW14cGJXbDBjeUk2SURJd0xDQUtJQ0FnSUNBZ0lDQWljSEp2WkhWamRDSTZJQ0pPUjBsT1dDQkRiMjUwY205cwpiR1Z5SUV4dllXUWdRbUZzWVc1amFXNW5JaXdnQ2lBZ0lDQWdJQ0FnSW5ObGNtbGhiQ0k2SURNNE1EY3NJQW9nSUNBZ0lDQWdJQ0p6CmRXSnpZM0pwY0hScGIyNGlPaUFpU1RBd01ERXhOVE01TXlJc0lBb2dJQ0FnSUNBZ0lDSjBlWEJsSWpvZ0ltbHVkR1Z5Ym1Gc0lpd2cKQ2lBZ0lDQWdJQ0FnSW5abGNuTnBiMjRpT2lBeENpQWdJQ0I5TENBS0lDQWdJSHNLSUNBZ0lDQWdJQ0FpWlhod2FYSjVJam9nSWpJdwpNakV0TVRFdE1qRlVNVEk2TXpBNk16QXVOemszTkRVeldpSXNJQW9nSUNBZ0lDQWdJQ0pzYVcxcGRITWlPaUE1T1RrNU9Td2dDaUFnCklDQWdJQ0FnSW14cGJXbDBjMTloY0dsZlkyRnNiSE1pT2lBeU1EQXdNREF3TUN3Z0NpQWdJQ0FnSUNBZ0luQnliMlIxWTNRaU9pQWkKVGtkSlRsZ2dRMjl1ZEhKdmJHeGxjaUJCVUVrZ1RXRnVZV2RsYldWdWRDSXNJQW9nSUNBZ0lDQWdJQ0p6WlhKcFlXd2lPaUF6T0RBMwpMQ0FLSUNBZ0lDQWdJQ0FpYzNWaWMyTnlhWEIwYVc5dUlqb2dJa2t3TURBeE1UVXpPVE1pTENBS0lDQWdJQ0FnSUNBaWRIbHdaU0k2CklDSnBiblJsY201aGJDSXNJQW9nSUNBZ0lDQWdJQ0oyWlhKemFXOXVJam9nTVFvZ0lDQWdmUXBkCgotLS0tLS1BNTUyREEzN0IxMUQ3QjA3OTFCMDQ0ODJCRUQ3NzJEMApDb250ZW50LVR5cGU6IGFwcGxpY2F0aW9uL3gtcGtjczctc2lnbmF0dXJlOyBuYW1lPSJzbWltZS5wN3MiCkNvbnRlbnQtVHJhbnNmZXItRW5jb2Rpbmc6IGJhc2U2NApDb250ZW50LURpc3Bvc2l0aW9uOiBhdHRhY2htZW50OyBmaWxlbmFtZT0ic21pbWUucDdzIgoKTUlJRnZBWUpLb1pJaHZjTkFRY0NvSUlGclRDQ0Jha0NBUUV4RHpBTkJnbGdoa2dCWlFNRUFnRUZBREFMQmdrcQpoa2lHOXcwQkJ3R2dnZ016TUlJREx6Q0NBaGVnQXdJQkFnSUpBSU16cFhRSHBTeWFNQTBHQ1NxR1NJYjNEUUVCCkN3VUFNQzR4RWpBUUJnTlZCQW9NQ1U1SFNVNVlJRWx1WXpFWU1CWUdBMVVFQXd3UFEyOXVkSEp2Ykd4bGNpQkQKUVNBeE1CNFhEVEU0TURVeE1URXlNVE0xTVZvWERUSXlNRFV4TURFeU1UTTFNVm93TGpFU01CQUdBMVVFQ2d3SgpUa2RKVGxnZ1NXNWpNUmd3RmdZRFZRUUREQTlEYjI1MGNtOXNiR1Z5SUVOQklERXdnZ0VpTUEwR0NTcUdTSWIzCkRRRUJBUVVBQTRJQkR3QXdnZ0VLQW9JQkFRRFJWY1JHMW5XS1QyTy9zcnI2WWZzTWc3RUN5cEdocmgzckRzRmQKRXVwSzVRZFE3TVIvM0hrYjk0RFk4eDlMY0lkNVVjZnFXMVpZdXN4Z1pGTmx4OW9wbVlmaW5maXNXaHFyZXVZSgpNanBVTzZILzUvL1lRNk5sV05LQUdDMmp6NkxsR0QrVzAyakFTM2RHUGMzRXlOL2FnN3lVc1hKbUpldkVUK3UwCnFsUXI0QXBZanZnV1N2NG1pV0JjamYxbTEzczVGVDBhdWwrMUVJekhRWEtqK2xhR0xITUtzYUZ0MUdoL3EweVoKaEtNeXJpcFlMRGpHUWVNUW9zeDVsYUFBZ0o3TjNMbnhRbnpSaUE2Q3Q5QkZib3AvMEY3VDZ2NjRBcUJQR240Qgptem9sQ3Zlc1lnaWsranVDRGxNT0ZNbFV4cnFTejFBdlFlUHM4Z1lxb2FBcnRTY1RBZ01CQUFHalVEQk9NQjBHCkExVWREZ1FXQkJRU2FXR21XcXNtTXNzeFdwK1hqbHprd3luOFhUQWZCZ05WSFNNRUdEQVdnQlFTYVdHbVdxc20KTXNzeFdwK1hqbHprd3luOFhUQU1CZ05WSFJNRUJUQURBUUgvTUEwR0NTcUdTSWIzRFFFQkN3VUFBNElCQVFDcAo3emFEMU52TTFEVEVQemtDTm84QjBtUDhkMTRLdWV5YVlwVi9td01La0Frc2xMdnB3MTlqLzl3Wng4Rm0yWkZOClROQlRSYi9tcEh0Zk5QQ1BKWTEzY21lUUo2R1BNQTV4bGcvSUx3SWJzTzdsSno0bEZsWFlhTWpoKytHdkVPL2sKWEVsL05VRnROcW1yYjRzelhKMlNoYnIySjFoMHpURm5rMncxWDNwVnBpazJWTmpKZjd1VDZ0NVROWldwREhGdApLVzRhZkl4d0U1dXNVcUs4REF3YnJLazFGQit4S01XTnBUS1gxeXM2TitGZmVVeWM2SHVaM0pGVzNCNlhNMys5Ckw5cmVKbGkyVFFrYm9pQk1QSXFLZFJGVFovbGRhNHR3TW5pREVGOVlkTTd6QnR6VmZ4VGlmN1F5YndpZ3cvUDEKaFRJRlFpaTNQSWpLdkNyZHdGQmZNWUlDVFRDQ0Fra0NBUUV3T3pBdU1SSXdFQVlEVlFRS0RBbE9SMGxPV0NCSgpibU14R0RBV0JnTlZCQU1NRDBOdmJuUnliMnhzWlhJZ1EwRWdNUUlKQUlNenBYUUhwU3lhTUEwR0NXQ0dTQUZsCkF3UUNBUVVBb0lIa01CZ0dDU3FHU0liM0RRRUpBekVMQmdrcWhraUc5dzBCQndFd0hBWUpLb1pJaHZjTkFRa0YKTVE4WERUSXhNRGt5TWpFeU16QXpNRm93THdZSktvWklodmNOQVFrRU1TSUVJSHRBcUZyQXh4R04ycC9ZSEZMcwpMM1dFTUNXMXIvRyt0R0ZiV0I3M053YXpNSGtHQ1NxR1NJYjNEUUVKRHpGc01Hb3dDd1lKWUlaSUFXVURCQUVxCk1Bc0dDV0NHU0FGbEF3UUJGakFMQmdsZ2hrZ0JaUU1FQVFJd0NnWUlLb1pJaHZjTkF3Y3dEZ1lJS29aSWh2Y04KQXdJQ0FnQ0FNQTBHQ0NxR1NJYjNEUU1DQWdGQU1BY0dCU3NPQXdJSE1BMEdDQ3FHU0liM0RRTUNBZ0VvTUEwRwpDU3FHU0liM0RRRUJBUVVBQklJQkFEa1BrQmZWdTJWTXp0RklJbThVakx4R0dXeDNwRmN6b1ZuaUpvT2cvdmJKCmJJbnhoUytjYW5pV251UW9ORTFwOCtvTGtQWUJIc1hsSW5RdXpRQ3I0THdzdmVIcmJpWWhxRThKZFlVRTkxblkKMkJBdE5hUEplUUE4d3JXYkcyUHRTZHNmUGc4eUdleHVHeGVOOVpHTE1QRjJsNm93aHZxczk5MHpCN3ZpSGIrWApma1o5ekpiYUlIOUFTU0R2Wm8rMVlZZllBVUFuOXYzZGp1clExQ0lkY3J1bEFWaXdkcWt1cDRQSHhVM2g4YnplCjJJZ1pBaG1PVmpIVXllTzh1SWZQaGx0dkxYSmZjb0NTOHZqWCt0Mkh3WXFOZ29Xa09IdmxvVi9oOHhiTWlpYTEKaGRmNGNZMnRlSW1EdU5sV09CWGJqYnJSRkNZMWlpU3BJMnIxMXQ1Ynhrdz0KCi0tLS0tLUE1NTJEQTM3QjExRDdCMDc5MUIwNDQ4MkJFRDc3MkQwLS0KCg=="}'
    EOF

  tags = {
    Name = "controller"
    Nginx = "nginx experience ${random_id.random-string.dec}"
  }
}
