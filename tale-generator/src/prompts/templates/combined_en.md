Create a bedtime story featuring both a child and a hero together:

Child Character:
- Name: {{ child.name }}
- Age: {{ child.age_category | format_age_category(language) }}
- Gender: {{ child.gender | translate_gender(language) }}
- Interests: {{ child.interests | translate_interests(language) | join(', ') }}

Hero Character:
- Name: {{ hero.name }}
- Age: {{ hero.age }}
- Gender: {{ hero.gender | translate_gender(language) }}
- Appearance: {{ hero.appearance }}
- Personality Traits: {{ hero.personality_traits | join(', ') }}
- Strengths: {{ hero.strengths | join(', ') }}

Relationship: {{ relationship }}
- Story theme / type: {{ theme | translate_theme(language) }}

{% if parent_story %}
Previous Story:
Title: {{ parent_story.title }}
Content: {% if parent_story.summary %}{{ parent_story.summary }}{% else %}{{ parent_story.content | truncate(500) if parent_story.content else "" }}{% endif %}

This story is a continuation of the previous one. Create a natural continuation that develops the plot and characters from the previous story. Start the new story where the previous one ended and continue the adventures.
{% endif %}

The story should focus on the moral value of "{{ moral | translate_moral(language) }}".
Make the story approximately {{ word_count }} words long.
Include both characters' names throughout the story and show how they work together.
End the story with a clear message about the moral value.
Write the story in English.

IMPORTANT: Start directly with the story. Do not include any introductory text, explanations, or metadata. Just write the story title and content.
