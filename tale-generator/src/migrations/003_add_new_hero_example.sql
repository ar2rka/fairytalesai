-- Migration: Add new hero example
-- Description: Example of how to add a new hero to the heroes table

-- This is an example of how to add a new hero to the existing heroes table
-- Uncomment the following lines to add a new hero

/*
INSERT INTO heroes (name, gender, appearance, personality_traits, interests, strengths, language) VALUES
(
    'New Hero Name',
    'male/female/other',
    'Description of the hero''s appearance',
    ARRAY['trait1', 'trait2', 'trait3'],
    ARRAY['interest1', 'interest2', 'interest3'],
    ARRAY['strength1', 'strength2', 'strength3'],
    'en/ru'
);
*/