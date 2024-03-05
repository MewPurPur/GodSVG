script_dir=$(dirname "$(readlink -f "$0")")
cd "$script_dir" || exit
count=$(find *.po -maxdepth 1 -type f | wc -l)
printf "Found $count po files.\n\n"
for file in ./*.po; do
    printf "Updating $file: "
    msgmerge --update --quiet --verbose --backup=off $file GodSVG.pot
    if [ "$?" != "0" ]; then # Exit loop on error.
        printf "\nUpdating failed, exiting.\n"
        exit
    fi
done
printf "\nUpdating completed!\n"
