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
unset "$MAAS_DBNAME"
unset "$INSTALL_LOG"
# Set pre-configured variables for internal use.
PSQL_REQ=12
MAAS_REQ=3.4
DB_HOSTNAME=localhost
DATE=$(date +%Y-%m-%d)
WD=$(pwd)
INSTALL_LOG="$WD/maas_install_$DATE.log"

# Check if PostgreSQL is installed and extract version information if available
# otherwise set PSQL_VERSION variable to 0. Check if MaaS is installed and extract
# version information if available otherwise set MAAS_VERSION variable to 0.
function PRE_CHECK {
    echo "Checking is PostgreSQL is installed and getting version..." | tee -a ./"$INSTALL_LOG"
    if command -v psql > /dev/null; then
        PSQL_VERSION=$(psql --version | awk -F '{print $3}' | cut -d. -f1)
        echo "PostgreSQL is already installed - version is $PSQL_VERSION" | tee -a ./"$INSTALL_LOG"
    else
        PSQL_VERSION=0
        echo "Previous PostgreSQL installation could not be found. It will be installed here" | tee -a ./"$INSTALL_LOG"
    fi
    echo "Checking if MaaS is installed and getting version..." | tee -a ./"$INSTALL_LOG"
    if command -v maas > /dev/null; then
        MAAS_VERSION=$(snap list maas | awk -F '{print $4}' | tail -n1)
        echo "MaaS is already installed - version is $MAAS_VERSION" | tee -a ./"$INSTALL_LOG"
    else
        MAAS_VERSION=0
        echo "Previous MaaS installation could not be found. It will be installed here" | tee -a ./"$INSTALL_LOG"
    fi
    VAR_INPUT
}

# User input for variables needed for PostgreSQL configuration and MaaS initialization.
function VAR_INPUT {
    printf "Database User: %s\n" "Database Password: %s\n" "Database Name: %s\n" "PostgreSQL Server: %s\n\n" "$MAAS_DBUSER" "$MAAS_DBPASS" "$MAAS_DBNAME" "$DB_HOSTNAME"
    read -rp "Enter Database User: " MAAS_DBUSER
    read -rp "Enter Database Password: " MAAS_DBPASS
    read -rp "Enter Database Name: " MAAS_DBNAME
    read -rp "Change PostgreSQL Server? (y/n): " yn
        case $yn in
            [yY] ) echo "Changing PostgreSQL Server Hostname";
                read -rp "Enter Database Name: " DB_HOSTNAME; 
                VAR_INPUT;;
            [nN] ) echo "PostgreSQL Server Hostname will remain: $DB_HOSTNAME"; PSQL_CHECK;;
            * ) echo "Invalid"; clear; VAR_INPUT;;
        esac
}

# Check if /etc/postgresql/"$PSQL_VERSION"/main/pg_hba.conf has any conflict with current data.
function PSQL_CHECK {
    if sudo grep -q "host    ""$MAAS_DBNAME""    ""$MAAS_DBUSER""    0/0     md5" /etc/postgresql/"$PSQL_VERSION"/main/pg_hba.conf; then
        echo "PostgreSQL config file already contains the entry required to continue. Going back to User Setup." | tee -a ./"$INSTALL_LOG"; VAR_INPUT;
    else
        echo "PostgreSQL config file has been successfully checked for conflicting configuration." | tee -a ./"$INSTALL_LOG"
    fi
    if  [ "$PSQL_VERSION" -gt "$PSQL_REQ" ]; then
        echo "PostgreSQL Version: $PSQL_VERSION. Minimum requirement met."; wait 90; MAAS_CHECK;
    else
        echo "Setup cannot continue!" | tee -a ./"$INSTALL_LOG"
        echo "Please upgrade, inspect, or fix PostgreSQL then run this script again." | tee -a ./"$INSTALL_LOG"
        echo "Follow guide at: https://maas.io/docs/upgrading-postgresql-12-to-version-14" | tee -a ./"$INSTALL_LOG"; EXIT 0;
    fi
}

# Verify user-set variables and validate requirements accordingly.
function MAAS_CHECK {
    clear
    printf "Database User: %s\n" "Database Password: %s\n" "Database Name: %s\n" "PostgreSQL Server: %s\n" "PostgreSQL Version: %s\n\n" "$MAAS_DBUSER" "$MAAS_DBPASS" "$MAAS_DBNAME" "$DB_HOSTNAME" "$PSQL_VERSION" | tee -a ./"$INSTALL_LOG"
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
                [yY] ) echo "Installing PostgreSQL" | tee -a ./"$INSTALL_LOG"; sudo apt update -y && sudo apt install -y postgresql | tee -a ./"$INSTALL_LOG";;
                [nN] ) echo "Cancelling Installation"; exit 0;;
                * ) echo "Invalid"; POSTGRE_INSTALL;;
            esac
        done
    elif  [ "$PSQL_VERSION" -gt "$PSQL_REQ" ]; then
        echo "PostgreSQL Version: $PSQL_VERSION. Minimum requirement met." | tee -a ./"$INSTALL_LOG"; wait 90; MAAS_INSTALL;
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
            echo "installing MaaS $MAAS_REQ and disabling system-timesyncd." | tee -a ./"$INSTALL_LOG"
            sudo snap install --channel=$MAAS_REQ maas | tee -a ./"$INSTALL_LOG"
            sudo systemctl disable --now systemd-timesyncd | tee -a ./"$INSTALL_LOG"
        elif [ "$MAAS_VERSION" -lt "$MAAS_REQ" ]; then
            echo "MaaS already installed." | tee -a ./"$INSTALL_LOG"
            printf "CAUTION: Check https://maas.io/docs/upgrading-maas\n
                    to verify current version can be upgraded (via snap refresh)\n
                    from %s$MAAS_VERSION to %s$MAAS_REQ with PostgreSQL %s$PSQL_VERSION.\n" | tee -a ./"$INSTALL_LOG"
            while true; do
                read -rp "Continue? " yn
                case $yn in
                    [yY] ) sudo snap refresh --channel=3.4 maas && sudo systemctl disable --now systemd-timesyncd | tee -a ./"$INSTALL_LOG"; MAAS_INSTALL2;;
                    [nN] ) echo "Cancelling Installation"; exit 0;;
                    * ) echo "Invalid"; MAAS_INSTALL;;
                esac
            done
        elif [ "$MAAS_VERSION" == $MAAS_REQ ]; then
            echo "Required version of MaaS is already installed on theis system." | tee -a ./"$INSTALL_LOG"
            echo "If you continue, there may be issues with an existing MaaS installation." | tee -a ./"$INSTALL_LOG"
            while true; do
                read -rp "Continue? " yn
                case $yn in
                    [yY] ) echo "Ok, but this may cause issues." | tee -a ./"$INSTALL_LOG"; MAAS_INSTALL2;;
                    [nN] ) echo "Cancelling Installation"; exit 0;;
                    * ) echo "Invalid"; MAAS_INSTALL;;
                esac
            done
        fi
}
# Setup PostgreSQL an initialize MaaS region+rack.
function MAAS_INSTALL2 {
        sudo -i -u postgres psql -c "CREATE USER \"$MAAS_DBUSER\" WITH ENCRYPTED PASSWORD '$MAAS_DBPASS'" | tee -a ./"$INSTALL_LOG"
        sudo -i -u postgres createdb -O "$MAAS_DBUSER" "$MAAS_DBNAME" | tee -a ./"$INSTALL_LOG"
        cat "host    ""$MAAS_DBNAME""    ""$MAAS_DBUSER""    0/0     md5" >> /etc/postgresql/"$PSQL_VERSION"/main/pg_hba.conf
        sudo maas init region+rack --database-uri "postgres://$MAAS_DBUSER:$MAAS_DBPASS@$DB_HOSTNAME/$MAAS_DBNAME" | tee -a ./"$INSTALL_LOG"
        printf "\n\nInstallation complete!!! Logfile is located at %s$INSTALL_LOG\n\n" | tee -a ./"$INSTALL_LOG"
}
# Begin installation
        while true; do
            read -rp "Install PostgreSQL and MaaS? " yn
            case $yn in
                [yY] ) echo "Beginning installation" | tee -a ./"$INSTALL_LOG"; PRE_CHECK;;
                [nN] ) echo "Cancel"; exit 0;;
                * ) echo "Invalid";;
            esac
        done
