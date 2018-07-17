load common

setup() {
  reinit_repo repo1 /repo1.test
}

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

@test "email: routing to different repositories via email-ingress argument" {
  tmp=$(mktemp -d)
  git clone /repo.test "${tmp}/repo"
  cd ${tmp}/repo
  item=$(sit item)
  sit record -t Test ${item}
  git add .sit
  git commit -m "correct patch"
  git format-patch origin/master
  run email-ingress repo1 <*.patch
  rm -rf ${tmp}
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" =~ "From: test <test@test>" ]]
  [[ "${lines[2]}" =~ "Subject: [PATCH] correct patch" ]]
  [[ "${lines[3]}" =~ "Patch applied and pushed" ]]
  head=$(git -C /repo1.test show HEAD)
  [[ "${head}" =~ "correct patch" ]]
  [[ "${head}" =~ "Signed-off-by: sit-inbox <inbox@sit>" ]]
}

@test "email: routing to different repositories via email-ingress argument (maildrop)" {
  tmp=$(mktemp -d)
  git clone /repo.test "${tmp}/repo"
  cd ${tmp}/repo
  item=$(sit item)
  sit record -t Test ${item}
  git add .sit
  git config user.email special@test
  git commit -m "correct patch"
  git format-patch origin/master
  REPOSITORY=repo run maildrop -f special@test /root/.getmail/maildrop.email <*.patch
  rm -rf ${tmp}
  echo "${output}"
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" =~ "From: test <special@test>" ]]
  [[ "${lines[2]}" =~ "Subject: [PATCH] correct patch" ]]
  [[ "${lines[3]}" =~ "Patch applied and pushed" ]]
  head=$(git -C /repo1.test show HEAD)
  [[ "${head}" =~ "correct patch" ]]
  [[ "${head}" =~ "Signed-off-by: sit-inbox <inbox@sit>" ]]
}
