#!/bin/sh
# Lab : mot de passe "deploy" pour la 1re connexion (ssh-copy-id depuis Jenkins, atelier 05)
echo "deploy:deploy" | chpasswd
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
exec /usr/sbin/sshd -D -e
