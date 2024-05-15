#!/bin/bash

# Define the file where entries will be stored
[ ! -f "$HOME/timesheet.txt" ] &&	touch "$HOME/timesheet.txt"
FILE="$HOME/timesheet.txt"

# Function to add an entry with a timestamp
add_entry() {
    # Trim leading and trailing whitespace characters from the entry
    local entry="$(echo -e "$*" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    # Check if the entry is empty after trimming
    if [[ -z "$entry" ]]; then
        echo "Error: No meaningful entry provided."
        return 1
    fi
    # Get the current timestamp in the format YYYYMMDDHHMMSS
    local timestamp=$(date +"%Y%m%d%H%M%S")
    # Append the timestamp and entry to the file
    echo "$timestamp: $entry" >> "$FILE"
    echo "Entry added to $FILE"
}

# Function to show all entries
show_entries() {
    # Check if the file exists
    if [ -f "$FILE" ]; then
        # Initialize line counter
        line_number=1
        # Read the file line by line
        while IFS= read -r line; do
            # Check if the line starts with a timestamp
            if [[ $line =~ ^[0-9]{14}: ]]; then
                # If it does, print the line number followed by the line
                printf "%2d. %s\n" "$line_number" "$line"
                ((line_number++))
            else
                # If it doesn't, print the line directly without an index
                echo "   $line"
            fi
        done < "$FILE"
    else
        echo "$FILE not found."
    fi
}

# Function to delete an entry by index, timestamp, or delete all entries
delete_entry() {
    local option=$1
    local value=$2
    # Check if the file exists
    if [ -f "$FILE" ]; then
        if [ "$option" == "-i" ]; then
            # Validate the index value
            if ! [[ "$value" =~ ^[0-9]+$ ]]; then
                echo "Invalid index: $value"
                return 1
            fi
            # Delete the entry at the specified index
            sed -i.bak "${value}d" "$FILE" && echo "Deleted entry at index $value from $FILE"
        elif [ "$option" == "-t" ]; then
            # Validate the timestamp value
            if ! [[ "$value" =~ ^[0-9]{14}$ ]]; then
                echo "Invalid timestamp: $value"
                return 1
            fi
            # Delete entries with the specified timestamp
            sed -i.bak "/^$value/d" "$FILE" && echo "Deleted entries with timestamp $value from $FILE"
        elif [ "$option" == "-a" ]; then
            # Delete all entries
            > "$FILE" && echo "Deleted all entries from $FILE"
        else
            echo "Invalid delete option. Use -i for index, -t for timestamp, or -a for all."
        fi
    else
        echo "$FILE not found."
    fi
}

# Function to edit an entry's message by index
edit_entry() {
    local index=$1
    local new_message=$2
    # Check if the file exists
    if [ -f "$FILE" ]; then
        # Validate the index value
        if ! [[ "$index" =~ ^[0-9]+$ ]]; then
            echo "Invalid index: $index"
            return 1
        fi
        # Get the current entry at the specified index
        local current_entry=$(sed "${index}q;d" "$FILE")
        # Extract the timestamp from the current entry
        local timestamp=$(echo "$current_entry" | cut -d' ' -f1)
        # Replace only the message part of the current entry with the new message
        local new_entry="$timestamp: $new_message"
        # Replace the current entry with the new entry
        sed -i.bak "${index}s/.*/$new_entry/" "$FILE" && echo "Updated entry at index $index: $current_entry -> $new_entry"
    else
        echo "$FILE not found."
    fi
}

# Function to print the help message
print_help() {
    echo "Usage: timesheet {-m \"message\" | -a | -d [-i index | -t timestamp | -a] | -e index \"new_message\" | -h}"
    echo
    echo "Options:"
    echo "  -m, --message      Add a new entry with a timestamp."
    echo "  -a, --all          Show all entries or an option for delete all entries."
    echo "  -d, --delete       Delete an entry by index, timestamp, or all entries."
    echo "  -i, --index        Specify the index for deletion."
    echo "  -t, --timestamp    Specify the timestamp for deletion."
    echo "  -e, --edit         Edit an entry's message by index."
    echo "  -h, --help         Show this help message."
    echo
    echo "Examples:"
    echo "  timesheet -m \"coding\"          Add a new entry \"coding\"."
    echo "  timesheet -a                   Show all entries."
    echo "  timesheet -d -a              	 Delete all the entries."
    echo "  timesheet -d -i 2              Delete the entry at index 2."
    echo "  timesheet -d -t 20230514153000 Delete entries with timestamp 20230514153000."
    echo "  timesheet -e 2 \"new message\"  Edit the message at index 2."
}

# Main logic to parse command-line arguments
case $1 in
    -m|--message)
        shift
        add_entry "$@"
        ;;
    -a|--all)
        show_entries
        ;;
    -d|--delete)
        shift
        case $1 in
            -i|--index)
                shift
                delete_entry -i "$1"
                ;;
            -t|--timestamp)
                shift
                delete_entry -t "$1"
                ;;
            -a|--all)
                delete_entry -a
                ;;
            *)
                echo "Error: Missing or invalid argument for delete."
                print_help
                ;;
        esac
        ;;
    -e|--edit)
        shift
        edit_entry "$1" "$2"
        ;;
    -h|--help)
        print_help
        ;;
    *)
        echo "Error: Invalid option."
        print_help
        ;;
esac
