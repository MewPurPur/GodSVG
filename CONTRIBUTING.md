Thank you for your interest in contributing to GodSVG!

## PR workflow

For code contributions, use the following workflow:

1. Fork the repository.
2. Create a new branch: `git checkout -b implement-gradients`
3. Make your modifications, add them with `git add .`
4. Commit your changes: `git commit -m "Implement linear gradients"`
5. Push to the branch: `git push origin implement-gradients`
6. Create a new pull request with a clear and informative title and describe your changes.

This is the preferred workflow, but tidiness is not as important as work being done, so feel free to do something else you're comfortable with.

After submitting your pull request, I (MewPurPur) will review your changes and may provide feedback or request modifications. Be responsive to any comments or suggestions. Once your pull request is approved, it will be merged. Afterward, you can delete your branch from your fork.

## Governance 

Before starting to work on a PR, look through the list of issues to see if your PR will resolve any of them. If said issue is not assigned to anyone and you don't want anyone else to work on it,  ask to be assigned to the issue.

If an issue doesn't exist and you want to fix a bug, then it's a good practice, but not required, to make an issue for it. If you want to implement a more complex feature or overhaul a system, a proposal is required first.

Do understand that PRs with a large maintenance cost may be under high scrutiny because of their long-term responsibility, even in the absence of the original contributor.

## Code style

For scripts, only GDScript code is allowed. Follow the [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html). Most of its rules are enforced here. Additionally:

- Static typing is predominantly used.
- Comments should be written like sentences with punctuation.
- Class names must use `class_name X extends Y` syntax.

Pull requests may get production tweaks to fix their style before being merged.
