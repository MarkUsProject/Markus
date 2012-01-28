Keeping Your Personal Fork-Clone Up-to-date
=================================

* Add the ``upstream`` remote: ``git remote add upstream
  git://github.com/MarkUsProject/Markus.git``

* Fetch changes in MarkUsProject/MarkUs: ``git fetch upstream``

* Bring ``master`` of your personal fork-clone up-to-date: ``git checkout
  master && git merge upstream/master``. If you are currently working on a
  feature branch and upstream ``master`` changed meanwhile, you may want to
  rebase to HEAD of upstream/master. If this doesn't mean anything to you, you
  may want to ask for help first. [[GitRebaseFeatureBranch]] may also be of
  interest.

