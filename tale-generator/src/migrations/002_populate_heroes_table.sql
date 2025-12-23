-- Migration: Populate heroes table
-- Description: Insert predefined heroes into the heroes table

-- First, clear any existing data to ensure we have a clean state
DELETE FROM tales.heroes;

-- Insert English heroes
INSERT INTO tales.heroes (name, gender, appearance, personality_traits, interests, strengths, language) VALUES
(
    'Captain Wonder',
    'male',
    'Wears a blue cape with a golden star, has bright eyes and a confident smile',
    ARRAY['brave', 'kind', 'curious', 'determined'],
    ARRAY['exploring space', 'helping others', 'solving mysteries'],
    ARRAY['flying', 'super strength', 'problem-solving'],
    'en'
),
(
    'Starlight',
    'female',
    'Glows with a gentle light, has silver hair and wears a star-themed outfit',
    ARRAY['wise', 'compassionate', 'creative', 'adventurous'],
    ARRAY['stargazing', 'music', 'ancient history'],
    ARRAY['light manipulation', 'teleportation', 'healing'],
    'en'
);

-- Insert Russian heroes
INSERT INTO tales.heroes (name, gender, appearance, personality_traits, interests, strengths, language) VALUES
(
    'Капитан Чудо',
    'female',
    'Носит красный плащ с серебряной звездой, у неё карие глаза и добрый взгляд',
    ARRAY['храбрая', 'добрая', 'любознательная', 'настойчивая'],
    ARRAY['путешествия по космосу', 'помощь другим', 'разгадывание загадок'],
    ARRAY['летает', 'суперсила', 'решение проблем'],
    'ru'
),
(
    'Ледяная Волшебница',
    'female',
    'Носит голубое платье, украшенное снежинками, с белыми волосами и голубыми глазами',
    ARRAY['спокойная', 'умная', 'элегантная', 'могущественная'],
    ARRAY['зимние пейзажи', 'магия', 'древние руны'],
    ARRAY['управление льдом', 'телекинез', 'невидимость'],
    'ru'
);