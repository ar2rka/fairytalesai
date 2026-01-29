#!/usr/bin/env python3
"""
Скрипт для сброса пароля пользователя в Supabase.

ВАЖНО: Для работы скрипта требуется service_role ключ от Supabase.
Этот ключ имеет полные права администратора и должен храниться в секрете!

Использование:
    python reset_password.py --email user@example.com --new-password newpassword
    
    Или с указанием service_role ключа:
    python reset_password.py --email user@example.com --new-password newpassword \\
        --service-role-key YOUR_SERVICE_ROLE_KEY
"""

import os
import argparse
import sys
import httpx
from dotenv import load_dotenv
from supabase import create_client, Client

# Загружаем переменные окружения
load_dotenv()


def reset_user_password(
    email: str,
    new_password: str,
    supabase_url: str,
    service_role_key: str
) -> bool:
    """
    Сбрасывает пароль пользователя через Supabase Admin API.
    
    Args:
        email: Email пользователя
        new_password: Новый пароль
        supabase_url: URL проекта Supabase
        service_role_key: Service role ключ (административный ключ)
        
    Returns:
        True если пароль успешно изменен
        
    Raises:
        ValueError: Если не удалось изменить пароль
    """
    # Создаем клиент с service_role ключом для административных операций
    supabase: Client = create_client(supabase_url, service_role_key)
    
    try:
        # Сначала находим пользователя по email
        # Используем Admin API для поиска пользователя
        auth_admin = supabase.auth.admin
        
        # Получаем список пользователей и ищем нужного
        # В Supabase Python SDK нет прямого метода для поиска по email через admin,
        # поэтому используем прямой вызов API
        
        # Получаем пользователя через Admin API
        response = httpx.get(
            f"{supabase_url}/auth/v1/admin/users",
            headers={
                "apikey": service_role_key,
                "Authorization": f"Bearer {service_role_key}",
                "Content-Type": "application/json"
            },
            params={"per_page": 1000}  # Получаем всех пользователей
        )
        
        if response.status_code != 200:
            raise ValueError(f"Не удалось получить список пользователей: {response.status_code} - {response.text}")
        
        users = response.json().get("users", [])
        user = None
        
        for u in users:
            if u.get("email", "").lower() == email.lower():
                user = u
                break
        
        if not user:
            raise ValueError(f"Пользователь с email {email} не найден")
        
        user_id = user.get("id")
        
        # Обновляем пароль пользователя через Admin API
        update_response = httpx.put(
            f"{supabase_url}/auth/v1/admin/users/{user_id}",
            headers={
                "apikey": service_role_key,
                "Authorization": f"Bearer {service_role_key}",
                "Content-Type": "application/json"
            },
            json={
                "password": new_password
            }
        )
        
        if update_response.status_code not in [200, 204]:
            error_text = update_response.text
            try:
                error_json = update_response.json()
                error_text = error_json.get("message", error_text)
            except:
                pass
            raise ValueError(f"Не удалось обновить пароль: {update_response.status_code} - {error_text}")
        
        return True
        
    except httpx.HTTPError as e:
        raise ValueError(f"Ошибка HTTP при сбросе пароля: {e}")
    except Exception as e:
        if isinstance(e, ValueError):
            raise
        raise ValueError(f"Ошибка при сбросе пароля: {e}")


def send_password_reset_email(
    email: str,
    supabase_url: str,
    service_role_key: str
) -> bool:
    """
    Отправляет ссылку на сброс пароля пользователю на email.
    
    Args:
        email: Email пользователя
        supabase_url: URL проекта Supabase
        service_role_key: Service role ключ
        
    Returns:
        True если ссылка успешно отправлена
    """
    try:
        # Отправляем ссылку на сброс пароля через Admin API
        response = httpx.post(
            f"{supabase_url}/auth/v1/admin/users/generate_link",
            headers={
                "apikey": service_role_key,
                "Authorization": f"Bearer {service_role_key}",
                "Content-Type": "application/json"
            },
            json={
                "type": "recovery",
                "email": email
            }
        )
        
        if response.status_code not in [200, 201]:
            error_text = response.text
            try:
                error_json = response.json()
                error_text = error_json.get("message", error_text)
            except:
                pass
            raise ValueError(f"Не удалось отправить ссылку на сброс пароля: {response.status_code} - {error_text}")
        
        return True
        
    except httpx.HTTPError as e:
        raise ValueError(f"Ошибка HTTP при отправке ссылки: {e}")
    except Exception as e:
        if isinstance(e, ValueError):
            raise
        raise ValueError(f"Ошибка при отправке ссылки: {e}")


def main():
    """Главная функция."""
    parser = argparse.ArgumentParser(
        description="Сброс пароля пользователя в Supabase",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
ВАЖНО: Service Role Key
  Для работы скрипта требуется service_role ключ от Supabase.
  Этот ключ можно найти в Supabase Dashboard → Settings → API → service_role key
  ВАЖНО: Этот ключ имеет полные права администратора! Не используйте его во фронтенде!

Примеры использования:

  # Прямой сброс пароля (требует service_role ключ в .env или через --service-role-key)
  python reset_password.py --email user@example.com --new-password newpassword123

  # С указанием service_role ключа
  python reset_password.py --email user@example.com --new-password newpassword123 \\
      --service-role-key YOUR_SERVICE_ROLE_KEY

  # Отправка ссылки на сброс пароля (пользователь сам выберет новый пароль)
  python reset_password.py --email user@example.com --send-reset-link

  # С указанием URL Supabase
  python reset_password.py --email user@example.com --new-password newpassword123 \\
      --supabase-url https://your-project.supabase.co \\
      --service-role-key YOUR_SERVICE_ROLE_KEY
        """
    )
    
    parser.add_argument(
        "--email",
        required=True,
        help="Email пользователя, для которого нужно сбросить пароль"
    )
    
    parser.add_argument(
        "--new-password",
        help="Новый пароль (если не указан, будет отправлена ссылка на сброс)"
    )
    
    parser.add_argument(
        "--send-reset-link",
        action="store_true",
        help="Отправить ссылку на сброс пароля на email вместо прямого изменения пароля"
    )
    
    parser.add_argument(
        "--supabase-url",
        help="URL проекта Supabase (по умолчанию из .env или из get_token.py)"
    )
    
    parser.add_argument(
        "--service-role-key",
        help="Service role ключ от Supabase (по умолчанию из переменной окружения SUPABASE_SERVICE_ROLE_KEY)"
    )
    
    args = parser.parse_args()
    
    # Определяем способ сброса пароля
    if not args.new_password and not args.send_reset_link:
        parser.error("Необходимо указать либо --new-password, либо --send-reset-link")
    
    if args.new_password and args.send_reset_link:
        parser.error("Нельзя использовать --new-password и --send-reset-link одновременно")
    
    # Получаем настройки Supabase
    supabase_url = args.supabase_url or os.getenv("SUPABASE_URL") or "https://yefsocnfbcdyuajaanaz.supabase.co"
    service_role_key = args.service_role_key or os.getenv("SUPABASE_SERVICE_ROLE_KEY")
    
    if not service_role_key:
        print("\n✗ Ошибка: Service role ключ не найден!", file=sys.stderr)
        print("\nУкажите ключ одним из способов:", file=sys.stderr)
        print("  1. Через аргумент: --service-role-key YOUR_KEY", file=sys.stderr)
        print("  2. Через переменную окружения: SUPABASE_SERVICE_ROLE_KEY", file=sys.stderr)
        print("  3. Добавьте SUPABASE_SERVICE_ROLE_KEY в файл .env", file=sys.stderr)
        print("\nService role ключ можно найти в:", file=sys.stderr)
        print("  Supabase Dashboard → Settings → API → service_role key", file=sys.stderr)
        return 1
    
    try:
        if args.send_reset_link:
            print(f"Отправка ссылки на сброс пароля для {args.email}...")
            success = send_password_reset_email(args.email, supabase_url, service_role_key)
            if success:
                print(f"\n✓ Ссылка на сброс пароля успешно отправлена на {args.email}")
                print("Пользователь получит email со ссылкой для выбора нового пароля.")
        else:
            print(f"Сброс пароля для пользователя {args.email}...")
            success = reset_user_password(args.email, args.new_password, supabase_url, service_role_key)
            if success:
                print(f"\n✓ Пароль успешно изменен для пользователя {args.email}")
                print(f"Новый пароль: {args.new_password}")
                print("\nВАЖНО: Сообщите пользователю новый пароль безопасным способом!")
        
        return 0
        
    except ValueError as e:
        print(f"\n✗ Ошибка: {e}", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"\n✗ Неожиданная ошибка: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
