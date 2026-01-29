#!/usr/bin/env python3
"""
Скрипт для получения JWT access_token от Supabase Auth.

Использование:
    python get_token.py
    
    Или с указанием учетных данных:
    python get_token.py --email i@i.i --password 12345678
"""

import os
import argparse
import sys
from dotenv import load_dotenv
from supabase import create_client, Client

# Загружаем переменные окружения
load_dotenv()


def get_supabase_token(email: str, password: str) -> str:
    """
    Получает JWT access_token от Supabase Auth.
    
    Args:
        email: Email пользователя
        password: Пароль пользователя
        
    Returns:
        JWT access_token
        
    Raises:
        ValueError: Если не удалось получить токен
    """
    supabase_url = "https://yefsocnfbcdyuajaanaz.supabase.co"#os.getenv("SUPABASE_URL")
    supabase_key = "sb_publishable_7zRmYEEijPp4ZegMMi55Rg_GNyLY-eM"##os.getenv("SUPABASE_KEY")
    
    if not supabase_url:
        raise ValueError(
            "SUPABASE_URL не найден в переменных окружения. "
            "Убедитесь, что файл .env существует и содержит SUPABASE_URL."
        )
    
    if not supabase_key:
        raise ValueError(
            "SUPABASE_KEY не найден в переменных окружения. "
            "Убедитесь, что файл .env существует и содержит SUPABASE_KEY."
        )
    
    # Создаем клиент Supabase
    # Для авторизации нужен anon key (публичный ключ)
    supabase: Client = create_client(supabase_url, supabase_key)
    
    # Авторизуемся
    try:
        response = supabase.auth.sign_in_with_password({
            "email": email,
            "password": password
        })
        
        if response.user is None or response.session is None:
            raise ValueError("Не удалось получить сессию после авторизации")
        
        access_token = response.session.access_token
        
        if not access_token:
            raise ValueError("Access token не найден в ответе")
        
        return access_token
        
    except Exception as e:
        error_msg = str(e)
        if "Invalid login credentials" in error_msg or "Email not confirmed" in error_msg:
            raise ValueError(f"Ошибка авторизации: {error_msg}")
        raise ValueError(f"Ошибка при получении токена: {error_msg}")


def main():
    """Главная функция."""
    parser = argparse.ArgumentParser(
        description="Получение JWT access_token от Supabase Auth",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Примеры использования:

  # Использование учетных данных по умолчанию (i@i.i / 12345678)
  python get_token.py

  # Указание своих учетных данных
  python get_token.py --email user@example.com --password mypassword

  # Сохранение токена в переменную окружения
  export SUPABASE_TOKEN=$(python get_token.py)
  python load_test.py --url https://api.example.com --token $SUPABASE_TOKEN --child-id CHILD_UUID

  # Использование токена напрямую в нагрузочном тесте
  python load_test.py --url https://api.example.com \\
      --token $(python get_token.py) \\
      --child-id CHILD_UUID
        """
    )
    
    parser.add_argument(
        "--email",
        default="i@i.i",
        help="Email пользователя (по умолчанию: i@i.i)"
    )
    
    parser.add_argument(
        "--password",
        default="12345678",
        help="Пароль пользователя (по умолчанию: 12345678)"
    )
    
    parser.add_argument(
        "--quiet",
        action="store_true",
        help="Вывести только токен без дополнительной информации"
    )
    
    args = parser.parse_args()
    
    try:
        if not args.quiet:
            print("Авторизация в Supabase...")
            print(f"Email: {args.email}")
        
        token = get_supabase_token(args.email, args.password)
        
        if args.quiet:
            print(token)
        else:
            print("\n✓ Токен успешно получен!")
            print(f"\nAccess Token:")
            print(f"{token}\n")
            print("Использование:")
            print(f"  python load_test.py --url YOUR_API_URL --token '{token}' --child-id CHILD_UUID")
            print("\nИли сохраните в переменную окружения:")
            print(f"  export SUPABASE_TOKEN='{token}'")
        
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
