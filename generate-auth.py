#!/usr/bin/env python3
import yaml
import os
import re
import subprocess
from pathlib import Path

def generate_ssh_key(key_name):
    """Генерирует новый SSH-ключ и возвращает путь к публичному ключу"""
    key_path = os.path.expanduser(f"~/.ssh/{key_name}")
    if os.path.exists(key_path):
        raise FileExistsError(f"SSH-ключ {key_path} уже существует")
    
    subprocess.run(
        ["ssh-keygen", "-t", "ed25519", "-f", key_path, "-N", "", "-q"],
        check=True
    )
    return f"{key_path}.pub"

def get_existing_ssh_keys():
    """Список существующих ключей в ~/.ssh"""
    ssh_dir = Path.home() / ".ssh"
    return [f for f in ssh_dir.glob("*.pub") if f.is_file()]

def select_ssh_key():
    """Выбор существующего ключа или создание нового"""
    existing_keys = get_existing_ssh_keys()
    
    if existing_keys:
        print("Доступные SSH-ключи:")
        for i, key in enumerate(existing_keys, 1):
            print(f"{i}. {key.name}")
        print(f"{len(existing_keys)+1}. Создать новый ключ")
        
        while True:
            try:
                choice = input("Выберите ключ или создайте новый: ")
                choice_num = int(choice)
                
                if 1 <= choice_num <= len(existing_keys):
                    return existing_keys[choice_num-1]
                elif choice_num == len(existing_keys)+1:
                    break
                else:
                    print("Неверный выбор, попробуйте снова")
            except ValueError:
                print("Введите число")
    
    # Создание нового ключа
    while True:
        key_name = input("Введите имя для нового SSH-ключа: ").strip()
        if not key_name:
            print("Имя не может быть пустым")
            continue
        
        try:
            pub_key_path = generate_ssh_key(key_name)
            print(f"Создан новый SSH-ключ: {pub_key_path}")
            return Path(pub_key_path)
        except FileExistsError:
            print("Ключ с таким именем уже существует, введите другое имя")
        except subprocess.CalledProcessError:
            print("ОШИБКА при создании SSH-ключа, попробуйте снова")

def write_tfvars_file(path, content):
    """Записывает .tfvars файл с автоматическим созданием директорий"""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write(content)
    print(f"Файл создан: {path}")

def main():
    # Пути к файлам конфигурации
    config_path = os.path.expanduser('~/.config/yandex-cloud/config.yaml')
    
    # Пути для выходных файлов
    output_paths = [
        ('terraform/sa-and-bucket/yandex-auth.auto.tfvars', False),  # Без SSH и github-actions
        ('terraform/infrastruct/yandex-auth.auto.tfvars', True)     # Полная версия
    ]
    
    # Проверяем наличие Яндекс конфига
    if not os.path.exists(config_path):
        print(f"ОШИБКА: Yandex-config файл не найден по пути {config_path}")
        exit(1)
    
    # Читаем YAML файл
    with open(config_path, 'r') as f:
        config = yaml.safe_load(f)
    
    # Получаем данные из профиля default
    profile_data = config['profiles']['default']
    
    # Обработка SSH-ключа
    print("\n" + "="*40)
    print("Настройка SSH-ключа для доступа к инстансам")
    print("="*40)
    selected_pub_key = select_ssh_key()
    
    # Читаем публичный ключ
    with open(selected_pub_key, 'r') as f:
        ssh_key_content = f.read().strip()

    # Формируем содержимое файлов
    base_tfvars_content = """# Yandex authority variables
token     = "{token}"
folder_id = "{folder_id}"
cloud_id  = "{cloud_id}"
""".format(
        token=profile_data["token"],
        folder_id=profile_data["folder-id"],
        cloud_id=profile_data["cloud-id"]
    )

    full_tfvars_content = """# Yandex authority variables
github-actions = "false"
token          = "{token}"
folder_id      = "{folder_id}"
cloud_id       = "{cloud_id}"
ssh_public_key = "{ssh_key}"
""".format(
        token=profile_data["token"],
        folder_id=profile_data["folder-id"],
        cloud_id=profile_data["cloud-id"],
        ssh_key=ssh_key_content
    )

    # Записываем файлы в обе директории с разным содержимым
    for path, is_full in output_paths:
        content = full_tfvars_content if is_full else base_tfvars_content
        write_tfvars_file(path, content)

    print("\nФайлы переменных успешно созданы:")
    for path, _ in output_paths:
        print(f"  - {path}")

if __name__ == '__main__':
    main()