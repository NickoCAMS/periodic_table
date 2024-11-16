#!/bin/bash

# Set the PostgreSQL database credentials
DB_NAME="periodic_table"
DB_USER="freecodecamp"

# Function to query the database for element information
lookup_element() {
    local input=$1

    # Query for atomic number, symbol, and name from the 'elements' table
    if [[ $input =~ ^[0-9]+$ ]]; then
        # Search by atomic number
        result=$(psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT e.atomic_number, e.symbol, e.name, p.type_id, p.atomic_mass, p.melting_point_celsius, p.boiling_point_celsius 
                FROM elements e 
                JOIN properties p ON e.atomic_number = p.atomic_number 
                WHERE e.atomic_number = $input;")
    elif [[ $input =~ ^[A-Za-z]+$ ]]; then
        # Search by symbol or name
        result=$(psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT e.atomic_number, e.symbol, e.name, p.type_id, p.atomic_mass, p.melting_point_celsius, p.boiling_point_celsius 
                FROM elements e 
                JOIN properties p ON e.atomic_number = p.atomic_number 
                WHERE e.symbol = '$input' OR e.name = '$input';")
    else
        echo "Invalid input."
        return 1
    fi

    # Check if the result is empty or not
    if [[ -z "$result" ]]; then
        echo "I could not find that element in the database."
    else
        # Trim any extra spaces using `sed` or `awk`
        result=$(echo "$result" | sed 's/^[ \t]*//;s/[ \t]*$//')

        # Format and output the result (Trim spaces between fields)
        IFS='|' read -r atomic_number symbol name type_id atomic_mass melting_point boiling_point <<< "$result"

        # Remove unnecessary spaces between fields for output
        atomic_number=$(echo "$atomic_number" | sed 's/^[ \t]*//;s/[ \t]*$//')
        symbol=$(echo "$symbol" | sed 's/^[ \t]*//;s/[ \t]*$//')
        name=$(echo "$name" | sed 's/^[ \t]*//;s/[ \t]*$//')
        type_id=$(echo "$type_id" | sed 's/^[ \t]*//;s/[ \t]*$//')
        atomic_mass=$(echo "$atomic_mass" | sed 's/^[ \t]*//;s/[ \t]*$//')
        melting_point=$(echo "$melting_point" | sed 's/^[ \t]*//;s/[ \t]*$//')
        boiling_point=$(echo "$boiling_point" | sed 's/^[ \t]*//;s/[ \t]*$//')

        # Retrieve the type from the 'types' table using type_id
        type=$(psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT type FROM types WHERE type_id = $type_id;")
        type=$(echo "$type" | sed 's/^[ \t]*//;s/[ \t]*$//')

        # Final formatted output with trimmed spaces
        echo "The element with atomic number $atomic_number is $name ($symbol). It's a $type, with a mass of $atomic_mass amu. $name has a melting point of $melting_point celsius and a boiling point of $boiling_point celsius."
    fi
}

# Check if the user provided an argument
if [ -z "$1" ]; then
    echo "Please provide an element as an argument."
else
    # Call the lookup function with the provided argument
    lookup_element "$1"
fi
