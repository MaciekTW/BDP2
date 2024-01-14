#!/bin/bashHOST
# Created: 14.01.2024
# Usage: skrypt.sh [-u URL] [-i INDEX] [-h HOST] [-p PORT] [-U USER] [-P PASS] [-d DB_NAME] [-w PASSWORD]
    
#     -u URL        URL of the file to download (default: http://home.agh.edu.pl/~wsarlej/dyd/bdp2/materialy/cw10/InternetSales_new.zip)
#     -i INDEX      Your index (default: 402644)
#     -h HOST    Database host (default: mysql.agh.edu.pl)
#     -p PORT    Database port (default: 3306)
#     -U USER    Database user (default: maciejtw)
#     -P PASS    Database password (default: RktxRGFwWmRSQVRuNTc0VQo= in base64), provide plain version not in base64, it would be ciphered
#     -d DB_NAME    Database name (default: maciejtw)
#     -w PASSWORD   Password for file extraction (default: bdp2agh)



today() {
  date +"%m%d%Y"
}

time_now() {
    date '+%Y-%m-%d %H:%M:%S'
}

log() {
    echo "$(time_now) $1" | tee -a $log_file
}

# Default values for variables
DEFAULT_URL="http://home.agh.edu.pl/~wsarlej/dyd/bdp2/materialy/cw10/InternetSales_new.zip"
DEFAULT_INDEX="402644"
DEFAULT_HOST="mysql.agh.edu.pl"
DEFAULT_PORT="3306"
DEFAULT_USER="maciejtw"
DEFAULT_PASS="RktxRGFwWmRSQVRuNTc0VQo="
DEFAULT_NAME="maciejtw"
DEFAULT_PASSWORD="bdp2agh"

# Assigning passed arguments or default values
url="$DEFAULT_URL"
my_index="$DEFAULT_INDEX"
HOST="$DEFAULT_HOST"
PORT="$DEFAULT_PORT"
USER="$DEFAULT_USER"
PASS="$DEFAULT_PASS"
DB_NAME="$DEFAULT_NAME"
password="$DEFAULT_PASSWORD"

show_help() {
cat << EOF
Usage: ${0##*/} [-u URL] [-i INDEX] [-h HOST] [-p PORT] [-U USER] [-P PASS] [-d DB_NAME] [-w PASSWORD]
    
    -u URL        URL of the file to download (default: $DEFAULT_URL)
    -i INDEX      Your index (default: $DEFAULT_INDEX)
    -h HOST    Database host (default: $DEFAULT_HOST)
    -p PORT    Database port (default: $DEFAULT_PORT)
    -U USER    Database user (default: $DEFAULT_USER)
    -P PASS    Database password (default: $DEFAULT_PASS in base64), provide plain version not in base64, it would be ciphered
    -d DB_NAME    Database name (default: $DEFAULT_NAME)
    -w PASSWORD   Password for file extraction (default: $DEFAULT_PASSWORD)
EOF
}

# Parse command line options
while getopts "u:i:h:p:U:P:d:w:" opt; do
    case "$opt" in
        u)  url=$OPTARG
            ;;
        i)  my_index=$OPTARG
            ;;
        h)  HOST=$OPTARG
            ;;
        p)  PORT=$OPTARG
            ;;
        U)  USER=$OPTARG
            ;;
        P)  PASS=$(echo -n "$OPTARG" | base64)
            ;;
        d)  DB_NAME=$OPTARG
            ;;
        w)  password=$OPTARG
            ;;
        *)  show_help
            exit 1
            ;;
    esac
done

# Prepare needed global variables

export MYSQL_PWD=$(echo "$PASS" | base64 --decode)

processed_directory="PROCESSED"
zip_file="InternetSales_new.zip"
csv_file="InternetSales_new.txt"
log_file="$processed_directory/$0_$(date +"%m%d%Y").log"
csv_dump="CUSTOMERS_${my_index}.csv"
bad_records_file="InternetSales_new.bad_$(date +"%m%d%Y")"
SQL_CREATE_TABLE="CREATE TABLE IF NOT EXISTS CUSTOMERS_${my_index} (ProductKey INT, CurrencyAlternateKey VARCHAR(8), FIRST_NAME VARCHAR(255), LAST_NAME VARCHAR(255), OrderDateKey DATE, OrderQuantity INT, UnitPrice DECIMAL(10,2), SecretCode VARCHAR(11));"
SQL_LOAD_DATA="LOAD DATA LOCAL INFILE '"$processed_directory/$(today)_$csv_file"' INTO TABLE CUSTOMERS_${my_index} FIELDS TERMINATED BY '|' LINES TERMINATED BY '\n' IGNORE 1 LINES (ProductKey, CurrencyAlternateKey, FIRST_NAME, LAST_NAME, OrderDateKey, OrderQuantity, UnitPrice, SecretCode);"
SQL_UPDATE_SECRET_CODE="UPDATE CUSTOMERS_${my_index} SET SecretCode=LEFT(MD5(RAND()), 10);"
SQL_SELECT_ALL="SELECT * FROM CUSTOMERS_${my_index};"


check_exit_status() {
    if [ $? -ne 0 ]; then
        log "$1"
        exit 1
    fi
}

create_directory() {
    mkdir -p "$1"
    check_exit_status "Failed to create directory $1."
}

download_file() {
    wget "$1" -O "$2" > /dev/null 2>&1
    check_exit_status "Downloading $2 failed."
    log "File download Success!"
}

unzip_file() {
    unzip -o -P "$1" "$2" > /dev/null 2>&1
    check_exit_status "Unzipping $2 failed."
    log "Unzip file Success!"

}

check_csv_file_exists() {
    if [ ! -f "$csv_file" ]; then
        log "Original CSV file does not exist."
        exit 1
    fi
}

remove_invalid_records_and_split() {
    # Combined AWK command to process CSV file
    awk -F'|' 'BEGIN {OFS="|"} 
    NR == 1 {
        print $1, $2, "FIRST_NAME", "LAST_NAME", $4, $5, $6, $7
        header = $0
        print header > "'$bad_records_file'"
        num_cols = NF; next
    }
    NF != num_cols || $0 == "" || seen[$0]++ || $5 > 100 || $7 != "" || !match($3, /[A-Za-z]+,[A-Za-z]+/) {
        $7 = ""  # Remove SecretCode values
        print $0 > "'$bad_records_file'"
        next
    }
    {
        split($3, name, ",")
        gsub(/"/, "", name[1])
        gsub(/"/, "", name[2])
        print $1, $2, name[2], name[1], $4, $5, $6, $7
    }' "$csv_file" > temp_file && mv temp_file "$csv_file"

    check_exit_status "Removing invalid records failed."
}

move_processed_csv() {
    mv "$csv_file" "$processed_directory/$(today)_$csv_file"
    check_exit_status "Moving processed CSV file to $processed_directory failed."
    log "Moving file Success!"
}

process_csv() {
    check_csv_file_exists
    remove_invalid_records_and_split
    log "Validate file Success!"
    move_processed_csv
    log "CSV file processed and moved to $processed_directory."
}

execute_sql() {
    mysql --local-infile=1 --host="$HOST" --port="$PORT" --user="$USER" "$DB_NAME" -e "$1"  > /dev/null 2>&1
    check_exit_status "$2"
    log "$3"
}

dump_csv() {
    mysql --local-infile=1 --host="$HOST" --port="$PORT" --user="$USER" "$DB_NAME" -e "$1" -B | sed 's/\t/,/g' > $csv_dump 2>/dev/null
    check_exit_status "$2"
    log "$3"
}

compress_csv() {
    gzip -f "$csv_dump" > /dev/null 2>&1
    check_exit_status "$2"
    log "CSV compression success!"
}

# Main script execution
create_directory "$processed_directory"
download_file "$url" "$zip_file"
unzip_file "$password" "$zip_file"
process_csv
execute_sql "$SQL_CREATE_TABLE" "Creating table failed." "Table create Success!"
execute_sql "$SQL_LOAD_DATA" "Loading data into table failed." "Data load Success!"
execute_sql "$SQL_UPDATE_SECRET_CODE" "Updating SecretCode failed." "SecretCode generation Success!"
dump_csv "$SQL_SELECT_ALL" "Select query failed." "Dumping to CSV file Success!"
compress_csv
log "Script Execution Success!"
