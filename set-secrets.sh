#!/bin/bash

# --- Конфигурационные переменные ---
TERRAFORM_DIR="terraform/infrastruct"
YANDEX_AUTH_FILE="${TERRAFORM_DIR}/yandex-auth.auto.tfvars"
BACKET_AUTH_FILE="${TERRAFORM_DIR}/bucket-auth.auto.tfvars"

# Глобальная переменная для отслеживания ошибок
ERRORS=0

# --- 1. Проверка установки необходимого ПО ---
function check_software_installation() {
    echo "Проверка установленного ПО..."
    local errors=0
    
    # Проверка GitHub CLI
    if ! command -v gh &> /dev/null; then
        echo "ОШИБКА: GitHub CLI (gh) не установлен. Установите: https://cli.github.com/"
        ((errors++))
    fi
    
    # Проверка jq
    if ! command -v jq &> /dev/null; then
        echo "ОШИБКА: jq не установлен. Установите: 'sudo apt install jq' или 'brew install jq'"
        ((errors++))
    fi
    
    # Проверка base64
    if ! command -v base64 &> /dev/null; then
        echo "ОШИБКА: base64 не установлен"
        ((errors++))
    fi
    
    if [ $errors -eq 0 ]; then
        echo " Все необходимые программы установлены"
    else
        echo "ОШИБКА: Необходимое ПО не установлено"
        ((ERRORS++))
    fi
    
    return $errors
}

# --- 2. Проверка авторизации ---
function check_authorization() {
    echo "Проверка авторизации..."
    local errors=0
    
    # Проверка авторизации в GitHub CLI
    if ! gh auth status &> /dev/null; then
        echo "ОШИБКА: Нет аутентификации в GitHub CLI. Сначала выполните:"
        echo "  gh auth login"
        ((errors++))
    fi
    
    # Проверка авторизации в Docker Hub
    DOCKER_CONFIG="$HOME/.docker/config.json"
    if [ ! -f "$DOCKER_CONFIG" ]; then
        echo "ВНИМАНИЕ: Файл конфигурации Docker не найден: $DOCKER_CONFIG"
        echo "  Для работы с Docker Hub выполните: docker login"
        ((errors++))
    elif ! jq -e '.auths["https://index.docker.io/v1/"]' "$DOCKER_CONFIG" &> /dev/null; then
        echo "ВНИМАНИЕ: Вы не авторизованы в Docker Hub."
        echo "  Для работы с Docker Hub выполните: docker login"
        ((errors++))
    fi
    
    if [ $errors -eq 0 ]; then
        echo "Все необходимые авторизации выполнены"
    else
        echo "ВНИМАНИЕ: Проблемы с авторизацией. Некоторые переменные не будут записаны"
        ((ERRORS++))
    fi
    
    return $errors
}

# --- 3. Проверка наличия необходимых файлов ---
function check_required_files() {
    echo "Проверка необходимых файлов..."
    local files_missing=0
    
    # Проверка файлов переменных
    if [ ! -f "$YANDEX_AUTH_FILE" ]; then
        echo "ВНИМАНИЕ: Файл $YANDEX_AUTH_FILE не найден"
        ((files_missing++))
    fi
    
    if [ ! -f "$BACKET_AUTH_FILE" ]; then
        echo "ВНИМАНИЕ: Файл $BACKET_AUTH_FILE не найден"
        ((files_missing++))
    fi
    
    # Проверка kubeconfig
    KUBE_CONFIG_FILE="$HOME/.kube/config"
    if [ ! -f "$KUBE_CONFIG_FILE" ]; then
        echo "ВНИМАНИЕ: Файл конфигурации Kubernetes не найден: $KUBE_CONFIG_FILE"
        ((files_missing++))
    fi
    
    if [ $files_missing -gt 0 ]; then
        echo "ВНИМАНИЕ: Некоторые файлы отсутствуют, соответствующие переменные будут пропущены"
        ((ERRORS++))
    fi
    
    return $files_missing
}

# --- 4. Блок отправки секретов из yandex-auth.auto.tfvars ---
function process_yandex_auth() {
    if [ ! -f "$YANDEX_AUTH_FILE" ]; then
        echo "ВНИМАНИЕ: Файл $YANDEX_AUTH_FILE не найден. Пропускаем обработку..."
        return 1
    fi

    echo " Обработка файла: $YANDEX_AUTH_FILE"
    local errors=0
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^# ]] || [[ -z "$line" ]]; then
            continue
        fi
        
        if [[ "$line" =~ ^([^=]+)[[:space:]]*=[[:space:]]*\"?(.*[^\"])?\"?$ ]]; then
            var_name=$(echo "${BASH_REMATCH[1]}" | xargs)
            var_value="${BASH_REMATCH[2]}"
            var_value="${var_value%\"}"
            var_value="${var_value#\"}"
            
            if [[ "$var_name" == "github-actions" ]]; then
               continue
            fi
            
            echo "Установка секрета $var_name..."
            if ! gh secret set "$var_name" --body "$var_value"; then
                echo "ОШИБКА: Не удалось установить секрет $var_name"
                ((errors++))
            fi
        fi
    done < "$YANDEX_AUTH_FILE"
    
    if [ $errors -gt 0 ]; then
        ((ERRORS++))
    fi
    
    return $errors
}

# --- 5. Блок отправки секретов из backet-auth.auto.tfvars ---
function process_backet_auth() {
    if [ ! -f "$BACKET_AUTH_FILE" ]; then
        echo "ВНИМАНИЕ: Файл $BACKET_AUTH_FILE не найден. Пропускаем обработку..."
        return 1
    fi

    echo "Обработка файла: $BACKET_AUTH_FILE"
    local errors=0
    
    while IFS= read -r line; do

        if [[ "$line" =~ ^# ]] || [[ -z "$line" ]]; then
            continue
        fi

        if [[ "$line" =~ ^([^=[:space:]]+)[[:space:]]*=[[:space:]]*\"?(.*[^\"])?\"?$ ]]; then
            var_name=$(echo "${BASH_REMATCH[1]}" | xargs)
            var_value="${BASH_REMATCH[2]}"
            var_value="${var_value%\"}"
            var_value="${var_value#\"}"

            echo "Установка секрета $var_name..."
            if ! gh secret set "$var_name" --body "$var_value"; then
                echo "ОШИБКА: Не удалось установить секрет $var_name"
                ((errors++))
            fi
        else
            echo "ОШИБКА: Не удалось разобрать строку: '$line'"
            ((errors++))
        fi
    done < "$BACKET_AUTH_FILE"
    
    if [ $errors -gt 0 ]; then
        ((ERRORS++))
    fi
    
    return $errors
}

# --- 6. Блок отправки конфигурации Kubernetes ---
function process_kube_config() {
    KUBE_CONFIG_FILE="$HOME/.kube/config"
    if [ ! -f "$KUBE_CONFIG_FILE" ]; then
        echo "ВНИМАНИЕ: Файл $KUBE_CONFIG_FILE не найден. Пропускаем обработку..."
        return 1
    fi
    
    echo "Обработка конфигурации Kubernetes..."
    
    local errors=0
    KUBE_CONFIG=$(base64 -w0 < "$KUBE_CONFIG_FILE")
    
    echo "Установка секрета KUBE_CONFIG в GitHub..."
    if ! gh secret set KUBE_CONFIG -b"$KUBE_CONFIG"; then
        echo "ОШИБКА: Не удалось установить секрет KUBE_CONFIG"
        ((errors++))
    fi
    
    if [ $errors -gt 0 ]; then
        ((ERRORS++))
    fi
    
    return $errors
}

# --- 7. Блок отправки данных Docker Hub ---
function process_dockerhub_secrets() {
    DOCKER_CONFIG="$HOME/.docker/config.json"
    if [ ! -f "$DOCKER_CONFIG" ]; then
        echo "ВНИМАНИЕ: Файл конфигурации Docker не найден: $DOCKER_CONFIG"
        echo "  Пропускаем обработку Docker Hub секретов"
        return 1
    fi
    
    DOCKERHUB_AUTH=$(jq -r '.auths["https://index.docker.io/v1/"].auth' "$DOCKER_CONFIG")
    if [ -z "$DOCKERHUB_AUTH" ] || [ "$DOCKERHUB_AUTH" = "null" ]; then
        echo "ВНИМАНИЕ: Не удалось извлечь данные авторизации Docker Hub."
        echo "  Пропускаем обработку Docker Hub секретов"
        return 1
    fi

    echo "Добавление Docker Hub секретов..."
    local errors=0
    
    DECODED_AUTH=$(echo "$DOCKERHUB_AUTH" | base64 --decode)
    DOCKERHUB_USERNAME=$(echo "$DECODED_AUTH" | cut -d ':' -f 1)
    DOCKERHUB_TOKEN=$(echo "$DECODED_AUTH" | cut -d ':' -f 2)

    if [ -z "$DOCKERHUB_USERNAME" ] || [ -z "$DOCKERHUB_TOKEN" ]; then
        echo "ВНИМАНИЕ: Не удалось получить username или token из Docker Hub."
        echo "  Пропускаем обработку Docker Hub секретов"
        return 1
    fi

    echo "Установка DOCKERHUB_USERNAME и DOCKERHUB_TOKEN в GitHub Secrets..."
    
    if ! gh secret set DOCKERHUB_USERNAME --body "$DOCKERHUB_USERNAME"; then
        echo "ОШИБКА: Не удалось установить DOCKERHUB_USERNAME"
        ((errors++))
    fi
    
    if ! gh secret set DOCKERHUB_TOKEN --body "$DOCKERHUB_TOKEN"; then
        echo "ОШИБКА: Не удалось установить DOCKERHUB_TOKEN"
        ((errors++))
    fi

    echo "  - DOCKERHUB_USERNAME: $DOCKERHUB_USERNAME"
    echo "  - DOCKERHUB_TOKEN: (скрыто)"
    
    if [ $errors -gt 0 ]; then
        ((ERRORS++))
    fi
    
    return $errors
}

# Главная функция
function main() {
    # Сбрасываем счетчик ошибок
    ERRORS=0
    
    # Проверки
    check_software_installation
    check_authorization
    check_required_files
    
    # Обработка
    process_yandex_auth
    process_backet_auth
    process_kube_config
    process_dockerhub_secrets
    
    # Итоговое сообщение
    if [ $ERRORS -gt 0 ]; then
        echo " "
        echo "────────────────────────────────────────────"
        echo "ОШИБКА: Скрипт завершил работу с ошибками!"
        echo "   Всего ошибок: $ERRORS"
        echo "   Проверьте вывод выше."
        echo "────────────────────────────────────────────"
        read -p "Нажмите Enter для продолжения..."  # Добавлена пауза
    else
        echo " "
        echo "────────────────────────────────────────────"
        echo "Переменные добавлены успешно, без ошибок!"
        echo "────────────────────────────────────────────"
        read -p "Нажмите Enter для продолжения..."  # Добавлена пауза
    fi
}

main