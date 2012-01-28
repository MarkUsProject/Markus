Merging MarkUs Pull Requests
================================================================================

This is what I've been doing for merging things into master so far (feedback
welcome):

* Clone main MarkUs: ``git clone git@github.com:MarkUsProject/Markus.git``. If
  you have it cloned, make sure to be on master and pull from origin/master.
  Note, if you have the repo already cloned, a ``git fetch origin && git
  checkout master && git rebase origin/master`` should bring you up to date.

* Add remote for fork of developer: ``git remote add
  <developer-github-name>-fork <read-only-url>``

* Fetch changes in fork: ``git fetch <developer-github-name>-fork``

* Create a local branch tracking the remote branch of the developer: ``git
  branch <feature-branch-name> <developer-github-name>-fork/<branch-name>``

* Checkout and double-check if everything is in order: ``git checkout
  <feature-branch-name>``

* Use ``git log``, ``gitk`` or whatever you prefer to make sure feature-branch
  has nice history based on latest HEAD of origin/master.

* If it isn't, you could try rebasing it or ask the developer to bring it to
  up-to-date master. You may also fixup some history, squash things and what
  not (i.e. ``git rebase -i HEAD~<#of-commits-back>`` may be useful).

* If the rebase causes conflicts, it's likely that the developer did not keep
  up-to-date with HEAD of origin/master (i.e. did not rebase the feature branch
  on latest HEAD of origin/master. The developer should do the merging if
  necessary and resolve conflicts (maybe ``git mergetool`` helps).

* Finally merge feature-branch into master: ``git checkout master && git merge
  <feature-branch-name>``. Ideally, this is only a Fast-forward merge.

* Again, make sure history looks ok. If everything looks good, push to origin:
  ``git push origin master``

Does this make sense?
