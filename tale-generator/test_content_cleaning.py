"""Test script to verify content cleaning functionality."""

import re


def clean_story_content(content: str) -> str:
    """Clean story content by removing formatting markers.
    
    Args:
        content: Raw story content from AI
        
    Returns:
        Cleaned content without formatting markers
    """
    # Remove sequences of 3 or more asterisks
    cleaned = re.sub(r'\*{3,}', '', content)
    
    # Remove sequences of 3 or more underscores
    cleaned = re.sub(r'_{3,}', '', cleaned)
    
    # Remove sequences of 3 or more hyphens (but not in words)
    cleaned = re.sub(r'(?<!\w)-{3,}(?!\w)', '', cleaned)
    
    # Clean up any excessive whitespace that might have been left
    cleaned = re.sub(r'\n{3,}', '\n\n', cleaned)
    
    return cleaned.strip()


def test_cleaning():
    """Test the cleaning function with various inputs."""
    
    # Test 1: Content with ****
    test1 = """# The Magical Adventure

Once upon a time, there was a brave child.

****

The child went on an adventure.

****

And they lived happily ever after."""
    
    expected1 = """# The Magical Adventure

Once upon a time, there was a brave child.

The child went on an adventure.

And they lived happily ever after."""
    
    result1 = clean_story_content(test1)
    print("Test 1 - Removing ****:")
    print(f"Original:\n{test1}\n")
    print(f"Cleaned:\n{result1}\n")
    assert result1 == expected1, f"Test 1 failed:\nExpected:\n{expected1}\nGot:\n{result1}"
    print("✓ Test 1 passed\n")
    
    # Test 2: Content with multiple asterisks
    test2 = "A story ****** with many ****** asterisks ********"
    expected2 = "A story  with many  asterisks"
    result2 = clean_story_content(test2)
    print("Test 2 - Multiple asterisks:")
    print(f"Original: {test2}")
    print(f"Cleaned: {result2}")
    assert result2 == expected2, f"Test 2 failed"
    print("✓ Test 2 passed\n")
    
    # Test 3: Content with underscores
    test3 = "A story ___ with underscores ______"
    expected3 = "A story  with underscores"
    result3 = clean_story_content(test3)
    print("Test 3 - Underscores:")
    print(f"Original: {test3}")
    print(f"Cleaned: {result3}")
    assert result3 == expected3, f"Test 3 failed"
    print("✓ Test 3 passed\n")
    
    # Test 4: Content with excessive newlines
    test4 = "Line 1\n\n\n\nLine 2\n\n\n\n\nLine 3"
    expected4 = "Line 1\n\nLine 2\n\nLine 3"
    result4 = clean_story_content(test4)
    print("Test 4 - Excessive newlines:")
    print(f"Original: {repr(test4)}")
    print(f"Cleaned: {repr(result4)}")
    assert result4 == expected4, f"Test 4 failed"
    print("✓ Test 4 passed\n")
    
    # Test 5: Content with hyphens (should preserve in words)
    test5 = "well-known and self-made --- with separator ---"
    expected5 = "well-known and self-made  with separator"
    result5 = clean_story_content(test5)
    print("Test 5 - Hyphens:")
    print(f"Original: {test5}")
    print(f"Cleaned: {result5}")
    assert result5 == expected5, f"Test 5 failed"
    print("✓ Test 5 passed\n")
    
    # Test 6: Normal content (should remain unchanged)
    test6 = "This is a normal story with no special markers."
    expected6 = "This is a normal story with no special markers."
    result6 = clean_story_content(test6)
    print("Test 6 - Normal content:")
    print(f"Original: {test6}")
    print(f"Cleaned: {result6}")
    assert result6 == expected6, f"Test 6 failed"
    print("✓ Test 6 passed\n")
    
    print("✅ All tests passed!")


if __name__ == "__main__":
    test_cleaning()
