#!/bin/sh

# db_create_date finds last table creation date
# db_mod_date finds last table modification date
# db_mod_date_secs converts the db_mod_date to seconds
# date_diff is the difference between today (now) and db_mod_date to find days between today and database last modification date
# if a database is not modified or does not contain any table it will saved in the file unmodified_dbs
# Finding Databases' Last Table Creation Time, Last Modification Time
if [ ! -e ./unmodified_dbs ]
then
    touch unmodified_dbs
else
    cat /dev/null > unmodified_dbs
    echo "Databse - Table - Creation Time - Update Time" >> ./unmodified_dbs
fi

file=./ignore_dbs
while IFS= read -r line
do
    for DB in $(echo "show databases" | mysql | grep -Ev "^($line)$");
    do
        db_create_table=$(mysql -e "use $DB;select concat(table_name,' - ',max(create_time)) from information_schema.tables where table_schema = database();" | grep -v "\----" | grep -v "max(create_time)" | grep -v "table_name")
        db_create_date=$(mysql -e "use $DB;select max(create_time) from information_schema.tables where table_schema = database();" | grep -v "\----" | grep -v "max(create_time)")
     	db_mod_date=$(mysql -e "use $DB;select max(update_time) from information_schema.tables where table_schema = database();" | grep -v "\----" | grep -v "max(update_time)")
       	db_mod_table=$(mysql -e "use $DB;select concat(table_name,' - ',max(update_time)) from information_schema.tables where table_schema = database();" | grep -v "\----" | grep -v "max(update_time)" | grep -v "table_name")
        if [ "$db_create_date" == NULL ]
        then
            echo "$DB - - - - - - -" >> ./unmodified_dbs
            echo -e "Database '\033[1m$DB\033[0m' does not contain any table."
            echo "" 
        elif [ "$db_mod_date" == NULL ]
        then
            echo "$DB - $db_create_table - $db_mod_date" >> ./unmodified_dbs
            db_create_date_secs=$(date --date="${db_create_date}" +%s)
	    today=$(date "+%s")
            date_diff_create=$((($today - $db_create_date_secs)/86400))
            echo -e "Database: '\033[1m$DB\033[0m', last created table and creation time: '\033[1m$db_create_table\033[0m', $date_diff_create days ago, and no modification occurred."
            echo ""
        else
            db_mod_date_secs=$(date --date="${db_mod_date}" +%s)
	    today=$(date "+%s")
            date_diff_mod=$((($today - $db_mod_date_secs)/86400))
            echo -e "Database: '\033[1m$DB\033[0m', last modified table and modification time: '\033[1m$db_mod_table\033[0m', $date_diff_mod days ago."
            echo ""
        fi
    done
    column -t ./unmodified_dbs
done < "$file"
