#!/bin/zsh
set -e
cd "${0:A:h:h}"

Scripts/AppStore/archive_app_store.sh
Scripts/AppStore/validate_app_store.sh
Scripts/AppStore/distribute_app_store.sh
