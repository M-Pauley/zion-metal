#! /usr/bin/env bash
########################################################################
# 
# Install and configure MaaS v3.4 Snap with PostgreSQL.
# Initialize MaaS as rack+region controller.
# MaaS configuration and machine management to be manually completed.
#    https://maas.io/docs/fresh-installation-of-maas
#
########################################################################
#
# Unset any stored variables from previous (failed?) runs.
unset "$MAAS_DBUSER"
unset "$MAAS_DBPASS"
unset "$ENC_MAAS_DBPASS"
unset "$MAAS_DBNAME"
unset "$INSTALL_LOG"
unset "$SESSION_ID"
# Set pre-configured variables for internal use.
PSQL_REQ=12
MAAS_REQ=3.4
DB_HOSTNAME=localhost
DATE=$(date +%Y%m%d)
WD=$(pwd)
INSTALL_LOG="$WD/log_install-MaaS_$DATE.log"
SESSION_ID=$(openssl rand -base64 32 | paste --delimiters '' --serial)

# Check if PostgreSQL is installed and extract version information if available
# otherwise set PSQL_VERSION variable to 0. Check if MaaS is installed and extract
# version information if available otherwise set MAAS_VERSION variable to 0.
function PRE_CHECK {
    echo "Checking is PostgreSQL is installed and getting version..." | tee -a "$INSTALL_LOG"
    if command -v psql > /dev/null; then
        PSQL_VERSION=$(psql --version | awk -F ' ' '{print $3}' | cut -d. -f1)
        echo "PostgreSQL is already installed - version is $PSQL_VERSION" | tee -a "$INSTALL_LOG"
    else
        PSQL_VERSION=0
        echo "Previous PostgreSQL installation could not be found. It will be installed here" | tee -a "$INSTALL_LOG"
    fi
    echo "Checking if MaaS is installed and getting version..." | tee -a "$INSTALL_LOG"
    if command -v maas > /dev/null; then
        MAAS_VERSION=$(snap list maas | awk -F ' ' '{print $4}' | tail -n1 | cut -d "/" -f 1)
        echo "MaaS is already installed - version is $MAAS_VERSION" | tee -a "$INSTALL_LOG"
    else
        MAAS_VERSION=0
        echo "Previous MaaS installation could not be found. It will be installed here" | tee -a "$INSTALL_LOG"
    fi
    VAR_INPUT
}

# User input for variables needed for PostgreSQL configuration and MaaS initialization.
function VAR_INPUT {
    if [ -z "$MAAS_DBUSER" ] || [ -z "$ENC_MAAS_DBPASS" ] || [ -z "$MAAS_DBNAME" ]; then
        read -rp "Enter Database User: " MAAS_DBUSER
        read -srp "Enter Database Password: " MAAS_DBPASS
        printf "\n"
        read -rp "Enter Database Name: " MAAS_DBNAME
    else
        printf 'Database User: %s \n Database Password: %s \n Database Name: %s \n\n' "$MAAS_DBUSER" "$ENC_MAAS_DBPASS" "$MAAS_DBNAME"
        read -rp "Would you like to make any changes? (y/n): " yn
            case $yn in
                [yY] ) echo "Changing PostgreSQL Server Information";
                        read -rp "Enter Database User: " MAAS_DBUSER;
                        read -srp "Enter Database Password: " MAAS_DBPASS;
                        printf "\n";
                        read -rp "Enter Database Name: " MAAS_DBNAME;
                    VAR_INPUT;;
                [nN] ) echo "Continue with PostgreSQL Server setup...";;
                * ) echo "Invalid"; clear; VAR_INPUT;;
            esac
    fi
# Set a variable for an encrypted version of the password to use in tty printed output and log textfile.
# To decrypt the password run:
# echo 'encrypted-password-in-logfile' | openssl enc -aes-256-cbc -md sha512 -a -pbkdf2 -iter 100000 -salt -pass pass:'sessionID-number' -d
    ENC_MAAS_DBPASS=$(echo "$MAAS_DBPASS" | openssl enc -aes-256-cbc -md sha512 -a -pbkdf2 -iter 100000 -salt -pass pass:"$SESSION_ID" >> "$INSTALL_LOG")
    printf 'PostgreSQL Server: %s \n \n' "$DB_HOSTNAME"
    read -rp "Change PostgreSQL Server? (y/n): " yn
        case $yn in
            [yY] ) read -rp "Enter PostgreSQL Server Name or IP: " DB_HOSTNAME;;
            [nN] ) echo "PostgreSQL Server Hostname will remain: $DB_HOSTNAME"; PSQL_CHECK;;
            * ) echo "Invalid"; clear; VAR_INPUT;;
        esac
    clear
    printf 'Setup is using the following -- \n Database User: %s \n Database Password: %s \n Database Name: %s \n PostgreSQL Server: %s \n \n' "$MAAS_DBUSER" "$ENC_MAAS_DBPASS" "$MAAS_DBNAME" "$DB_HOSTNAME"
    read -rp "Continue installation? (y/n): " yn
        case $yn in
            [yY] ) printf 'Install is continuing... \n' | tee -a "$INSTALL_LOG"; PSQL_CHECK;; 
            [nN] ) echo "Clearing user information..." | tee -a "$INSTALL_LOG"; unset "$MAAS_DBUSER"; unset "$MAAS_DBPASS"; unset "$ENC_MAAS_DBPASS"; unset "$MAAS_DBNAME";VAR_INPUT;;
            * ) echo "Invalid"; clear; VAR_INPUT;;
        esac
}


function PSQL_CHECK {
    if [ "$DB_HOSTNAME" != "localhost" ]; then
    read -rp "Is the PostgreSQL Server already configured properly on a remote host? (y/n): " yn
        case $yn in
            [yY] ) printf "You have indicated the PostgreSQL Server %s is remote. \n Skipping PostgreSQL Installation." "$DB_HOSTNAME" | tee -a "$INSTALL_LOG";;
            [nN] ) printf "You have indicated the PostgreSQL Server %s is local." "$DB_HOSTNAME" | tee -a "$INSTALL_LOG";;
            * ) echo "Invalid"; clear; VAR_INPUT;;
        esac
# First, check if PSQL is installed and goto install if pre-check function set PSQL_VERSION to 0.
    elif [ "$PSQL_VERSION" == 0 ]; then
            POSTGRE_INSTALL
# Second, check if version meets minimum requirement.
    elif  [ "$PSQL_VERSION" -gt "$PSQL_REQ" ]; then
        echo "PostgreSQL Version: $PSQL_VERSION. Minimum requirement met."
# If installed and meets required version, check if /etc/postgresql/"$PSQL_VERSION"/main/pg_hba.conf has any conflict with current data.
# This indicates if the database was previously created. It may need to be removed and this entry deleted from the config file.
# It is possible to restore a previous MaaS database from backup, but if you are doing that, manually install MaaS and follow the maas.io docs.
    fi
    if [ -f /etc/postgresql/"$PSQL_VERSION"/main/pg_hba.conf ]; then
        if sudo grep -q "host    ""$MAAS_DBNAME""    ""$MAAS_DBUSER""    0/0     md5" /etc/postgresql/"$PSQL_VERSION"/main/pg_hba.conf; then
            echo "PostgreSQL config file already contains the entry required to continue. Going back to User Setup." | tee -a "$INSTALL_LOG"
            sleep 15
            VAR_INPUT
        else
            echo "PostgreSQL config file has been successfully checked for conflicting configuration. Continuing..." | tee -a "$INSTALL_LOG"
            sleep 15
            MAAS_CHECK
        fi
# Catch-all error for if none of the above are true.
    else
            printf "Unexpected error: Setup cannot continue! \n
            Please upgrade, inspect, or fix PostgreSQL issue then run this script again. \n
            Follow guide at: https://maas.io/docs/upgrading-postgresql-12-to-version-14 \n" | tee -a "$INSTALL_LOG"; exit 0;
    fi
}

# Verify user-set variables and validate requirements accordingly.
function MAAS_CHECK {
    clear
    printf "Setup is using the following -- \n Database User: %s \n Database Password: %s \n Database Name: %s \n PostgreSQL Server: %s \n PostgreSQL Version: %s \n" "$MAAS_DBUSER" "$ENC_MAAS_DBPASS" "$MAAS_DBNAME" "$DB_HOSTNAME" "$PSQL_VERSION" | tee -a "$INSTALL_LOG"
    while true; do
        read -rp "Continue with these parameters? " yn
        case $yn in
            [yY] ) echo "Proceeding with above parameters..."; POSTGRE_INSTALL;;
            [nN] ) echo "Cancelling Installation"; exit 0;;
            * ) echo "Invalid"; MAAS_CHECK;;
        esac
    done
}

# Install PostgreSQL Server if not already installed. Verify version is greater than minimum version
# required. MaaS 3.4 requires greater than PSQL 12. If version is 12 or less print link to upgrade
# guide and exit script. Scripted upgrade would be possible, but impractical/unsafe if it were to
# disturb other database operations.
function POSTGRE_INSTALL {
    if [ "$PSQL_VERSION" == 0 ]; then
        while true; do
            read -rp "Install PostgreSQL? " yn
            case $yn in
                [yY] ) echo "Installing PostgreSQL" | tee -a "$INSTALL_LOG"
            # Removes apt's restart services prompt.
                    echo "\$nrconf{restart} = \"l\"" | sudo tee -a /etc/needrestart/needrestart.conf
                    sudo apt update -y && sudo apt install -y postgresql | tee -a "$INSTALL_LOG"
                    MAAS_INSTALL;;
                [nN] ) echo "Cancelling Installation"; exit 0;;
                * ) echo "Invalid"; POSTGRE_INSTALL;;
            esac
        done
    elif  [ "$PSQL_VERSION" -gt "$PSQL_REQ" ]; then
        echo "PostgreSQL Version: $PSQL_VERSION. Minimum requirement met." | tee -a "$INSTALL_LOG"
        wait 90
        MAAS_INSTALL
    else
        echo "Please inspect and fix or upgrade PostgreSQL to required version and run this script again."
        echo "Follow guide at: https://maas.io/docs/upgrading-postgresql-12-to-version-14"; EXIT 0;
    fi
}

# Main MaaS install. Verify current MaaS state and take appropiate action.
function MAAS_INSTALL {
    clear
    echo "Installing MaaS and initializing as a region+rack controller."
        if [ "$MAAS_VERSION" == 0 ]; then
            echo "installing MaaS $MAAS_REQ and disabling system-timesyncd." | tee -a "$INSTALL_LOG"
            sudo snap install --channel=$MAAS_REQ/candidate maas | tee -a "$INSTALL_LOG"
            sudo systemctl disable --now systemd-timesyncd | tee -a "$INSTALL_LOG"
            MAAS_INSTALL2
        elif [ "$MAAS_VERSION" -lt "$MAAS_REQ" ]; then
            echo "MaaS already installed." | tee -a "$INSTALL_LOG"
            printf "CAUTION: Check https://maas.io/docs/upgrading-maas\n
                    to verify current version can be upgraded (via snap refresh)\n
                    from %s$MAAS_VERSION to %s$MAAS_REQ with PostgreSQL %s$PSQL_VERSION.\n" | tee -a "$INSTALL_LOG"
            while true; do
                read -rp "Continue? " yn
                case $yn in
                    [yY] ) sudo snap refresh --channel=3.4/candidate maas && sudo systemctl disable --now systemd-timesyncd | tee -a "$INSTALL_LOG"
                        MAAS_INSTALL2;;
                    [nN] ) echo "Cancelling Installation"; exit 0;;
                    * ) echo "Invalid"; MAAS_INSTALL;;
                esac
            done
# Not sure how to remove Interger Warning
        elif [[ "$MAAS_VERSION" == "$MAAS_REQ" ]]; then
            echo "Required version of MaaS is already installed on theis system." | tee -a "$INSTALL_LOG"
            echo "If you continue, there may be issues if there is an existing MaaS installation." | tee -a "$INSTALL_LOG"
            while true; do
                read -rp "Continue? " yn
                case $yn in
                    [yY] ) echo "Ok, but this may cause issues." | tee -a "$INSTALL_LOG"; MAAS_INSTALL2;;
                    [nN] ) echo "Cancelling Installation";
                    printf "If re-running the installation script, make sure to remove the entry created in pg_hba.conf, and remove the PostgreSQL user and database that were created. \n\n
                    examples to remove Postgre components: \n
                    host    %s$MAAS_DBNAME    %s$MAAS_DBUSER    0/0     md5 \n
                    found in file \n
                    sudo vi /etc/postgresql/%s$PSQL_VERSION/main/pg_hba.conf \n
                    sudo -u postgresql psql -c \"drop database %s$MAAS_DBNAME\" \n
                    sudo -u postgresql psql -c \"drop user %s$MAAS_DBUSER\" \n"
                    exit 0;;
                    * ) echo "Invalid"; MAAS_INSTALL;;
                esac
            done
        fi
}
# Setup PostgreSQL an initialize MaaS region+rack.
# If re-running the installation script, make sure to remove the psql user, database, and entry in pg_hba.conf
function MAAS_INSTALL2 {
        printf "Creating PostgreSQL user/password and database... "
        sudo -i -u postgres psql -c "CREATE USER \"$MAAS_DBUSER\" WITH ENCRYPTED PASSWORD '$MAAS_DBPASS'" | tee -a "$INSTALL_LOG"
        sudo -i -u postgres createdb -O "$MAAS_DBUSER" "$MAAS_DBNAME" | tee -a "$INSTALL_LOG"
        echo "host    ""$MAAS_DBNAME""    ""$MAAS_DBUSER""    0/0     md5" | sudo tee -a /etc/postgresql/"$PSQL_VERSION"/main/pg_hba.conf
        printf "Initalizing MaaS region+rack..."
        sleep 10
        sudo maas init region+rack --database-uri "postgres://$MAAS_DBUSER:$MAAS_DBPASS@$DB_HOSTNAME/$MAAS_DBNAME" | tee -a "$INSTALL_LOG"
        printf "\nInstallation complete!!! Logfile is located at %s$INSTALL_LOG \n \n" | tee -a "$INSTALL_LOG"
        tail -n 19 "$INSTALL_LOG"
        exit 0
}
# Begin installation
    clear
    printf 'This will install PostgreSQL from repository packages and MaaS snap package if not already installed and meet the minimum required versions. \n
    It will also check for previous configurations and warn you about them, but will allow you to continue. If there are any previous configurations, this script will add more lines to PostgreSQL pg_hba.conf file ; potentially causing issues. \n\n
    !!! WARNING !!! : If you are not using "localhost" for the PostgreSQL host, make sure the the PostgreSQL server is configured and accepting connections before proceeding. \n\n'
        while true; do
            read -rp "Has networking been configured on this host? " yn
            case $yn in
                [yY] ) touch "$INSTALL_LOG" && echo "Beginning installation" | tee -a "$INSTALL_LOG";
                echo "Clearing old Logfile if present..."
                printf "Installation Session ID: \n%s$SESSION_ID" > "$INSTALL_LOG"
                PRE_CHECK;;
                [nN] ) echo "Cancel"; exit 0;;
                * ) echo "Invalid";;
            esac
        done
