# Legacy Prompt System Removal from populate_stories.py

## Overview

Migrate the `populate_stories.py` script from using legacy prompt functions (`get_child_story_prompt`, `get_heroic_story_prompt` from `src/prompts.py`) to the new modular prompt builder system (`EnglishPromptBuilder`, `RussianPromptBuilder`) with character types (`ChildCharacter`, `HeroCharacter`).

## Background

The project has implemented a new modular prompt generation system that provides better separation of concerns, improved testability, and enhanced flexibility through a component-based architecture. However, the `populate_stories.py` script still relies on legacy compatibility functions that wrap the new system, preventing full migration and making it impossible to remove deprecated code.

### Current State

The script currently:
- Imports legacy functions from `src/prompts.py`: `get_child_story_prompt`, `get_heroic_story_prompt`
- Imports legacy data classes: `Child`, `Hero` from `src/prompts_old.py`
- Uses legacy helper class `Heroes` for accessing predefined heroes
- Converts between legacy and new character types through wrapper functions

### Target State

After migration, the script will:
- Import prompt builders directly: `EnglishPromptBuilder`, `RussianPromptBuilder`
- Import character types: `ChildCharacter`, `HeroCharacter`
- Import domain entities: `Child`, `Hero` from `src/domain/entities.py`
- Construct characters using new character type classes
- Use builder pattern for prompt generation

## Migration Strategy

### Phase 1: Update Imports

Remove legacy imports and replace with new system imports.

**Remove:**
- `from src.prompts import get_child_story_prompt, get_heroic_story_prompt, Child, Hero`
- `from src.prompts import Heroes` (predefined hero access)

**Add:**
- `from src.prompts.builders import EnglishPromptBuilder, RussianPromptBuilder`
- `from src.prompts.character_types import ChildCharacter, HeroCharacter`
- `from src.domain.entities import Child, Hero` (for domain entity types)

### Phase 2: Refactor Hero Retrieval Logic

The current hero retrieval logic uses:
1. Database retrieval via `SupabaseClient.get_all_heroes()` returning domain `Hero` entities
2. Fallback to legacy `Heroes` helper class for predefined heroes

**Transformation:**

The database retrieval already returns domain `Hero` entities with the correct structure. The conversion logic needs to map domain entities to character types.

| Current Approach | New Approach |
|-----------------|--------------|
| Convert database `HeroDB` to legacy `Hero` dataclass | Convert domain `Hero` entity to `HeroCharacter` |
| Fallback to `Heroes.get_english_hero_by_index()` | Fallback to database-only approach or remove fallback |
| Manual field mapping for age, name, gender, etc. | Direct mapping using domain entity attributes |

**Mapping Logic:**

Domain `Hero` entity attributes map directly to `HeroCharacter`:
- `name` → `name`
- `age` → `age`
- `gender` → `gender.value` (convert enum to string)
- `appearance` → `appearance`
- `personality_traits` → `personality_traits`
- `strengths` → `strengths`
- `interests` → `interests`
- `language` → `language` (preserve Language enum)

### Phase 3: Refactor Child Character Construction

The current approach creates a legacy `Child` dataclass from dictionary data, then passes it to the legacy function.

**Transformation:**

| Current Pattern | New Pattern |
|----------------|-------------|
| Create legacy `Child` from dict | Create `ChildCharacter` from domain data |
| Pass to `get_child_story_prompt()` | Use with builder pattern |

**Mapping Logic:**

Dictionary/Domain `Child` to `ChildCharacter`:
- `name` → `name`
- `age` → `age`
- `gender` → `gender` or `gender.value` (handle both string and enum)
- `interests` → `interests`
- `description` → `None` (optional field, not in legacy data)

### Phase 4: Refactor Prompt Generation

Replace legacy function calls with builder pattern.

**Current Pattern:**
```
prompt = get_heroic_story_prompt(hero, moral, language, story_length=3)
# or
prompt = get_child_story_prompt(child_obj, moral, language, story_length=3)
```

**New Pattern:**
```
builder = EnglishPromptBuilder() if language == Language.ENGLISH else RussianPromptBuilder()
prompt = (builder
    .set_character(hero_character)
    .set_moral(moral)
    .set_story_length(story_length)
    .build())
```

**Builder Selection Logic:**

The builder is selected based on the target language:
- `Language.ENGLISH` → `EnglishPromptBuilder`
- `Language.RUSSIAN` → `RussianPromptBuilder`

All builders support the same fluent interface:
1. `set_character(character)` - accepts any `BaseCharacter` (ChildCharacter or HeroCharacter)
2. `set_moral(moral)` - string moral value
3. `set_story_length(minutes)` - integer story length in minutes
4. `build()` - assembles and returns the final prompt string

### Phase 5: Update Helper Functions

The `create_story_prompt` function orchestrates character creation and prompt generation. This function needs comprehensive refactoring.

**Function Signature:**

Remains unchanged to maintain compatibility with calling code:
```
def create_story_prompt(child, moral, language: Language, story_type: str = "child", hero_index: int = 0)
```

**Internal Logic Transformation:**

For child story type:
1. Extract child data from dictionary parameter
2. Create `ChildCharacter` instance
3. Select appropriate builder based on language
4. Build prompt using builder pattern

For hero story type:
1. Retrieve domain `Hero` entity from database filtered by language
2. Convert domain entity to `HeroCharacter`
3. Select appropriate builder based on language
4. Build prompt using builder pattern

**Error Handling:**

The current fallback mechanism to predefined heroes via the `Heroes` helper class should be evaluated:
- Option A: Remove fallback entirely, fail fast if no database heroes exist
- Option B: Define fallback heroes as `HeroCharacter` instances in the script
- Option C: Log warning and skip hero story generation

Recommended approach: **Option A** - Fail fast with clear error message, as the database should always contain heroes for supported languages.

## Implementation Details

### Character Type Conversion

**Child Conversion:**
```
Input: Dictionary with keys {name, age, gender, interests}
Output: ChildCharacter instance

Steps:
1. Extract values from dictionary
2. Handle gender (may be string or Gender enum)
3. Create ChildCharacter with description=None
4. Character validation happens automatically in __post_init__
```

**Hero Conversion:**
```
Input: Domain Hero entity from database
Output: HeroCharacter instance

Steps:
1. Access entity attributes directly
2. Convert gender enum to string using .value
3. Pass language enum directly (no conversion needed)
4. Set description=None (not present in domain entities)
5. Character validation happens automatically in __post_init__
```

### Builder Usage Pattern

**Standard Flow:**
1. Determine target language from parameters
2. Instantiate appropriate builder (English or Russian)
3. Chain configuration methods:
   - set_character() with ChildCharacter or HeroCharacter
   - set_moral() with moral string value
   - set_story_length() with integer minutes
4. Call build() to generate final prompt
5. Strip whitespace from result

**Builder State:**

Each builder maintains internal state through method calls and validates completeness when `build()` is invoked:
- Missing character → ValidationError
- Missing moral → ValidationError  
- Invalid story length (≤0) → ValidationError

### Database Hero Retrieval

**Current Flow:**
1. Initialize SupabaseClient
2. Call `get_all_heroes()` to retrieve all heroes
3. Filter heroes by language in-memory
4. Select hero by index modulo filtered list length
5. Convert to character type

**Optimization Opportunity:**

The repository pattern should provide language-filtered retrieval to avoid loading all heroes. However, this is outside the scope of the current migration.

**Language Filtering:**

Heroes must match the target language for story generation:
- For English stories → filter `language == Language.ENGLISH`
- For Russian stories → filter `language == Language.RUSSIAN`

The hero index parameter ensures variety by rotating through available heroes using modulo arithmetic.

## Affected Components

### Files to Modify

| File | Modification Type | Description |
|------|------------------|-------------|
| `populate_stories.py` | Refactor | Remove legacy imports, update character creation, replace prompt generation |

### Functions to Refactor

| Function | Change Type | Key Changes |
|----------|------------|-------------|
| `create_story_prompt()` | Major refactor | Replace legacy function calls with builder pattern |
| `generate_single_story()` | No change | Continues to call `create_story_prompt()`, no direct changes needed |

### Removed Dependencies

After migration, the following can be deprecated:
- `src/prompts.py` (legacy compatibility module) - when no other usage exists
- `src/prompts/legacy.py` (legacy wrapper functions) - when no other usage exists
- `src/prompts_old.py` (old monolithic prompts) - when no other usage exists

**Important:** Before removal, verify no other scripts or modules depend on these legacy components.

## Testing Considerations

### Validation Strategy

The migration should maintain identical functional behavior while changing the implementation approach.

**Test Approach:**

1. **Smoke Test:** Run the script and verify stories are generated successfully
2. **Prompt Comparison:** Compare generated prompts before and after migration (should be identical)
3. **Language Coverage:** Test both English and Russian story generation
4. **Story Type Coverage:** Test both child and hero story types
5. **Database Integration:** Verify hero retrieval from database works correctly
6. **Error Handling:** Verify appropriate errors when heroes are missing for a language

### Expected Behavior Preservation

| Behavior | Verification Method |
|----------|-------------------|
| Generated prompts are identical | String comparison of prompts |
| Stories are saved to database | Query database for new records |
| Both languages work correctly | Generate stories in EN and RU |
| Hero rotation works | Verify different heroes used across stories |
| Error handling preserved | Test with missing database heroes |

### Edge Cases

1. **Empty hero database:** Script should fail with clear error message
2. **Missing language heroes:** Filter returns empty list, index access fails
3. **Invalid child data:** Character validation catches issues early
4. **Invalid moral values:** Builders accept any string, no validation change

## Migration Benefits

### Code Quality Improvements

1. **Direct API Usage:** Eliminates wrapper functions, using the modular system directly
2. **Type Safety:** Character types provide stronger validation than dictionary-based approaches
3. **Explicit Dependencies:** Clear imports show exactly which components are used
4. **Future-Proof:** Aligns with the project's architectural direction

### Maintainability Gains

1. **Single System:** Only one prompt generation system to maintain
2. **Reduced Complexity:** Removes compatibility layers and conversion logic
3. **Clearer Intent:** Builder pattern makes prompt construction explicit
4. **Easier Testing:** Character types and builders are independently testable

### Path to Legacy Removal

This migration is a critical step toward removing deprecated code:
- Once all scripts migrate, legacy modules can be deleted
- Reduces codebase size and maintenance burden
- Eliminates confusion about which system to use

## Success Criteria

The migration is complete when:

1. **Code Changes:**
   - All legacy imports removed from `populate_stories.py`
   - New builder and character type imports added
   - `create_story_prompt()` uses builder pattern
   - Character conversion uses new character types

2. **Functional Verification:**
   - Script runs without errors
   - Stories are generated for both languages
   - Stories are generated for both child and hero types
   - Generated stories are saved to database correctly
   - Audio generation still works (if enabled)

3. **Quality Assurance:**
   - No regression in story quality or format
   - Prompt structure remains consistent
   - Error handling works as expected
   - Database interactions unchanged

## Risk Mitigation

### Potential Issues

| Risk | Mitigation Strategy |
|------|-------------------|
| Character validation fails with edge cases | Test with existing sample data before deployment |
| Hero database empty or missing language | Add database validation check before generation |
| Builder behavior differs from legacy | Compare generated prompts in testing |
| Gender enum vs string mismatch | Handle both types during conversion |
| Import errors | Verify all imports exist and are accessible |

### Rollback Plan

If critical issues arise:
1. Revert file to previous version using version control
2. Investigate prompt differences or errors
3. Fix issues in new implementation
4. Re-test before deployment

### Validation Checkpoint

Before considering migration complete:
- Run full generation cycle (10 stories)
- Verify all stories saved to database
- Check story content quality manually
- Verify both languages and story types work
- Test with GENERATE_AUDIO both enabled and disabled

## Post-Migration Actions

After successful migration:

1. **Verification:**
   - Search codebase for remaining legacy imports
   - Check if other scripts use `src/prompts.py`
   - Identify all references to `src/prompts_old.py`

2. **Documentation:**
   - Update script comments to reference new system
   - Document builder usage pattern if not already done
   - Update any relevant README files

3. **Legacy Cleanup (if applicable):**
   - If no other dependencies exist, create deprecation plan
   - Mark legacy modules as deprecated
   - Schedule removal in future release

4. **Code Review:**
   - Review changes for code quality
   - Verify error handling is comprehensive
   - Ensure consistent coding style
