#!/bin/bash

# setup_conky.sh — Индивидуальная установка Conky config для Arch Linux с автозапуском
# Автор: als-creator (conky_conf repo)

echo "Установка Conky + config для мониторинга температуры CPU с автозапуском"

# Проверка дистрибутива (Arch-based)
if ! grep -qi arch /etc/os-release; then
    echo "Этот скрипт для Arch Linux (или производных). Для других — ручная установка."
    exit 1
fi

# Обновление и установка пакетов
echo "Установка Conky и lm_sensors..."
sudo pacman -Syu --noconfirm --needed conky lm_sensors

# Настройка датчиков (авто)
echo "Настройка датчиков температуры..."
sudo sensors-detect --auto <<< "yes"
sudo systemctl enable --now lm_sensors

# Создание директории и скачивание config
echo "Создание ~/.config/conky..."
mkdir -p ~/.config/conky

# Скачиваем conky.conf из репо
if curl -fsSL https://raw.githubusercontent.com/als-creator/conky_conf/main/conky.conf -o ~/.config/conky/conky.conf; then
    echo "Config скачан: ~/.config/conky/conky.conf"
else
    echo "Ошибка скачивания config. Проверь интернет."
    exit 1
fi

# Проверка датчиков
echo "Проверка температуры (sensors):"
sensors | grep -E "(coretemp|Package id)" || echo "Датчики CPU не найдены. Перезагрузись и проверь modprobe coretemp."

# Настройка автозапуска Conky через.desktop (единственный метод, для DE/WM)
echo "Настройка автозапуска Conky через.desktop..."
mkdir -p ~/.config/autostart

# Создаём.desktop файл
cat > ~/.config/autostart/conky.desktop << EOF
[Desktop Entry]
Type=Application
Name=Conky
Exec=conky -c ~/.config/conky/conky.conf --daemonize --pause=5
Comment=Системный мониторинг Conky
NoDisplay=false
X-GNOME-Autostart-enabled=true
Hidden=false
Terminal=false
EOF

# Подсказка пользователю
echo "Автозапуск настроен только через.desktop! Conky будет запускаться автоматически при входе в графическую сессию."
echo "Проверить файл: ls ~/.config/autostart/conky.desktop"
echo "Для тестирования: conky -c ~/.config/conky/conky.conf"
echo "Для отключения: rm ~/.config/autostart/conky.desktop"
echo "Если в WM (i3), добавьте в config WM: exec --no-startup-id conky -c ~/.config/conky/conky.conf"

echo "Готово! Repo: https://github.com/als-creator/conky_conf"