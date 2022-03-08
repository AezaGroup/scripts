autoincr() {
    f="$1"
    ext=""

    # Extract the file extension (if any), with preceeding '.'
    [[ "$f" == *.* ]] && ext=".${f##*.}"

    if [[ -e "$f" ]] ; then
        i=1
        f="${f%.*}";

        while [[ -e "${f}_${i}${ext}" ]]; do
            let i++
        done

        f="${f}_${i}${ext}"
    fi
    echo "$f"
}

# Create new client
read -e -p "Peer ip: " -i "10.66.66.2/24" PEER_IP
read -e -p "Allowed ips: " -i "10.66.66.0/24" ALLOWED_IPS

CONFIG_NAME="$(autoincr "./client.conf")"

PRIVATE_KEY="$(wg genkey)"
PUBLIC_KEY="$(echo ${PRIVATE_KEY} | wg pubkey)"
SERVER_PUBLIC_KEY="$(cat /etc/wireguard/public.key)"

MY_IP=$(getent hosts $(hostname) | awk '{print $1}')

CLIENT_CONFIG="
[Interface]
PrivateKey = ${PRIVATE_KEY}
Address = ${PEER_IP}
DNS = 8.8.8.8,8.8.4.4
[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
Endpoint = ${MY_IP}:63665
AllowedIPs = ${ALLOWED_IPS}
"

echo "${CLIENT_CONFIG}" >> ${CONFIG_NAME}

SERVER_CONFIG="
[Peer]
PublicKey = ${PUBLIC_KEY}
AllowedIPs = ${ALLOWED_IPS}
"

cp /etc/wireguard/wg0.conf /etc/wireguard/wg0.conf.bak
echo "${SERVER_CONFIG}" >> /etc/wireguard/wg0.conf

systemctl restart wg-quick@wg0
