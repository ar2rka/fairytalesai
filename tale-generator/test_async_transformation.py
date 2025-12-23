"""Test script to verify async transformation of the backend."""

import asyncio
import sys
import os

# Add project root to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))


async def test_openrouter_client():
    """Test that OpenRouter client is async."""
    print("Testing OpenRouter client async transformation...")
    try:
        from src.openrouter_client import OpenRouterClient
        
        # Check if generate_story is a coroutine function
        import inspect
        if inspect.iscoroutinefunction(OpenRouterClient.generate_story):
            print("✓ OpenRouterClient.generate_story is async")
        else:
            print("✗ OpenRouterClient.generate_story is NOT async")
            return False
        
        if inspect.iscoroutinefunction(OpenRouterClient.fetch_generation_info):
            print("✓ OpenRouterClient.fetch_generation_info is async")
        else:
            print("✗ OpenRouterClient.fetch_generation_info is NOT async")
            return False
        
        return True
    except Exception as e:
        print(f"✗ Error testing OpenRouter client: {e}")
        return False


async def test_supabase_client():
    """Test that Supabase client wrapper is async."""
    print("\nTesting AsyncSupabaseClient...")
    try:
        from src.supabase_client_async import AsyncSupabaseClient
        
        # Check if key methods are async
        import inspect
        methods_to_check = [
            'save_child', 'get_child', 'get_all_children',
            'save_hero', 'get_hero', 'get_all_heroes',
            'save_story', 'get_story', 'get_all_stories',
            'upload_audio_file'
        ]
        
        all_async = True
        for method_name in methods_to_check:
            method = getattr(AsyncSupabaseClient, method_name)
            if inspect.iscoroutinefunction(method):
                print(f"✓ AsyncSupabaseClient.{method_name} is async")
            else:
                print(f"✗ AsyncSupabaseClient.{method_name} is NOT async")
                all_async = False
        
        return all_async
    except Exception as e:
        print(f"✗ Error testing AsyncSupabaseClient: {e}")
        return False


async def test_voice_providers():
    """Test that voice providers are async."""
    print("\nTesting Voice Providers async transformation...")
    try:
        from src.voice_providers.elevenlabs_provider import ElevenLabsProvider
        from src.voice_providers.voice_service import VoiceService
        
        import inspect
        
        # Check ElevenLabsProvider
        if inspect.iscoroutinefunction(ElevenLabsProvider.generate_speech):
            print("✓ ElevenLabsProvider.generate_speech is async")
        else:
            print("✗ ElevenLabsProvider.generate_speech is NOT async")
            return False
        
        # Check VoiceService
        if inspect.iscoroutinefunction(VoiceService.generate_audio):
            print("✓ VoiceService.generate_audio is async")
        else:
            print("✗ VoiceService.generate_audio is NOT async")
            return False
        
        if inspect.iscoroutinefunction(VoiceService._try_fallback):
            print("✓ VoiceService._try_fallback is async")
        else:
            print("✗ VoiceService._try_fallback is NOT async")
            return False
        
        return True
    except Exception as e:
        print(f"✗ Error testing Voice Providers: {e}")
        return False


async def test_api_routes():
    """Test that API routes use await for async clients."""
    print("\nTesting API routes async integration...")
    try:
        # Read the routes file and check for await keywords
        routes_file = os.path.join(os.path.dirname(__file__), 'src', 'api', 'routes.py')
        with open(routes_file, 'r') as f:
            content = f.read()
        
        # Check for async patterns
        checks = [
            ('await openrouter_client.generate_story', 'OpenRouter client calls use await'),
            ('await supabase_client.save_child', 'Supabase save_child uses await'),
            ('await supabase_client.get_child', 'Supabase get_child uses await'),
            ('await supabase_client.save_story', 'Supabase save_story uses await'),
            ('await voice_service.generate_audio', 'Voice service uses await'),
            ('await supabase_client.upload_audio_file', 'Audio upload uses await'),
        ]
        
        all_found = True
        for pattern, description in checks:
            if pattern in content:
                print(f"✓ {description}")
            else:
                print(f"✗ {description} - NOT FOUND")
                all_found = False
        
        return all_found
    except Exception as e:
        print(f"✗ Error testing API routes: {e}")
        return False


async def main():
    """Run all tests."""
    print("=" * 60)
    print("Backend Async Transformation Validation")
    print("=" * 60)
    
    results = []
    
    # Test OpenRouter client
    results.append(await test_openrouter_client())
    
    # Test Supabase client
    results.append(await test_supabase_client())
    
    # Test voice providers
    results.append(await test_voice_providers())
    
    # Test API routes
    results.append(await test_api_routes())
    
    print("\n" + "=" * 60)
    print("Test Summary")
    print("=" * 60)
    
    if all(results):
        print("✓ All async transformation tests PASSED!")
        print("\nThe backend has been successfully transformed to async:")
        print("  - OpenRouter client: Fully async")
        print("  - Supabase client: Async wrapper implemented")
        print("  - Voice providers: Fully async")
        print("  - API routes: Using await for all async operations")
        return 0
    else:
        print("✗ Some async transformation tests FAILED")
        print("Please review the errors above")
        return 1


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)
