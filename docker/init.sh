#!/bin/bash

set -e

# The bench image's MariaDB CLI may default to requiring TLS, while the local
# MariaDB service does not enable TLS. Frappe uses this client for site setup
# and recovery, including when an existing bench is started again.
if ! grep -q '^skip-ssl$' "$HOME/.my.cnf" 2>/dev/null; then
    if [ -f "$HOME/.my.cnf" ]; then
        printf '\n[client]\nskip-ssl\n' >> "$HOME/.my.cnf"
    else
        printf '[client]\nskip-ssl\n' > "$HOME/.my.cnf"
    fi
fi

sync_local_project() {
    local project=/workspace/project
    local app=/home/frappe/frappe-bench/apps/crm

    if [ ! -d "$project/crm/fcrm/doctype/crm_project" ]; then
        return
    fi

    cp "$project/crm/api/activities.py" "$app/crm/api/activities.py"
    mkdir -p "$app/crm/fcrm/doctype/crm_project"
    cp "$project/crm/fcrm/doctype/crm_project/"* "$app/crm/fcrm/doctype/crm_project/"
    mkdir -p "$app/crm/fcrm/doctype/crm_purchase" "$app/crm/fcrm/doctype/crm_credit_record"
    cp "$project/crm/fcrm/doctype/crm_purchase/"* "$app/crm/fcrm/doctype/crm_purchase/"
    cp "$project/crm/fcrm/doctype/crm_credit_record/"* "$app/crm/fcrm/doctype/crm_credit_record/"
    cp "$project/crm/fcrm/doctype/crm_task/crm_task.py" "$app/crm/fcrm/doctype/crm_task/crm_task.py"
    cp "$project/crm/fcrm/doctype/crm_task/crm_task.json" "$app/crm/fcrm/doctype/crm_task/crm_task.json"

    cp "$project/frontend/src/router.js" "$app/frontend/src/router.js"
    cp "$project/frontend/src/stores/views.js" "$app/frontend/src/stores/views.js"
    cp "$project/frontend/src/utils/navigation.js" "$app/frontend/src/utils/navigation.js"
    cp "$project/frontend/src/components/Layouts/AppSidebar.vue" "$app/frontend/src/components/Layouts/AppSidebar.vue"
    mkdir -p "$app/frontend/src/components/ListViews"
    cp "$project/frontend/src/components/ListViews/ProjectsListView.vue" "$app/frontend/src/components/ListViews/ProjectsListView.vue"
    mkdir -p "$app/frontend/src/components/Dashboard"
    cp "$project/frontend/src/components/Dashboard/ProjectsDashboard.vue" "$app/frontend/src/components/Dashboard/ProjectsDashboard.vue"
    cp "$project/frontend/src/pages/TransactionTracker.vue" "$app/frontend/src/pages/TransactionTracker.vue"
    cp "$project/frontend/src/pages/HR.vue" "$app/frontend/src/pages/HR.vue"
    cp "$project/frontend/src/doctypes/crm_task/form.js" "$app/frontend/src/doctypes/crm_task/form.js"
    cp "$project/frontend/src/pages/Tasks.vue" "$app/frontend/src/pages/Tasks.vue"
    cp "$project/frontend/src/pages/Project.vue" "$app/frontend/src/pages/Project.vue"
    cp "$project/frontend/src/pages/Projects.vue" "$app/frontend/src/pages/Projects.vue"
    cp "$project/frontend/src/pages/Dashboard.vue" "$app/frontend/src/pages/Dashboard.vue"
}

install_business_apps() {
    business_apps_changed=0
    if [ ! -d "/home/frappe/frappe-bench/apps/erpnext" ]; then
        bench get-app https://github.com/frappe/erpnext.git --branch version-15
        business_apps_changed=1
    fi
    if [ ! -d "/home/frappe/frappe-bench/apps/hrms" ]; then
        bench get-app https://github.com/frappe/hrms.git --branch version-15
        business_apps_changed=1
    fi
    if [ -f "/home/frappe/frappe-bench/apps/erpnext/package.json" ] && \
       [ ! -f "/home/frappe/frappe-bench/apps/erpnext/node_modules/onscan.js/package.json" ]; then
        echo "Completing ERPNext frontend dependencies"
        (cd /home/frappe/frappe-bench/apps/erpnext && yarn install --check-files)
        business_apps_changed=1
    fi

    if [ -f "/home/frappe/frappe-bench/sites/crm.localhost/site_config.json" ]; then
        local installed_apps
        installed_apps="$(bench --site crm.localhost list-apps 2>/dev/null || true)"
        if ! printf '%s\n' "$installed_apps" | grep -q '^erpnext[[:space:]]'; then
            bench --site crm.localhost install-app erpnext
            business_apps_changed=1
        fi
        installed_apps="$(bench --site crm.localhost list-apps 2>/dev/null || true)"
        if ! printf '%s\n' "$installed_apps" | grep -q '^hrms[[:space:]]'; then
            bench --site crm.localhost install-app hrms
            business_apps_changed=1
        fi
    fi
}

if [ -d "/home/frappe/frappe-bench/apps/frappe" ]; then
    echo "Bench already exists, syncing the local CRM project"
    cd /home/frappe/frappe-bench
    sync_local_project
    install_business_apps
    if [ "$business_apps_changed" = "1" ]; then
        bench build
    else
        bench build --app crm
    fi
    bench --site crm.localhost migrate
    exec bench start
fi

echo "Creating new bench..."
bench init --ignore-exist --skip-redis-config-generation frappe-bench --version version-15

cd frappe-bench

# Use containers instead of localhost
bench set-mariadb-host mariadb
bench set-redis-cache-host redis://redis:6379
bench set-redis-queue-host redis://redis:6379
bench set-redis-socketio-host redis://redis:6379

# Remove redis, watch from Procfile
sed -i '/redis/d' ./Procfile
sed -i '/watch/d' ./Procfile

bench get-app crm --branch main
bench get-app https://github.com/frappe/erpnext.git --branch version-15
bench get-app https://github.com/frappe/hrms.git --branch version-15
sync_local_project
bench build

bench new-site crm.localhost \
    --mariadb-root-password 123 \
    --admin-password admin \
    --no-mariadb-socket

bench --site crm.localhost install-app crm
bench --site crm.localhost install-app erpnext
bench --site crm.localhost install-app hrms
bench --site crm.localhost set-config developer_mode 1
bench --site crm.localhost set-config mute_emails 1
bench --site crm.localhost set-config server_script_enabled 1
bench --site crm.localhost clear-cache
bench use crm.localhost

bench start
