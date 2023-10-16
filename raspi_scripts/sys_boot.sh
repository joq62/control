[Unit]
Description= Sys boot to start rpi from reset
After=network.target

[Service]
Type=forking
ExecStart=/home/ubuntu/sys_boot.sh
PIDFile=/run/my-service.pid   ???
Restart=on-failure	      ???

[Install]
WantedBy=multi-user.target
