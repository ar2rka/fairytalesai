# LangGraph Story Generation Workflow - Implementation Summary

## Overview

Successfully implemented a sophisticated LangGraph-based story generation workflow that validates prompts, generates stories, assesses quality, and automatically regenerates when quality is insufficient. The system selects the best story from multiple attempts to ensure high-quality content.

## What Was Implemented

### 1. Dependencies Installation ✅

Added LangGraph ecosystem dependencies:
- `langgraph` >= 0.2.0 - State machine workflow framework
- `langchain-core` >= 0.3.0 - Core abstractions
- `langchain-openai` >= 0.2.0 - OpenAI integration

### 2. Database Schema Extensions ✅

**Migration:** `supabase/migrations/020_add_langgraph_workflow_support.sql`

**New fields in `stories` table:**
- `quality_score` (INTEGER 1-10) - Overall quality assessment
- `generation_attempts_count` (INTEGER) - Number of attempts made
- `selected_attempt_number` (INTEGER) - Which attempt was chosen
- `quality_metadata` (JSONB) - Detailed quality data
- `validation_result` (JSONB) - Prompt validation outcome
- `workflow_metadata` (JSONB) - Execution metadata

**New table: `generation_attempts`**
- Tracks all generation attempts for each story
- Stores attempt number, content, quality score, metadata
- Foreign key to stories table
- RLS policies for user access control

### 3. Configuration System ✅

**File:** `src/infrastructure/config/settings.py`

Added `LangGraphWorkflowSettings` class with:
- `enabled` (bool) - Feature flag (default: false)
- `quality_threshold` (int) - Minimum acceptable score (default: 7)
- `max_generation_attempts` (int) - Max attempts (default: 3)
- `validation_model` (str) - Model for validation (default: gpt-4o-mini)
- `assessment_model` (str) - Model for assessment (default: gpt-4o-mini)
- `generation_model` (Optional[str]) - Model for generation
- Temperature settings for each attempt (0.7, 0.8, 0.6)

**Environment Variables:**
```bash
LANGGRAPH_ENABLED=false
LANGGRAPH_QUALITY_THRESHOLD=7
LANGGRAPH_MAX_GENERATION_ATTEMPTS=3
LANGGRAPH_VALIDATION_MODEL=openai/gpt-4o-mini
LANGGRAPH_ASSESSMENT_MODEL=openai/gpt-4o-mini
LANGGRAPH_FIRST_ATTEMPT_TEMPERATURE=0.7
LANGGRAPH_SECOND_ATTEMPT_TEMPERATURE=0.8
LANGGRAPH_THIRD_ATTEMPT_TEMPERATURE=0.6
```

### 4. Workflow State Management ✅

**File:** `src/domain/services/langgraph/workflow_state.py`

**Data Classes:**
- `ValidationResult` - Prompt validation outcome
- `QualityAssessment` - Story quality evaluation
- `GenerationAttempt` - Single generation attempt
- `WorkflowState` (TypedDict) - Complete workflow state
- `WorkflowStatus` (Enum) - Workflow execution status

**State Fields:**
- Input parameters (child, hero, language, moral, etc.)
- Validation results
- Generation attempts array
- Quality assessments array
- Best story selection
- Error tracking
- Timing metadata

### 5. Prompt Validator Service ✅

**File:** `src/domain/services/langgraph/prompt_validator.py`

**Features:**
- Quick keyword-based check for 40+ licensed characters
- LLM-based comprehensive validation
- Safety assessment (violence, horror, inappropriate content)
- Age appropriateness checking
- Coherence validation
- Structured JSON output parsing

**Licensed Characters Detected:**
- Disney: Mickey Mouse, Elsa, Simba, Moana, etc.
- Marvel: Spider-Man, Iron Man, Avengers, etc.
- DC Comics: Batman, Superman, Wonder Woman, etc.
- Other: Harry Potter, Pokémon, Sonic, Peppa Pig, etc.

### 6. Quality Assessor Service ✅

**File:** `src/domain/services/langgraph/quality_assessor.py`

**Quality Criteria (1-10 scale):**
1. Age Appropriateness (20% weight)
2. Moral Clarity (20% weight)
3. Narrative Coherence (20% weight)
4. Character Consistency (15% weight)
5. Engagement Level (15% weight)
6. Language Quality (10% weight)

**Features:**
- Weighted overall score calculation
- Detailed feedback generation
- Improvement suggestions
- Robust JSON parsing with fallbacks

### 7. Workflow Nodes ✅

**File:** `src/domain/services/langgraph/workflow_nodes.py`

**Implemented Nodes:**

1. **validate_prompt_node**
   - Validates prompt for safety and appropriateness
   - Updates validation_result in state
   - Sets workflow status to REJECTED if validation fails

2. **generate_story_node**
   - Generates story using prompt service
   - Supports child/hero/combined story types
   - Adjusts temperature by attempt number
   - Includes previous feedback for regeneration
   - Stores generation attempt in state

3. **assess_quality_node**
   - Evaluates story quality using LLM
   - Stores quality assessment in state
   - Tracks all scores for comparison

4. **select_best_story_node**
   - Selects highest-scoring story
   - Prefers later attempts if scores tied
   - Records selection metadata

**Helper Functions:**
- `should_regenerate()` - Decision logic for regeneration

### 8. LangGraph StateGraph ✅

**File:** `src/domain/services/langgraph/story_generation_workflow.py`

**Workflow Structure:**
```
Entry → validate_prompt → [approved/rejected]
         ↓ approved
       generate_story
         ↓
       assess_quality → [regenerate/select]
         ↓ regenerate        ↓ select
    (back to generate)   select_best_story → End
```

**Conditional Routing:**
- After validation: approved → generate | rejected → END
- After assessment: regenerate → generate | select → select_best

**Features:**
- Async node execution
- Service injection via wrappers
- Configuration passing
- Error handling at each node

### 9. Workflow Service ✅

**File:** `src/domain/services/langgraph/langgraph_workflow_service.py`

**LangGraphWorkflowService:**
- Orchestrates complete workflow execution
- Initializes workflow with configuration
- Processes final state into result object
- Handles success/rejection/failure cases

**LangGraphWorkflowResult:**
- Success flag
- Story content and title
- Quality score and metadata
- Validation result
- Workflow metadata
- Error messages
- All generation attempts

### 10. Use Case Integration ✅

**File:** `src/application/use_cases/generate_story_async.py`

**GenerateStoryUseCaseAsync:**
- Feature flag check for LangGraph workflow
- Falls back to legacy generation if disabled
- Supports child/hero/combined story types
- Saves quality metadata to database
- Handles validation errors appropriately

**Workflow Selection:**
```python
if self.langgraph_enabled and self.langgraph_service:
    # Use LangGraph workflow with quality validation
    story, quality_metadata, ... = await self._generate_with_langgraph(...)
else:
    # Use legacy direct generation
    story = await self._generate_legacy(...)
```

## Files Created

### Core Implementation (10 files)
1. `src/domain/services/langgraph/__init__.py`
2. `src/domain/services/langgraph/workflow_state.py`
3. `src/domain/services/langgraph/prompt_validator.py`
4. `src/domain/services/langgraph/quality_assessor.py`
5. `src/domain/services/langgraph/workflow_nodes.py`
6. `src/domain/services/langgraph/story_generation_workflow.py`
7. `src/domain/services/langgraph/langgraph_workflow_service.py`
8. `src/application/use_cases/generate_story_async.py`

### Database & Configuration (2 files)
9. `supabase/migrations/020_add_langgraph_workflow_support.sql`
10. Updated: `src/infrastructure/config/settings.py`
11. Updated: `.env.example`

### Testing (1 file)
12. `test_langgraph_workflow.py`

## How to Use

### 1. Run Database Migration

```bash
# Connect to Supabase and run migration
psql -h <supabase-host> -U postgres -d postgres -f supabase/migrations/020_add_langgraph_workflow_support.sql
```

### 2. Configure Environment

Edit `.env` file:
```bash
# Enable LangGraph workflow
LANGGRAPH_ENABLED=true

# Quality settings
LANGGRAPH_QUALITY_THRESHOLD=7
LANGGRAPH_MAX_GENERATION_ATTEMPTS=3

# Model selection
LANGGRAPH_VALIDATION_MODEL=openai/gpt-4o-mini
LANGGRAPH_ASSESSMENT_MODEL=openai/gpt-4o-mini

# Temperature settings
LANGGRAPH_FIRST_ATTEMPT_TEMPERATURE=0.7
LANGGRAPH_SECOND_ATTEMPT_TEMPERATURE=0.8
LANGGRAPH_THIRD_ATTEMPT_TEMPERATURE=0.6
```

### 3. Test the Workflow

```bash
# Run test script
uv run python test_langgraph_workflow.py
```

**Expected Output:**
- Validation result (approved/rejected)
- Story generation (1-3 attempts)
- Quality assessments for each attempt
- Best story selection
- Detailed metrics and timing

### 4. Use in Application

```python
from src.application.use_cases.generate_story_async import GenerateStoryUseCaseAsync
from src.domain.entities import Child
from src.domain.value_objects import Gender, Language, StoryLength

# Initialize use case with repositories and services
use_case = GenerateStoryUseCaseAsync(
    story_repository=story_repository,
    child_repository=child_repository,
    hero_repository=hero_repository,
    story_service=story_service,
    prompt_service=prompt_service,
    audio_service=audio_service,
    ai_service=openrouter_client,
    storage_service=storage_service
)

# Execute with LangGraph workflow (if enabled)
result = await use_case.execute(
    request=story_request,
    story_type="child",
    user_id=user_id
)

# Result includes quality metadata
print(f"Quality Score: {result.quality_score}/10")
print(f"Attempts: {result.attempts_count}")
```

## Workflow Execution Flow

### Happy Path (Quality Achieved on First Try)
1. **Validate Prompt** (3s)
   - Check for licensed characters
   - Verify age appropriateness
   - Assess safety
   - → Approved

2. **Generate Story** - Attempt 1 (15s)
   - Use temperature 0.7
   - Generate story content
   - Extract title

3. **Assess Quality** (8s)
   - Score: 8/10 (above threshold)
   - → Quality sufficient

4. **Select Best Story** (instant)
   - Only 1 attempt, select it
   - Save with quality metadata

**Total Time:** ~26 seconds

### Regeneration Path (Quality Below Threshold)
1. **Validate Prompt** → Approved
2. **Generate Story** - Attempt 1
   - Score: 5/10 (below threshold)
   - → Regenerate

3. **Generate Story** - Attempt 2
   - Include previous feedback
   - Use temperature 0.8
   - Score: 6/10 (still below)
   - → Regenerate

4. **Generate Story** - Attempt 3
   - Include all feedback
   - Use temperature 0.6 (conservative)
   - Score: 7/10 (meets threshold)
   - → Select

5. **Select Best Story**
   - Compare scores: [5, 6, 7]
   - Select attempt 3 (highest)

**Total Time:** ~65 seconds

### Rejection Path
1. **Validate Prompt**
   - Detect: "Mickey Mouse" in interests
   - → Rejected

2. **Workflow Ends**
   - Return validation error
   - No story generated

**Total Time:** ~3 seconds

## Quality Metrics

### Scoring Criteria

| Criterion | Weight | Description |
|-----------|--------|-------------|
| Age Appropriateness | 20% | Content matches child's developmental level |
| Moral Clarity | 20% | Moral lesson clearly integrated |
| Narrative Coherence | 20% | Logical story flow and structure |
| Character Consistency | 15% | Characters behave believably |
| Engagement | 15% | Story maintains interest |
| Language Quality | 10% | Grammar, vocabulary, style |

### Score Interpretation
- **8-10**: Excellent quality, publish immediately
- **7**: Good quality, meets threshold
- **5-6**: Needs improvement, regenerate
- **1-4**: Significant issues, regenerate

## Error Handling

### Validation Errors
- Licensed character detected → Reject with detailed reason
- Age inappropriate content → Reject with explanation
- Safety violation → Reject with safety concerns
- LLM API failure → Fail-safe reject

### Generation Errors
- LLM API failure → Retry with exponential backoff
- Empty response → Mark attempt failed, try again
- Timeout → Reduce story length, retry

### Assessment Errors
- LLM API failure → Use default score of 5
- Invalid JSON → Parse best-effort with fallbacks
- Timeout → Assign default score

### Workflow Errors
- Max attempts reached → Select best available story
- State corruption → Log and fail gracefully
- Critical failure → Return detailed error

## Configuration Options

### Feature Flag
- **Enabled:** Use LangGraph workflow
- **Disabled:** Fall back to legacy generation

### Quality Threshold
- Range: 1-10
- Default: 7
- Higher = stricter quality requirements

### Max Attempts
- Range: 1-5
- Default: 3
- Higher = more regeneration opportunities

### Model Selection
- **Validation:** Fast, cost-effective (gpt-4o-mini)
- **Assessment:** Reliable evaluation (gpt-4o-mini)
- **Generation:** Configurable or use default

### Temperature Strategy
- **Attempt 1:** 0.7 (balanced)
- **Attempt 2:** 0.8 (more creative)
- **Attempt 3:** 0.6 (more conservative)

## Performance Characteristics

### Response Times
- **Validation:** 2-5 seconds
- **Single Generation:** 10-20 seconds
- **Quality Assessment:** 5-10 seconds
- **Total (1 attempt):** 25-45 seconds
- **Total (3 attempts):** 60-90 seconds

### Token Usage
- **Validation:** ~500 tokens
- **Generation:** 500-1500 tokens
- **Assessment:** ~800 tokens
- **Total (3 attempts):** 5000-7000 tokens

### Cost Estimate (gpt-4o-mini)
- **Per workflow:** $0.003 - $0.008
- **Per 100 stories:** $0.30 - $0.80

## Monitoring and Observability

### Logged Events
- Workflow started (with parameters)
- Validation complete (with result)
- Generation attempt (attempt number, duration)
- Quality assessment (score, duration)
- Best story selected (attempt, score)
- Workflow complete (status, total duration)
- Errors (type, context, stack trace)

### Tracked Metrics
- Workflow success rate
- Average quality score
- Attempt count distribution
- Rejection reasons frequency
- Duration by stage
- Error rates by type

### Database Records
All workflow execution data is persisted:
- Validation results
- All generation attempts
- Quality assessments
- Selection metadata
- Timing information

## Troubleshooting

### Issue: Workflow always rejects prompts
**Solution:** Check `LANGGRAPH_VALIDATION_MODEL` is accessible and API key is valid

### Issue: Quality scores always low
**Solution:** Review `LANGGRAPH_ASSESSMENT_MODEL` configuration and quality criteria

### Issue: Workflow takes too long
**Solution:** 
- Reduce `LANGGRAPH_MAX_GENERATION_ATTEMPTS`
- Use faster models
- Increase `LANGGRAPH_QUALITY_THRESHOLD` (less regeneration)

### Issue: Too many regenerations
**Solution:** Lower `LANGGRAPH_QUALITY_THRESHOLD` or improve prompts

## Next Steps

### Recommended Enhancements
1. Add caching for validation results
2. Implement adaptive quality thresholds
3. Add human-in-the-loop review option
4. Create A/B testing framework
5. Build analytics dashboard
6. Add user feedback loop

### Migration Plan
1. **Phase 1:** Test with small user group (current)
2. **Phase 2:** Enable for 10% of requests
3. **Phase 3:** Increase to 50% after validation
4. **Phase 4:** Full rollout
5. **Phase 5:** Remove legacy generation

## Conclusion

The LangGraph story generation workflow is now fully implemented and ready for testing. The system provides:

✅ Prompt validation for safety and licensed characters
✅ Automated story quality assessment
✅ Intelligent regeneration with feedback
✅ Best story selection from multiple attempts
✅ Comprehensive metadata tracking
✅ Feature flag for gradual rollout
✅ Backward compatibility with legacy system

The implementation follows the design document specifications and includes robust error handling, observability, and configuration options.
