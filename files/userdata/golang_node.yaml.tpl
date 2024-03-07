#cloud-config

write_files:
  - path: root/config.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:AmazonCloudWatch-linux
      aws ssm get-parameter --name '/demo-app/systemdfile' --query 'Parameter.Value' --output text --with-decryptio > /etc/systemd/system/demo-app.service
      sudo systemctl daemon-reload
      sudo systemctl enable demo-app.service
      sudo systemctl start demo-app.service"

packages:
  - vim

runcmd:
  - [ sh, -c, '/root/config.sh' ]
  - [ sh, -c, 'timedatectl set-timezone Asia/Baku' ]