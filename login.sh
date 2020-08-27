#!/bin/bash
#wp-config
echo START MODIFYING WP-CONFIG
sed  -i "/That's all, stop editing! Happy publishing./i//CHANGE LOGIN SLUG" /opt/easyengine/sites/$SITE/app/wp-config.php
sed  -i "/That's all, stop editing! Happy publishing./idefine('WP_ADMIN_DIR', 'admin');" /opt/easyengine/sites/$SITE/app/wp-config.php
sed  -i "/That's all, stop editing! Happy publishing./idefine('ADMIN_COOKIE_PATH', SITECOOKIEPATH . WP_ADMIN_DIR);" /opt/easyengine/sites/$SITE/app/wp-config.php
echo MODIFYING WP-CONFIG SUCCESSFULLY
