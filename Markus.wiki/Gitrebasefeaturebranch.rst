What to do when main MarkUs is further ahead than when I created the branch for my feature/bug?
================================================================================

* If you don't have the "upstream" remote add it: ``git remote add upstream
  git://github.com/MarkUsProject/Markus.git``

* Fetch main MarkUs changes: ``git fetch upstream``

* Switch to your feature branch: ``git checkout <feature-branch-name>``

* Rebase your feature branch on current HEAD of upstream/master: ``git rebase
  upstream/master``.

If this doesn't say anything to you, ask for help. Seriously, ask for help!
There's always somebody around to clarify things :)
