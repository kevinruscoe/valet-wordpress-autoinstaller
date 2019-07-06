#!/bin/bash

echo "Checking for wp-cli, mysql, php and valet..."

# Check WP-cli
if ! [ -x "$(command -v wp)" ]; then
    echo "Error: wp-cli is not installed." >&2
    exit 1
fi

# Check MySQL
if ! [ -x "$(command -v mysql)" ]; then
    echo "Error: mysql is not installed." >&2
    exit 1
fi

# Check PHP
if ! [ -x "$(command -v php)" ]; then
    echo "Error: php is not installed." >&2
    exit 1
fi

# Check PHP
if ! [ -x "$(command -v valet)" ]; then
    echo "Error: valet is not installed." >&2
    exit 1
fi

echo "All good..."

# Setup vars
FOLDER="
while [[ $FOLDER == " ]]
do
    read -p "What's the name of the folder you wish to install WordPress in? " FOLDER
done 

ROOT_DIR="$(pwd)/$FOLDER"

# Confirm we"re good to go
read -p "WordPress will be installed in $ROOT_DIR. Is that OK? [Y/n]" -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled.";
    exit 1
fi

MYSQL_USER="wp_${FOLDER}_usr"
MYSQL_NAME="wp_${FOLDER}_sys"
MYSQL_PASS="$(openssl rand -hex 12)"

WP_USER="admin"
WP_PASS="$(openssl rand -hex 12)"

# Download WP
echo "Creating directory..."
mkdir $ROOT_DIR
wp core download --path="$ROOT_DIR"

echo "Creating MySQL database, you'll be asked for the mysql root password..."
mysql -u root -p -e "CREATE DATABASE $MYSQL_NAME; CREATE USER $MYSQL_USER@'localhost' IDENTIFIED BY "$MYSQL_PASS"; GRANT ALL PRIVILEGES ON $MYSQL_NAME.* TO $MYSQL_USER@'localhost'; FLUSH PRIVILEGES;"

echo "Downloading and installing WordPress"
wp config create --path="$ROOT_DIR" --dbname=$MYSQL_NAME --dbuser=$MYSQL_USER --dbpass=$MYSQL_PASS
wp core install --path="$ROOT_DIR" --url="$FOLDER.test" --title="Test Site" --admin_user=$WP_USER --admin_password=$WP_PASS --admin_email=no@no.no

# Install a couple of plugins
read -p "Do you want me to install yoast? [Y/n]" -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    wp plugin install wordpress-seo --path="$ROOT_DIR" 
fi

read -p "Do you want me to install Woocommerce? [Y/n]" -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    wp plugin install woocommerce --path="$ROOT_DIR" 
fi

# Link valet, if it fails let the user know
echo "Requesting to link valet, you"ll be asked for your system password..."
set -e
VALET_EXIT_CODE=0
cd $ROOT_DIR
valet link || VALET_EXIT_CODE=$?

if [ $VALET_EXIT_CODE == 1 ]; then
    echo "Valet failed to link the directory, you"ll need to manually link it."
else
    open "http://$FOLDER.test"
fi


echo "[Directory: $ROOT_DIR]"
echo "[Username: $WP_USER]"
echo "[Password: $WP_PASS]"

# Open VSC
if [ -x "$(command -v code)" ]; then
    code $ROOT_DIR
fi