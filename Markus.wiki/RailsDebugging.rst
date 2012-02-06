================================================================================
Rails Debugging HOWTO
================================================================================

This is a really short, yet essential, introduction as to how to use the
debugger in rails. It is assumed that you have a console showing you the
mongrel server output and you know at what line your code fails. Also, you
should have 'ruby-debug' installed on your machine (do a 'gem install
ruby-debug', if you don't). For simplicity, assume there is an error on line
21 in file 'rubrics_controller'. Here is what you would do:

1. Add the word 'debugger' on line 20 (one line prior to the erroneous line)
   in 'rubrics_controller.rb'
2. Reload the page giving you the error (it will stop executing right at the
   line you added 'debugger')
3. Go to the console window where your mongrel server output is printed and
   type 'irb'
4. That's it! You have a debugging console ready and you are save typing your
  debugging commands, now (see the [[Rails debugging guide |
  http://guides.rubyonrails.org/debugging_rails_applications.html]] for more
  information)
5. Once you have finished debugging, type 'quit', hit return, remove the line
   'debugger' and type 'continue' to resume your mongrel server.

Enjoy, debugging!
