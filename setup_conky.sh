#!/bin/bash

# setup_conky.sh — Глобальная установка Conky config для Arch Linux с автозапуском
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

# Создание общей директории для конфига
echo "Создание общего config-файла (/etc/conky/)..."
sudo mkdir -p /etc/conky

# Скачиваем conky.conf из репо
if curl -fsSL https://raw.githubusercontent.com/als-creator/conky_conf/main/conky.conf -o /etc/conky/conky.conf; then
    echo "Config скачан: /etc/conky/conky.conf"
else
    echo "Ошибка скачивания config. Проверь интернет."
    exit 1
fi

# Проверка датчиков
echo "Проверка температуры (sensors):"
sensors | grep -E "(coretemp|Package id)" || echo "Датчики CPU не найдены. Перезагрузись и проверь modprobe coretemp."

# Создание systemd global service для автозапуска Conky
echo "Настройка глобального автозапуска Conky через systemd..."
sudo tee /etc/systemd/system/conky@.service > /dev/null << 'EOF'
[Unit]
Description=Conky System Monitor for User %I
After=graphical-session.target
Wants=graphical-session.target

[Service]
User=%I
Group=%I
Type=simple
Environment=DISPLAY=:0 XAUTHORITY=/run/user/%U/gdm/Xauthority
ExecStart=/usr/bin/conky -c /etc/conky/conky.conf
Restart=on-failure
RestartSec=5

[Install]
WantedBy=graphical-session.target
EOF

# Перезагрузка systemd units
sudo systemctl daemon-reload

# Включаем службу для текущего пользователя
CURRENT_USER=$(whoami)
echo "Активация службы для пользователя $CURRENT_USER..."
sudo systemctl enable conky@$CURRENT_USER.service
sudo systemctl start conky@$CURRENT_USER.service

# Сообщение пользователю
echo "Автозапуск настроен! Conky будет запускаться автоматически при входе в графическую сессию."
echo "Статусы сервисов:"
echo "- Активировать: sudo systemctl enable conky@username.service"
echo "- Отключить: sudo systemctl disable conky@username.service"
echo "- Статус: sudo systemctl status conky@username.service"

echo "Готово! Repo: https://github.com/als-creator/conky_conf"
