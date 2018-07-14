setup () {
  rm -rf /repo.test
  git clone --bare /repo /repo.test
  cp /var/lib/repositories/repo/.git/config /tmp/config
  rm -rf /var/lib/repositories/repo
  git clone /repo.test /var/lib/repositories/repo
  mv /tmp/config /var/lib/repositories/repo/.git/config
}

@test "git patch workflow: email with no patch" {
  run email.repo <<EOF
From: test@test
Subject: test

Hello!
EOF
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" =~ "From: test@test" ]]
  [[ "${lines[1]}" =~ "Subject: test" ]]
  [[ "${lines[2]}" =~ "No patch found, skipping" ]]
}

@test "git patch workflow: email with a correct patch" {
  tmp=$(mktemp -d)
  git clone /repo.test "${tmp}/repo"
  cd ${tmp}/repo
  item=$(sit item)
  sit record -t Test ${item}
  git add .sit
  git commit -m "correct patch"
  git format-patch origin/master
  run email.repo <*.patch
  rm -rf ${tmp}
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" =~ "From: test <test@test>" ]]
  [[ "${lines[2]}" =~ "Subject: [PATCH] correct patch" ]]
  [[ "${lines[3]}" =~ "Patch applied and pushed" ]]
  head=$(git -C /repo.test show HEAD)
  [[ "${head}" =~ "correct patch" ]]
  [[ "${head}" =~ "Signed-off-by: sit-inbox <inbox@sit>" ]]
}

@test "git patch workflow: email with a patch with a conflicting record" {
  tmp=$(mktemp -d)
  git clone /repo.test "${tmp}/repo"
  cd ${tmp}/repo
  item=$(sit item)
  record=$(sit record -t Test ${item})
  git add .sit
  git commit -m "correct patch"
  git format-patch origin/master
  run email.repo <*.patch
  cd /
  rm -rf "${tmp}"
  [ "$status" -eq 0 ]
  [[ "${lines[3]}" =~ "Patch applied and pushed" ]]
  tmp=$(mktemp -d)
  git clone /repo.test "${tmp}/repo"
  cd ${tmp}/repo
  touch ".sit/items/${item}/${record}/test"
  git add ".sit/items/${item}/${record}/test"
  git commit -m "updated"
  git format-patch origin/master
  run email.repo <*.patch
  [ "$status" -eq 0 ]
  [[ "${lines[3]}" =~ "Patch rejected" ]]
  [[ "${lines[4]}" =~ "Record ${item}/${record} already exists in the target repository" ]]
  rm -rf "${tmp}"
}

@test "git patch workflow: email with a patch manipulating existing files" {
  tmp=$(mktemp -d)
  git clone /repo.test "${tmp}/repo"
  cd ${tmp}/repo
  item=$(sit item)
  record=$(sit record -t Test ${item})
  git add .sit
  git commit -m "correct patch"
  git format-patch origin/master
  run email.repo <*.patch
  cd /
  rm -rf "${tmp}"
  [ "$status" -eq 0 ]
  [[ "${lines[3]}" =~ "Patch applied and pushed" ]]
  tmp=$(mktemp -d)
  git clone /repo.test "${tmp}/repo"
  cd ${tmp}/repo
  git rm ".sit/items/${item}/${record}/.type/Test"
  echo "new authors" > ".sit/items/${item}/${record}/.authors"
  git add ".sit/items/${item}/${record}"
  git commit -m "updated"
  git format-patch origin/master
  run email.repo <*.patch
  [ "$status" -eq 0 ]
  [[ "${lines[3]}" =~ "Patch rejected" ]]
  [[ "${lines[4]}" =~ "File .sit/items/${item}/${record}/.authors already exists in the target repository" ]]
  [[ "${lines[5]}" =~ "File .sit/items/${item}/${record}/.type/Test already exists in the target repository" ]]
  rm -rf "${tmp}"
}

@test "git patch workflow: email with a patch with files outside of .sit/items" {
  tmp=$(mktemp -d)
  git clone /repo.test "${tmp}/repo"
  cd ${tmp}/repo
  commit=$(git rev-parse HEAD)
  touch a .sit/a
  git add a .sit/a
  git commit -m "files outside"
  git format-patch origin/master
  run email.repo <*.patch
  rm -rf ${tmp}
  [ "$status" -eq 0 ]
  origin_commit=$(git -C /repo.test rev-parse HEAD)
  [ "${origin_commit}" == "${commit}" ]
  [[ "${lines[0]}" =~ "From: test <test@test>" ]]
  [[ "${lines[2]}" =~ "Subject: [PATCH] files outside" ]]
  [[ "${lines[3]}" =~ "Patch rejected" ]]
  [[ "${lines[4]}" =~ ".sit/a is outside of .sit/items" ]]
  [[ "${lines[5]}" =~ "a is outside of .sit/items" ]]
}
