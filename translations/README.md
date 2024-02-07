**The official GNU gettext manual can be found [here](https://www.gnu.org/software/gettext/manual/html_node/index.html)**
# The po format
You can familiarize yourself with the po format [here](https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html).
# For programmers
New translatable strings have to be added manually. This is done in the `Translations.pot` template file.

A single translatable string to add in the POT looks like this:
```po
msgid "Your translatable string"
msgstr ""
```
>[!IMPORTANT]  
>The `msgstr` should be left empty in the template. The `msgid` should be in plain english and exactly the same as whats used in the source code.

All translation files have to be updated to include the new string.
This is best done with [gettext tools](https://www.gnu.org/software/gettext/manual/html_node/Updating.html) or [Poedit](https://poedit.net).
# Contributing translations
## [Adding a new language](https://www.gnu.org/software/gettext/manual/html_node/Creating.html)
### With editor ([Poedit](https://poedit.net)):
1. Open `Translations.pot` in Poedit
2. Click "Create new translation", choose the language and start adding your translation.
3. Save the file and delete the `.mo`.
4. Update project settings to include the new translation.
5. Create a pull request with your changes.
### Without editor:
1. Duplicate `Translations.pot` file and rename it to the locale code of the new language `<locale code>.po`.
2. Open it in a text editor, add the locale code in the info at the top (`"Language: <locale code>`) and insert translated strings in the `msgstr "<your translation>"` spots.
3. Update project settings to include the new translation.
4. Create a pull request with your changes.
## Editing translations
1. Find the file with the locale code of the language you want to edit. Open it in your editor.
2. Search for the translation you want to change and change it.
3. Create a pull request with your changes.
# Testing translations
Translation changes can be viewed by running the project from the Godot editor.
If you added a new language, you need to make sure its added in the project settings.