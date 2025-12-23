# Quick Start: Story Generation Types

## 🚀 Getting Started in 5 Minutes

This guide will help you quickly test the new story generation types feature.

## Prerequisites

- Backend server running on `http://localhost:8000`
- Frontend dev server running
- Database with at least one child profile
- User account created

## Step 1: Verify Heroes Exist (1 minute)

Run the hero verification tool:

```bash
python verify_and_populate_heroes.py
```

**If prompted to populate heroes, type `y` and press Enter.**

This will create 6 English and 6 Russian sample heroes in your database.

Expected output:
```
✓ Created 12 new heroes
Total heroes: 12
English heroes: 6 ✓
Russian heroes: 6 ✓
```

## Step 2: Start Frontend (if not running)

```bash
cd frontend
npm run dev
```

Frontend should be available at `http://localhost:5173`

## Step 3: Test Child Story (1 minute)

1. Navigate to http://localhost:5173/stories/generate
2. **Story Type:** Keep default "Child Story" selected
3. **Child:** Select your child from dropdown
4. **Language:** Choose "English"
5. **Length:** 3-5 minutes
6. **Moral:** Type "kindness"
7. Click **Generate Story**

✅ **Expected:** Story generated with child as main character

## Step 4: Test Hero Story (1 minute)

1. Navigate to http://localhost:5173/stories/generate
2. **Story Type:** Select "Hero Story"
3. **Child:** Select your child
4. **Hero:** Select "Captain Wonder" from dropdown (appears automatically)
5. **Language:** Keep "English"
6. **Length:** 5 minutes
7. **Moral:** Type "bravery"
8. Click **Generate Story**

✅ **Expected:** 
- Hero selector appears when "Hero Story" selected
- Story generated with hero as main character
- Hero information displayed on story detail page

## Step 5: Test Combined Story (2 minutes)

1. Navigate to http://localhost:5173/stories/generate
2. **Story Type:** Select "Combined Adventure"
3. **Child:** Select your child
4. **Hero:** Select "Luna the Starkeeper"
5. **Language:** Keep "English"
6. **Length:** 7 minutes
7. **Moral:** Type "teamwork"
8. Click **Generate Story**

✅ **Expected:**
- Both child and hero in the story
- Relationship description displayed (e.g., "Emma meets the legendary Luna the Starkeeper")
- Story features both characters working together

## Step 6: Test Language Filtering (30 seconds)

1. On the story generation page
2. **Story Type:** "Hero Story"
3. **Language:** Switch to "Русский (Russian)"
4. **Hero dropdown:** Should now show Russian heroes only
   - Капитан Чудо
   - Луна Хранительница Звёзд
   - etc.

✅ **Expected:** Hero list automatically filters by language

## Step 7: View Stories List (30 seconds)

1. Navigate to http://localhost:5173/stories
2. Look for your generated stories

✅ **Expected:**
- Story type badges visible (different colors)
- Filter dropdown shows "All Types", "Child Stories", "Hero Stories", "Combined"
- Hero names shown with 🦸 emoji
- Search includes hero names

## Step 8: View Story Details (30 seconds)

1. Click on a combined or hero story
2. View the detail page

✅ **Expected:**
- Story type badge at top
- Hero information section showing:
  - Hero name and gender
  - Hero appearance description
  - Relationship description (for combined stories)

## Verification Checklist

Use this to verify everything works:

### Story Generation
- [ ] Child story generates successfully
- [ ] Hero story generates successfully
- [ ] Combined story generates successfully
- [ ] Hero selector appears for hero/combined types
- [ ] Hero selector hidden for child type
- [ ] Language filtering works on hero list

### Story Display
- [ ] Story type badges show correct colors
- [ ] Story list shows hero names
- [ ] Story type filter works
- [ ] Search includes hero names

### Story Detail
- [ ] Story type badge displayed
- [ ] Hero information shown
- [ ] Relationship description shown (combined)
- [ ] All metadata displays correctly

### Error Handling
- [ ] Validation error if hero missing for hero story
- [ ] No heroes message shows correct CTA
- [ ] Language mismatch prevented

## Troubleshooting

### "No heroes available for this language"

**Solution:**
```bash
python verify_and_populate_heroes.py
```
Type `y` to populate heroes.

### Heroes not appearing in dropdown

**Causes:**
1. No heroes in database → Run populate script
2. Language mismatch → Change story language
3. Backend not running → Start backend

### Story generation fails

**Check:**
1. Backend server running: `curl http://localhost:8000/health`
2. AI service configured (OpenRouter API key)
3. Database accessible
4. Check browser console for errors

### Frontend not updating

**Solutions:**
1. Hard refresh: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)
2. Clear browser cache
3. Restart dev server

## Testing Different Scenarios

### Scenario 1: Russian Story
```
Story Type: Combined Adventure
Language: Русский
Hero: Луна Хранительница Звёзд
Moral: доброта (or "kindness")
```

### Scenario 2: Longer Adventure
```
Story Type: Combined Adventure
Language: English
Hero: Professor Spark
Length: 10 minutes
Moral: creativity
```

### Scenario 3: Hero Focus
```
Story Type: Hero Story
Language: English
Hero: Sir Brightshield
Length: 7 minutes
Moral: courage
```

## Next Steps

After verifying basic functionality:

1. **Create Custom Hero:**
   - Navigate to Heroes page
   - Click "Create Hero"
   - Design your own character

2. **Test Audio Generation:**
   - Enable audio in story generation
   - Listen to generated narration

3. **Rate Stories:**
   - View story details
   - Rate stories 1-10
   - Compare ratings by type

4. **Test Filters:**
   - Use story type filter
   - Combine with language filter
   - Try search with hero names

## Performance Expectations

- **Child Story:** ~15-30 seconds generation
- **Hero Story:** ~15-30 seconds generation
- **Combined Story:** ~20-40 seconds generation (longer content)

Times may vary based on AI service response times.

## Success!

If all checklist items pass, the feature is working correctly! 🎉

### What You Can Do Now

1. Generate different story types for variety
2. Create custom heroes matching your child's interests
3. Build story collections with favorite child-hero pairs
4. Experiment with different moral values
5. Try both English and Russian stories

### Share Feedback

- Which story type does your child prefer?
- Are the heroes engaging?
- Any issues or suggestions?

## Quick Reference

### Story Types
- **Child:** Child is protagonist (personal focus)
- **Hero:** Hero is protagonist (adventure focus)
- **Combined:** Both work together (teamwork focus)

### When to Use Each
- **Child:** Bedtime, self-esteem building
- **Hero:** Action time, role model teaching
- **Combined:** Learning teamwork, longer stories

### Hero Languages
- English heroes → English stories only
- Russian heroes → Russian stories only
- Auto-filtered by language selection

---

**Happy Storytelling! 📚✨**

For detailed information, see `STORY_TYPES_USER_GUIDE.md`
