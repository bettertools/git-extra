# git-fetchout

This tool allows you to fetch and checkout a remote branch into a local branch, i.e.

```
git fetchout origin master
```

This operation is done often especially when interacting with remote branches like on github.

If your local branch is different from the remote branch, it will print the differences and ask if you'd like to overwrite your local branch, i.e.

```
================================================================================
LOCAL_BRANCH
================================================================================
commit 27160034a5e21474781abc09434d479f8ca016f4
Author: Jonathan Marler <johnnymarler@gmail.com>
Date:   Sat Jun 15 21:16:04 2019 -0600

    Add --no-pager to prevent terminal warnings

================================================================================
REMOTE_BRANCH
================================================================================
commit 8fd645e792ae5963e7e715c812747dbb8acd295c
Author: Jonathan Marler <jonathan.j.marler@hp.com>
Date:   Fri Jun 14 16:39:59 2019 -0600

    Add zig version

--------------------------------------------------------------------------------
Overwrite LOCAL_BRANCH with REMOTE_BRANCH[y/n]?
```

This makes it safe to run `git fetchout` at any time without fear of losing any local changes.

TODO: The user should know whether the new branch is going to overwrite any commits on the local branch, or if it is just adding new commits. Something like "Remote Branch will add 3 commits and overwrite 1 commit".
