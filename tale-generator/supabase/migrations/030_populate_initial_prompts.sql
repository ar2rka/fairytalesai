-- Migration 030: Populate initial prompts from existing component-based system
-- Description: Convert existing prompt components to Jinja templates in database

-- English Child Story Prompts
INSERT INTO tales.prompts (priority, language, story_type, prompt_text, description, is_active) VALUES
(1, 'en', 'child', 
'Create a bedtime story for a child with the following characteristics:
- Name: {{ child.name }}
- Age: {{ child.age_category | format_age_category(language) }}
- Gender: {{ child.gender | translate_gender(language) }}
- Interests: {{ child.interests | translate_interests(language) | join(", ") }}
{% if child.description %}
- Additional Context: {{ child.description }}
{% endif %}',
'Character description for English child stories', true),

(2, 'en', 'child',
'The story should focus on the moral value of "{{ moral | translate_moral(language) }}" and be appropriate for children aged {{ child.age_category | format_age_category(language) }}.',
'Moral instruction for English child stories', true),

(3, 'en', NULL,
'Make the story engaging, imaginative, and approximately {{ word_count }} words long.',
'Length instruction (universal)', true),

(4, 'en', 'child',
'Include the child''s name as the main character in the story.
End the story with a clear message about the moral value.',
'Ending instruction for English child stories', true),

(5, 'en', NULL,
'Write the story in English.',
'Language instruction for English', true),

(6, 'en', NULL,
'{% if parent_story %}
Previous Story:
Title: {{ parent_story.title }}
Content: {% if parent_story.summary %}{{ parent_story.summary }}{% else %}{{ parent_story.content | truncate(500) if parent_story.content else "" }}{% endif %}

This story is a continuation of the previous one. Create a natural continuation that develops the plot and characters from the previous story. Start the new story where the previous one ended and continue the adventures.
{% endif %}',
'Continuation section (universal, conditional)', true);

-- Russian Child Story Prompts
INSERT INTO tales.prompts (priority, language, story_type, prompt_text, description, is_active) VALUES
(1, 'ru', 'child',
'Создай детскую сказку на ночь со следующими характеристиками:
- Имя: {{ child.name }}
- Возраст: {{ child.age_category | format_age_category(language) }}
- Пол: {{ child.gender | translate_gender(language) }}
- Интересы: {{ child.interests | translate_interests(language) | join(", ") }}
{% if child.description %}
- Дополнительно: {{ child.description }}
{% endif %}',
'Описание персонажа для русских детских историй', true),

(2, 'ru', 'child',
'Сказка должна содержать нравственный урок о "{{ moral | translate_moral(language) }}" и быть подходящей для детей в возрасте {{ child.age_category | format_age_category(language) }}.',
'Нравственный урок для русских детских историй', true),

(3, 'ru', NULL,
'Сделай сказку увлекательной, воображаемой и приблизительно {{ word_count }} слов длинной.',
'Инструкция по длине (универсальная)', true),

(4, 'ru', 'child',
'Включи имя ребенка как главного героя сказки.
Закончи сказку четким сообщением о нравственном уроке.',
'Инструкция по окончанию для русских детских историй', true),

(5, 'ru', NULL,
'Напиши сказку на русском языке.',
'Инструкция по языку для русского', true),

(6, 'ru', NULL,
'{% if parent_story %}
Предыдущая история:
Заголовок: {{ parent_story.title }}
Содержание: {% if parent_story.summary %}{{ parent_story.summary }}{% else %}{{ parent_story.content[:500] if parent_story.content else "" }}{% endif %}

Эта история является продолжением предыдущей. Создай естественное продолжение, которое развивает сюжет и персонажей из предыдущей истории. Начни новую историю там, где закончилась предыдущая, и продолжай приключения.
{% endif %}',
'Секция продолжения (универсальная, условная)', true);

-- English Hero Story Prompts
INSERT INTO tales.prompts (priority, language, story_type, prompt_text, description, is_active) VALUES
(1, 'en', 'hero',
'Create a bedtime story featuring a heroic character with the following characteristics:
- Name: {{ hero.name }}
- Age: {{ hero.age }}
- Gender: {{ hero.gender | translate_gender(language) }}
- Appearance: {{ hero.appearance }}
- Personality Traits: {{ hero.personality_traits | join(", ") }}
- Strengths: {{ hero.strengths | join(", ") }}
- Interests: {{ hero.interests | join(", ") }}
{% if hero.description %}
- Additional Context: {{ hero.description }}
{% endif %}',
'Character description for English hero stories', true),

(2, 'en', 'hero',
'The story should focus on the moral value of "{{ moral | translate_moral(language) }}" and be appropriate for children.',
'Moral instruction for English hero stories', true),

(4, 'en', 'hero',
'Include the hero''s name as the main character in the story.
End the story with a clear message about the moral value.',
'Ending instruction for English hero stories', true);

-- Russian Hero Story Prompts
INSERT INTO tales.prompts (priority, language, story_type, prompt_text, description, is_active) VALUES
(1, 'ru', 'hero',
'Создай детскую сказку на ночь о герое со следующими характеристиками:
- Имя: {{ hero.name }}
- Возраст: {{ hero.age }}
- Пол: {{ hero.gender | translate_gender(language) }}
- Внешность: {{ hero.appearance }}
- Черты характера: {{ hero.personality_traits | join(", ") }}
- Сильные стороны: {{ hero.strengths | join(", ") }}
- Интересы: {{ hero.interests | join(", ") }}
{% if hero.description %}
- Дополнительно: {{ hero.description }}
{% endif %}',
'Описание персонажа для русских историй о героях', true),

(2, 'ru', 'hero',
'Сказка должна содержать нравственный урок о "{{ moral | translate_moral(language) }}" и быть подходящей для детей.',
'Нравственный урок для русских историй о героях', true),

(4, 'ru', 'hero',
'Включи имя героя как главного персонажа сказки.
Закончи сказку четким сообщением о нравственном уроке.',
'Инструкция по окончанию для русских историй о героях', true);

-- English Combined Story Prompts
INSERT INTO tales.prompts (priority, language, story_type, prompt_text, description, is_active) VALUES
(1, 'en', 'combined',
'Create a bedtime story featuring both a child and a hero together:

Child Character:
- Name: {{ child.name }}
- Age: {{ child.age_category | format_age_category(language) }}
- Gender: {{ child.gender | translate_gender(language) }}
- Interests: {{ child.interests | translate_interests(language) | join(", ") }}
{% if child.description %}
- Additional Context: {{ child.description }}
{% endif %}

Hero Character:
- Name: {{ hero.name }}
- Age: {{ hero.age }}
- Gender: {{ hero.gender | translate_gender(language) }}
- Appearance: {{ hero.appearance }}
- Personality Traits: {{ hero.personality_traits | join(", ") }}
- Strengths: {{ hero.strengths | join(", ") }}
- Interests: {{ hero.interests | join(", ") }}
{% if hero.description %}
- Additional Context: {{ hero.description }}
{% endif %}
{% if relationship %}
Relationship: {{ relationship }}
{% endif %}',
'Character description for English combined stories', true),

(2, 'en', 'combined',
'The story should focus on the moral value of "{{ moral | translate_moral(language) }}" and be appropriate for children aged {{ child.age_category | format_age_category(language) }}.',
'Moral instruction for English combined stories', true),

(4, 'en', 'combined',
'Include both characters'' names throughout the story and show how they work together.
End the story with a clear message about the moral value.',
'Ending instruction for English combined stories', true);

-- Russian Combined Story Prompts
INSERT INTO tales.prompts (priority, language, story_type, prompt_text, description, is_active) VALUES
(1, 'ru', 'combined',
'Создай детскую сказку на ночь с двумя главными героями:

Ребенок:
- Имя: {{ child.name }}
- Возраст: {{ child.age_category | format_age_category(language) }}
- Пол: {{ child.gender | translate_gender(language) }}
- Интересы: {{ child.interests | translate_interests(language) | join(", ") }}
{% if child.description %}
- Дополнительно: {{ child.description }}
{% endif %}

Герой:
- Имя: {{ hero.name }}
- Возраст: {{ hero.age }}
- Пол: {{ hero.gender | translate_gender(language) }}
- Внешность: {{ hero.appearance }}
- Черты характера: {{ hero.personality_traits | join(", ") }}
- Сильные стороны: {{ hero.strengths | join(", ") }}
- Интересы: {{ hero.interests | join(", ") }}
{% if hero.description %}
- Дополнительно: {{ hero.description }}
{% endif %}
{% if relationship %}
Отношения: {{ relationship }}
{% endif %}',
'Описание персонажей для русских комбинированных историй', true),

(2, 'ru', 'combined',
'Сказка должна содержать нравственный урок о "{{ moral | translate_moral(language) }}" и быть подходящей для детей в возрасте {{ child.age_category | format_age_category(language) }}.',
'Нравственный урок для русских комбинированных историй', true),

(4, 'ru', 'combined',
'Включи имена обоих персонажей в сказке и покажи, как они работают вместе.
Закончи сказку четким сообщением о нравственном уроке.',
'Инструкция по окончанию для русских комбинированных историй', true);

-- Verify migration results
DO $$
DECLARE
    total_prompts INTEGER;
    en_prompts INTEGER;
    ru_prompts INTEGER;
    child_prompts INTEGER;
    hero_prompts INTEGER;
    combined_prompts INTEGER;
    universal_prompts INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_prompts FROM tales.prompts;
    SELECT COUNT(*) INTO en_prompts FROM tales.prompts WHERE language = 'en';
    SELECT COUNT(*) INTO ru_prompts FROM tales.prompts WHERE language = 'ru';
    SELECT COUNT(*) INTO child_prompts FROM tales.prompts WHERE story_type = 'child';
    SELECT COUNT(*) INTO hero_prompts FROM tales.prompts WHERE story_type = 'hero';
    SELECT COUNT(*) INTO combined_prompts FROM tales.prompts WHERE story_type = 'combined';
    SELECT COUNT(*) INTO universal_prompts FROM tales.prompts WHERE story_type IS NULL;
    
    RAISE NOTICE 'Migration 030 Summary:';
    RAISE NOTICE '  Total prompts created: %', total_prompts;
    RAISE NOTICE '  English prompts: %', en_prompts;
    RAISE NOTICE '  Russian prompts: %', ru_prompts;
    RAISE NOTICE '  Child story prompts: %', child_prompts;
    RAISE NOTICE '  Hero story prompts: %', hero_prompts;
    RAISE NOTICE '  Combined story prompts: %', combined_prompts;
    RAISE NOTICE '  Universal prompts: %', universal_prompts;
END $$;

