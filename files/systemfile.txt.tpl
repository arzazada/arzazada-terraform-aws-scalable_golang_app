  [Unit]
  Description=MyService
  After=network.target

  [Service]
  User=root
  ExecStart=${appdir}/main
  WorkingDirectory=${appdir}
  Restart=always
  StandardOutput=file:${appdir}/main.log
  StandardError=file:${appdir}/main.log

  [Install]
  WantedBy=multi-user.target