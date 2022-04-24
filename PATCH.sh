#!/usr/bin/env bash

# TODO: Silent erroring if different Python version
# TODO: Error message & usage info if Notion archive is not found
# TODO: Race condition in run server & open in browser
# TODO: Message if no wifi is connected

unzip_archive() {
  relative_path="$1"
  archive_name=$(basename "$relative_path" .zip)

  rm -rf "$archive_name"
  mkdir "$archive_name"
  tar -xf "$archive_name".zip -C "$archive_name"

  echo "$archive_name"
}


create_index_file() {
  INDEX_FILE="$ARCHIVE_NAME/index.txt"
  CODE_INJECTION=$(get_code_injection)

  header="<!DOCTYPE html>
    <html>
    <head>
      <meta charset='utf-8'>
      <title>Teleprompter</title>
      $CODE_INJECTION
    </head>
    <body class='teleprompter-index'>
    <h1>$ARCHIVE_NAME.zip</h1>"

  footer="</body></html>"

  echo "$header" > "$INDEX_FILE"
  generate_index_recursively_from_filetree "$ARCHIVE_NAME"
  echo "$footer" >> "$INDEX_FILE"

  mv "$INDEX_FILE" "$ARCHIVE_NAME/index.html"
}


generate_index_recursively_from_filetree() {
  echo "<ul>" >> "$INDEX_FILE"

  for page_file in "$1"/*.html; do

    if [[ -f "$page_file" ]]; then
      page_name=$(extract_page_name_from_html "$page_file")
      page_folder=$(basename "$page_file" .html)
      link_url=$(echo "$page_file" | sed -e "s,$ARCHIVE_NAME/,,g")

      echo "<li><a href='$link_url'>$page_name</a>" >> "$INDEX_FILE"

      if [ -d "$1/$page_folder" ]; then
        generate_index_recursively_from_filetree "$1/$page_folder"
      fi

      echo "</li>" >> "$INDEX_FILE"
    fi
  done

  echo "</ul>" >> "$INDEX_FILE"
}


extract_page_name_from_html() {
  file="$1"
  xpath_emoji="string(//header//span[@class='icon'])"
  xpath_title="string(//*[@class='page-title'])"

  emoji_string=$(xmllint --xpath "$xpath_emoji" "$file")
  title_string=$(xmllint --xpath "$xpath_title" "$file")

  echo "$emoji_string $title_string"
}


get_code_injection() {
  P2P_HOST=$(get_p2p_server_host)
  echo "\
    <link rel='stylesheet' href='/teleprompter.css'/>\
    <script>window.P2P_SERVER_HOST = '$P2P_HOST';</script>\
    <script src='/teleprompter.js'></script>"
}


patch_notion_files_recursively() {
  CODE_INJECTION=$(get_code_injection)

  for html_file in "$1"/*.html; do
    echo "Patching $html_file"
    sed -i -e "s,</body></html>,$CODE_INJECTION</body></html>,g" "$html_file"
  done

  for folder in "$1"/*; do
    if [ -d "$folder" ]; then
      patch_notion_files_recursively "$folder"
    fi
  done
}


copy_teleprompter_files() {
#  cp "$SCRIPT_PATH/index.js" "$ARCHIVE_NAME"
#  cp "$SCRIPT_PATH/index.css" "$ARCHIVE_NAME"
  cp "$SCRIPT_PATH/teleprompter.js" "$ARCHIVE_NAME"
  cp "$SCRIPT_PATH/teleprompter.css" "$ARCHIVE_NAME"
}


get_teleprompter_url() {
  port="$1"
  local_ip_address=$(ifconfig | grep "inet " | grep -Fv 127.0.0.1 | awk '{print $2}')
  echo "http://$local_ip_address:$port"
}

get_p2p_server_host() {
  source "$SCRIPT_PATH/.env"
  echo "$P2P_SERVER_HOST"
}


show_user_message() {
  FORMAT_LINK="$(tput smul)$(tput setaf 006)"
  FORMAT_FILENAME="$(tput setaf 002)"
  FORMAT_RESET="$(tput sgr0)"

  echo -e "



    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⣿⣿⣿⣿⣿
    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠿⠛⠋⠉⢁⣤⠀⢿⣿⣿⣿⣿
    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠛⠛⠉⠁⢤⣴⣤⡀⠛⠿⣷⣦⠌⠁⠸⣿⣿⣿⣿
    ⣿⣿⣿⠿⠟⠛⠉⠁⣠⣤⣄⡘⠻⢿⣶⣤⡈⠙⠛⠃⢀⣀⣤⣴⣶⣾⣿⣿⣿⣿
    ⣿⣿⡆⠀⠐⠿⣷⣦⣄⠉⠛⠟⠒⢀⣈⣠⣤⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
    ⣿⣿⣷⠘⠟⠂⣀⣩⣤⣤⣶⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
    ⣿⣿⣿⡆⢉⣉⠉⢉⣉⣉⠉⢉⣉⡉⠉⣉⣉⡉⠉⣉⣉⠉⢉⣉⣉⠉⢹⣿⣿⣿
    ⣿⣿⣿⡇⠟⢁⣴⣿⠟⢁⣴⡿⠋⣠⣾⡿⠋⣠⣾⠟⢁⣴⣿⠟⢁⣴⢸⣿⣿⣿
    ⣿⣿⣿⡇⣀⣉⣉⣁⣀⣉⣉⣀⣈⣉⣉⣀⣈⣉⣁⣀⣉⣉⣁⣀⣉⣁⢸⣿⣿⣿
    ⣿⣿⣿⡇⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢸⣿⣿⣿
    ⣿⣿⣿⡇⣿⣿⣿⣧⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣼⣿⣿⣿⣿⣿⣿⣿⢸⣿⣿⣿
    ⣿⣿⣿⡇⣿⣿⣿⡟⠛⠛⠛⠛⠛⣿⣿⠛⠛⠛⢻⣿⣿⣿⣿⣿⣿⣿⢸⣿⣿⣿
    ⣿⣿⣿⡇⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢸⣿⣿⣿
    ⣿⣿⣿⡇⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⢸⣿⣿⣿
    ⣿⣿⣿⣷⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣾⣿⣿⣿
    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿



    TELEPROMPTER IS READY

    1. Connect your teleprompter device (e.g. tablet or phone)
       to the same Wi-Fi as this laptop.
    2. On your device, open ${FORMAT_LINK}${TELEPROMPTER_URL}${FORMAT_RESET}
    3. You're good to go!

    ------

    WITHOUT USING WI-FI:
    - Alternatively, upload the contents of the
      ${FORMAT_FILENAME}$ARCHIVE_NAME${FORMAT_RESET} folder
      to any static HTML-hosting

    TO READ HARDWARE SETUP TIPS:
    - See ${FORMAT_LINK}https://github.com/egorvinogradov/notion-teleprompter${FORMAT_RESET}

    TO QUIT TELEPROMPTER:
    - Press Ctrl+C here in the console



  "
}


run_local_server() {
  cd "$ARCHIVE_NAME"
  open "$TELEPROMPTER_URL?start=1"
  python -m SimpleHTTPServer "$TELEPROMPTER_PORT" || python -m http.server "$TELEPROMPTER_PORT"
}


SCRIPT_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

ARCHIVE_PATH="$1"
ARCHIVE_DIRNAME=$(dirname "$ARCHIVE_PATH")
cd "$ARCHIVE_DIRNAME"

ARCHIVE_NAME=$(unzip_archive "$ARCHIVE_PATH")

TELEPROMPTER_PORT=7777
TELEPROMPTER_URL=$(get_teleprompter_url "$TELEPROMPTER_PORT")

echo ""
patch_notion_files_recursively "$ARCHIVE_NAME"
create_index_file
copy_teleprompter_files
show_user_message
run_local_server
