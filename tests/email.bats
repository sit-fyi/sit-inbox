@test "email: getmail -> maildrop setup" {
  echo -n > /root/mbox
  mkdir -p /mbox/new

  cat >/mbox/new/msg <<EOF
  From: test@test
  To: test@test

  Hello
EOF
  check-email
  run cat /root/mbox
  [[ "${output}" =~ "X-getmail-retrieved-from-mailbox" ]]
  [[ "${output}" =~ "Hello" ]]
}
