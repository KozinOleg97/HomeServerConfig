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
: "${DYNU_API_KEY:?Ошибка: DYNU_API_KEY не задан в .env}"
: "${EMAIL:?Ошибка: EMAIL не задан в .env}"

MAIN_DOMAIN="$DOMAIN"
WILDCARD_DOMAIN="*.$DOMAIN"
#RELOAD_CMD="docker restart nginx"
RELOAD_CMD="docker exec nginx nginx -s reload"

# ---------- установка acme.sh (если отсутствует) ----------
if ! command -v acme.sh &> /dev/null; then
  echo "Устанавливаю acme.sh с email=$EMAIL..."
  curl https://get.acme.sh | sh -s email="$EMAIL"
  # подгружаем окружение acme.sh
  . "$HOME/.acme.sh/acme.sh.env"
fi

# ---------- Dynu API ----------
export Dynu_Secret="$DYNU_API_KEY"

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