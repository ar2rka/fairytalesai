Создай детскую сказку на ночь с двумя главными героями:

Ребенок:
- Имя: {{ child.name }}
- Возраст: {{ child.age_category | format_age_category(language) }}
- Пол: {{ child.gender | translate_gender(language) }}
- Интересы: {{ child.interests | translate_interests(language) | join(', ') }}

Герой:
- Имя: {{ hero.name }}
- Возраст: {{ hero.age }}
- Пол: {{ hero.gender | translate_gender(language) }}
- Внешность: {{ hero.appearance }}
- Черты характера: {{ hero.personality_traits | join(', ') }}
- Сильные стороны: {{ hero.strengths | join(', ') }}

Отношения: {{ relationship }}
- Тема / тип истории: {{ theme | translate_theme(language) }}

{% if parent_story %}
Предыдущая история:
Заголовок: {{ parent_story.title }}
Содержание: {% if parent_story.summary %}{{ parent_story.summary }}{% else %}{{ parent_story.content | truncate(500) if parent_story.content else "" }}{% endif %}

Эта история является продолжением предыдущей. Создай естественное продолжение, которое развивает сюжет и персонажей из предыдущей истории. Начни новую историю там, где закончилась предыдущая, и продолжай приключения.
{% endif %}

Сказка должна содержать нравственный урок о "{{ moral | translate_moral(language) }}".
Сделай сказку приблизительно {{ word_count }} слов длинной.
Включи имена обоих персонажей в сказке и покажи, как они работают вместе.
Закончи сказку четким сообщением о нравственном уроке.
Напиши сказку на русском языке.

ВАЖНО: Начни сразу со сказки. Не включай вводный текст, объяснения или метаданные. Просто напиши заголовок и содержание сказки.
