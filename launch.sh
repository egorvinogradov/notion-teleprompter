#!/usr/bin/env bash

# TODO: Silent erroring if different Python version
# TODO: Error message & usage info if Notion archive is not found
# TODO: Race condition in run server & open in browser
# TODO: Message if no wifi is connected


unzip_archive() {
  filename=$(basename "$1" .zip)
  dirname=$(dirname "$1")
  path="$dirname/$filename"

  rm -rf "$path"
  mkdir "$path"
  tar -xf "$1" -C "$path"
  echo "$path"
}


create_index_file() {
  index_file="$2/index.txt"

  header="<!DOCTYPE html>
    <html>
    <head>
      <meta charset='utf-8'>
      <title>Teleprompter</title>
    </head>
    <body class='teleprompter-index'>
    <h1>$(basename "$2").zip</h1>"

  footer="$1</body></html>"

  echo "$header" > "$index_file"
  generate_index_recursively_from_filetree "$index_file" "$2" "$2"
  echo "$footer" >> "$index_file"

  mv "$index_file" "$2/index.html"
}


generate_index_recursively_from_filetree() {
  index_file="$1"
  current_dir="$2"
  link_replacement="$3"

  echo "<ul>" >> "$index_file"

  for page_file in "$current_dir"/*.html; do

    if [[ -f "$page_file" ]]; then
      page_name=$(extract_page_name_from_html "$page_file")
      page_folder=$(basename "$page_file" .html)
      link_url=$(echo "$page_file" | sed -e "s,$link_replacement/,,g")

      echo "<li><a href='$link_url'>$page_name</a>" >> "$index_file"

      if [ -d "$current_dir/$page_folder" ]; then
        generate_index_recursively_from_filetree "$index_file" "$current_dir/$page_folder" "$link_replacement"
      fi

      echo "</li>" >> "$index_file"
    fi
  done

  echo "</ul>" >> "$index_file"
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
  echo "\
    <link rel='stylesheet' href='/teleprompter.css'/>\
    <script src='/socket.io.js'></script>\
    <script src='/teleprompter.js'></script>"
}


patch_notion_files_recursively() {
  for html_file in "$2"/*.html; do
    echo "Patching $html_file"
    perl -pi -e "s,</body></html>,$1</body></html>,g" "$html_file"
  done

  for folder in "$2"/*; do
    if [ -d "$folder" ]; then
      patch_notion_files_recursively "$1" "$folder"
    fi
  done
}


copy_teleprompter_files() {
  ln -s "$1/socket.io.js" "$2/socket.io.js"
  ln -s "$1/teleprompter.js" "$2/teleprompter.js"
  ln -s "$1/teleprompter.css" "$2/teleprompter.css"
}


get_teleprompter_url() {
  local_ip_address=$(ifconfig | grep "inet " | grep -Fv 127.0.0.1 | awk '{print $2}')
  echo "http://$local_ip_address:$1"
}


show_user_message() {
  url="$1"
  dirname=$(basename "$2")
  format_link="$(tput smul)$(tput setaf 006)"
  format_filename="$(tput setaf 002)"
  format_reset="$(tput sgr0)"
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
    2. On your device, open ${format_link}${url}${format_reset}
    3. You're good to go!

    ------

    WITHOUT USING WI-FI:
    - Alternatively, upload the contents of the
      ${format_filename}${dirname}${format_reset} folder
      to any static HTML-hosting

    TO READ HARDWARE SETUP TIPS:
    - See ${format_link}https://github.com/egorvinogradov/notion-teleprompter${format_reset}

    TO QUIT TELEPROMPTER:
    - Press Ctrl+C here in the console



  "
}


run_local_server() {
  cd "$2"
  {
    python -m SimpleHTTPServer "$1"
  } || {
    python -m http.server "$1"
  }
}


get_script_path() {
  path=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
  echo "$path";
}


ARCHIVE_PATH="$1"
UNPACKED_PATH=$(unzip_archive "$ARCHIVE_PATH")

SCRIPT_PATH=$(get_script_path)
CODE_INJECTION=$(get_code_injection "$SCRIPT_PATH")

TELEPROMPTER_PORT=7777
TELEPROMPTER_URL=$(get_teleprompter_url "$TELEPROMPTER_PORT")

echo ""
patch_notion_files_recursively "$CODE_INJECTION" "$UNPACKED_PATH"
create_index_file "$CODE_INJECTION" "$UNPACKED_PATH"
copy_teleprompter_files "$SCRIPT_PATH" "$UNPACKED_PATH"
show_user_message "$TELEPROMPTER_URL" "$UNPACKED_PATH"
run_local_server "$TELEPROMPTER_PORT" "$UNPACKED_PATH"

## TODO: uncomment
## open "$TELEPROMPTER_URL?start=1"
