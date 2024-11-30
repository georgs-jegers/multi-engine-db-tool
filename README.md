# Multi-Engine Database Tool

A tool for exporting and importing MySQL/MariaDB and PostgreSQL databases with domain replacement support.

## Features
- Export/import databases (MySQL/MariaDB & PostgreSQL).
- Domain replacement during import/export (e.g., change `https://example.com` to `https://newdomain.com`).

## Usage

1. Clone the repository:
    ```bash
    git clone https://github.com/georgs-jegers/multi-engine-db-tool.git
    cd multi-engine-db-tool
    ```

2. Make the script executable:
    ```bash
    chmod +x multi-engine-db-tool.sh
    ```

3. Run the script:
    ```bash
    ./multi-engine-db-tool.sh
    ```

4. Follow the prompts to:
    - Select an operation (Export/Import)
    - Choose your database engine (MySQL/MariaDB or PostgreSQL)
    - Enter database details (username, password, host, etc.)
    - Optionally, replace domains in the database dump.

## Author
Georg Eger

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
