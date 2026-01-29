#!/usr/bin/env python3
"""
Скрипт для нагрузочного тестирования генератора историй.

ВАЖНО: Токен авторизации
  Параметр --token должен быть JWT access_token от Supabase Auth.
  Это токен, который пользователь получает при авторизации через Supabase.

Использование:
    python load_test.py --url https://api.example.com --token SUPABASE_ACCESS_TOKEN --child-id CHILD_UUID
    
    Или с дополнительными параметрами:
    python load_test.py --url https://api.example.com --token SUPABASE_ACCESS_TOKEN --child-id CHILD_UUID \\
        --concurrent 10 --requests 100 --story-type child
"""

import asyncio
import argparse
import random
import time
import statistics
import sys
from datetime import datetime
from typing import List, Dict, Optional
from dataclasses import dataclass, field
import httpx
import json
import os
from dotenv import load_dotenv
import logging

# Настраиваем логирование
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

# Загружаем переменные окружения для получения токена
load_dotenv()

# Доступные темы (как в API / jinja_helpers)
THEMES = [
    "adventure", "space", "fantasy", "pirates", "dinosaurs",
    "magic", "ocean", "forest", "robots", "fairies", "knights", "animals"
]


@dataclass
class RequestResult:
    """Результат одного запроса."""
    success: bool
    status_code: int
    response_time: float
    error: Optional[str] = None
    story_id: Optional[str] = None


@dataclass
class LoadTestStats:
    """Статистика нагрузочного тестирования."""
    total_requests: int = 0
    successful_requests: int = 0
    failed_requests: int = 0
    response_times: List[float] = field(default_factory=list)
    status_codes: Dict[int, int] = field(default_factory=dict)
    errors: List[str] = field(default_factory=list)
    start_time: Optional[float] = None
    end_time: Optional[float] = None
    
    @property
    def duration(self) -> float:
        """Общая длительность теста в секундах."""
        if self.start_time and self.end_time:
            return self.end_time - self.start_time
        return 0.0
    
    @property
    def requests_per_second(self) -> float:
        """Запросов в секунду."""
        if self.duration > 0:
            return self.total_requests / self.duration
        return 0.0
    
    @property
    def success_rate(self) -> float:
        """Процент успешных запросов."""
        if self.total_requests > 0:
            return (self.successful_requests / self.total_requests) * 100
        return 0.0
    
    @property
    def avg_response_time(self) -> float:
        """Среднее время ответа."""
        if self.response_times:
            return statistics.mean(self.response_times)
        return 0.0
    
    @property
    def median_response_time(self) -> float:
        """Медианное время ответа."""
        if self.response_times:
            return statistics.median(self.response_times)
        return 0.0
    
    @property
    def min_response_time(self) -> float:
        """Минимальное время ответа."""
        if self.response_times:
            return min(self.response_times)
        return 0.0
    
    @property
    def max_response_time(self) -> float:
        """Максимальное время ответа."""
        if self.response_times:
            return max(self.response_times)
        return 0.0
    
    @property
    def p95_response_time(self) -> float:
        """95-й перцентиль времени ответа."""
        if self.response_times:
            sorted_times = sorted(self.response_times)
            index = int(len(sorted_times) * 0.95)
            return sorted_times[index] if index < len(sorted_times) else sorted_times[-1]
        return 0.0
    
    @property
    def p99_response_time(self) -> float:
        """99-й перцентиль времени ответа."""
        if self.response_times:
            sorted_times = sorted(self.response_times)
            index = int(len(sorted_times) * 0.99)
            return sorted_times[index] if index < len(sorted_times) else sorted_times[-1]
        return 0.0


class LoadTester:
    """Класс для проведения нагрузочного тестирования."""
    
    def __init__(
        self,
        base_url: str,
        token: str,
        child_id: str,
        hero_id: Optional[str] = None,
        story_type: str = "child",
        language: str = "en",
        story_length: int = 4,
        theme: Optional[str] = None,
        themes_mode: bool = False,
        concurrent: int = 10,
        total_requests: int = 80,
        verbose: bool = False
    ):
        self.base_url = base_url.rstrip('/')
        self.token = token
        self.child_id = child_id
        self.hero_id = hero_id
        self.story_type = story_type
        self.language = language
        self.story_length = story_length
        self.theme = theme or "adventure"
        self.themes_mode = themes_mode  # True = случайная тема для каждого запроса
        self.concurrent = concurrent
        self.total_requests = total_requests
        self.verbose = verbose
        self.stats = LoadTestStats()
        self.results: List[RequestResult] = []
        
        # Настраиваем уровень логирования
        if verbose:
            logging.getLogger().setLevel(logging.DEBUG)
        
    async def make_request(self, client: httpx.AsyncClient, request_num: int) -> RequestResult:
        """Выполняет один запрос на генерацию истории."""
        url = f"{self.base_url}/api/v1/stories/generate"
        headers = {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json"
        }
        
        # Тема: одна для всех запросов или случайная при themes_mode
        theme = random.choice(THEMES) if self.themes_mode else self.theme

        payload = {
            "language": self.language,
            "child_id": self.child_id,
            "story_type": self.story_type,
            "story_length": self.story_length,
            "generate_audio": False,
            "theme": theme
        }
        
        if self.story_type in ["hero", "combined"] and self.hero_id:
            payload["hero_id"] = self.hero_id
        
        # Подробное логирование запроса
        if self.verbose or request_num <= 3:  # Всегда логируем первые 3 запроса
            logger.info(f"\n{'='*80}")
            logger.info(f"Запрос #{request_num}")
            logger.info(f"{'='*80}")
            logger.info(f"URL: {url}")
            logger.info(f"Метод: POST")
            logger.info(f"Заголовки:")
            logger.info(f"  Authorization: Bearer {self.token[:20]}...{self.token[-10:] if len(self.token) > 30 else ''}")
            logger.info(f"  Content-Type: {headers['Content-Type']}")
            logger.info(f"Тело запроса (JSON):")
            logger.info(json.dumps(payload, indent=2, ensure_ascii=False))
        
        start_time = time.time()
        try:
            response = await client.post(url, json=payload, headers=headers, timeout=300.0)
            response_time = time.time() - start_time
            
            # Подробное логирование ответа
            if self.verbose or request_num <= 3 or response.status_code != 200:
                logger.info(f"\nОтвет на запрос #{request_num}:")
                logger.info(f"  Статус код: {response.status_code}")
                logger.info(f"  Время ответа: {response_time:.2f} сек")
                logger.info(f"  Заголовки ответа:")
                for key, value in response.headers.items():
                    logger.info(f"    {key}: {value}")
                
                try:
                    response_data = response.json()
                    logger.info(f"  Тело ответа (JSON):")
                    logger.info(json.dumps(response_data, indent=2, ensure_ascii=False))
                except:
                    response_text = response.text
                    logger.info(f"  Тело ответа (текст, первые 500 символов):")
                    logger.info(response_text[:500])
                    if len(response_text) > 500:
                        logger.info(f"  ... (еще {len(response_text) - 500} символов)")
            
            if response.status_code == 200:
                data = response.json()
                story_id = data.get("id", "unknown")
                if self.verbose or request_num <= 3:
                    logger.info(f"✓ Запрос #{request_num} успешен. Story ID: {story_id}")
                return RequestResult(
                    success=True,
                    status_code=response.status_code,
                    response_time=response_time,
                    story_id=story_id
                )
            else:
                # Детальная обработка ошибок
                error_msg = f"HTTP {response.status_code}"
                error_details = {}
                
                try:
                    error_data = response.json()
                    error_msg = error_data.get("detail", error_data.get("message", error_msg))
                    error_details = error_data
                except:
                    error_text = response.text
                    error_msg = error_text[:200] if error_text else error_msg
                    error_details = {"raw_response": error_text}
                
                # Подробное логирование ошибки
                logger.error(f"\n✗ ОШИБКА в запросе #{request_num}:")
                logger.error(f"  Статус код: {response.status_code}")
                logger.error(f"  Сообщение об ошибке: {error_msg}")
                logger.error(f"  Детали ошибки:")
                logger.error(json.dumps(error_details, indent=2, ensure_ascii=False))
                logger.error(f"  Полный ответ (первые 1000 символов):")
                logger.error(response.text[:1000])
                
                return RequestResult(
                    success=False,
                    status_code=response.status_code,
                    response_time=response_time,
                    error=error_msg
                )
        except httpx.TimeoutException:
            response_time = time.time() - start_time
            logger.error(f"\n✗ ТАЙМАУТ в запросе #{request_num} после {response_time:.2f} сек")
            return RequestResult(
                success=False,
                status_code=0,
                response_time=response_time,
                error="Request timeout"
            )
        except httpx.HTTPError as e:
            response_time = time.time() - start_time
            logger.error(f"\n✗ HTTP ОШИБКА в запросе #{request_num}:")
            logger.error(f"  Тип ошибки: {type(e).__name__}")
            logger.error(f"  Сообщение: {str(e)}")
            return RequestResult(
                success=False,
                status_code=0,
                response_time=response_time,
                error=f"HTTP Error: {str(e)}"
            )
        except Exception as e:
            response_time = time.time() - start_time
            logger.error(f"\n✗ НЕОЖИДАННАЯ ОШИБКА в запросе #{request_num}:")
            logger.error(f"  Тип ошибки: {type(e).__name__}")
            logger.error(f"  Сообщение: {str(e)}")
            import traceback
            logger.error(f"  Трассировка:")
            logger.error(traceback.format_exc())
            return RequestResult(
                success=False,
                status_code=0,
                response_time=response_time,
                error=f"Exception: {str(e)}"
            )
    
    async def worker(self, client: httpx.AsyncClient, queue: asyncio.Queue, stop_event: asyncio.Event):
        """Воркер для выполнения запросов из очереди."""
        worker_id = id(asyncio.current_task())
        logger.debug(f"Воркер {worker_id} запущен")
        
        try:
            while not stop_event.is_set():
                try:
                    # Получаем задачу с таймаутом, чтобы периодически проверять stop_event
                    request_num = await asyncio.wait_for(queue.get(), timeout=0.1)
                    
                    result = await self.make_request(client, request_num)
                    self.results.append(result)
                    
                    # Обновляем статистику
                    self.stats.total_requests += 1
                    if result.success:
                        self.stats.successful_requests += 1
                    else:
                        self.stats.failed_requests += 1
                        if result.error:
                            self.stats.errors.append(result.error)
                    
                    self.stats.response_times.append(result.response_time)
                    self.stats.status_codes[result.status_code] = self.stats.status_codes.get(result.status_code, 0) + 1
                    
                    # Выводим прогресс каждые 10 запросов или при ошибках
                    if self.stats.total_requests % 10 == 0 or not result.success:
                        progress = (self.stats.total_requests / self.total_requests) * 100
                        print(f"\rПрогресс: {self.stats.total_requests}/{self.total_requests} ({progress:.1f}%) | "
                              f"Успешно: {self.stats.successful_requests} | "
                              f"Ошибок: {self.stats.failed_requests}", end="", flush=True)
                    
                    queue.task_done()
                except asyncio.TimeoutError:
                    # Таймаут - проверяем, нужно ли продолжать
                    continue
                except Exception as e:
                    logger.error(f"Ошибка при обработке задачи в воркере {worker_id}: {e}")
                    import traceback
                    logger.error(traceback.format_exc())
                    try:
                        queue.task_done()
                    except ValueError:
                        pass  # Игнорируем, если task_done() уже был вызван
            
            # Выводим финальный прогресс при завершении воркера
            print()  # Новая строка после прогресса
        except Exception as e:
            logger.error(f"Критическая ошибка в воркере {worker_id}: {e}")
            import traceback
            logger.error(traceback.format_exc())
        finally:
            logger.debug(f"Воркер {worker_id} завершен")
    
    async def run(self):
        """Запускает нагрузочное тестирование."""
        print(f"\n{'='*80}")
        print(f"Нагрузочное тестирование генератора историй")
        print(f"{'='*80}")
        print(f"URL: {self.base_url}")
        print(f"Тип истории: {self.story_type}")
        print(f"Язык: {self.language}")
        print(f"Длина истории: {self.story_length} минут")
        print(f"Тема: {'все по очереди (random)' if self.themes_mode else self.theme}")
        print(f"Child ID: {self.child_id}")
        if self.hero_id:
            print(f"Hero ID: {self.hero_id}")
        print(f"Параллельных запросов: {self.concurrent}")
        print(f"Всего запросов: {self.total_requests}")
        print(f"Подробное логирование: {'Включено' if self.verbose else 'Выключено (первые 3 запроса)'}")
        print(f"Токен (первые 20 символов): {self.token[:20]}...")
        print(f"{'='*80}\n")
        
        logger.info("Начало нагрузочного тестирования")
        logger.info(f"Конфигурация:")
        logger.info(f"  Base URL: {self.base_url}")
        logger.info(f"  Endpoint: /api/v1/stories/generate")
        logger.info(f"  Story type: {self.story_type}")
        logger.info(f"  Language: {self.language}")
        logger.info(f"  Story length: {self.story_length} минут")
        logger.info(f"  Theme: {'all (random per request)' if self.themes_mode else self.theme}")
        logger.info(f"  Child ID: {self.child_id}")
        if self.hero_id:
            logger.info(f"  Hero ID: {self.hero_id}")
        logger.info(f"  Concurrent requests: {self.concurrent}")
        logger.info(f"  Total requests: {self.total_requests}")
        logger.info(f"  Verbose logging: {self.verbose}")
        
        self.stats.start_time = time.time()
        
        # Создаем очередь задач
        queue = asyncio.Queue()
        logger.info(f"Добавление {self.total_requests} задач в очередь...")
        for i in range(self.total_requests):
            await queue.put(i + 1)
        
        logger.info(f"Очередь создана, задач: {queue.qsize()}")
        
        # Создаем HTTP клиент с настройками
        limits = httpx.Limits(max_keepalive_connections=20, max_connections=100)
        timeout = httpx.Timeout(300.0, connect=10.0)
        
        async with httpx.AsyncClient(limits=limits, timeout=timeout) as client:
            # Создаем событие для остановки воркеров
            stop_event = asyncio.Event()
            
            # Запускаем воркеров
            workers = [
                asyncio.create_task(self.worker(client, queue, stop_event))
                for _ in range(self.concurrent)
            ]
            
            logger.info(f"Запущено {len(workers)} воркеров")
            logger.info("Ожидание завершения всех запросов...")
            
            # Ждем завершения всех задач в очереди
            await queue.join()
            
            logger.info("Все задачи выполнены, отправка сигнала остановки воркерам...")
            
            # Отправляем сигнал остановки всем воркерам
            stop_event.set()
            
            # Ждем завершения всех воркеров с таймаутом
            try:
                await asyncio.wait_for(
                    asyncio.gather(*workers, return_exceptions=True),
                    timeout=10.0
                )
            except asyncio.TimeoutError:
                logger.warning("Таймаут при ожидании завершения воркеров, отмена задач...")
                # Отменяем незавершенные задачи
                for worker in workers:
                    if not worker.done():
                        worker.cancel()
                # Ждем еще немного для завершения отмененных задач
                try:
                    await asyncio.wait_for(
                        asyncio.gather(*workers, return_exceptions=True),
                        timeout=5.0
                    )
                except asyncio.TimeoutError:
                    logger.warning("Некоторые воркеры не завершились вовремя")
            
            logger.info("Все воркеры завершены")
        
        self.stats.end_time = time.time()
        logger.info(f"Тестирование завершено за {self.stats.duration:.2f} секунд")
    
    def print_stats(self):
        """Выводит статистику тестирования."""
        print(f"\n{'='*80}")
        print(f"РЕЗУЛЬТАТЫ ТЕСТИРОВАНИЯ")
        print(f"{'='*80}\n")
        
        print(f"Общая статистика:")
        print(f"  Всего запросов:        {self.stats.total_requests}")
        print(f"  Успешных запросов:     {self.stats.successful_requests}")
        print(f"  Неудачных запросов:    {self.stats.failed_requests}")
        print(f"  Процент успеха:        {self.stats.success_rate:.2f}%")
        print(f"  Длительность теста:    {self.stats.duration:.2f} секунд")
        print(f"  Запросов в секунду:    {self.stats.requests_per_second:.2f}")
        
        print(f"\nВремя ответа:")
        print(f"  Среднее:               {self.stats.avg_response_time:.2f} сек")
        print(f"  Медиана:               {self.stats.median_response_time:.2f} сек")
        print(f"  Минимум:               {self.stats.min_response_time:.2f} сек")
        print(f"  Максимум:              {self.stats.max_response_time:.2f} сек")
        print(f"  95-й перцентиль:       {self.stats.p95_response_time:.2f} сек")
        print(f"  99-й перцентиль:       {self.stats.p99_response_time:.2f} сек")
        
        if self.stats.status_codes:
            print(f"\nКоды ответов:")
            for status_code, count in sorted(self.stats.status_codes.items()):
                percentage = (count / self.stats.total_requests) * 100
                print(f"  {status_code}: {count} ({percentage:.1f}%)")
        
        if self.stats.errors:
            print(f"\nОшибки (первые 20):")
            error_counts: Dict[str, int] = {}
            for error in self.stats.errors:
                # Обрезаем длинные сообщения для статистики
                error_key = error[:200] if len(error) > 200 else error
                error_counts[error_key] = error_counts.get(error_key, 0) + 1
            
            for error, count in sorted(error_counts.items(), key=lambda x: x[1], reverse=True)[:20]:
                print(f"  [{count}x] {error}")
                if len(error) > 200:
                    print(f"      ... (полное сообщение в логах выше)")
        
        print(f"\n{'='*80}\n")
        
        # Сохраняем детальные результаты в файл
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        results_file = f"load_test_results_{timestamp}.json"
        
        results_data = {
            "test_config": {
                "base_url": self.base_url,
                "story_type": self.story_type,
                "language": self.language,
                "story_length": self.story_length,
                "theme": "all (random)" if self.themes_mode else self.theme,
                "concurrent": self.concurrent,
                "total_requests": self.total_requests
            },
            "stats": {
                "total_requests": self.stats.total_requests,
                "successful_requests": self.stats.successful_requests,
                "failed_requests": self.stats.failed_requests,
                "success_rate": self.stats.success_rate,
                "duration": self.stats.duration,
                "requests_per_second": self.stats.requests_per_second,
                "avg_response_time": self.stats.avg_response_time,
                "median_response_time": self.stats.median_response_time,
                "min_response_time": self.stats.min_response_time,
                "max_response_time": self.stats.max_response_time,
                "p95_response_time": self.stats.p95_response_time,
                "p99_response_time": self.stats.p99_response_time,
                "status_codes": self.stats.status_codes
            },
            "results": [
                {
                    "success": r.success,
                    "status_code": r.status_code,
                    "response_time": r.response_time,
                    "error": r.error,
                    "story_id": r.story_id
                }
                for r in self.results
            ]
        }
        
        with open(results_file, 'w', encoding='utf-8') as f:
            json.dump(results_data, f, indent=2, ensure_ascii=False)
        
        print(f"Детальные результаты сохранены в файл: {results_file}")


async def main():
    """Главная функция."""
    parser = argparse.ArgumentParser(
        description="Нагрузочное тестирование генератора историй",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
ВАЖНО: Токен авторизации
  Токен --token должен быть JWT access_token от Supabase Auth.
  Это токен, который пользователь получает при авторизации через Supabase.
  
  Как получить токен:
  1. Авторизуйтесь в приложении через Supabase
  2. Получите access_token из сессии (session.access_token)
  3. Используйте этот токен для тестирования
  
  Или через Supabase CLI/API:
  - Используйте Supabase Auth API для получения токена
  - Или экспортируйте токен из браузера (DevTools -> Application -> Cookies)

Примеры использования:

  # Базовый тест (токен будет получен автоматически)
  python load_test.py --url https://api.example.com --child-id CHILD_UUID

  # Базовый тест с указанием токена вручную
  python load_test.py --url https://api.example.com --token YOUR_SUPABASE_ACCESS_TOKEN --child-id CHILD_UUID

  # Тест с большей нагрузкой
  python load_test.py --url https://api.example.com --child-id CHILD_UUID \\
      --concurrent 20 --requests 200

  # Тест генерации истории с героем
  python load_test.py --url https://api.example.com --child-id CHILD_UUID \\
      --story-type hero --hero-id HERO_UUID

  # Тест генерации комбинированной истории
  python load_test.py --url https://api.example.com --child-id CHILD_UUID \\
      --story-type combined --hero-id HERO_UUID

  # Использование другого пользователя для получения токена
  python load_test.py --url https://api.example.com --child-id CHILD_UUID \\
      --email user@example.com --password mypassword

  # С подробным логированием всех запросов (для отладки)
  python load_test.py --url https://api.example.com --child-id CHILD_UUID --verbose

  # Тест с одним запросом и подробным логированием (для диагностики ошибок)
  python load_test.py --url https://api.example.com --child-id CHILD_UUID \\
      --requests 1 --verbose

  # Тест с определённой темой (space, fantasy, pirates и т.д.)
  python load_test.py --url https://api.example.com --child-id CHILD_UUID --theme space

  # Тест со случайной темой для каждого запроса (все темы: adventure, space, fantasy, ...)
  python load_test.py --url https://api.example.com --child-id CHILD_UUID --theme all
        """
    )
    
    parser.add_argument(
        "--url",
        required=True,
        help="Базовый URL API сервера (например, https://api.example.com)"
    )
    
    parser.add_argument(
        "--token",
        help="JWT access token от Supabase Auth (access_token из сессии пользователя). "
             "Если не указан, будет попытка получить токен автоматически через get_token.py"
    )
    
    parser.add_argument(
        "--email",
        default="i@i.i",
        help="Email для автоматического получения токена (по умолчанию: i@i.i)"
    )
    
    parser.add_argument(
        "--password",
        default="12345678",
        help="Пароль для автоматического получения токена (по умолчанию: 12345678)"
    )
    
    parser.add_argument(
        "--child-id",
        required=True,
        help="UUID ребенка для генерации историй"
    )
    
    parser.add_argument(
        "--hero-id",
        help="UUID героя (требуется для story-type hero или combined)"
    )
    
    parser.add_argument(
        "--story-type",
        choices=["child", "hero", "combined"],
        default="child",
        help="Тип истории (по умолчанию: child)"
    )
    
    parser.add_argument(
        "--language",
        choices=["en", "ru"],
        default="en",
        help="Язык истории (по умолчанию: en)"
    )
    
    parser.add_argument(
        "--story-length",
        type=int,
        default=4,
        help="Длина истории в минутах (по умолчанию: 5)"
    )
    
    parser.add_argument(
        "--theme",
        choices=THEMES + ["all"],
        default="adventure",
        help="Тема истории: adventure, space, fantasy, pirates, dinosaurs, magic, ocean, forest, robots, fairies, knights, animals; 'all' — случайная тема для каждого запроса (по умолчанию: adventure)"
    )
    
    parser.add_argument(
        "--concurrent",
        type=int,
        default=8,
        help="Количество параллельных запросов (по умолчанию: 8)"
    )
    
    parser.add_argument(
        "--requests",
        type=int,
        default=80,
        help="Общее количество запросов (по умолчанию: 80)"
    )
    
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Подробное логирование всех запросов и ответов"
    )
    
    args = parser.parse_args()
    
    # Валидация аргументов
    if args.story_type in ["hero", "combined"] and not args.hero_id:
        parser.error(f"Для story-type '{args.story_type}' требуется указать --hero-id")
    
    # Получаем токен, если не указан
    token = args.token
    if not token:
        print("Токен не указан, пытаюсь получить автоматически...")
        try:
            from supabase import create_client
            supabase_url = os.getenv("SUPABASE_URL")
            supabase_key = os.getenv("SUPABASE_KEY")
            
            if not supabase_url or not supabase_key:
                parser.error(
                    "Не удалось получить токен автоматически. "
                    "Убедитесь, что в .env файле указаны SUPABASE_URL и SUPABASE_KEY, "
                    "или укажите токен вручную через --token"
                )
            
            supabase = create_client(supabase_url, supabase_key)
            response = supabase.auth.sign_in_with_password({
                "email": args.email,
                "password": args.password
            })
            
            if response.user is None or response.session is None:
                parser.error("Не удалось авторизоваться в Supabase. Проверьте учетные данные.")
            
            token = response.session.access_token
            print(f"✓ Токен успешно получен для пользователя {args.email}")
        except Exception as e:
            parser.error(f"Ошибка при получении токена: {e}")
    
    # Создаем тестер и запускаем тест
    themes_mode = args.theme == "all"
    theme = None if themes_mode else args.theme
    tester = LoadTester(
        base_url=args.url,
        token=token,
        child_id=args.child_id,
        hero_id=args.hero_id,
        story_type=args.story_type,
        language=args.language,
        story_length=args.story_length,
        theme=theme or "adventure",
        themes_mode=themes_mode,
        concurrent=args.concurrent,
        total_requests=args.requests,
        verbose=args.verbose
    )
    
    try:
        await tester.run()
        tester.print_stats()
    except KeyboardInterrupt:
        print("\n\nТестирование прервано пользователем")
        tester.print_stats()
    except Exception as e:
        print(f"\n\nОшибка при выполнении теста: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    asyncio.run(main())
