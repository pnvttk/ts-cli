#!/bin/bash

# Define the file where entries will be stored
[ ! -f "~/timesheet.txt" ] &&	touch ~/timesheet.txt
FILE="$HOME/timesheet.txt"

# Function to add an entry with a timestamp
add_entry() {
    local entry="$*"
    # Check if the entry is empty
    if [[ -z "$entry" ]]; then
        echo "Error: No entry provided."
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
        # Print the file content with line numbers
        nl -w2 -s". " "$FILE"
    else
        echo "$FILE not found."
    fi
}

# Function to delete an entry by index or timestamp
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
            sed -i.bak "d" "$FILE" && echo "Deleted entries file from $FILE"
        else
            echo "Invalid delete option. Use -i for index, -t for timestamp or -a for all."
        fi
    else
        echo "$FILE not found."
    fi
}

# Function to print the help message
print_help() {
    echo "Usage: timesheet {-m \"message\" | -a | -d [-i index | -t timestamp] | -h}"
    echo
    echo "Options:"
    echo "  -m, --message      Add a new entry with a timestamp."
    echo "  -a, --all          Show all entries or an option for delete all entries"
    echo "  -d, --delete       Delete an entry by index or timestamp."
    echo "  -i, --index        Specify the index for deletion."
    echo "  -t, --timestamp    Specify the timestamp for deletion."
    echo "  -h, --help         Show this help message."
    echo
    echo "Examples:"
    echo "  timesheet -m \"coding\"          Add a new entry \"coding\"."
    echo "  timesheet -a                   Show all entries."
    echo "  timesheet -d -a              	 Delete all the entries."
    echo "  timesheet -d -i 2              Delete the entry at index 2."
    echo "  timesheet -d -t 20230514153000 Delete entries with timestamp 20230514153000."
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
								shift
								delete_entry -a
								;;
            *)
                echo "Error: Missing or invalid argument for delete."
                print_help
                ;;
        esac
        ;;
    -h|--help)
        print_help
        ;;
    *)
        echo "Error: Invalid option."
        print_help
        ;;
esac
