## Table of Contents
- [Testing with RSpec](#testing-with-rspec)
- [How to Run Specifications](#how-to-run-specifications)
- [Naming Conventions](#naming-conventions)
- [Helper Gems](#helper-gems)
- [Model Specifications](#model-specifications)
- [Controller Specifications](#controller-specifications)
- [General Tips](#general-tips)

## Testing with RSpec

Testing with RSpec involves specifications (files containing tests), and examples within these specifications (the actual tests). In order to get the most out of this tutorial, it is recommended that you follow along in the `spec` folder, which is located in the Markus root folder.

**Note**: [Better Specs](http://betterspecs.org/) is another resource that illustrates best practices using RSpec (you will notice most of our style uses their suggestions). Refer to this guide for anything not explicitly covered here. It is also a great resource for more examples on most of what *is* covered.

## How to Run Specifications

**Note:** The following commands assume you are within the Markus root folder.

To run all specifications:

```
$ bundle exec rspec
```
To run a specific specification:

```
$ bundle exec rspec <file-path>
```
For example, to run the group model specification, run `bundle rspec spec/models/group_spec.rb`.

## Naming Conventions

### Folders

The name of the folder which holds the specifications should have the same name as the folder storing the files being tested. For example, model files are stored in the folder `app/models`, so model specifications are stored in `spec/models`.

### Files

The name of the specification for the file being tested is the name of the file followed by `'_spec'`. For example, the group model file is named `group.rb`, so the group model specification will be `group_spec.rb`.

## Helper Gems
### FactoryBot

FactoryBot is used to create instances of Models for testing. A great introduction to FactoryBot can be found [here](https://rubydoc.info/gems/factory_bot/file/GETTING_STARTED.md).

Within the `spec` folder (found in the Markus root folder), you will find a folder called `factories`. This is where all current factories being used for testing are stored. The filename of each factory should be the plural form of the filename of the Model it refers to (because there are multiple factories of the same kind in one file). For example, the `Group` Model is contained in a file called `group.rb` and so the factory filename is `groups.rb`. Another example would be a model filename of `criterion.rb` and a factory filename of `criteria.rb`.

Look through a few of them to get a sense of what the template looks like. Each factory corresponds to one of Markus's Models.

FactoryBot's `create` method is used to make and save instances of Models. The `create` method should only be used when absolutely necessary. It creates instances that will persist within the database making it a culprit to extremely slow tests. It may be difficult to avoid using them in Model specifications because you are testing interactions with the database (Active Record queries).

Not using `create` means using `build_stubbed`, another Factory Girl method that makes a mock object (meaning an object that does not persist in the database). We will go into more detail about mock objects in the [Controller Specifications](#controller-specifications) section.

As an example, say we want to create a `Group` instance that will persist within the database, we would use `create`:

```ruby
@group = create(:group)
```
If the instance does not need to persist within the database we use `build_stubbed`:

```ruby
@group = build_stubbed(:group)
```
It is also possible to explicitly assign a value to attributes of the object you are creating. A `Group` instance has an attribute `group_name` and we'd like to make sure it has the value 'g2markus'. This is done like so:

```ruby
@group = create(:group, group_name: 'g2markus')
```

### Faker

While exploring the files within the factories folder you probably noticed the Faker gem being used. We use Faker alongside Factory Girl to easily create fake data. Faker calls are placed within curly braces to ensure when an instance is created using Factory Girl it has unique values for its attributes. Types of data available to fake can be found [here](https://github.com/stympy/faker).

## Model Specifications

Open the `models` folder within the `spec` folder, and explore the files. All model specifications have the following template:

```ruby
describe ModelName do
  attribute_examples
  method_examples
end
```

We will explore the code that would replace `attribute_examples`, and `method_examples` above. Code from the `group_spec.rb` file, which tests the `Group` model, will be used as reference throughout the Model specification section of the guide. Open that file, and look through it as you follow along below.

### Attribute Examples

The first set of examples in our model specification will be for the Model’s attributes. Shoulda-matchers are used to test common rails attribute validators. It makes for simple, elegant one-liners.

For example, recall the model `Group` has an attribute `group_name`. This attribute must be present in order for a group to be successfully created. Now look in the `group_spec.rb`, and notice the first example is testing that requirement:

```ruby
it { is_expected.to validate_presence_of(:group_name) }
```

We use shoulda-matchers because the examples are easily understood just by reading them. As seen in the file, there are other matchers available to test for uniqueness, length, etc. More available shoulda-matchers can be found [here](https://github.com/thoughtbot/shoulda-matchers).

### Method Examples

As you  have probably noticed in the `group_spec.rb` file, all method examples are written within their own `describe` block. If the method is an instance method, the description of the block will be a hash followed by the method’s name:

```ruby
describe '#method_name' do
  method_example
end
```

If the method is a class method, the description of the block will be a dot followed by the method name:

```ruby
describe '.method_name' do
  method_example
end
```

The example for this method will be contained within the block, replacing `method_example`. Most examples will need instances of Model's to run. There are various ways instances can be initialized. One is within a before block:

```ruby
before :each do
  @group = create(:group, group_name: 'g2markus')
end
```
The code within the before block will be executed before every example. Before blocks should only be used if there is something other than initializing variables that needs to be done before each test.

Another way to Initialize instances is by using `let`, or `let!`. This is the preferred method. `let` and `let!` allow for lazy and eager evaluation of an instance, respectively:

```ruby
# This will evaluate the instance when `group` is first called in the example.
let(:group) { create(:group, group_name: 'g2markus') }

# This will evaluate before the example is executed.
let!(:group) { create(:group, group_name: 'g2markus') }
```
The initialization can be placed in various places depending on need. If all methods will need the instance, it would make sense to place it at the beginning of the Model's `describe` block. If only a certain method needs it, place it at the beginning of that method's `describe` block (this would also work for other types of blocks described below).

You almost certainly want to wrap initialization code in either `let` or `before` as it guarantees they are run before each enclosed example is run. If your initialization is outside of `let` and `before`, then they will only be (eagerly) evaluated once before the enclosed examples capture the variables in the closures of their blocks. This is often undesired in unit testing.

All examples should be contained within `it` blocks, all of which must be accompanied by a description written in third person present tense ([avoid the use of "should" in the description](http://betterspecs.org/#should)):

```ruby
it 'does ...' do
it 'is ...'
```
Each example is limited to one expectation. Bad:

```ruby
it 'does ...' do
  expect(something).to be_something
  expect(another_thing).to be_another_thing
end
```
Good:

```ruby
it 'does ...' do
  expect(something).to be_something
end

it 'does ...' do
  expect(another_thing).to be_another_thing
end
```
This improves readability and ensures all aspects are tested even in the case of a failure (whereas with multiple expectations per example, later expectations won't be run if an earlier expectation fails).

For a simple example of this, within `group_spec.rb`, scroll down to the method `repository_name`. An instance is created using Factory Girl, and used within the `it` block. Looking through the different examples within the specification files is a great resource for learning how to test. A starting point for understanding how to use the `expect` syntax can be found [here](https://github.com/rspec/rspec-expectations). A great introduction, but not free, resource is Aaron Sumnor's [Everyday Rails Testing with RSpec](https://leanpub.com/everydayrailsrspec).

As you scrolled down to `repository_name` examples, you probably noticed another set of examples testing the `set_repo_name` method. Some methods may have different states in which a different set of instructions will be executed based on the state. This is the case for the `set_repo_name` method which can be called on an instance of `Group`. When the instance was created a repository name may have been specified if it was specified that group names should be automatically generated (if it was not specified an auto generated name will be created). In these cases the `context` block is used to distinguish the different states. Context descriptions begin with `when` or `with`, and the template for this is usually:

```ruby
describe '#method_name' do
  context 'when in this state' do
    method_example
  end

  context 'when in this other state' do
    method_example
  end
end
```
You can use as many context blocks as needed to represent the possible states the method can be called in.

All methods within the model being tested, should be tested. If you feel a method should not be tested, leave a comment explaining your reasoning above the method's describe block:

```ruby
# This method is not being tested because...
describe '#method_name'
```
This will inform other developers that the method was not accidentally forgotten, but instead, just reasoned to not be tested.

## Controller Specifications

Controller specifications will have the following template:

```ruby
describe ControllerName do
  context 'some type of user' do
    method_examples
  end

  context 'some other type of user' do
    method_examples
  end
end
```
`some type of user` and `some other type of user` describing the context blocks usually correspond to someone who has authorization to perform certain tasks (usually an admin) and someone who does not.

Code from the `groups_controller_spec.rb` file, which tests the `GroupsController` controller, will be used as reference throughout the Controller specification section of the guide. Open that file, and look through it as you follow along below.

### Method Examples

Controller methods are placed within `describe` blocks with the description as a hash followed by the method name. Before the hash, the description also has the request type the method will make.

For example, the `GroupController` has a method called `index`, which sends out a GET request, so:

```ruby
describe 'GET #index' do
  method_example
end
```
Controller testing is not concerned with states of objects, and so mocking instances is preferred (the tests are a lot faster). Also, because we would have already tested the Model methods within the Model specification, we do not need to be retesting them when they are called within a Controller method.

A stub is used to create the illusion that a method was called, returning a specified result. A mock is a stub expecting a specified method to be called. A starting point for learning to stubbing and mocking can be found [here](https://github.com/rspec/rspec-mocks). If you want another resource on mocking and stubbing, check out Code School’s Testing with RSpec videos ([Level 5 is on Mocking and Stubbing](http://rspec.codeschool.com/)).

Controller specifications will have both mocks and stubs, so when do you use which? As the examples will illustrate below, you stub a method when you need to prevent it from accessing the database. And you mock a method when you need to ensure it is called.

Lets start with mocking objects (which is different than mocking methods). As seen in the [FactoryBot](#factorybot) section above we make a mock object like this:

```ruby
build_stubbed(:object)
```
If we wanted to create a mock grouping object:

```ruby
grouping = build_stubbed(:grouping)
```
Now `grouping` is a mock instance that does not persist in the database. All methods called on `grouping` that requires database access would fail. This is why we need stubs.

Open the `groups_controller_spec.rb` file (if you haven't already). Both mock grouping, and assignment objects are created at the start using `let`. The `before` block just under these mocks contains a whole bunch of stubs. The first few are to ensure we have administrative privileges. Many of the methods tested within this file call the `Assignment` model’s `find` method. This method takes an `id` belonging to an assignment and returns the assignment. To make sure this method isn’t actually executed, we stub it (remember we don’t actually have an assignment so this search will fail). This is what the stub for the `Assignment`’s `find` method looks like:

```ruby
allow(Assignment).to receive(:find).and_return(assignment)
```
The above stub will make sure when `find` is called the mocked assignment will be returned.

All Model methods called within the controller should be mocked. This is a test that ensures the methods that should be called, will be called. For example, the method `new` within the `GroupsController` calls `Assignment` model’s method `add_group`. It is called using the mock assignment we have, and returns a grouping. To make sure this method is called we create the mock, and call the controller method being tested:

```ruby
expect(assignment).to receive(:add_group).with(nil).and_return(grouping)
get :new, assignment_id: assignment
```

## General Tips
### Code Duplication
Sometimes you will find yourself writing very similar specs for different models or controllers. If you smell such code duplication (e.g., when you are copying and pasting a lot of old spec to create new spec without changing much of the spec code structure), you should probably use [shared examples](https://www.relishapp.com/rspec/rspec-core/docs/example-groups/shared-examples). Shared examples give you a way to specify the abstract common behavior of some objects (a model or a controller in most cases) in a single place, and apply the behavior to multiple specs of concrete objects. Shared examples that logically belong to the same group are given a name appropriate for the concrete objects they are describing. Usually, the name would be a noun starting with an article (e.g., `a duck`, `an apple`), but that might not always be the case. Think of the use case of your shared examples -- how does it read when you say `it_behaves_like 'your_shared_examples_name'` (or any other alias of `it_behaves_like`)?

Shared examples are usually placed in its own file under `spec/support`, unless they are only shared by specs in one file, in which case they can placed within the same file. Name the file using the shared examples name without the article (e.g., `duck.rb`, `apple.rb`). Don't append `_spec` in the filename of shared examples, as that causes RSpec to double load the file (first by RSpec itself and later by `spec_helper.rb`) and generate warnings.


```ruby
# spec/support/duck.rb

shared_examples 'a duck' do
  # You can write RSpec code like normal in a `shared_examples` block.

  describe '#swim' do
    # ...
  end

  describe '#quack' do
    # ...
  end
end

# spec/model/swan.rb

describe Swan do
  it_behaves_like_a 'duck'
end

# spec/model/goose.rb

describe Goose do
  it_behaves_like_a 'duck'
end

```

In Markus, one use case of shared examples is [`a criterion`](https://github.com/MarkUsProject/Markus/blob/master/spec/support/criterion.rb), which specifies the common behavior of `RubricCriterion` and a `FlexibleCriterion`.

You can also use an alias for the method `it_behaves_like_a` to make the spec code read better. For example, `it_has_behavior 'enumerability'`. The aliases should be defined in [spec/support/it_behaves_like_aliases.rb](https://github.com/MarkUsProject/Markus/blob/master/spec/support/it_behaves_like_aliases.rb).
