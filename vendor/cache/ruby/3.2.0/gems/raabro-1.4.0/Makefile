
## gem tasks ##

NAME = \
  $(shell ruby -e "s = eval(File.read(Dir['*.gemspec'][0])); puts s.name")
VERSION = \
  $(shell ruby -e "s = eval(File.read(Dir['*.gemspec'][0])); puts s.version")

count_lines:
	find lib -name "*.rb" | xargs cat | ruby -e "p STDIN.readlines.count { |l| l = l.strip; l[0, 1] != '#' && l != '' }"
	find spec -name "*_spec.rb" | xargs cat | ruby -e "p STDIN.readlines.count { |l| l = l.strip; l[0, 1] != '#' && l != '' }"
cl: count_lines

gemspec_validate:
	@echo "---"
	ruby -e "s = eval(File.read(Dir['*.gemspec'].first)); p s.validate"
	@echo "---"

name: gemspec_validate
	@echo "$(NAME) $(VERSION)"

cw:
	find lib -name "*.rb" -exec ruby -cw {} \;

build: gemspec_validate
	gem build $(NAME).gemspec
	mkdir -p pkg
	mv $(NAME)-$(VERSION).gem pkg/

push: build
	gem push --otp "$(OTP)" pkg/$(NAME)-$(VERSION).gem

spec:
	bundle exec rspec
test: spec


.PHONY: count_lines gemspec_validate name cw build push spec

