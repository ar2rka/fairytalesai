# LangGraph Workflow - Quick Start Guide

## Overview

This guide helps you get started with the LangGraph story generation workflow in 5 minutes.

## What It Does

The LangGraph workflow enhances story generation with:
1. **Prompt Validation** - Checks for licensed characters and inappropriate content
2. **Quality Assessment** - Evaluates stories on 6 quality criteria (1-10 scale)
3. **Automatic Regeneration** - Retries if quality is below threshold
4. **Best Story Selection** - Chooses highest-quality story from all attempts

## Quick Start

### Step 1: Install Dependencies (Already Done)

Dependencies have been installed:
- `langgraph` - Workflow framework
- `langchain-core` - Core abstractions
- `langchain-openai` - OpenAI integration

### Step 2: Run Database Migration

```bash
# Make sure your .env file has Supabase credentials
psql -h <your-supabase-host> -U postgres -d postgres \
  -f supabase/migrations/020_add_langgraph_workflow_support.sql
```

Or use Supabase dashboard to run the migration.

### Step 3: Configure Environment

Add to your `.env` file:

```bash
# Enable LangGraph workflow
LANGGRAPH_ENABLED=true

# Quality threshold (7 = good quality)
LANGGRAPH_QUALITY_THRESHOLD=7

# Max regeneration attempts
LANGGRAPH_MAX_GENERATION_ATTEMPTS=3
```

### Step 4: Test the Workflow

```bash
# Run the test script
uv run python test_langgraph_workflow.py
```

**Expected Output:**
```
==============================================================
LangGraph Story Generation Workflow Test
==============================================================

LangGraph enabled: True
Quality threshold: 7
Max attempts: 3

1. Initializing services...
✓ Services initialized

2. Creating test child...
✓ Child created: Emma, age 7

3. Executing LangGraph workflow...
This will:
  - Validate the prompt for safety
  - Generate a story
  - Assess story quality
  - Regenerate if quality < 7
  - Select best story from attempts

==============================================================
WORKFLOW RESULTS
==============================================================

✓ Workflow completed successfully in 35.2s

Story Title: Emma and the Magic of Kindness
Quality Score: 8/10
Attempts Made: 2
Selected Attempt: 2

All Scores: [6, 8]
Selection Reason: Selected attempt 2 with score 8/10
```

### Step 5: Use in Your Code

```python
from src.application.use_cases.generate_story_async import GenerateStoryUseCaseAsync

# Initialize use case (with your actual repositories and services)
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

# Generate story with LangGraph workflow
result = await use_case.execute(
    request=story_request_dto,
    story_type="child",  # or "hero" or "combined"
    user_id=user_id
)

# Access quality metadata
print(f"Quality Score: {result.quality_score}/10")
print(f"Generation Attempts: {result.attempts_count}")
```

## Configuration Options

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LANGGRAPH_ENABLED` | `false` | Enable/disable workflow |
| `LANGGRAPH_QUALITY_THRESHOLD` | `7` | Minimum quality score (1-10) |
| `LANGGRAPH_MAX_GENERATION_ATTEMPTS` | `3` | Max regeneration attempts |
| `LANGGRAPH_VALIDATION_MODEL` | `openai/gpt-4o-mini` | Model for validation |
| `LANGGRAPH_ASSESSMENT_MODEL` | `openai/gpt-4o-mini` | Model for assessment |
| `LANGGRAPH_FIRST_ATTEMPT_TEMPERATURE` | `0.7` | Temperature for 1st attempt |
| `LANGGRAPH_SECOND_ATTEMPT_TEMPERATURE` | `0.8` | Temperature for 2nd attempt |
| `LANGGRAPH_THIRD_ATTEMPT_TEMPERATURE` | `0.6` | Temperature for 3rd attempt |

### Tuning for Different Use Cases

**Fast Generation (Lower Quality Acceptable):**
```bash
LANGGRAPH_QUALITY_THRESHOLD=6
LANGGRAPH_MAX_GENERATION_ATTEMPTS=2
```

**High Quality (Willing to Wait):**
```bash
LANGGRAPH_QUALITY_THRESHOLD=8
LANGGRAPH_MAX_GENERATION_ATTEMPTS=5
```

**Cost Optimization:**
```bash
LANGGRAPH_MAX_GENERATION_ATTEMPTS=2
LANGGRAPH_VALIDATION_MODEL=openai/gpt-4o-mini
LANGGRAPH_ASSESSMENT_MODEL=openai/gpt-4o-mini
```

## How It Works

### Workflow Flow

```
1. Validate Prompt
   ├─ Check for licensed characters (Disney, Marvel, etc.)
   ├─ Verify age appropriateness
   ├─ Assess content safety
   └─ [Approved] → Continue | [Rejected] → Stop

2. Generate Story (Attempt 1)
   ├─ Create story with temperature 0.7
   └─ Store attempt

3. Assess Quality
   ├─ Score on 6 criteria (1-10)
   ├─ Calculate weighted overall score
   └─ [Score ≥ 7] → Select | [Score < 7] → Regenerate

4. Generate Story (Attempt 2, if needed)
   ├─ Include feedback from attempt 1
   ├─ Use temperature 0.8 (more creative)
   └─ Store attempt

5. Assess Quality
   └─ [Score ≥ 7] → Select | [Score < 7] → Regenerate

6. Generate Story (Attempt 3, if needed)
   ├─ Include all previous feedback
   ├─ Use temperature 0.6 (conservative)
   └─ Store attempt

7. Select Best Story
   ├─ Compare all quality scores
   ├─ Select highest-scoring story
   └─ Save with quality metadata
```

### Quality Criteria

Each story is scored 1-10 on:
- **Age Appropriateness** (20%) - Language and themes match child's age
- **Moral Clarity** (20%) - Moral lesson is clear and integrated
- **Narrative Coherence** (20%) - Story has logical flow
- **Character Consistency** (15%) - Characters behave believably
- **Engagement** (15%) - Story maintains interest
- **Language Quality** (10%) - Grammar and vocabulary

## Common Scenarios

### Scenario 1: First Attempt Succeeds
- Validation: 3s
- Generation 1: 15s
- Assessment: 8s (score: 8/10 ✓)
- **Total: ~26s**

### Scenario 2: Two Attempts Needed
- Validation: 3s
- Generation 1: 15s
- Assessment 1: 8s (score: 6/10)
- Generation 2: 15s
- Assessment 2: 8s (score: 8/10 ✓)
- **Total: ~49s**

### Scenario 3: Prompt Rejected
- Validation: 3s (detected "Mickey Mouse")
- **Total: ~3s** (no story generated)

## Troubleshooting

### Issue: Workflow not running

**Check:**
```bash
# Verify LANGGRAPH_ENABLED is set
echo $LANGGRAPH_ENABLED  # Should be "true"

# Check logs
tail -f app.log | grep langgraph
```

### Issue: Always rejects prompts

**Solution:**
- Check licensed character list doesn't match your content
- Review validation model configuration
- Check OpenRouter API key is valid

### Issue: Quality scores too low

**Solution:**
- Lower `LANGGRAPH_QUALITY_THRESHOLD` to 6
- Improve prompt clarity
- Check assessment model is working correctly

### Issue: Takes too long

**Solution:**
- Reduce `LANGGRAPH_MAX_GENERATION_ATTEMPTS` to 2
- Use faster models
- Increase threshold to reduce regenerations

## Monitoring

### Check Workflow Status

```python
# In your application logs
logger.info(f"Workflow status: {final_state['workflow_status']}")
logger.info(f"Quality score: {final_state['best_story']['quality_assessment']['overall_score']}")
logger.info(f"Attempts: {final_state['current_attempt']}")
```

### Database Queries

```sql
-- View quality scores
SELECT 
    title,
    quality_score,
    generation_attempts_count,
    selected_attempt_number
FROM stories
WHERE quality_score IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;

-- View all attempts for a story
SELECT 
    attempt_number,
    quality_score,
    model_used,
    created_at
FROM generation_attempts
WHERE story_id = '<story-uuid>'
ORDER BY attempt_number;
```

## Disabling LangGraph

To switch back to legacy generation:

```bash
# In .env
LANGGRAPH_ENABLED=false
```

The system will automatically fall back to the original story generation method.

## Next Steps

1. **Test thoroughly** with your content
2. **Monitor quality scores** in production
3. **Adjust thresholds** based on results
4. **Review validation rules** for your use case
5. **Optimize model selection** for cost/quality balance

## Support

For issues or questions:
1. Check logs for detailed error messages
2. Review `LANGGRAPH_IMPLEMENTATION_SUMMARY.md` for details
3. Run `test_langgraph_workflow.py` to diagnose issues

## Summary

You now have:
✅ LangGraph workflow installed and configured
✅ Database schema updated
✅ Feature flag for gradual rollout
✅ Quality validation and regeneration
✅ Comprehensive testing tools

The workflow is ready to enhance your story generation with automated quality control!
