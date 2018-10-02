load common

setup () {
  reinit_repo repo /repo.test
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
  echo "${lines[3]}" >&1
  [[ "${lines[3]}" =~ "Patch applied and pushed" ]]
  head=$(git -C /repo.test show HEAD)
  [[ "${head}" =~ "correct patch" ]]
  [[ "${head}" =~ "Signed-off-by: sit-inbox <inbox@sit>" ]]
  run cat /root/sent
  [ "$status" -eq 0 ]
  [[ "${output}" =~ "From: sit@inbox" ]]
  [[ "${output}" =~ "To: test <test@test>" ]]
  [[ "${output}" =~ "Subject: Re: [PATCH] correct patch" ]]
  [[ "${output}" =~ "It has been successfully pushed to the master repository" ]]
}

@test "git patch workflow: email with a correct patch for a branch" {
  tmp=$(mktemp -d)
  git clone /repo.test "${tmp}/repo"
  cd ${tmp}/repo
  item=$(sit item)
  sit record -t Test ${item}
  git config user.email branch@test
  git add .sit
  git commit -m "correct patch"
  git format-patch origin/master
  run email.repo-branch <*.patch
  rm -rf ${tmp}
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" =~ "From: test <branch@test>" ]]
  [[ "${lines[2]}" =~ "Subject: [PATCH] correct patch" ]]
  [[ "${lines[3]}" =~ "Patch applied and pushed" ]]
  head=$(git -C /repo.test show test-branch)
  [[ "${head}" =~ "correct patch" ]]
  [[ "${head}" =~ "Signed-off-by: sit-inbox <inbox@sit>" ]]
  run cat /root/sent
  [ "$status" -eq 0 ]
  [[ "${output}" =~ "From: sit@inbox" ]]
  [[ "${output}" =~ "To: test <branch@test>" ]]
  [[ "${output}" =~ "Subject: Re: [PATCH] correct patch" ]]
  [[ "${output}" =~ "It has been successfully pushed to the master repository" ]]
}


@test "git patch workflow: email with a correct patch for a top repo" {
  tmp=$(mktemp -d)
  git clone /repo.test "${tmp}/repo"
  cd ${tmp}/repo
  # TODO: since `sit init -u` not available in a release yet, work around it
  mkdir _temp
  cd _temp
  sit init
  cd ..
  mv _temp/.sit/* .
  rm -rf _temp
  # Push it out to the target repo
  git add config.json
  git commit -m "init top"
  git push /repo.test
  #
  item=$(sit -r . item)
  sit -r . record -t Test ${item}
  git add .
  git commit -m "correct patch"
  git format-patch HEAD^1..HEAD
  run email.repo <*.patch
  rm -rf ${tmp}
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" =~ "From: test <test@test>" ]]
  [[ "${lines[2]}" =~ "Subject: [PATCH] correct patch" ]]
  [[ "${lines[3]}" =~ "Patch applied and pushed" ]]
  head=$(git -C /repo.test show HEAD)
  [[ "${head}" =~ "correct patch" ]]
  [[ "${head}" =~ "Signed-off-by: sit-inbox <inbox@sit>" ]]
  run cat /root/sent
  [ "$status" -eq 0 ]
  [[ "${output}" =~ "From: sit@inbox" ]]
  [[ "${output}" =~ "To: test <test@test>" ]]
  [[ "${output}" =~ "Subject: Re: [PATCH] correct patch" ]]
  [[ "${output}" =~ "It has been successfully pushed to the master repository" ]]
}

@test "git patch workflow: email with a correct patch for a sub repo" {
  tmp=$(mktemp -d)
  git clone /repo.test "${tmp}/repo"
  cd ${tmp}/repo
  # subrepos
  mkdir -p subrepos/{sub1,sub2}
  sit -d subrepos/sub1 init
  sit -d subrepos/sub2 init
  # Push it out to the target repo
  git add subrepos
  git commit -m "init subrepos"
  git push /repo.test
  #
  item1=$(sit -d subrepos/sub1 item)
  sit -d subrepos/sub1 record -t Test ${item1}
  item2=$(sit -d subrepos/sub2 item)
  sit -d subrepos/sub2 record -t Test ${item2}
  git add subrepos
  git commit -m "correct patch"
  git format-patch HEAD^1..HEAD
  run email.repo <*.patch
  rm -rf ${tmp}
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" =~ "From: test <test@test>" ]]
  [[ "${lines[2]}" =~ "Subject: [PATCH] correct patch" ]]
  [[ "${lines[3]}" =~ "Patch applied and pushed" ]]
  head=$(git -C /repo.test show HEAD)
  [[ "${head}" =~ "correct patch" ]]
  [[ "${head}" =~ "Signed-off-by: sit-inbox <inbox@sit>" ]]
  run cat /root/sent
  [ "$status" -eq 0 ]
  [[ "${output}" =~ "From: sit@inbox" ]]
  [[ "${output}" =~ "To: test <test@test>" ]]
  [[ "${output}" =~ "Subject: Re: [PATCH] correct patch" ]]
  [[ "${output}" =~ "It has been successfully pushed to the master repository" ]]
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
  if [ -d ".sit/items/${item}/${record}" ]; then
      touch ".sit/items/${item}/${record}/test"
      git add ".sit/items/${item}/${record}/test"
  else
      touch `pwd`/.sit/items/${item}/`cat ".sit/items/${item}/${record}"`/test
      git add `pwd`/.sit/items/${item}/`cat ".sit/items/${item}/${record}"`/test
  fi 
  git commit -m "updated"
  git format-patch origin/master
  run email.repo <*.patch
  [ "$status" -eq 0 ]
  echo "$output"
  [[ "${lines[3]}" =~ "Patch rejected" ]]
  if [ -d ".sit/items/${item}/${record}" ]; then
      [[ "${lines[4]}" =~ "Record ${item}/${record} already exists in the target repository" ]]
  else
      [[ "${lines[4]}" =~ "Record ${record} already exists in the target repository" ]]
  fi
  run cat /root/sent
  [ "$status" -eq 0 ]
  [[ "${output}" =~ "From: sit@inbox" ]]
  [[ "${output}" =~ "To: test <test@test>" ]]
  [[ "${output}" =~ "Subject: Re: [PATCH] updated" ]]
  [[ "${output}" =~ "Please resolve the following issues" ]]
  if [ -d ".sit/items/${item}/${record}" ]; then
      [[ "${output}" =~ "Record ${item}/${record} already exists in the target repository" ]]
  else
      [[ "${output}" =~ "Record ${record} already exists in the target repository" ]]
  fi
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
  if [ -d ".sit/items/${item}/${record}" ]; then
      git rm ".sit/items/${item}/${record}/.type/Test"
      echo "new authors" > ".sit/items/${item}/${record}/.authors"
      git add ".sit/items/${item}/${record}"
  else
      _path=`pwd`/.sit/items/${item}/`cat ".sit/items/${item}/${record}"`
      git rm "${_path}/.type/Test"
      echo "new authors" > "${_path}/.authors"
      git add ".sit/records"
  fi
  git commit -m "updated"
  git format-patch origin/master
  run email.repo <*.patch
  [ "$status" -eq 0 ]
  [[ "${lines[3]}" =~ "Patch rejected" ]]
  [[ "${lines[4]}" =~ "${record}/.authors already exists in the target repository" ]]
  [[ "${lines[5]}" =~ "${record}/.type/Test already exists in the target repository" ]]
  rm -rf "${tmp}"
  run cat /root/sent
  [ "$status" -eq 0 ]
  [[ "${output}" =~ "From: sit@inbox" ]]
  [[ "${output}" =~ "To: test <test@test>" ]]
  [[ "${output}" =~ "Subject: Re: [PATCH] updated" ]]
  [[ "${output}" =~ "Please resolve the following issues" ]]
  [[ "${output}" =~ "${record}/.authors already exists in the target repository" ]]
  [[ "${output}" =~ "${record}/.type/Test already exists in the target repository" ]]
}

@test "git patch workflow: email with a patch with files outside of record storage" {
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
  [[ "${lines[5]}" =~ ".sit/a is outside of subrepos" ]]
  [[ "${lines[6]}" =~ ".sit/a is outside of items" ]]
  [[ "${lines[7]}" =~ "a is outside of .sit/items" ]]
  [[ "${lines[8]}" =~ "a is outside of subrepos" ]]
  [[ "${lines[9]}" =~ "a is outside of items" ]]
  run cat /root/sent
  [ "$status" -eq 0 ]
  [[ "${output}" =~ "From: sit@inbox" ]]
  [[ "${output}" =~ "To: test <test@test>" ]]
  [[ "${output}" =~ "Subject: Re: [PATCH] files outside" ]]
  [[ "${output}" =~ "Please resolve the following issues" ]]
  [[ "${output}" =~ ".sit/a is outside of .sit/items" ]]
  [[ "${output}" =~ ".sit/a is outside of subrepos" ]]
  [[ "${output}" =~ ".sit/a is outside of items" ]]
  [[ "${output}" =~ "a is outside of .sit/items" ]]
  [[ "${output}" =~ "a is outside of subrepos" ]]
  [[ "${output}" =~ "a is outside of items" ]]
}

@test "git patch workflow: email with a conflicting patch" {
  tmp0=$(mktemp -d)
  git clone /repo.test "${tmp0}/repo"
  tmp=$(mktemp -d)
  git clone /repo.test "${tmp}/repo"
  cd ${tmp}/repo
  item=$(sit item)
  record=$(sit record -t Test ${item})
  git add .sit
  git commit -m "correct patch"
  git format-patch origin/master
  run email.repo <*.patch
  [ "$status" -eq 0 ]
  # Now, try to simulate a conflict
  cd "${tmp0}/repo"
  if [ -d "${tmp}/repo/.sit/items/${item}/${record}" ]; then
      mkdir -p .sit/items/${item}/${record}
      echo test > .sit/items/${item}/${record}/.timestamp
  else
      _path=.sit/items/${item}/`cat "${tmp}/repo/.sit/items/${item}/${record}"`
      mkdir -p ${_path}
      echo test > ${_path}/.timestamp
      _path=`realpath ${_path} --relative-to=.`
  fi
  git add .sit
  git commit -m "correct patch"
  git format-patch origin/master
  run email.repo <*.patch
  [ "$status" -eq 0 ]
  [[ "${lines[3]}" =~ "Patch rejected" ]]

  if [ -d "${tmp}/repo/.sit/items/${item}/${record}" ]; then
      [[ "${output}" =~ "Merge conflict in .sit/items/${item}/${record}/.timestamp" ]]
  else
      [[ "${output}" =~ "Merge conflict in ${_path}/.timestamp" ]]
  fi

  run cat /root/sent
  [ "$status" -eq 0 ]
  [[ "${output}" =~ "From: sit@inbox" ]]
  [[ "${output}" =~ "To: test <test@test>" ]]
  [[ "${output}" =~ "Subject: Re: [PATCH] correct patch" ]]
  [[ "${output}" =~ "Please resolve the following issue" ]]
  if [ -d "${tmp}/repo/.sit/items/${item}/${record}" ]; then
      [[ "${output}" =~ "Merge conflict in .sit/items/${item}/${record}/.timestamp" ]]
  else
      [[ "${output}" =~ "Merge conflict in ${_path}/.timestamp" ]]
  fi
  rm -rf ${tmp} ${tmp0}
}

