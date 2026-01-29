Создай детскую сказку на ночь со следующими характеристиками:
- Имя: {{ child.name }}
- Возраст: {{ child.age_category | format_age_category(language) }}
- Пол: {{ child.gender | translate_gender(language) }}
- Интересы: {{ child.interests | translate_interests(language) | join(', ') }}
- Тема / тип истории: {{ theme | translate_theme(language) }}

{% if parent_story %}
Предыдущая история:
Заголовок: {{ parent_story.title }}
Содержание: {% if parent_story.summary %}{{ parent_story.summary }}{% else %}{{ parent_story.content | truncate(500) if parent_story.content else "" }}{% endif %}

Эта история является продолжением предыдущей. Создай естественное продолжение, которое развивает сюжет и персонажей из предыдущей истории. Начни новую историю там, где закончилась предыдущая, и продолжай приключения.
{% endif %}

Сказка должна содержать нравственный урок о "{{ moral | translate_moral(language) }}".
Сделай сказку приблизительно {{ word_count }} слов длинной.
Включи имя ребенка как главного героя сказки.
Закончи сказку четким сообщением о нравственном уроке.
Напиши сказку на русском языке.

ВАЖНО: Начни сразу со сказки. Не включай вводный текст, объяснения или метаданные. Просто напиши заголовок и содержание сказки.
