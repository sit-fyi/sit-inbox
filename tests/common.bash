reinit_repo () {
  rm -rf $2
  git clone --bare /repo $2
  cp /var/lib/repositories/$1/.git/config /tmp/config
  rm -rf /var/lib/repositories/$1
  git clone $2 /var/lib/repositories/$1
  mv /tmp/config /var/lib/repositories/$1/.git/config

}
