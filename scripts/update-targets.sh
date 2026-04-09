#!/bin/bash
# Actualiza los Target Groups del ALB con la IP actual del contenedor
# Detecta targets unhealthy con IPs viejas y los reemplaza
#
# Requiere: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, ALB_ARN
# Se ejecuta via cron o via webhookd dentro del contenedor Nginx

set -e

[ -n "${DEBUG:-}" ] && set -x

export AWS_REGION=${AWS_REGION:-"us-east-1"}
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-""}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-""}
export ALB_ARN=${ALB_ARN:-}

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "SKIP: Credenciales AWS no configuradas"
    exit 0
fi

if [ -z "$ALB_ARN" ]; then
    echo "SKIP: ALB_ARN no configurado"
    exit 0
fi

# Obtener la IP actual del contenedor
CURRENT_IP=$(hostname -i 2>/dev/null | awk '{print $1}')

if [ -z "$CURRENT_IP" ]; then
    echo "ERROR: No se pudo obtener la IP del contenedor"
    exit 1
fi

echo "=== Target Groups - Diagnostico ==="
echo ""
echo "IP del contenedor: $CURRENT_IP"
echo "Region: $AWS_REGION"
echo ""

# Obtener todos los target groups asociados al ALB
LISTENER_ARNS=$(aws elbv2 describe-listeners \
    --load-balancer-arn "$ALB_ARN" \
    --query "Listeners[].ListenerArn" \
    --output text 2>/dev/null)

if [ -z "$LISTENER_ARNS" ]; then
    echo "WARN: No se encontraron listeners en el ALB"
    exit 0
fi

# Recopilar todos los target group ARNs unicos del ALB
TG_ARNS=""
for LISTENER_ARN in $LISTENER_ARNS; do
    DEFAULT_TGS=$(aws elbv2 describe-listeners \
        --listener-arns "$LISTENER_ARN" \
        --query "Listeners[].DefaultActions[].TargetGroupArn" \
        --output text 2>/dev/null)
    TG_ARNS="$TG_ARNS $DEFAULT_TGS"

    RULE_TGS=$(aws elbv2 describe-rules \
        --listener-arn "$LISTENER_ARN" \
        --query "Rules[].Actions[].TargetGroupArn" \
        --output text 2>/dev/null)
    TG_ARNS="$TG_ARNS $RULE_TGS"
done

TG_ARNS=$(echo "$TG_ARNS" | tr ' ' '\n' | grep -v '^$' | grep -v '^None$' | sort -u)

if [ -z "$TG_ARNS" ]; then
    echo "WARN: No se encontraron target groups"
    exit 0
fi

FIXED=0
TOTAL=0
HEALTHY_COUNT=0
UNHEALTHY_COUNT=0

for TG_ARN in $TG_ARNS; do
    TG_NAME=$(aws elbv2 describe-target-groups \
        --target-group-arns "$TG_ARN" \
        --query "TargetGroups[0].TargetGroupName" \
        --output text 2>/dev/null)
    TG_PORT=$(aws elbv2 describe-target-groups \
        --target-group-arns "$TG_ARN" \
        --query "TargetGroups[0].Port" \
        --output text 2>/dev/null)

    TOTAL=$((TOTAL + 1))
    echo "--- $TG_NAME (puerto $TG_PORT) ---"

    HEALTH=$(aws elbv2 describe-target-health \
        --target-group-arn "$TG_ARN" \
        --output json 2>/dev/null)

    TARGET_COUNT=$(echo "$HEALTH" | jq '.TargetHealthDescriptions | length')

    if [ "$TARGET_COUNT" -eq 0 ]; then
        echo "  Sin targets registrados"
        echo "  -> Registrando $CURRENT_IP:$TG_PORT"
        aws elbv2 register-targets \
            --target-group-arn "$TG_ARN" \
            --targets "Id=$CURRENT_IP,Port=$TG_PORT" 2>/dev/null && FIXED=$((FIXED + 1))
        echo ""
        continue
    fi

    # Mostrar estado de cada target
    echo "$HEALTH" | jq -r '.TargetHealthDescriptions[] | "  \(.Target.Id):\(.Target.Port) -> \(.TargetHealth.State)\(if .TargetHealth.Description then " (\(.TargetHealth.Description))" else "" end)"'

    # Verificar si la IP actual ya esta registrada y healthy
    CURRENT_STATE=$(echo "$HEALTH" | jq -r \
        ".TargetHealthDescriptions[] | select(.Target.Id==\"$CURRENT_IP\" and .Target.Port==$TG_PORT) | .TargetHealth.State")

    if [ "$CURRENT_STATE" = "healthy" ]; then
        HEALTHY_COUNT=$((HEALTHY_COUNT + 1))

        OLD_IPS=$(echo "$HEALTH" | jq -r \
            ".TargetHealthDescriptions[] | select(.TargetHealth.State==\"unhealthy\" and .Target.Id!=\"$CURRENT_IP\") | .Target.Id")

        for OLD_IP in $OLD_IPS; do
            OLD_PORT=$(echo "$HEALTH" | jq -r \
                ".TargetHealthDescriptions[] | select(.Target.Id==\"$OLD_IP\") | .Target.Port")
            echo "  -> Eliminando IP vieja $OLD_IP:$OLD_PORT"
            aws elbv2 deregister-targets \
                --target-group-arn "$TG_ARN" \
                --targets "Id=$OLD_IP,Port=$OLD_PORT" 2>/dev/null && FIXED=$((FIXED + 1))
        done
        echo ""
        continue
    fi

    UNHEALTHY_COUNT=$((UNHEALTHY_COUNT + 1))

    if [ -z "$CURRENT_STATE" ]; then
        echo "  -> Registrando IP actual $CURRENT_IP:$TG_PORT"
        aws elbv2 register-targets \
            --target-group-arn "$TG_ARN" \
            --targets "Id=$CURRENT_IP,Port=$TG_PORT" 2>/dev/null && FIXED=$((FIXED + 1))
    else
        echo "  IP actual en estado: $CURRENT_STATE (esperando...)"
    fi

    OLD_IPS=$(echo "$HEALTH" | jq -r \
        ".TargetHealthDescriptions[] | select(.TargetHealth.State==\"unhealthy\" and .Target.Id!=\"$CURRENT_IP\") | .Target.Id")

    for OLD_IP in $OLD_IPS; do
        OLD_PORT=$(echo "$HEALTH" | jq -r \
            ".TargetHealthDescriptions[] | select(.Target.Id==\"$OLD_IP\") | .Target.Port")
        echo "  -> Eliminando IP vieja $OLD_IP:$OLD_PORT"
        aws elbv2 deregister-targets \
            --target-group-arn "$TG_ARN" \
            --targets "Id=$OLD_IP,Port=$OLD_PORT" 2>/dev/null && FIXED=$((FIXED + 1))
    done
    echo ""
done

echo "=== Resumen ==="
echo ""
echo "Target groups: $TOTAL"
echo "Healthy: $HEALTHY_COUNT"
echo "Requieren atencion: $UNHEALTHY_COUNT"
echo "Correcciones realizadas: $FIXED"
if [ "$FIXED" -eq 0 ] && [ "$UNHEALTHY_COUNT" -eq 0 ]; then
    echo ""
    echo "Todos los targets estan correctos."
fi
