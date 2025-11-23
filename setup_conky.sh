#!/bin/bash

# Переменная с именем текущего пользователя
USER=$(whoami)
HOME_DIR="/home/${USER}"

# Копирование файла конфигурации
echo "Создание директории .config/conky..."
mkdir -p "${HOME_DIR}/.config/conky"
cp ./conky.conf "${HOME_DIR}/.config/conky/"

# Установка автозагрузки
echo "Настройка автоматического запуска Conky..."
mkdir -p "${HOME_DIR}/.config/autostart"
cat > "${HOME_DIR}/.config/autostart/conky.desktop" << EOF
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

# Проверяем наличие программы Conky
if ! command -v conky &>/dev/null; then
    echo "Программа Conky не установлена."
    exit 1
fi

# Запускаем Conky вручную
echo "Запуск Conky..."
conky &

echo "Автонастройка выполнена успешно!"
