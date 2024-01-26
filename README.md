## Use
copy files: `watch-dog.timer` and `watch-dog.service` into /etc/systemd/system directory
copy file: `check-services.sh` into `/usr/local/bin`

### Permissions
sudo chmod +x  /usr/local/bin/check-services.sh

### Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable watch-dog.timer
sudo systemctl start watch-dog.timer
sudo systemctl restart watch-dog.timer




