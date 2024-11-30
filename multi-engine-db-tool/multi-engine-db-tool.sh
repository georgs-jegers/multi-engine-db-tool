#!/bin/bash

# Add colors for more interactive
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
RESET="\033[0m"

# Banner function for visual flair
print_banner() {
  echo -e "${CYAN}==============================${RESET}"
  echo -e "${MAGENTA}  MULTI-ENGINE DB TOOL ${RESET}"
  echo -e "${CYAN}==============================${RESET}"
}

# Success and error messages
success_message() {
  echo -e "${GREEN}[✔] $1${RESET}"
}

error_message() {
  echo -e "${RED}[✖] $1${RESET}"
}

info_message() {
  echo -e "${YELLOW}[ℹ] $1${RESET}"
}

# Validate database name
validate_db_name() {
  if [[ ! "$1" =~ ^[a-zA-Z0-9_]+$ ]]; then
    error_message "Invalid database name. Only letters, numbers, and underscores are allowed."
    exit 1
  fi
}

# Generate naming convention
generate_filename() {
  local DB_ENGINE=$1
  local DB_NAME=$2
  local TIMESTAMP=$(date +"%Y-%m-%d")
  echo "${TIMESTAMP}_${DB_ENGINE}_${DB_NAME}"
}

# Replace domain in SQL file
replace_domain() {
  local BACKUP_FILE=$1
  local OLD_DOMAIN=$2
  local NEW_DOMAIN=$3

  info_message "Replacing domain $OLD_DOMAIN with $NEW_DOMAIN in the backup file..."

  if [[ "$BACKUP_FILE" =~ \.sql$ ]]; then
    sed -i "s|$OLD_DOMAIN|$NEW_DOMAIN|g" "$BACKUP_FILE"
    success_message "Domain replacement complete in $BACKUP_FILE"
  elif [[ "$BACKUP_FILE" =~ \.dump$ ]]; then
    error_message "Cannot perform direct replacements on binary dump files (.dump). Please use .sql format for domain replacement."
    exit 1
  else
    error_message "Unsupported file format for domain replacement."
    exit 1
  fi
}

# Export MySQL/MariaDB
export_mysql() {
  echo -e "${MAGENTA}Enter the MySQL/MariaDB details:${RESET}"
  read -p "Database username: " DB_USER
  read -s -p "Database password: " DB_PASSWORD
  echo
  read -p "Database host (default: localhost): " DB_HOST
  DB_HOST=${DB_HOST:-localhost}

  # List available databases
  info_message "Fetching available databases..."
  DB_LIST=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "SHOW DATABASES;" 2>/dev/null | tail -n +2)
  if [[ $? -ne 0 ]]; then
    error_message "Failed to fetch database list. Please check your credentials."
    exit 1
  fi
  echo -e "${CYAN}Available databases:${RESET}"
  echo "$DB_LIST"
  
  read -p "Enter the database name to export: " DB_NAME
  validate_db_name "$DB_NAME"

  # Generate filename
  FILENAME=$(generate_filename "MySQL" "$DB_NAME")
  FILEPATH="$(pwd)/${FILENAME}.sql"

  # Export the database
  info_message "Exporting the database..."
  mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" > "$FILEPATH" 2>/dev/null
  if [[ $? -ne 0 ]]; then
    error_message "Failed to export the database. Please check your credentials and database name."
    exit 1
  fi
  success_message "MySQL/MariaDB database exported to $FILEPATH"
}

# Import MySQL/MariaDB
import_mysql() {
  echo -e "${MAGENTA}Enter the MySQL/MariaDB details:${RESET}"
  read -p "Database username: " DB_USER
  read -s -p "Database password: " DB_PASSWORD
  echo
  read -p "Database host (default: localhost): " DB_HOST
  DB_HOST=${DB_HOST:-localhost}

  # Import the database
  read -p "Enter the path to the backup file (e.g., 2024-11-30_MySQL_exampledb.sql): " BACKUP_FILE
  if [[ ! -f "$BACKUP_FILE" ]]; then
    error_message "Backup file not found."
    exit 1
  fi

  read -p "Enter the database name to import into: " DB_NAME
  validate_db_name "$DB_NAME"

  # Option to replace domain
  read -p "Do you need to replace a domain in the database? (y/n): " REPLACE_OPTION
  if [[ "$REPLACE_OPTION" =~ ^[Yy]$ ]]; then
    read -p "Enter the old domain (e.g., https://snake.io): " OLD_DOMAIN
    read -p "Enter the new domain (e.g., https://multitool.dev): " NEW_DOMAIN
    replace_domain "$BACKUP_FILE" "$OLD_DOMAIN" "$NEW_DOMAIN"
  fi

  info_message "Importing the database..."
  mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "$BACKUP_FILE" 2>/dev/null
  if [[ $? -ne 0 ]]; then
    error_message "Failed to import the database. Please check your credentials and backup file."
    exit 1
  fi
  success_message "MySQL/MariaDB database imported from $BACKUP_FILE"
}

# Export PostgreSQL
export_postgresql() {
  echo -e "${MAGENTA}Enter the PostgreSQL details:${RESET}"
  read -p "Database username: " DB_USER
  read -s -p "Database password: " DB_PASSWORD
  echo
  read -p "Database host (default: localhost): " DB_HOST
  DB_HOST=${DB_HOST:-localhost}
  read -p "Database port (default: 5432): " DB_PORT
  DB_PORT=${DB_PORT:-5432}

  export PGPASSWORD="$DB_PASSWORD"

  # List available databases
  info_message "Fetching available databases..."
  DB_LIST=$(psql -h "$DB_HOST" -U "$DB_USER" -p "$DB_PORT" -lqt | cut -d \| -f 1 | grep -wv "template0\|template1" | sed -e 's/^ *//' -e '/^$/d')
  if [[ $? -ne 0 ]]; then
    error_message "Failed to fetch database list. Please check your credentials."
    exit 1
  fi
  echo -e "${CYAN}Available databases:${RESET}"
  echo "$DB_LIST"

  read -p "Enter the database name to export: " DB_NAME
  validate_db_name "$DB_NAME"

  # Generate filename
  FILENAME=$(generate_filename "PostgreSQL" "$DB_NAME")
  FILEPATH="$(pwd)/${FILENAME}.sql"

  # Export the database
  info_message "Exporting the database..."
  pg_dump -h "$DB_HOST" -U "$DB_USER" -p "$DB_PORT" "$DB_NAME" > "$FILEPATH" 2>/dev/null
  if [[ $? -ne 0 ]]; then
    error_message "Failed to export the database. Please check your credentials."
    exit 1
  fi
  success_message "PostgreSQL database exported to $FILEPATH"
}

# Import PostgreSQL
import_postgresql() {
  echo -e "${MAGENTA}Enter the PostgreSQL details:${RESET}"
  read -p "Database username: " DB_USER
  read -s -p "Database password: " DB_PASSWORD
  echo
  read -p "Database host (default: localhost): " DB_HOST
  DB_HOST=${DB_HOST:-localhost}
  read -p "Database port (default: 5432): " DB_PORT
  DB_PORT=${DB_PORT:-5432}

  export PGPASSWORD="$DB_PASSWORD"

  # Import the database
  read -p "Enter the path to the backup file (e.g., 2024-11-30_PostgreSQL_exampledb.sql): " BACKUP_FILE
  if [[ ! -f "$BACKUP_FILE" ]]; then
    error_message "Backup file not found."
    exit 1
  fi

  read -p "Enter the database name to restore into: " DB_NAME
  validate_db_name "$DB_NAME"

  # Option to replace domain
  read -p "Do you need to replace a domain in the database? (y/n): " REPLACE_OPTION
  if [[ "$REPLACE_OPTION" =~ ^[Yy]$ ]]; then
    read -p "Enter the old domain (e.g., https://snake.io): " OLD_DOMAIN
    read -p "Enter the new domain (e.g., https://multitool.dev): " NEW_DOMAIN
    replace_domain "$BACKUP_FILE" "$OLD_DOMAIN" "$NEW_DOMAIN"
  fi

  info_message "Importing the database..."
  pg_restore -h "$DB_HOST" -U "$DB_USER" -p "$DB_PORT" -d "$DB_NAME" -v "$BACKUP_FILE" 2>/dev/null
  if [[ $? -ne 0 ]]; then
    error_message "Failed to import the database. Please check your credentials and backup file."
    exit 1
  fi
  success_message "PostgreSQL database imported from $BACKUP_FILE"
}

# Main menu
main_menu() {
  print_banner
  echo -e "${BLUE}Select operation:${RESET}"
  echo "1. Export Database"
  echo "2. Import Database"
  read -p "Enter your choice (1 or 2): " OPERATION

  echo -e "${BLUE}Select the database engine:${RESET}"
  echo "1. MySQL/MariaDB"
  echo "2. PostgreSQL"
  read -p "Enter your choice (1 or 2): " DB_ENGINE

  case $OPERATION in
    1)
      case $DB_ENGINE in
        1) export_mysql ;;
        2) export_postgresql ;;
        *) error_message "Invalid database engine. Exiting."; exit 1 ;;
      esac
      ;;
    2)
      case $DB_ENGINE in
        1) import_mysql ;;
        2) import_postgresql ;;
        *) error_message "Invalid database engine. Exiting."; exit 1 ;;
      esac
      ;;
    *)
      error_message "Invalid operation. Exiting."
      exit 1
      ;;
  esac
}

# Run the script
main_menu