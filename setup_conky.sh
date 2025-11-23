#!/bin/bash

# Имя текущего пользователя
USER=$(whoami)
HOME_DIR="/home/${USER}"
CONFIG_FILE="./conky.conf"
CONKY_DESKTOP="${HOME_DIR}/.config/autostart/conky.desktop"

# Функция установки пакета для Arch Linux
install_package() {
    # Проверяем права root и устанавливаем пакеты
    if sudo -v; then
        sudo pacman -Syy
        sudo pacman -S conky --noconfirm
    else
        echo "Необходимо ввести пароль администратора для установки пакетов."
        return 1
    fi
}

# Проверка наличия необходимых файлов
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Ошибка: Файл '$CONFIG_FILE' не найден."
    exit 1
fi

# Проверка установленного дистрибутива
if cat /etc/os-release | grep -qi "arch"; then
    DISTRO="Arch Linux"
else
    DISTRO="не Arch Linux"
fi

# Создание директорий и копирование файлов
echo "Создание директории .config/conky..."
mkdir -p "${HOME_DIR}/.config/conky"
cp "$CONFIG_FILE" "${HOME_DIR}/.config/conky/"

# Установка автозагрузки
echo "Настройка автоматического запуска Conky..."
mkdir -p "${HOME_DIR}/.config/autostart"
cat > "$CONKY_DESKTOP" << EOF
[Desktop Entry]
Type=Application
Name=Conky
Exec=/usr/bin/conky
Comment=Запуск Conky
NoDisplay=false
X-GNOME-Autostart-enabled=true
Hidden=false
Terminal=false
EOF

# Проверка наличия программы Conky
if ! command -v conky &>/dev/null; then
    if [ "$DISTRO" == "Arch Linux" ]; then
        install_package || { echo "Ошибка установки пакета conky."; exit 1; }
    else
        echo "Ваш дистрибутив не основан на Arch Linux. Ручная установка Conky рекомендуется."
        exit 1
    fi
fi

# Запуск Conky вручную
echo "Запуск Conky..."
conky &

echo "Автонастройка выполнена успешно!"
exit 0
