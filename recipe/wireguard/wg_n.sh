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
read -e -p "Peer ip: " -i "10.66.66.2" PEER_IP
# read -e -p "Allowed ips: " -i "10.66.66.0/24" ALLOWED_IPS

CONFIG_NAME="$(autoincr "./client.conf")"

PRIVATE_KEY="$(wg genkey)"
PUBLIC_KEY="$(echo ${PRIVATE_KEY} | wg pubkey)"
SERVER_PUBLIC_KEY="$(cat /etc/wireguard/public.key)"

MY_IP=$(hostname -I | awk '{print $1}')

CLIENT_CONFIG="
[Interface]
PrivateKey = ${PRIVATE_KEY}
Address = ${PEER_IP}/32
DNS = 8.8.8.8,8.8.4.4
[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
Endpoint = ${MY_IP}:51820
AllowedIPs = 0.0.0.0/0
"

echo "${CLIENT_CONFIG}" >> ${CONFIG_NAME}

SERVER_CONFIG="
[Peer]
PublicKey = ${PUBLIC_KEY}
AllowedIPs = ${PEER_IP}/32
"

cp /etc/wireguard/wg0.conf /etc/wireguard/wg0.conf.bak
echo "${SERVER_CONFIG}" >> /etc/wireguard/wg0.conf

wg syncconf wg0 <(wg-quick strip wg0)

echo "$(qrencode -t ansiutf8 < ${CONFIG_NAME})"
echo "The client configuration is saved at ${CONFIG_NAME}"
echo "Save it to the device from which you want to connect via VPN and import it into WireGuard,"
echo "Or scan the QR code above via wireguard."
