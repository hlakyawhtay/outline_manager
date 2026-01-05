openssl s_client -connect https://159.89.168.18:9947:443 -showcerts \
< /dev/null 2>/dev/null | openssl x509 -outform PEM > certificate.pem