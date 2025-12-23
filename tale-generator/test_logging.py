#!/usr/bin/env python3
"""Test script to verify logging configuration."""

import logging
import time

# Set up logger with the same configuration as populate_stories.py
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),  # Log to console
        logging.FileHandler('test_logging.log')  # Also log to file
    ]
)
logger = logging.getLogger("tale_generator.test")

def main():
    logger.info("Starting test logging...")
    
    # Simulate some operations with timing
    start_time = time.time()
    
    logger.info("Operation 1: Initializing...")
    time.sleep(0.1)  # Simulate work
    duration = time.time() - start_time
    logger.info(f"Operation 1 completed in {duration:.2f}s")
    
    logger.info("Operation 2: Processing data...")
    time.sleep(0.2)  # Simulate work
    duration = time.time() - start_time
    logger.info(f"Operation 2 completed in {duration:.2f}s")
    
    total_duration = time.time() - start_time
    logger.info(f"All operations completed in {total_duration:.2f}s")

if __name__ == "__main__":
    main()