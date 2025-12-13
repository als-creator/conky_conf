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

# Настройка автозапуска Conky через systemd для текущего пользователя
echo "Настройка автозапуска Conky через systemd..."
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/conky.service << 'EOF'
[Unit]
Description=Conky System Monitor
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=simple
Environment=DISPLAY=%i  # Для X11; для Wayland: WAYLAND_DISPLAY=wayland-0
ExecStartPre=/bin/sleep 5
ExecStart=/usr/bin/conky -c %h/.config/conky/conky.conf
Restart=on-failure
RestartSec=5

[Install]
WantedBy=graphical-session.target
EOF

# Перезагрузка systemd user units
systemctl --user daemon-reload

# Активация службы
systemctl --user enable --now conky.service

# Подсказка пользователю
echo "Автозапуск настроен! Conky будет запускаться автоматически при входе в графическую сессию."
echo "Проверить статус службы можно командой: systemctl --user status conky.service"

echo "Готово! Repo: https://github.com/als-creator/conky_conf"
