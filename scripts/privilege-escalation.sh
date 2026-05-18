sudo bash -c 'for i in $(seq 1 20); do
  echo "$(date "+%b %d %T") kworung sudo: auth failure; logname=hacker uid=1000 euid=0 tty=/dev/pts/0 ruser=hacker rhost= user=root" >> /var/log/auth.log
  echo "$(date "+%b %d %T") kworung su[$$]: BAD SU hacker to root on /dev/pts/0" >> /var/log/auth.log
  sleep 0.2
done'