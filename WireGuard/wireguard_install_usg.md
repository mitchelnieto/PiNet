# Install WireGuard on Unifi USG 3
#### Use Curl to Download
curl -sL https://github.com/Lochnair/vyatta-wireguard/releases/download/0.0.20191219-2/wireguard-ugw4-0.0.20191219-2.deb -o wireguard.deb
#### Install debian package
sudo dpkg -i wireguard.deb
#### Delete Debian Package
rm wireguard.deb

#### Change Directory
cd /config/auth
#### Set User Only Access
umask 077 && mkdir wireguard && cd wireguard

#### Generate Key Pair
wg genkey | tee /config/auth/wg.key | wg pubkey >  wg.public
