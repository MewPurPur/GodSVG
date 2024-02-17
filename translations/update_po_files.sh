count=$(find *.po -maxdepth 1 -type f|wc -l)
echo
echo "Found $count po files. Starting update..."
for file in ./*.po
    do
        echo
        echo "$count files left, updating $file:"
        let count--
        msgmerge --update --quiet --verbose --backup=off $file Translations.pot
        if [ "$?" != "0" ]; then  # Error check.
            echo
            echo "Updating failed."
            exit
        fi
    done
echo
echo "Updating completed!"