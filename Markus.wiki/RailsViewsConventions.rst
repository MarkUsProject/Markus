# Rails Views Coding Conventions

## Use h() and - where appropriate - sanitize()

There are several reasons as to why to use 'h()' and 'sanitize()' in Rails views (see [http://guides.rubyonrails.org/security.html](http://guides.rubyonrails.org/security.html) ).

The basic problem is that users enter plenty of input (assignment names, descriptions, etc.) when using MarkUs. But that input can be anything. That input could for instance be something like: "assignment title \<script\>alert('Hello World');\</script\>". Say, one does not use 'h()' in views, then whenever the assignment name is rendered a fun little "Hello World" message would pop up. That little JavaScript is pretty harmless, but whatever the user enters as input would get to be executed. We don't want that. 'h()' helps us to accomplish that. It escapes HTML entities etc. Conclusion: Use 'h()' whenever you are printing some Rails variables in views! This isn't optional! Thanks.
