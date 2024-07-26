#!/bin/bash

# Gerekli paketleri kur
sudo apt update
sudo apt install -y jq curl

API_URL="https://proxy-api.gokturkhost.com/api/ssh/addip"
CATEGORY_IDS=("replace_with_category_id_1" "replace_with_category_id_2")

# Kullanıcıdan UUID al
read -p "Lütfen SSH bağlantısı için bir UUID girin: " SSH_CONNECTION_ID

# Diskalifiye edilecek IP adresleri
EXCLUDE_IPS=("127.0.0.1" "::1")

# IP adreslerini al ve diskalifiye edilecek IP'leri hariç tut
ip_addresses=$(ip -j address | jq -r '.[].addr_info[] | select(.family == "inet" or .family == "inet6") | .local' | grep -v -E '^(127\.0\.0\.1|::1|fe80::)')

for ip in $ip_addresses; do
    json_payload=$(jq -n \
        --arg ip "$ip" \
        --arg ssh_connection_id "$SSH_CONNECTION_ID" \
        --argjson categories "$(printf '%s\n' "${CATEGORY_IDS[@]}" | jq -R . | jq -s .)" \
        '{
            ip_address: $ip,
            ssh_connection: $ssh_connection_id,
            categories: $categories,
            is_active: true
        }')

    response=$(curl -s -w "%{http_code}" -o /dev/null -X POST "$API_URL" \
        -H "Content-Type: application/json" \
        -d "$json_payload")

    if [ "$response" -eq 201 ]; then
        echo "Successfully posted IP address: $ip"
    else
        echo "Failed to post IP address: $ip (HTTP status code: $response)"
    fi
done
