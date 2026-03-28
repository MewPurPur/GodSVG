## Governance

Your contribution is always appreciated!

Contributions don't need to be perfect, but they must move GodSVG in the right direction. If you are planning to implement a feature or overhaul a system, it's important to write a proposal and discuss your ideas first. I will try to be quick with accepting or declining them. Please do understand that PRs with a large maintenance cost may be under high scrutiny because of their long-term responsibility, even in the absence of the original contributor.

## Setup

GodSVG is made in Godot using its GDScript language. Refer to the [README](https://github.com/MewPurPur/GodSVG?tab=readme-ov-file#how-to-get-it) on how to get GodSVG running.

Git must be configured, then you can clone the repository to your local machine: `git clone https://github.com/MewPurPur/GodSVG.git`

The documentation won't go into detail about how to use Git. Refer to outside resources if you are unfamiliar with it.

## PR workflow

Look through the list of issues to see if your contribution would resolve any of them. If said issue is not assigned to anyone and you don't want anyone else to work on it, ask to be assigned to the issue. If an issue doesn't exist and you want to fix a bug, then it's a good practice, but not required, to make an issue for it.

1. Fork the repository.
2. Create a new branch: `git checkout -b implement-masks`
3. Make your modifications, add them with `git add .`
4. Commit your changes: `git commit -m "Implement the mask element"`
5. Push to the branch: `git push origin implement-masks`
6. Create a new pull request with a clear and informative title and describe your changes.

After submitting your pull request, I (MewPurPur) will review your changes and may provide feedback or request modifications. Be responsive to any comments or suggestions. Once your pull request is approved, it will be merged. Afterward, you can delete its branch from your fork.

## Translation

Editing translations is explained [here](translations/README.md)

## Code guidelines and style

As usual, look around and try to copy the style and patterns of the surrounding code.

Using AI for anything that would end up in the codebase is not allowed. I will enforce this to the best of my ability.

Guidelines:

- Avoid StringNames.
  - Rationale: This makes the codebase simpler, and StringNames aren't a universal optimization. I've heard of a lot of cases where they counterintuitively make performance worse, and I don't currently understand them well-enough to not fall into traps. If performance benefits for using StringName somewhere are arduously benchmarked, it can be considered.
- Avoid exporting nodes.
  - Rationale: At the moment, we just don't do this, and I'd rather we're consistent with how we use Godot features.
- Translate strings with `Translator.translate()`, not `tr()`.

Follow the [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html). Almost all rules from the guide are enforced in the GodSVG codebase.

We have some additional style rules:

- Always use static typing. And if possible, use inferred typing, i.e., `var f := 4.0` instead of `var f: float = 4.0`
- If comments have sentence structure, they must be written like sentences, with punctuation.
- Inline comments are separated from the code by two spaces.
- Documentation comments are written like normal comments, without modifiers like `[param]` or `[code]`.
  - Rationale: The amount by which they improve the readability of the documentation isn't enough to outweigh how much worse they are when you look at them in code. I believe they aren't suitable in a project where only developers will be reading them.
- For empty lines in the middle of indented blocks, the scope's indentation is kept.
  - Rationale: This only makes sense in languages with curly brackets. GDScript is indentation-based, so it just gets annoying having to indent things when you want to add new code.
- Class names use `class_name X extends Y` syntax.

Don't make pull requests for code style changes without discussing them first (unless it's for corrections to abide by the ones described here). The same generally applies to making style changes unrelated to a PR's main goal. Pull requests may also get production tweaks to their style before being merged.
