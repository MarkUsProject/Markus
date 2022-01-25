# Action Policy Style Guide

## About

MarkUs manages authorization and permissions using the [ActionPolicy gem](https://actionpolicy.evilmartians.io).

Before any controller route is accessed, the corresponding policy determines whether the current user has permission to access that route.

Policies can also be used to check whether a user has permission to access a specific resource or perform a specific action. These policies can be called in controller methods at any time.

Before reading the rest of this style guide, make sure you are familiar with ActionPolicy by reading the [documentation](https://actionpolicy.evilmartians.io). It is especially important to understand the section on [Rails integration](https://actionpolicy.evilmartians.io/#/rails?id=using-with-rails)

### File locations

Policy files can be found under: `app/policies`

Policy translation files can be found under: `config/locales/policies`

Rspec tests can be found under: `spec/policies`

## Guidelines for writing policies

#### All controller routes must have a corresponding policy

If you create or rename a route, you *must* create or rename the corresponding policy. In the `ApplicationController` class there is the [`verify_authorized`](https://actionpolicy.evilmartians.io/#/rails?id=verify_authorized-hooks) hook which will raise an error if a user tries to access a route and a policy is not checked.


#### Controllers must all have an implicit_authorization_target

MarkUs tries to use [resourceless authorization](https://actionpolicy.evilmartians.io/#/rails?id=resource-less-authorize) whenever possible. This means that every time ActionPolicy authorizes a route, we do not need to specify which policy it needs to use.

Instead, we can define an [`implicit_authorization_target`](https://actionpolicy.evilmartians.io/#/behaviour?id=implicit-authorization-target) method for each controller.

By default, controllers will inherit this method from `ApplicationController` but in some cases it may be necessary to override this method for a subclass. For example, if a controller does not have a corresponding model, the default `implicit_authorization_target` will need to be overwritten since it assumes the existance of that model.


#### Policy names should reflect their purpose

Policy classes should be named the same as the corresponding controller, except the policy class name should be singular (not plural) and "Controller" should be replaced with "Policy".

If a policy function is used to determine whether a user has access to a route, the policy function should be named the same as the route followed by a question mark. For example:

```ruby
class ExamplesController < ApplicationController
    def index
    end
end

class ExamplePolicy < ApplicationPolicy
    def index?
    end
end
```

If a policy function is used for some other purpose (determine whether a user has access to a resource or can perform a specific action), the policy name should describe the purpose.

For example, a policy that checks whether a student is allowed to work alone in a group is named `work_alone?`. A good rule when trying to think of policy names is: does the name make sense if inserted into the sentence:

"Is this user allowed to \_\_\_\_\_\_?"


#### All policy functions must have a failure reason

If you create or rename a policy function, make sure to create or update the internationalization strings for that policy function (in `config/locales/policies`)


#### Use `allowed_to?` and `check?` in different contexts

The `allowed_to?` function has an alias `check?`. However, to improve clarity of code, `check?` should be only used in policy classes and `allowed_to?` should only be used outside of policy classes (in controllers or views).


#### Be purposeful about calling `check?`

When a policy fails (returns false), the [failure reasons](https://actionpolicy.evilmartians.io/#/reasons?id=failure-reasons) are collected in the policy's `result` attribute.

Failure reasons are added every time a `check?` or `allowed_to?` function returns false. Because of this, it is important to think about how policy functions call each other and what failure reasons you want to include. For example:

```yml
en:
  action_policy:
    policy:
      example:
        index?: "You don't have access to the index route."
        be_an_admin?: "You are not an admin user"
      other:
        be_an_admin?: "You are still not an admin user"
        be_a_ta_or_student?:  "You are not a TA or a student"
```

Scenario 1:

```ruby
class ExamplePolicy < ApplicationPolicy
    def index?
        check?(:be_an_admin?)
    end

    def be_an_admin?
        user.admin?
    end
end
```

If the `index?` policy fails the error messages will be: `["You don't have access to the index route.", "You are not an admin user"]` becuase both the `index?` and `admin?` policies are called.

Scenario 2:

```ruby
class ExamplePolicy < ApplicationPolicy
    def index?
        user.admin?
    end

    def be_an_admin?
        user.admin?
    end
end
```

If the `index?` policy fails the error messages will be: `["You don't have access to the index route."]` because only the `index?` policy is called.


Note that failure reasons will only be added if `check?` or `allowed_to?` is called in the original policy class. For example:

```ruby
class ExamplePolicy < ApplicationPolicy
    def index?
        check?(:admin?, with: OtherPolicy)
    end
end

class OtherPolicy < ApplicationPolicy
    def be_an_admin?
        !check?(:be_a_ta_or_student?)
    end

    def be_a_ta_or_student?
        user.ta? || user.student?
    end
end
```
If the `index?` policy fails, the error messages will be: `["You don't have access to the index route.", "You are still not an admin user"]`. It will not include `"You are not a TA or a student"` because the `check?` function was called in a policy class different to the one that `index?` is in.


#### Include additional context for policies if needed

If a policy requires additional context that can be provided using [explicit additional context](https://actionpolicy.evilmartians.io/#/authorization_context?id=explicit-context).

For example:

```ruby
class ExamplePolicy < ApplicationPolicy
    authorize :submission

    def index?
        submission.revision_identifier.present?
    end
end
```

In the example above, the `index?` policy needs to check a submission object. Then when calling this policy the submission object can be passed as part of the `context` keyword:

```ruby
allowed_to?(:index?, context: { submission: Submission.find(10) })
```

#### Writing Tests

Rspec tests written for policies should use [Action Policies' Rspec DSL](https://actionpolicy.evilmartians.io/#/testing?id=rspec-dsl).

For clarity, we prefer to not nest `succeed` or `failed` blocks within each other. For example, the following two test classes are functionally equivalent but the second one is preferred:


```ruby
describe NotePolicy do
    let(:context) { { user: user } }
    let(:record) { create :note }
    describe_rule :manage? do
        failed 'user is a ta' do
            let(:user) { create :ta }
            succeed 'when the note is created by the ta' do  # <- succeed is nested in a failed block (DO NOT DO THIS)
                let(:record) { create :note, user: user }
            end
        end
    end
end
```

```ruby
describe NotePolicy do
    let(:context) { { user: user } }
    let(:record) { create :note }
    describe_rule :manage? do
        context 'user is a ta' do
            let(:user) { create :ta }
            failed 'when the note is not created by the ta'  # <- failed and succeed are nested in a context block (DO THIS)
            succeed 'when the note is created by the ta' do
                let(:record) { create :note, user: user }
            end
        end
    end
end
```
