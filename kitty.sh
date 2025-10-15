#!/bin/bash
echo "Am Kitty"
action="$1"
shift
args=("$@")

case "$action" in
    kpm)
        case "${args[0]}" in
            install)
                if [ "${args[1]}" == "deb" ]; then
                    sudo dpkg -i --force-overwrite "${args[2]}"
                else
                    subargs=("${args[@]:1}")
                    sudo apt install "${subargs[@]}" -y
                    sudo apt --fix-broken install -y
                fi
            ;;
            update)
                sudo apt update
            ;;
        esac
    ;;
    show)
        echo "ฅ^•ₒ•^ฅ"
        ;;
    search)
        query="${args[1]}"
        engine="${args[0]}"
        if [[ $engine != *.* ]]; then
            query="$engine"
            engine="google.com"
        fi
        ua="Kitty/2.0 (Linux; Android 11; Kitty KI-T7Y)"
        html=$(curl -s -A "$ua" "https://$engine")
        form_action=$(echo "$html" | grep -oP '(?i)<form[^>]+action="\K[^"]+')
        query_name=$(echo "$html" | grep -oP '(?i)<input[^>]+type="search"[^>]*name="\K[^"]+')
        query_name=${query_name:-q}
        form_action=${form_action:-"/search"}
        [[ "$form_action" =~ ^http ]] || form_action="https://$engine$form_action"
        encoded_query=$(printf "%s" "$query" | jq -sRr @uri)
        final_url=$(curl -Ls -o /dev/null -w "%{url_effective}" "$form_action?$query_name=$encoded_query")
        xdg-open $final_url
    ;;
    find)
        search_query="${args[0]}"
        mapfile -t results < <(find / -type f -iname "*$search_query*" 2>/dev/null)
        if [[ ${#results[@]} -eq 0 ]]; then
            echo "No results found."
            exit 0
        fi
        for i in "${!results[@]}"; do
            printf "%3d) %s\n" "$i" "${results[$i]}"
        done
        read -p "Enter a number to view info/open (or other to cancel): " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 0 && choice < ${#results[@]} )); then
            selected="${results[$choice]}"
            echo "File Info:"
            file "$selected"
            read -p "Press Enter to open it, or any other key to go back... "
            if [[ -z "$REPLY" ]]; then
                xdg-open "$selected" &>/dev/null &
            fi
        fi
    ;;
    launch)
        search_text="${args[0]}"
        app=$(find /usr/share -type f -iname "*$search_text*" -iregex '.*\.desktop$' 2>/dev/null | head -n 1)

        if [ -n "$app" ]; then
            gtk-launch "$(basename "$app")"
        else
            echo "No app found with the search text '$search_text'."
        fi
    ;;
    say)
        echo "${args[@]}"
        if command -v espeak &>/dev/null; then
            espeak "${args[@]}"
        else
            echo "Text-to-Speech not available."
        fi
    ;;
    play)
        search_text="${args[0]}"
        media_file=$(find ~ -type f -iname "*$search_text*" -iregex '.*\.\(mp3\|wav\|mp4\|flac\|mkv\)' | head -n 1)

        if [ -n "$media_file" ]; then
            xdg-open "$media_file"
        else
            echo "No media file found with the search text '$search_text'."
        fi
    ;;
    help)
        echo "Kitty Command List:"
        echo "|- kpm"
        echo "|  |- install <package>"
        echo "|  |  |- deb <package>"
        echo "|  |- update"
        echo "|- show"
        echo "|- search <query>"
        echo "|  |- <website> <query>"
        echo "|- find <filename>"
        echo "|- launch <name>"
        echo "|- say <speech>"
        echo "|- play <filename>"
    ;;
    *)
        echo "Usage: kitty <command>"
        echo "Example: kitty help"
    ;;
esac

echo "Kitty done. UwU"
