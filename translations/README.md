**The official GNU gettext manual can be found [here](https://www.gnu.org/software/gettext/manual/html_node/index.html)**

## Files to translate

All of the strings for a language are inside its respective po file. You can read more about this format [here](https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html).

## For programmers

New translatable strings must be within GDScript files, inside a `Translator.translate()` method. If they are part of a persistent UI, they must also respond to the `Configs.language_changed` signal.

To include or update strings, open godot_only/scripts/update_translations.gd in the Godot editor and follow the comment on top.

>[!IMPORTANT]
>To run the above script, you must install [gettext tools](https://www.gnu.org/software/gettext/). It's preinstalled on most Linux distributions and Git Bash on Windows.

## Contributing translations

### [Adding a new language](https://www.gnu.org/software/gettext/manual/html_node/Creating.html)

**With editor ([Poedit](https://poedit.net)):**
1. Open `GodSVG.pot` in Poedit
2. Click "Create new translation", choose the language and start adding your translation.
3. Save the file and delete the `.mo`.
4. Update project settings to include the new translation.
5. Create a pull request with your changes.

**Without editor:**
1. Duplicate `GodSVG.pot` file and rename it to the locale code of the new language `<locale code>.po`.
2. Open it in a text editor, add the locale code in the info at the top (`"Language: <locale code>`) and insert translated strings in the `msgstr "<your translation>"` spots.
3. Update project settings to include the new translation.
4. Create a pull request with your changes.

## Editing translations
1. Find the file with the locale code of the language you want to edit. Open it in your editor.
2. Search for the translation you want to change and change it.
3. Create a pull request with your changes.

# Testing translations
Translation changes can be viewed by running the project from the Godot editor.
If you added a new language, you need to make sure it's added in the project settings.
