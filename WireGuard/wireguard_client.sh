
#!/bin/bash
run=/opt/vyatta/bin/vyatta-op-cmd-wrapper


# This script will add a new peer to your router Wireguard
# server and present the conf file and QR code.
# Copy/paste/import the conf file settings, or use the WG
# mobile app to scan the QR code.
# It keeps track of used IP addresses and provides a new,
# unused IP for each peer created.

# variables - update the variables below to match your
# WireGuard config before you run the script


# path - where you want the script to store files it creates
# Each run creates a .conf and .peer file for that peer.
path=/home/admin/wireguard/clients
# router public key
routerpubkey= #Enter Your PublicKey#
# router WireGuard IP (up to third octet)
routerip=10.1.16
# DNS
dns=1.1.1.1
# Endpoint - router ext ip/hostname/dydns
endpoint=#wireguard.yourdomain.com
# port
port=51820
# allowed ips
allowedips=0.0.0.0/0


# After saving the script, make sure to make it executable:
# sudo chmod +x <path><scriptname>


# Now create a text file for the script to manage IP address.
# Create the text file in the path you set in the variables above.
# Name the file: nextip.txt.
# The file should contain only the value for the last octet
# of the next peer IP, i.e., the "x" in 192.168.33.x.
# E.g., if your current highest peer IP is set 192.168.33.4, the
# nextip.txt file should have the number 5 in it.
# chmod the file so it is editable by the script:
# e.g., sudo chmod 777 <path>nextip.txt.


# The script uses the nextip.txt file to assign the allowed IP to
# each peer you create. The script increments the value in
# the nextip.txt file each time it is run (e.g., from 5 to 6), so that
# you get a fresh unused IP address for each peer.


# ====================================
# Usage: <scriptname> <filename>


# Each time you run the script, two files are created in
# the path you set in the variables above:
# 1) <filename>.conf; and 2: <filename>.peer


# Use the .conf file for copy/paste/import if you aren't
# scanning the QR code from a mobile app

# =======================================

# Here we go…

myname=`basename $0`

if test $# != 1
then
  echo Usage: $myname confname 1>&2
  exit 1
fi

# Sets path to the conf & peer files the script creates
file=$path/$1.conf
peer=$path/$1.peer

# Makes sure the .conf and .peer file prefixes don't already exist.
if test -f $file
then
  echo $myname: $file already exists 2>&2
  exit 2
fi

# Ensures the QR code fits on the screen, prompts if
# CLI window needs to be resized
set -- `stty size`
if test $1 -lt 34
then
  echo $myname: Increase your terminal to at least 34 lines
  exit 3
fi

# Generates new private and public keys for the new device
priv=`wg genkey`
pub=`echo $priv | wg pubkey`
ipnum=`cat $path/nextip.txt`

# Creates the new conf file
cat > $file <<END
[Interface]
PrivateKey = $priv
Address = $routerip.$ipnum/32
DNS = $dns

[Peer]
PublicKey = $routerpubkey
Endpoint = $endpoint:$port
AllowedIPs = $allowedips
END

# Shows the .conf file to the user, to confirm it looks OK
echo ""
echo -n "-------------------------------"
echo ""
cat $file
echo ""
echo -n "-------------------------------"
echo ""
echo -n "Review your new peer config above."
echo

# Prompts to confirm OK to add the peer to router's WireGuard config
echo ""
echo -n "Commit? This will add this peer to your WireGuard config.  [Y/n]: "

read x
if test x$x = x -o x$x = xy -o x$x = xY
then
  # If accepted, create the peer file for the server
  rm -f $peer
  # Sets the IP number to be used the next time the script runs
  echo `expr $ipnum + 1` > $path/nextip.txt
  (
    echo '[Peer]'
    echo PublicKey = $pub
    echo AllowedIPs = $routerip.$ipnum/32
  ) > $peer

# Sets the new config
/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper begin
/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper set interfaces wireguard wg0 peer $pub allowed-ips 10.1.16.$ipnum/32
/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper commit

# Displays the new peer file, copy/paste for import if desired
echo ""
echo -n "-------------------------------"
echo ""
cat $file
echo ""
echo -n "-------------------------------"
echo ""
echo -n "Your new configuration."
echo ""

# Displays the the  QR code for scanning from mobile apps
#  qrencode -t ansiutf8 < $file
   qrencode -t PNG -o $file.png < $file
echo ""
echo -n "Your new QR code."
echo ""
 echo You can remove $file when code is scanned
else
  rm -f $file
fi
