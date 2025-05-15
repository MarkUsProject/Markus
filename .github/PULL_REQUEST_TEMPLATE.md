## Proposed Changes
*(Describe your changes here. Also describe the motivation for your changes: what problem do they solve, or how do they improve the application or codebase? If this pull request fixes an open issue, [use a keyword to link this pull request to the issue](https://docs.github.com/en/issues/tracking-your-work-with-issues/linking-a-pull-request-to-an-issue#linking-a-pull-request-to-an-issue-using-a-keyword).)*

Adds tests for the “marks released” edge-case to both `#new` (GET) and `#create` (POST). Each spec builds an assignment with released results, makes the corresponding request (`get_as` or `post_as`), and verifies that the controller flashes the correct error and returns `400 Bad Request`.

<details>
<summary>Screenshots of your changes (if applicable)</summary>

</details>

<details>
<summary>Associated <a href="https://github.com/MarkUsProject/Wiki">documentation repository</a> pull request (if applicable)</summary>

</details>

## Type of Change
*(Write an `X` or a brief description next to the type or types that best describe your changes.)*

| Type                                                                                    | Applies? |
|-----------------------------------------------------------------------------------------|----------|
| 🚨 *Breaking change* (fix or feature that would cause existing functionality to change) |          |
| ✨ *New feature* (non-breaking change that adds functionality)                          |          |
| 🐛 *Bug fix* (non-breaking change that fixes an issue)                                  |          |
| 🎨 *User interface change* (change to user interface; provide screenshots)              |          |
| ♻️ *Refactoring* (internal change to codebase, without changing functionality)          |          |
| 🚦 *Test update* (change that *only* adds or modifies tests)                            | X        |
| 📦 *Dependency update* (change that updates a dependency)                               |          |
| 🔧 *Internal* (change that *only* affects developers or continuous integration)         |          |


## Checklist
*(Complete each of the following items for your pull request. Indicate that you have completed an item by changing the `[ ]` into a `[x]` in the raw text, or by clicking on the checkbox in the rendered description on GitHub.)*

Before opening your pull request:

- [X] I have performed a self-review of my changes.
  - Check that all changed files included in this pull request are intentional changes.
  - Check that all changes are relevant to the purpose of this pull request, as described above.
- [X] I have added tests for my changes, if applicable.
  - This is **required** for all bug fixes and new features.
- [X] I have updated the project documentation, if applicable.
  - This is **required** for new features.
- [X] If this is my first contribution, I have added myself to the list of contributors.

After opening your pull request:

- [X] I have updated the project Changelog (this is required for all changes).
- [X] I have verified that the pre-commit.ci checks have passed.
- [X] I have verified that the CI tests have passed.
- [X] I have reviewed the test coverage changes reported by Coveralls.
- [X] I have [requested a review](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/requesting-a-pull-request-review) from a project maintainer.

## Questions and Comments
*(Include any questions or comments you have regarding your changes.)*\
I split each controller action into two scenarios:
1. Marks not released – existing examples remain here.
2. Marks released – new examples that test the error-path.
Github tests all pass for now.
