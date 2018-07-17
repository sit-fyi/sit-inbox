if ! [ -f /.initialized ]; then
  pushd $(pwd)
  # Configure git
  git config --global user.name "test"
  git config --global user.email "test@test"
  # Initialize a repo
  mkdir /repo
  cd /repo
  git init
  sit init
  git add .sit
  git commit -m "init"
  cd ..
  git clone --bare /repo /repo.test
  git clone --bare /repo /repo1.test
  mkdir -p /playbook/roles/common/vars
  toml2yaml /tests/fixtures/config.toml > /playbook/roles/common/vars/main.yml
  ANSIBLE_STDOUT_CALLBACK=unixy ansible-playbook /playbook/playbook.yml
  popd
  syslogd
  cat <<EOF >/usr/sbin/sendmail
#! /usr/bin/env bash
cat <&0 > /root/sent
EOF
  chmod +x /usr/sbin/sendmail
  touch /.initialized
fi
