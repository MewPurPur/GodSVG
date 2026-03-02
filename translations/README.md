**The official GNU gettext manual can be found [here](https://www.gnu.org/software/gettext/manual/html_node/index.html)**

## Files to translate

All the strings for a language are inside its respective .po file. You can read more about this format [here](https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html).

## For programmers

New translatable strings must be within GDScript files, inside a method from the `Translator` class. If they are part of a persistent UI, they must respond to the `Configs.language_changed` signal.

To include or update strings, open no_export/scripts/update_translations.gd in the Godot editor and follow the comment on top to run the script.

>[!IMPORTANT]
>To run the above script successfully, you must install [gettext tools](https://www.gnu.org/software/gettext/). It's preinstalled on most Linux distributions and Git Bash on Windows.

## Contributing translations

### [Adding a new language](https://www.gnu.org/software/gettext/manual/html_node/Creating.html)

**With editor ([Poedit](https://poedit.net)):**

1. Open `GodSVG.pot` in Poedit
2. Click "Create new translation", choose the language and start adding your translations.
3. Save the file and delete the `.mo`.

**Without editor:**

1. Duplicate `GodSVG.pot`, rename it to the locale code of the new language `<locale code>.po`, and open it in a text editor.
2. Add the locale code in the info at the top (`"Language: <locale code>`)
3. Start adding your translation by inserting translated strings in the `msgstr "<your translation>"` spots.

In both cases, once you're finished, you must update the Godot project settings to include the new translation, then create a pull request with your changes.

## Editing translations

1. Find the file with the locale code of the language you want to edit. Open it in your editor.
2. Search for the translation you want to change and do so.
3. Create a pull request with your changes.

# Testing translations

Translation changes can be viewed by running the project from the Godot editor. The new language must be added in the project settings to show up.
