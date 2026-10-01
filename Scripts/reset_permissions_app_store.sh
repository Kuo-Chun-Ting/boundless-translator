#!/bin/zsh

set -euo pipefail

exec "${0:A:h}/reset_permissions.sh" app-store
