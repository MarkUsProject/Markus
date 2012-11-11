require "testrunner_data/Hello.rb"

#Marks: 1
#Input: Helloooo
#Expected output: Helloooo

print "1\n\n"
print "Helloooo\n\n"
print "Helloooo\n\n"


def test_greet
  return greetly("Helloooo")
end

puts test_greet


