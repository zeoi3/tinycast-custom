#!/bin/bash
# Create a dedicated local signing identity. Private material never enters the repository.
set -euo pipefail
identity='Tinycast Custom Local'
if security find-identity -p codesigning | /usr/bin/grep -q "\"$identity\""; then
    echo '定制签名身份已存在。'
    exit 0
fi
openssl_bin="${OPENSSL_BIN:-/opt/homebrew/opt/openssl@3/bin/openssl}"
[ -x "$openssl_bin" ] || { echo '需要 OpenSSL 3；可通过 brew install openssl@3 安装。' >&2; exit 1; }
umask 077
signing_tmp=$(mktemp -d "${TMPDIR:-/tmp}/tinycast-custom-signing.XXXXXX")
trap 'rm -rf "$signing_tmp"' EXIT
"$openssl_bin" rand -hex 24 > "$signing_tmp/password"
"$openssl_bin" req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -keyout "$signing_tmp/key.pem" -out "$signing_tmp/cert.pem" \
    -subj "/CN=$identity" -addext 'basicConstraints=critical,CA:false' \
    -addext 'keyUsage=critical,digitalSignature' \
    -addext 'extendedKeyUsage=critical,codeSigning' 2>/dev/null
"$openssl_bin" pkcs12 -export -legacy -inkey "$signing_tmp/key.pem" -in "$signing_tmp/cert.pem" \
    -name "$identity" -out "$signing_tmp/identity.p12" -passout "file:$signing_tmp/password"
security import "$signing_tmp/identity.p12" -k "$HOME/Library/Keychains/login.keychain-db" \
    -P "$(cat "$signing_tmp/password")" -T /usr/bin/codesign
security find-identity -p codesigning | /usr/bin/grep -F "$identity"
echo '签名身份已导入本机登录钥匙串；未上传或导出任何私钥。'
