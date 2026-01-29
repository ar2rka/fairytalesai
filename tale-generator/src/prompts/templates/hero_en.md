Create a bedtime story featuring a heroic character with the following characteristics:
- Name: {{ hero.name }}
- Age: {{ hero.age }}
- Gender: {{ hero.gender | translate_gender(language) }}
- Appearance: {{ hero.appearance }}
- Personality Traits: {{ hero.personality_traits | join(', ') }}
- Strengths: {{ hero.strengths | join(', ') }}
- Interests: {{ hero.interests | join(', ') }}
- Story theme / type: {{ theme | translate_theme(language) }}

{% if parent_story %}
Previous Story:
Title: {{ parent_story.title }}
Content: {% if parent_story.summary %}{{ parent_story.summary }}{% else %}{{ parent_story.content | truncate(500) if parent_story.content else "" }}{% endif %}

This story is a continuation of the previous one. Create a natural continuation that develops the plot and characters from the previous story. Start the new story where the previous one ended and continue the adventures.
{% endif %}

The story should focus on the moral value of "{{ moral | translate_moral(language) }}".
Make the story approximately {{ word_count }} words long.
Include the hero's name as the main character in the story.
End the story with a clear message about the moral value.
Write the story in English.

IMPORTANT: Start directly with the story. Do not include any introductory text, explanations, or metadata. Just write the story title and content.
