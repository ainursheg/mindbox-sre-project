
#!/bin/bash

# ===================================================================================
# УНИВЕРСАЛЬНЫЙ СКРИПТ ЗАПУСКА И ТЕСТИРОВАНИЯ ПРОЕКТА
#
# Этот скрипт:
# 1. Проверяет наличие всех необходимых зависимостей (Docker, kubectl, Kind, Ansible).
# 2. Если что-то отсутствует, пытается это установить.
# 3. Запускает Ansible-плейбук, который выполняет полный цикл теста.
# ===================================================================================

# Выход из скрипта при любой ошибке
set -e

# --- Цвета для красивого вывода ---
C_INFO='\033[0;34m'
C_SUCCESS='\033[0;32m'
C_WARN='\033[0;33m'
C_ERROR='\033[0;31m'
C_RESET='\033[0m'

print_info() { echo -e "${C_INFO}[INFO]${C_RESET} $1"; }
print_success() { echo -e "${C_SUCCESS}[SUCCESS]${C_RESET} $1"; }
print_warning() { echo -e "${C_WARN}[WARNING]${C_RESET} $1"; }
print_error() { echo -e "${C_ERROR}[ERROR]${C_RESET} $1"; }

# --- Проверка операционной системы ---
if [[ "$(uname)" != "Linux" ]]; then
    print_error "Этот скрипт предназначен для работы в Linux-окружении (включая WSL)."
    print_error "Для macOS/Windows убедитесь, что у вас вручную установлены Docker, kubectl, Kind и Ansible."
    exit 1
fi

# --- Функции установки ---
install_kubectl() {
    print_warning "kubectl не найден. Устанавливаем..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    print_success "kubectl успешно установлен."
}

install_kind() {
    print_warning "Kind не найден. Устанавливаем..."
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
    print_success "Kind успешно установлен."
}

install_ansible() {
    print_warning "Ansible не найден. Устанавливаем через apt..."
    sudo apt-get update
    sudo apt-get install -y ansible python3-kubernetes
    print_success "Ansible и python3-kubernetes успешно установлены."
}

install_helm() {
    print_warning "Helm не найден. Устанавливаем..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    print_success "Helm успешно установлен."
}

# --- Главный блок ---

# Шаг 1: Проверка Docker
print_info "Шаг 1/6: Проверка Docker..."
if ! command -v docker &> /dev/null; then
    print_error "Команда 'docker' не найдена. Пожалуйста, установите Docker."
    exit 1
fi
if ! docker info &> /dev/null; then
    print_error "Не удалось подключиться к Docker daemon. Убедитесь, что Docker запущен и WSL Integration включена (для Windows)."
    exit 1
fi
print_success "Docker найден и работает."

# Шаг 2: Проверка kubectl
print_info "Шаг 2/5: Проверка kubectl..."
command -v kubectl &> /dev/null || install_kubectl
print_success "kubectl на месте."

# Шаг 3: Проверка Kind
print_info "Шаг 3/5: Проверка Kind..."
command -v kind &> /dev/null || install_kind
print_success "Kind на месте."

# Шаг 4: Проверка Ansible
print_info "Шаг 4/6: Проверка Ansible..."
command -v ansible &> /dev/null || install_ansible
print_success "Ansible на месте."

# Шаг 5: Проверка Helm
print_info "Шаг 5/6: Проверка Helm..."
command -v helm &> /dev/null || install_helm
print_success "Helm на месте."

# Шаг 6: Запуск основного сценария
print_info "Шаг 6/6: Все зависимости на месте. Запускаем Ansible-плейбук..."
echo "==================================================================================="
cd ansible/
ansible-playbook playbook.yml
echo "==================================================================================="
print_success "Сценарий успешно завершен!"

exit 0