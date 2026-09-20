# 1. Получить access_token

ACCESS_TOKEN=$(curl -s -X POST https://matrix.egoidei.giize.com/_matrix/client/r0/login \
  -H "Content-Type: application/json" \
  -d '{"type":"m.login.password","user":"guga","password":"Prof9999!"}' \
  | jq -r '.access_token')
echo "Token: $ACCESS_TOKEN"


TURN_CREDS=$(curl -s -k "https://matrix.egoidei.giize.com/_matrix/client/r0/voip/turnServer?access_token=$ACCESS_TOKEN")
TURN_USERNAME=$(echo "$TURN_CREDS" | jq -r '.username')
TURN_PASSWORD=$(echo "$TURN_CREDS" | jq -r '.password')
echo "Username: $TURN_USERNAME"
echo "Password: $TURN_PASSWORD"






docker run --rm --network container:coturn \
  coturn/coturn:latest \
  turnutils_uclient -v -u "$TURN_USERNAME" -w "$TURN_PASSWORD" -y 127.0.0.1










docker run --rm \
  coturn/coturn:latest \
  turnutils_uclient -v -u "$TURN_USERNAME" -w "$TURN_PASSWORD" -y matrix.egoidei.giize.com


docker run --rm \
  coturn/coturn:latest \
  turnutils_uclient -v -u "1778005213:@guga:matrix.egoidei.giize.com" -w "***" -y matrix.egoidei.giize.com




docker run --rm \
  coturn/coturn:latest \
  turnutils_uclient -v -u "any" -w "any" -y matrix.egoidei.giize.com