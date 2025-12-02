#!/bin/bash

# setup_conky.sh — Установка Conky config для Arch Linux с автозапуском
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

# Создание systemd user service для автозапуска Conky
echo "Настройка автозапуска Conky через systemd..."
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/system/conky.service << 'EOF'
[Unit]
Description=Conky System Monitor
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=simple
Environment=DISPLAY=:0
ExecStart=/usr/bin/conky -c %h/.config/conky/conky.conf
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

# Перезагрузка systemd user units и активация автозапуска
systemctl --user daemon-reload
systemctl --user enable --now conky.service

echo "Autostart настроен! Conky будет запускаться автоматически при входе в графическую сессию."
echo "Проверить статус: systemctl --user status conky.service"

# Запуск Conky для текущей сессии
if pgrep -x "conky" > /dev/null; then
    echo "Перезапуск Conky..."
    killall conky
    sleep 1
fi

conky -c ~/.config/conky/conky.conf &
CONKY_PID=$!

# Проверка запуска
if ps -p $CONKY_PID > /dev/null; then
    echo "Conky запущен! Температура Intel CPU отображается в реалтайм."
    echo "Проверь: sensors (должно быть coretemp с ~30-40°C)"
    echo "Остановить: systemctl --user stop conky.service"
    echo "Отключить автозапуск: systemctl --user disable conky.service"
else
    echo "Conky не запустился. Проверь ошибки: conky -c ~/.config/conky/conky.conf"
fi

echo "Готово! Repo: https://github.com/als-creator/conky_conf"
echo "Статус сервиса можно проверить через systemctl --user status conky.service"
