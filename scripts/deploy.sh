
#!/bin/sh

set -eu

PROJECT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"
NGINX_DIR="$PROJECT_ROOT/nginx"
NGINX_TEMPLATE="$NGINX_DIR/default.conf.template"
ACTIVE_CONFIG="$NGINX_DIR/default.conf"

TARGET="${1:-}"

if [ "$TARGET" != "blue" ] && [ "$TARGET" != "green" ]; then
    echo "Usage: ./scripts/deploy.sh <blue|green>"
    exit 1
fi

if [ "$TARGET" = "blue" ]; then
    TARGET_UPSTREAM="app-blue:4000"
    TARGET_VERSION="1.0.0"
else
    TARGET_UPSTREAM="app-green:4000"
    TARGET_VERSION="1.1.0"
fi

if [ ! -f "$NGINX_TEMPLATE" ] || [ ! -f "$ACTIVE_CONFIG" ]; then
    echo "Error: Nginx template or active configuration is missing."
    exit 1
fi

echo "Starting deployment to $TARGET..."

RUNNING_SERVICES=$(docker compose -f "$COMPOSE_FILE" ps --status running --services)

if ! printf '%s\n' "$RUNNING_SERVICES" | grep -qx "nginx"; then
    echo "Error: Nginx is not running."
    exit 1
fi

if ! printf '%s\n' "$RUNNING_SERVICES" | grep -qx "app-$TARGET"; then
    echo "Error: Target application is not running."
    exit 1
fi

TARGET_STATUS=$(docker inspect \
    --format '{{.State.Health.Status}}' \
    "blue-green-app-$TARGET" 2>/dev/null || true)

if [ "$TARGET_STATUS" != "healthy" ]; then
    echo "Error: Target application is not healthy."
    exit 1
fi

BACKUP_CONFIG=$(mktemp "$NGINX_DIR/.default.conf.backup.XXXXXX")
CANDIDATE_CONFIG=$(mktemp "$NGINX_DIR/.default.conf.candidate.XXXXXX")
RESTORE_CONFIG=""

cleanup() {
    rm -f "$BACKUP_CONFIG" "$CANDIDATE_CONFIG"

    if [ -n "$RESTORE_CONFIG" ]; then
        rm -f "$RESTORE_CONFIG"
    fi
}

trap cleanup EXIT

cp "$ACTIVE_CONFIG" "$BACKUP_CONFIG"

rollback() {
    echo "Restoring previous Nginx configuration..."

    RESTORE_CONFIG=$(mktemp "$NGINX_DIR/.default.conf.restore.XXXXXX")

    if ! cp "$BACKUP_CONFIG" "$RESTORE_CONFIG"; then
        echo "Error: Could not prepare the previous configuration."
        return 1
    fi

    if ! mv "$RESTORE_CONFIG" "$ACTIVE_CONFIG"; then
        echo "Error: Could not restore the previous configuration."
        return 1
    fi

    RESTORE_CONFIG=""

    if ! docker compose -f "$COMPOSE_FILE" exec -T nginx nginx -t; then
        echo "Error: Restored Nginx configuration is invalid."
        return 1
    fi

    if ! docker compose -f "$COMPOSE_FILE" exec -T nginx nginx -s reload; then
        echo "Error: Could not reload the previous Nginx configuration."
        return 1
    fi

    echo "Rollback completed."
}

if ! sed "s|__TARGET_UPSTREAM__|$TARGET_UPSTREAM|g" \
    "$NGINX_TEMPLATE" > "$CANDIDATE_CONFIG"; then
    echo "Error: Failed to generate Nginx configuration."
    exit 1
fi

if ! grep -q "server $TARGET_UPSTREAM;" "$CANDIDATE_CONFIG"; then
    echo "Error: Generated configuration does not contain the expected upstream."
    exit 1
fi

if ! mv "$CANDIDATE_CONFIG" "$ACTIVE_CONFIG"; then
    echo "Error: Failed to activate the generated configuration."
    exit 1
fi

if ! docker compose -f "$COMPOSE_FILE" exec -T nginx nginx -t; then
    echo "Error: Invalid Nginx configuration."
    rollback || true
    exit 1
fi

if ! docker compose -f "$COMPOSE_FILE" exec -T nginx nginx -s reload; then
    echo "Error: Nginx reload failed."
    rollback || true
    exit 1
fi

verify_deployment() {
    RESPONSE=$(curl --fail --silent --show-error \
        http://localhost:8080/version 2>/dev/null) || return 1

    printf '%s' "$RESPONSE" | node -e '
        let input = "";

        process.stdin.on("data", (chunk) => {
            input += chunk;
        });

        process.stdin.on("end", () => {
            try {
                const data = JSON.parse(input);
                const expectedVersion = process.argv[1];
                const expectedColor = process.argv[2];

                if (
                    data.version !== expectedVersion ||
                    data.environment !== expectedColor
                ) {
                    process.exit(1);
                }
            } catch {
                process.exit(1);
            }
        });
    ' "$TARGET_VERSION" "$TARGET"
}

VERIFIED=false

for ATTEMPT in 1 2 3 4 5; do
    if verify_deployment; then
        VERIFIED=true
        break
    fi

    sleep 2
done

if [ "$VERIFIED" != "true" ]; then
    echo "Error: Target application verification failed."
    rollback || true
    exit 1
fi

echo "Deployment successful: $TARGET ($TARGET_VERSION)"
