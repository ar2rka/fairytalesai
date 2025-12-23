# Prompt Module Refactoring Design

## 1. Purpose and Context

### 1.1 Current Situation
The prompt generation logic in `src/prompts.py` is monolithic with separate template methods for heroic stories and child-based stories. The current structure does not support composable prompt building or combined character types (e.g., hero + child together).

### 1.2 Design Goals
Transform the prompt system into a modular, composable architecture that enables:
- Building prompts from reusable components
- Supporting multiple character configurations (child-only, hero-only, hero+child)
- Maintaining language-specific customization
- Preserving backward compatibility with existing code
- Enabling future extensibility for new character types and prompt variations

## 2. Proposed Module Structure

### 2.1 Directory Organization
```
src/
  prompts/
    __init__.py
    character_types/
      __init__.py
      base.py
      child_character.py
      hero_character.py
      combined_character.py
    components/
      __init__.py
      base_component.py
      moral_component.py
      length_component.py
      ending_component.py
      language_component.py
      character_description_component.py
    builders/
      __init__.py
      prompt_builder.py
      english_prompt_builder.py
      russian_prompt_builder.py
    legacy.py
```

### 2.2 Module Responsibilities

#### Character Types Module (`character_types/`)
Defines different character configurations that can be used in stories.

**Base Character Interface** (`base.py`):
- Defines common character attributes (name, age, gender)
- Provides interface for character data extraction
- Supports validation and serialization

**Child Character** (`child_character.py`):
- Represents a child protagonist
- Contains attributes: name, age, gender, interests
- Supports optional freeform text description for additional context

**Hero Character** (`hero_character.py`):
- Represents a heroic protagonist
- Contains attributes: name, age, gender, appearance, personality_traits, strengths, interests, language
- Supports optional freeform text description for additional context or backstory

**Combined Character** (`combined_character.py`):
- Represents both hero and child together in the story
- Enables stories where a child meets or teams up with a hero
- Contains both child and hero instances
- Provides merged interest lists and combined character descriptions

#### Components Module (`components/`)
Provides reusable prompt building blocks that can be assembled in different configurations.

**Base Component** (`base_component.py`):
- Abstract interface for prompt components
- Defines `render()` method that returns a prompt fragment
- Language-aware rendering support

**Moral Component** (`moral_component.py`):
- Generates moral/lesson instructions
- Supports translation of moral values
- Language-specific phrasing

**Length Component** (`length_component.py`):
- Generates story length instructions
- Converts reading time to word count
- Adjusts for language-specific reading speeds

**Ending Component** (`ending_component.py`):
- Generates ending requirements
- Language-specific conclusion styles

**Language Component** (`language_component.py`):
- Specifies target language
- Provides language-specific writing instructions

**Character Description Component** (`character_description_component.py`):
- Renders character information based on character type
- Supports child, hero, and combined character formats
- Language-specific field formatting
- Includes optional freeform description if provided
- Merges structured attributes with custom description text

### 2.3 Builders Module (`builders/`)

#### Prompt Builder (`prompt_builder.py`)
Central orchestrator that assembles components into complete prompts.

**Key Responsibilities:**
- Accepts character type and configuration parameters
- Selects appropriate components based on language and character type
- Assembles components in correct order
- Validates completeness before rendering
- Returns final prompt string

**Builder Interface:**
```
PromptBuilder:
  - set_character(character: CharacterType) -> self
  - set_moral(moral: str) -> self
  - set_language(language: Language) -> self
  - set_story_length(minutes: int) -> self
  - add_component(component: Component) -> self
  - build() -> str
```

#### Language-Specific Builders
- `EnglishPromptBuilder`: Pre-configured for English prompts
- `RussianPromptBuilder`: Pre-configured for Russian prompts

These builders extend the base `PromptBuilder` with language-specific:
- Component selections
- Default templates
- Translation mappings
- Cultural adjustments

### 2.4 Legacy Compatibility Module (`legacy.py`)
Maintains backward compatibility with existing code that imports from `src/prompts.py`.

**Provided Functions:**
- `get_heroic_story_prompt(hero, moral, language, story_length)`
- `get_child_story_prompt(child, moral, language, story_length)`
- `get_story_prompt(child, moral, language, story_length)`

**Implementation Approach:**
- Wraps new modular system
- Translates legacy data structures to new character types
- Delegates to appropriate builder
- Returns results in expected format

## 3. Character Type Configurations

### 3.0 Freeform Description Feature

**Purpose:**
Provides flexibility to add custom, unstructured text descriptions for both child and hero characters beyond the predefined structured fields.

**Use Cases:**
- **Personality Details:** Specific character quirks not captured by personality_traits list (e.g., "loves to sing while walking", "always wears a lucky bracelet")
- **Backstory Elements:** Brief context about the character's history (e.g., "recently moved to a new city", "dreams of becoming an astronaut")
- **Physical Details:** Additional appearance notes for heroes or children (e.g., "has a dimple when smiling", "wears glasses with rainbow frames")
- **Preferences and Habits:** Daily routines or favorite things (e.g., "never goes anywhere without teddy bear Max", "loves hot chocolate before bed")
- **Emotional Context:** Current feelings or situations (e.g., "feeling nervous about starting school", "missing grandparents who live far away")

**Integration Strategy:**
The Character Description Component incorporates freeform description by:
1. Rendering all structured fields first (name, age, gender, interests, etc.)
2. Appending freeform description as an additional context field
3. Language-aware formatting ("Additional Context:" for English, "Дополнительно:" for Russian)
4. Skipping the description section if field is empty or null

**Format in Prompt:**
```
English Example:
- Name: Emma
- Age: 7
- Gender: female
- Interests: unicorns, fairies, princesses
- Additional Context: Emma recently adopted a rescue puppy named Sparkle and loves reading stories to him every night. She's very shy around new people but becomes talkative when discussing her favorite animals.

Russian Example:
- Имя: Аня
- Возраст: 6
- Пол: девочка
- Интересы: котята, цветы, танцы
- Дополнительно: Аня обожает рисовать и мечтает стать художницей. У неё есть младший брат, о котором она заботится как настоящая старшая сестра.
```

### 3.1 Child-Only Configuration
**Use Case:** Story featuring the child as the main protagonist

**Character Components:**
- Child name, age, gender
- Child interests
- Optional freeform description (personality, quirks, backstory, preferences)

**Prompt Structure:**
- Character introduction focusing on child
- Interests-driven plot suggestions
- Age-appropriate narrative guidance
- Additional description integrated into character context

### 3.2 Hero-Only Configuration
**Use Case:** Story featuring a predefined hero character

**Character Components:**
- Hero name, age, gender
- Hero appearance description
- Personality traits
- Strengths and abilities
- Interests
- Optional freeform description (backstory, motivation, unique characteristics)

**Prompt Structure:**
- Detailed hero characterization
- Heroic journey narrative hints
- Character-driven plot suggestions
- Additional description woven into hero profile

### 3.3 Hero + Child Configuration
**Use Case:** Story where child meets or interacts with a hero character

**Character Components:**
- Both child and hero profiles
- Relationship context (child meets hero, child becomes hero's companion, etc.)
- Combined interests for plot development
- Optional descriptions for both characters

**Prompt Structure:**
- Dual character introduction
- Interaction dynamics specification
- Shared adventure narrative guidance
- Dual perspective considerations
- Additional descriptions enriching both character portrayals

## 4. Component Assembly Flow

### 4.1 Builder Usage Pattern

**Example: Child-Only Story in English**
```
Workflow:
1. Create EnglishPromptBuilder instance
2. Set character type to ChildCharacter(
     name="Emma", 
     age=7, 
     gender="female", 
     interests=["unicorns", "fairies"],
     description="Emma is very imaginative and loves creating her own fairy tales. She has a special notebook where she draws all her story ideas."
   )
3. Set moral value to "kindness"
4. Set story length to 5 minutes
5. Builder automatically selects components:
   - CharacterDescriptionComponent (child format, includes freeform description)
   - MoralComponent (English)
   - LengthComponent (English, 750 words)
   - EndingComponent (English)
   - LanguageComponent (English)
6. Call build() to assemble final prompt
```

**Example: Hero + Child Story in Russian**
```
Workflow:
1. Create RussianPromptBuilder instance
2. Set character type to CombinedCharacter(
     child=ChildCharacter(
       name="Аня", 
       age=6, 
       gender="female", 
       interests=["котята", "цветы"],
       description="Аня очень добрая и всегда помогает младшим детям в детском саду."
     ),
     hero=HeroCharacter(
       name="Капитан Чудо", 
       ...,
       description="Капитан Чудо защищает город уже много лет и известен своей мудростью."
     )
   )
3. Set moral value to "bravery"
4. Set story length to 5 minutes
5. Builder automatically selects components:
   - CharacterDescriptionComponent (combined format, Russian, both descriptions included)
   - MoralComponent (Russian, translated moral)
   - LengthComponent (Russian, 750 words)
   - EndingComponent (Russian)
   - LanguageComponent (Russian)
6. Call build() to assemble final prompt with both characters and their descriptions
```

### 4.2 Component Rendering Order
1. Character Description Component (introduces protagonists)
2. Moral Component (defines story theme)
3. Length Component (sets narrative scope)
4. Character Instruction (name inclusion requirement)
5. Ending Component (conclusion requirements)
6. Language Component (target language specification)

## 5. Data Structures

### 5.1 Character Type Definitions

**BaseCharacter Interface:**
| Attribute | Type | Description |
|-----------|------|-------------|
| name | string | Character name |
| age | integer | Character age |
| gender | string | Character gender |
| get_description() | method | Returns formatted description for prompts |

**ChildCharacter:**
| Attribute | Type | Description |
|-----------|------|-------------|
| name | string | Child's name |
| age | integer | Child's age (1-18) |
| gender | string | Child's gender |
| interests | list[string] | Child's interests and hobbies |
| description | string (optional) | Additional freeform text description of the child |

**HeroCharacter:**
| Attribute | Type | Description |
|-----------|------|-------------|
| name | string | Hero's name |
| age | integer | Hero's age |
| gender | string | Hero's gender |
| appearance | string | Physical description |
| personality_traits | list[string] | Character traits |
| strengths | list[string] | Abilities and powers |
| interests | list[string] | Hero's interests |
| language | Language | Hero's language context |
| description | string (optional) | Additional freeform text description of the hero |

**CombinedCharacter:**
| Attribute | Type | Description |
|-----------|------|-------------|
| child | ChildCharacter | Child protagonist |
| hero | HeroCharacter | Hero protagonist |
| relationship | string | How they interact (optional) |
| get_merged_interests() | method | Combines interests from both |

### 5.2 Component Interface

**Component Base Structure:**
| Method | Returns | Description |
|--------|---------|-------------|
| render(context) | string | Generates prompt fragment |
| validate(context) | boolean | Checks if component can render |
| get_dependencies() | list[ComponentType] | Required components |

**Component Context:**
| Field | Type | Description |
|-------|------|-------------|
| character | CharacterType | Character(s) in the story |
| moral | string | Moral value |
| language | Language | Target language |
| story_length | integer | Story length in minutes |
| word_count | integer | Calculated word count |

## 6. Migration Strategy

### 6.1 Phase 1: Create New Module Structure
- Create directory structure
- Implement base classes and interfaces
- Build character type classes
- Develop component classes
- Implement builder classes

### 6.2 Phase 2: Legacy Compatibility Layer
- Create `legacy.py` with wrapper functions
- Update `src/prompts.py` to import from legacy module
- Ensure existing code continues to work unchanged
- Add deprecation warnings for future transition

### 6.3 Phase 3: Internal Adoption
- Update `PromptService` in domain layer to use new builders
- Modify use cases to leverage new character types
- Add support for combined character stories in API

### 6.4 Phase 4: Deprecation
- Mark old functions as deprecated
- Update documentation with new usage patterns
- Provide migration guide for external consumers

## 7. Extension Points

### 7.1 Adding New Character Types
To add a new character configuration (e.g., "Animal Character", "Historical Figure"):
1. Create new class extending `BaseCharacter`
2. Define character-specific attributes
3. Implement `get_description()` method
4. Update `CharacterDescriptionComponent` to handle new type
5. Add builder configuration if needed

### 7.2 Adding New Components
To add new prompt elements (e.g., "Setting Component", "Conflict Component"):
1. Create new class extending `BaseComponent`
2. Implement `render(context)` method
3. Define language-specific variations
4. Update builders to include component where appropriate

### 7.3 Adding New Languages
To support additional languages:
1. Create language-specific builder class
2. Implement translation mappings for morals, genders, interests
3. Customize component rendering for language nuances
4. Update `PromptFactory` to include new language

## 8. Quality Considerations

### 8.1 Validation Requirements
- Character data completeness verification before prompt generation
- Language-moral value mapping validation
- Word count calculation accuracy
- Component dependency satisfaction checks

### 8.2 Error Handling Strategy
- Missing required fields trigger clear validation errors
- Unsupported language defaults to English with warning
- Invalid character type raises descriptive exception
- Incomplete builder state prevents prompt generation

### 8.3 Testing Strategy
**Unit Tests:**
- Each character type validates and serializes correctly
- Each component renders proper prompt fragments
- Builders assemble components in correct order
- Legacy compatibility functions produce expected output

**Integration Tests:**
- End-to-end prompt generation for all character configurations
- Multi-language prompt generation accuracy
- Builder flexibility with custom component combinations

**Regression Tests:**
- Existing prompts remain unchanged with legacy compatibility layer
- Generated prompts maintain quality and structure

## 9. Dependencies and Integration

### 9.1 Internal Dependencies
- `src/models.py`: Language enum
- `src/domain/entities.py`: Child and Hero entity definitions
- `src/domain/value_objects.py`: Language, Gender value objects
- `src/domain/services/prompt_service.py`: Consumer of prompt builders

### 9.2 External API Impact
- No breaking changes to public API endpoints
- New optional parameters for combined character stories
- Backward compatible request/response formats

### 9.3 Database Considerations
- No database schema changes required
- Existing hero and child tables support all character types
- Combined character stories reference both child and hero records

## 10. Benefits and Trade-offs

### 10.1 Benefits
- **Flexibility:** Easy to create new character configurations without duplicating code
- **Maintainability:** Changes to prompt structure isolated to specific components
- **Testability:** Small, focused components easier to test independently
- **Extensibility:** New languages, character types, and components added without refactoring
- **Reusability:** Components shared across different prompt types
- **Clarity:** Clear separation of concerns between character data and prompt assembly

### 10.2 Trade-offs
- **Complexity:** More files and abstractions to understand initially
- **Overhead:** Simple prompts require more setup than monolithic approach
- **Migration Effort:** Requires careful transition planning to avoid breaking changes
- **Learning Curve:** Developers need to understand component composition pattern
