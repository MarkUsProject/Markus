================================================================================
General Guide
================================================================================

**Integration Tests:**
"Integration test coverage is nonexistent. Not good. You
should either think about adding some traditional Rails integration tests or
experimenting with a tool like Cucumber to do BDD-style integration tests."


**Models too light, controller too heavy**
"Models are generally pretty light and controllers are pretty heavy. Likely
you'll want to look at moving functionality from controllers down into
models."

**Move Page Updates to RJS**
"Doing a bunch of AJAX-style updating in controller methods is iffy. Normally,
I'd move those to RJS templates. Alternatively, it's worth looking at whether
to avoid RJS and the page.replace_html (etc) method entirely, and move to
JQuery or similar."

Fix up models to use ActiveRecord better
================================================================================

Here are a few spots I see where ActiveRecord isn't being used effectively.

For example:

:: 
  class Mark < ActiveRecord::Base
    belongs_to :rubric_criterion
    ...
    #return the current mark for this criterion
    def get_mark
      criterion = RubricCriterion.find(rubric_criterion_id)
      return mark.to_f * criterion.weight
    end
  end

Could be rewritten to

::  
  class Mark < ActiveRecord::Base
    belongs_to :rubric_criterion
    ...
    #return the  current mark for this criterion
    def get_mark
      return mark.to_f * rubric_criterion.weight
    end
  end
