#!/usr/bin/env bash
set -euo pipefail

# ---------- загрузка .env ----------
if [ -f .env ]; then
  set -a            # автоматически экспортировать все переменные
  source .env       # исполнить .env в текущей оболочке
  set +a            # отключить автоэкспорт
fi

# ---------- проверка обязательных переменных ----------
: "${DOMAIN:?Ошибка: DOMAIN не задан в .env}"
: "${EMAIL:?Ошибка: EMAIL не задан в .env}"

# проверка учётных данных Dynu
if [ -n "${DYNU_CLIENT_ID:-}" ] && [ -n "${DYNU_CLIENT_SECRET:-}" ]; then
    echo "Использую Dynu OAuth2 (Client ID + Secret)"
elif [ -n "${DYNU_API_KEY:-}" ]; then
    echo "Использую Dynu API Key (устаревший метод)"
else
    echo "Ошибка: необходимо задать DYNU_CLIENT_ID и DYNU_CLIENT_SECRET, либо DYNU_API_KEY в .env"
    exit 1
fi

MAIN_DOMAIN="$DOMAIN"
WILDCARD_DOMAIN="*.$DOMAIN"
#RELOAD_CMD="docker restart nginx"
RELOAD_CMD="docker exec nginx nginx -s reload 2>/dev/null || true"

# ---------- установка acme.sh (если отсутствует) ----------
if ! command -v acme.sh &> /dev/null; then
  echo "Устанавливаю acme.sh с email=$EMAIL..."
  curl https://get.acme.sh | sh -s email="$EMAIL"
  # после установки сразу задаём путь к acme.sh
  export PATH="$HOME/.acme.sh:$PATH"
  if ! command -v acme.sh &> /dev/null; then
    echo "Ошибка: acme.sh не установлен корректно"
    exit 1
  fi
  echo "acme.sh установлен успешно"
fi


echo "Настраиваю Let's Encrypt как центр сертификации..."
acme.sh --set-default-ca --server letsencrypt

# ---------- Dynu API ----------
if [ -n "${DYNU_CLIENT_ID:-}" ] && [ -n "${DYNU_CLIENT_SECRET:-}" ]; then
    export Dynu_ClientId="$DYNU_CLIENT_ID"
    export Dynu_Secret="$DYNU_CLIENT_SECRET"
else
    export Dynu_Secret="$DYNU_API_KEY"
fi

ACME_HOME="$HOME/.acme.sh"
DOMAIN_DIR="$ACME_HOME/${MAIN_DOMAIN}_ecc"   # ECC по умолчанию

# ---------- выпуск сертификата (если его ещё нет) ----------
if [ ! -d "$DOMAIN_DIR" ]; then
  echo "Выпускаю wildcard-сертификат для $MAIN_DOMAIN и $WILDCARD_DOMAIN..."
  acme.sh --issue --dns dns_dynu -d "$MAIN_DOMAIN" -d "$WILDCARD_DOMAIN"
else
  echo "Сертификат уже существует в $DOMAIN_DIR"
fi

# ---------- настройка перезагрузки Nginx при обновлении ----------
echo "Настраиваю reload-команду..."
acme.sh --install-cert -d "$MAIN_DOMAIN" -d "$WILDCARD_DOMAIN" \
  --reloadcmd "$RELOAD_CMD"

# ---------- права для чтения контейнером nginx (uid 101) ----------
echo "Корректирую права доступа..."
chmod o+x "$HOME" "$ACME_HOME" "$DOMAIN_DIR" 2>/dev/null || true
chmod o+r "$DOMAIN_DIR"/${MAIN_DOMAIN}.{cer,key,conf} 2>/dev/null || true

echo "Готово. Сертификаты размещены в $DOMAIN_DIR"
echo "Автоматическое продление настроено."