#!/bin/bash
projectname=$1; # Project Handle and Website


# Static Variables
HOST='http://localhost/~USERDIR/' 
MYSQLPASSWORD='PASSWORD'
EMAIL='name@example.com'
THEMEAUTHOR='AN Other'

# Create Website Directory
mkdir ~/Sites/$projectname; 
cd ~/Sites/$projectname;

# Download Wordpress
wget http://wordpress.org/latest.zip; unzip latest.zip; rm latest.zip;
cd ~/Sites/$projectname/wordpress;

# Create a database / user on the local machine and grant access.
mysql -u root -e "create database $projectname; grant all privileges on $projectname.* to ${projectname}_user@localhost identified by '$MYSQLPASSWORD';"

cp wp-config-sample.php wp-config.php;
# Replace variables in wp-config.php: putyourdbnamehere, usernamehere, yourpasswordhere, localhost:
sed -i '' -e "s/database_name_here/$projectname/g; s/username_here/${projectname}_user/g; s/password_here/$MYSQLPASSWORD/g; s/localhost/localhost:\/tmp\/mysql.sock/g;" wp-config.php 

# Install WP Database.
curl -d "weblog_title=BLOGTITLE&admin_email=$EMAIL&blog_public=1" ${HOST}${projectname}/wordpress/wp-admin/install.php?step=2

# Get the stable version of thematic
cd wp-content/themes; 
svn checkout http://thematic.googlecode.com/svn/trunk/ thematic


# Create Custom theme
mkdir $projectname; mkdir $projectname/css; 
printf "/*\r\nTheme Name: $projectname Custom Theme\r\nAuthor: $THEMEAUTHOR\r\nTemplate: thematic\r\nVersion: 0.1\r\n*/\r\n\r\n@import url('css/screen.css');" > $projectname/style.css; touch $projectname/css/screen.css; 

printf "@import url('css/widescreen.css');" > $projectname/widescreen.css; touch $projectname/css/widescreen.css; 

cd $projectname;
compass create compass --css-dir=../css/ --bare;
touch compass/sass/screen.scss;
touch compass/sass/widescreen.scss;
cd -;

# Activate Custom Theme
mysql -u root -e "update $projectname.wp_options set option_value='thematic' where option_name='template'; update $projectname.wp_options set option_value='$projectname' where option_name='stylesheet';"


# Delete the Dashboard RSS feeds from the database.
mysql -u root -e "delete from $projectname.wp_options where option_name REGEXP '^_transient_(timeout_)*feed.*';"

####################### General Settings #######################

# Create Uploads Directory
mkdir ../uploads/; chmod 777 ../uploads/;

# Don't organise uploads into years/dates.
mysql -u root -e "update $projectname.wp_options set option_value='0' where option_name='uploads_use_yearmonth_folders';"


####################### Site Specific Settings #######################

# Update Password - you can set the password here using a hashed value if you like..
mysql -u root -e "update $projectname.wp_users set user_pass='SOMEHASHVALUE' where user_login='admin'"


# Update Blog name and description.
mysql -u root -e "update $projectname.wp_options set option_value='Blog Name' where option_name='blogname';"  
mysql -u root -e "update $projectname.wp_options set option_value='Blog Description' where option_name='blogdescription';"

# Edit thumbnail sizes if required.
mysql -u root -e "update $projectname.wp_options set option_value='576' where option_name REGEXP 'large_size_.*';"

# Set avatar to monster.
mysql -u root -e "update $projectname.wp_options set option_value='monsterid' where option_name='avatar_default';"


####################### Default Plugins #######################
# WP PageNavi
svn checkout http://plugins.svn.wordpress.org/wp-pagenavi/tags/2.61/ ../plugins/wp-pagenavi

# Activate Default Plugins 
mysql -u root -e "update $projectname.wp_options set option_value='a:2:{i:0;s:19:\"akismet/akismet.php\";i:1;s:27:\"wp-pagenavi/wp-pagenavi.php\";}' where option_name='active_plugins';"

# Enter Akismet Key.
mysql -u root -e "update $projectname.wp_options set option_value='AKISMETKEY' where option_name='wordpress_api_key';"


#### Extra Stuf ####
mysql -u root -e "update $projectname.wp_options set option_value='${HOST}$projectname/wordpress where option_name='siteurl';"
mysql -u root -e "update $projectname.wp_options set option_value='${HOST}$projectname/wordpress where option_name='home';"
