# Feature Design: Story Generation Types Support

## Context

The tale generator system currently supports three story generation types, but the implementation analysis reveals that hero-only and combined story generation capabilities are already fully implemented at the backend level. This design addresses the completion and verification of these features.

## Current State Analysis

### Implemented Components

The system already has comprehensive support for three story types:

| Story Type | Description | Status |
|------------|-------------|--------|
| `child` | Story featuring only the child as protagonist | ✅ Fully Implemented |
| `hero` | Story featuring only a hero character as protagonist | ✅ Fully Implemented |
| `combined` | Story featuring both child and hero working together | ✅ Fully Implemented |

### Existing Implementation Coverage

**Database Layer:**
- Migration 011 adds all required fields (story_type, hero_id, hero_name, hero_gender, hero_appearance, relationship_description)
- Proper constraints ensure data integrity (CHECK constraints for story_type values and hero_id requirements)
- Foreign key relationship to heroes table with ON DELETE RESTRICT
- Indexes created for query performance on story_type and hero_id

**Domain Layer:**
- Story entity includes all hero-related fields
- Hero entity properly defined with all attributes
- Value objects support all necessary enumerations

**Service Layer:**
- PromptService has methods for all three story types:
  - generate_child_prompt()
  - generate_hero_prompt()
  - generate_combined_prompt()
- Each method supports both English and Russian languages
- Proper moral translation and interest translation for Russian stories

**API Layer:**
- Endpoint `/api/v1/stories/generate` accepts story_type parameter
- Request validation ensures hero_id is provided for hero/combined stories
- Hero language validation matches requested story language
- Relationship descriptions auto-generated for combined stories
- All story metadata properly persisted to database

## Gap Analysis

While the backend implementation is complete, potential gaps may exist in:

### 1. Frontend Integration
The frontend may not yet expose UI controls for selecting story types beyond "child" stories.

**What needs verification:**
- Story generation form should include story type selector
- When "hero" or "combined" is selected, hero selection dropdown should appear
- Hero selection should filter by language matching the story language
- UI should clearly communicate the difference between story types

### 2. Data Population
The system may lack sufficient hero profiles to generate diverse hero and combined stories.

**What needs verification:**
- Number of hero profiles available in the database
- Language distribution of heroes (English vs Russian)
- Quality and variety of hero characteristics (personality traits, strengths, appearance)

### 3. Testing Coverage
Hero and combined story generation may lack comprehensive testing.

**What needs verification:**
- Unit tests for hero story generation flow
- Integration tests for combined story generation
- API endpoint tests for all three story types
- Error handling tests (missing hero, language mismatch)

### 4. User Documentation
Documentation may not adequately explain the new story types to end users.

**What needs verification:**
- User-facing documentation explains story type options
- Examples provided for each story type
- Clear guidance on when to use each type

## Design Decisions

### Decision 1: Leverage Existing Implementation
**Rationale:** The backend implementation is comprehensive and well-architected. Rather than redesigning, the focus should be on completing integration and testing.

**Approach:** Conduct verification of existing implementation and fill identified gaps rather than building new functionality.

### Decision 2: Story Type Selection Strategy
**Rationale:** Users need clear guidance on choosing story types appropriate for their needs.

**Approach:**
- Default to "child" story type for backwards compatibility
- Provide clear descriptions of each story type in the UI
- Allow users to filter/browse previously generated stories by type

### Decision 3: Hero Selection UX
**Rationale:** Hero selection should be intuitive and contextually appropriate.

**Approach:**
- Show hero selector only when story_type is "hero" or "combined"
- Filter heroes by language automatically based on story language selection
- Display hero preview (name, appearance, traits) to aid selection
- Provide option to browse all available heroes

### Decision 4: Relationship Description Generation
**Rationale:** Combined stories need meaningful relationship context between child and hero.

**Approach:**
- Use existing template-based approach for consistency
- Templates vary by language (English/Russian)
- Simple format: "{child_name} meets the legendary {hero_name}"
- Future enhancement could allow custom relationship descriptions

## Implementation Requirements

### Frontend Requirements

**Story Type Selection Component:**
- Radio buttons or dropdown to select story type: "Child Story", "Hero Story", "Combined Adventure"
- Display descriptive text for each option
- Visual indicators (icons) to differentiate story types

**Hero Selection Component:**
- Dropdown populated with heroes filtered by selected language
- Display format: "{hero_name} - {appearance_preview}"
- Empty state message when no heroes available for selected language
- Link to hero management page for creating new heroes

**Story Display Enhancement:**
- Show story type badge on story cards
- Display hero information for hero/combined stories
- Show relationship description for combined stories

### Data Requirements

**Minimum Hero Population:**
- At least 5 heroes per language (English, Russian)
- Diverse characteristics covering different themes and values
- Balanced gender representation
- Clear, child-appropriate descriptions

**Hero Attributes Coverage:**
- Varied personality traits (brave, wise, curious, kind, adventurous)
- Diverse strengths (magic, technology, nature, wisdom, courage)
- Multiple appearance styles (warriors, wizards, explorers, inventors)
- Interest alignment with child interests where possible

### Testing Requirements

**Unit Tests:**
- PromptService.generate_hero_prompt() with various hero profiles
- PromptService.generate_combined_prompt() with child-hero pairs
- Relationship description generation for both languages
- Moral and interest translation for Russian prompts

**Integration Tests:**
- End-to-end hero story generation via API
- End-to-end combined story generation via API
- Audio generation for hero and combined stories
- Story persistence with all hero fields populated

**Error Handling Tests:**
- Missing hero_id for hero/combined requests returns 400
- Invalid hero_id returns 404
- Hero language mismatch returns 400 with clear message
- Non-existent child_id returns 404

**Frontend Tests:**
- Story type selection updates UI state correctly
- Hero selector appears/disappears based on story type
- Hero filtering by language works correctly
- Form validation prevents submission with missing hero_id

### Documentation Requirements

**User Guide:**
- Section explaining three story types with examples
- Guidance on choosing appropriate story type for different situations
- Instructions for selecting heroes
- Visual examples of each story type output

**API Documentation:**
- Update OpenAPI schema with story_type parameter examples
- Document hero_id requirement for hero/combined types
- Provide sample requests for all three story types
- Document error responses for hero-related validation

**Developer Documentation:**
- Architecture diagram showing story type flow
- Explanation of prompt generation strategy per type
- Database schema documentation for hero fields
- Testing strategy for multi-type support

## Acceptance Criteria

### Functional Criteria

1. Users can successfully generate hero-only stories via the UI
2. Users can successfully generate combined (child + hero) stories via the UI
3. Hero selection is filtered by story language automatically
4. Generated hero stories include hero as the main character
5. Generated combined stories feature both child and hero working together
6. Relationship descriptions are generated correctly in both English and Russian
7. All story types support audio generation
8. Story metadata (type, hero info) persists correctly to database

### Quality Criteria

1. Story type selection has clear, understandable labels
2. Hero selection provides sufficient preview information
3. Error messages are user-friendly and actionable
4. Generated stories are age-appropriate and engaging
5. Performance is comparable across all three story types
6. UI remains responsive during hero story generation

### Testing Criteria

1. All new UI components have unit tests
2. All story generation types have integration tests
3. Error scenarios have explicit test coverage
4. Testing includes both English and Russian language paths
5. Audio generation tested for all story types

## Risk Assessment

### Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Insufficient hero data causes poor story quality | Medium | High | Implement hero quality validation and minimum population checks |
| Language mismatch between hero and story confuses AI | Low | Medium | Strict validation prevents mismatched combinations |
| Combined stories lack coherent narrative | Medium | High | Refine prompts based on generated story quality analysis |
| Frontend hero selection performance issues with many heroes | Low | Low | Implement pagination or search for hero selection |

### User Experience Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Users don't understand story type differences | Medium | Medium | Clear UI labels and help text explaining each option |
| Hero selection feels overwhelming | Low | Low | Provide curated hero recommendations based on child interests |
| Combined stories feel forced or unnatural | Medium | High | Test with real users and iterate on prompts |

### Data Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Hero database remains unpopulated | High | High | Create initial seed data and provide hero creation tools |
| Hero descriptions contain inappropriate content | Low | Critical | Implement content validation and review process |
| Unbalanced hero representation | Medium | Low | Monitor hero usage metrics and fill gaps proactively |

## Success Metrics

### Usage Metrics
- Percentage of stories generated by type (target: 40% child, 30% hero, 30% combined)
- Hero selection diversity (how many different heroes are used)
- Story generation success rate by type (target: >95% for all types)

### Quality Metrics
- User rating average by story type (target: >4.0/5.0 for all types)
- Story regeneration rate by type (lower is better)
- Audio generation success rate by type (target: >90%)

### Engagement Metrics
- Feature discovery rate (percentage of users who try hero/combined stories)
- Repeat usage of hero/combined story types
- Time spent reading different story types

## Future Enhancements

### Phase 2 Possibilities

**Custom Relationship Descriptions:**
- Allow users to specify custom relationships between child and hero
- Example: "mentor and student", "siblings", "teammates"
- Different prompt variations based on relationship type

**Multi-Hero Stories:**
- Support stories with multiple heroes working together
- Child teams up with multiple heroes for larger adventures
- Requires additional schema changes and prompt complexity

**Hero Collections:**
- Group heroes into thematic collections (e.g., "Space Explorers", "Magical Creatures")
- Allow story generation using entire collection
- Rotate heroes within collection for variety

**Dynamic Hero Creation:**
- AI-assisted hero generation based on child's interests
- User-guided hero builder with templates
- Community-contributed heroes (with moderation)

**Story Series:**
- Link multiple stories featuring the same child-hero pair
- Continuing adventures with character development
- Story arc planning and progression tracking

## Dependencies

### Internal Dependencies
- Existing database migrations must be applied
- Hero repository implementation
- Prompt service with all three generation methods
- API endpoint supporting story_type parameter

### External Dependencies
- AI model (OpenRouter) supports prompt variations for different story types
- Voice generation service supports content for hero stories
- Storage service handles audio files for all story types

### Data Dependencies
- Sufficient hero profiles in database (minimum 5 per language)
- Heroes have complete and valid attributes
- Child profiles exist for testing combined stories

## Rollout Strategy

### Phase 1: Backend Verification (Complete)
- Verify all database migrations applied successfully
- Confirm API endpoint handles all three story types
- Test prompt generation for hero and combined types
- Validate data persistence for all hero-related fields

### Phase 2: Data Preparation
- Populate hero database with initial seed data
- Create at least 10 heroes per language (English, Russian)
- Validate hero data quality and appropriateness
- Test story generation with real hero data

### Phase 3: Frontend Integration
- Implement story type selector component
- Add hero selection component with language filtering
- Update story display to show hero information
- Integrate components into story generation flow

### Phase 4: Testing and Validation
- Execute comprehensive test suite
- Perform user acceptance testing with real users
- Collect feedback on story quality and UX
- Iterate based on findings

### Phase 5: Documentation and Launch
- Complete user-facing documentation
- Update API documentation
- Create tutorial/onboarding for new story types
- Soft launch to subset of users

### Phase 6: Full Rollout
- Monitor metrics and error rates
- Address issues promptly
- Collect user feedback
- Plan next iteration

## Open Questions

1. Should hero selection be required or optional for combined stories? (Could default to random hero if not specified)
2. How should the system handle scenarios where no heroes exist for the selected language?
3. Should users be able to create custom heroes on-the-fly during story generation?
4. What is the desired ratio of story types in the seed/sample data?
5. Should hero stories always include moral lessons, or can they be pure adventure?
6. How should the system handle very young children (age 1-3) with hero/combined stories?
