"""Story content validator: detects and trims gibberish/word-salad tails from generated stories."""

import re
import logging
from typing import Tuple

from src.core.logging import get_logger

logger = get_logger("langgraph.story_content_validator")

# Tail analysis: look at last N words or last fraction of text
TAIL_WORDS_MAX = 400
TAIL_FRACTION = 0.25  # last 25% of story
MIN_STORY_WORDS = 50  # skip validation for very short texts

# Sentence structure: gibberish often has long runs without . ! ?
MAX_WORDS_WITHOUT_SENTENCE_END = 80

# Type-token ratio in tail: low = lots of repetition (gibberish)
# Normal narrative often 0.4-0.8; word salad can be < 0.3
TYPE_TOKEN_RATIO_THRESHOLD = 0.35

# If tail has much fewer sentence endings per word than the rest, flag it
# sentence_ends_per_100_words: normal ~3-8, gibberish ~0-1
TAIL_SENTENCE_END_RATIO_MIN = 0.5  # tail must have at least this fraction of body's ratio

# Marker words/phrases that strongly suggest religious or exclamatory gibberish
GIBBERISH_MARKERS = frozenset({
    "amen", "hallelujah", "hooray", "yippee", "yay", "whoopee", "whee", "yahoo",
    "goodness", "gracious", "golly", "gee", "gosh", "darn", "shucks", "mercy",
    "fiddlesticks", "golliwog", "doodads", "flabbergasted", "awestruck", "dumbfounded",
    "hip-hip", "hurray", "glory", "praise", "blessing", "bless", "praising",
    "goodness gracious", "golly gee", "land sake", "heavens above", "oopsie daisy",
})

# Compile pattern for marker detection (whole words, case-insensitive)
_GIBBERISH_PATTERN = re.compile(
    r"\b(" + "|".join(re.escape(m) for m in sorted(GIBBERISH_MARKERS, key=len, reverse=True)) + r")\b",
    re.IGNORECASE
)


def _get_tail_tokens(content: str, tail_words: int) -> list:
    """Return list of tokens (words) from the last tail_words of content."""
    tokens = content.split()
    if len(tokens) <= tail_words:
        return tokens
    return tokens[-tail_words:]


def _count_sentence_ends(text: str) -> int:
    """Count sentence-ending punctuation (. ! ?) in text."""
    return sum(1 for c in text if c in ".!?")


def _sentence_ends_per_100_words(tokens: list, text_slice: str) -> float:
    """Sentence ends per 100 words in the given text slice. Uses token count for words."""
    if not tokens:
        return 0.0
    n = _count_sentence_ends(text_slice)
    return (n / len(tokens)) * 100.0 if tokens else 0.0


def _type_token_ratio(tokens: list) -> float:
    """Type-token ratio: unique words / total words. Low = repetitive."""
    if not tokens:
        return 0.0
    return len(set(tokens)) / len(tokens)


def _tail_has_markers(tail_text: str) -> bool:
    """True if tail contains known gibberish marker words/phrases."""
    return _GIBBERISH_PATTERN.search(tail_text) is not None


def _long_run_without_sentence_end(tail_text: str) -> bool:
    """True if tail has a run of more than MAX_WORDS_WITHOUT_SENTENCE_END words without . ! ?"""
    tokens = tail_text.split()
    if len(tokens) <= MAX_WORDS_WITHOUT_SENTENCE_END:
        return False
    run = 0
    for t in tokens:
        if t.rstrip(".,;:!?") and t.rstrip(".,;:!?") == t:
            run += 1
        if t.endswith(".") or t.endswith("!") or t.endswith("?"):
            run = 0
        if run >= MAX_WORDS_WITHOUT_SENTENCE_END:
            return True
    return False


def _find_last_good_sentence_end(content: str) -> int:
    """Return index of the last character of the last 'good' sentence (before gibberish).
    Searches backwards for . ! ? and returns the position right after that character.
    """
    for i in range(len(content) - 1, -1, -1):
        if content[i] in ".!?":
            return i + 1
    return 0


def detect_and_trim_gibberish_tail(content: str) -> Tuple[bool, str]:
    """Detect a gibberish/word-salad tail at the end of story content and trim it if present.

    Heuristics used:
    - Tail = last N words (capped by TAIL_WORDS_MAX) or last TAIL_FRACTION of text.
    - Low type-token ratio in tail (repetition).
    - Few sentence endings in tail vs rest of text.
    - Presence of marker words (amen, hallelujah, etc.).
    - Very long run of words without . ! ?

    Args:
        content: Full story text.

    Returns:
        (has_gibberish_tail, trimmed_content).
        If has_gibberish_tail is True, trimmed_content is content cut at the last
        sentence end before the gibberish. Otherwise trimmed_content equals content.
    """
    if not content or not content.strip():
        return False, content

    stripped = content.strip()
    tokens = stripped.split()
    if len(tokens) < MIN_STORY_WORDS:
        return False, content

    tail_size = min(TAIL_WORDS_MAX, max(int(len(tokens) * TAIL_FRACTION), 100))
    tail_tokens = _get_tail_tokens(stripped, tail_size)
    # Character index where tail (last tail_size words) starts
    body_word_count = len(tokens) - tail_size
    if body_word_count <= 0:
        tail_start_char = 0
        body_tokens_list = []
    else:
        # Find start of (body_word_count+1)-th word in stripped
        tail_start_char = 0
        count = 0
        for m in re.finditer(r"\S+", stripped):
            count += 1
            if count > body_word_count:
                tail_start_char = m.start()
                break
        body_tokens_list = tokens[:body_word_count]
    tail_text = stripped[tail_start_char:].lstrip() if tail_start_char < len(stripped) else stripped

    # Body: everything before tail (for ratio comparison)
    body_text = stripped[:tail_start_char].strip() if tail_start_char > 0 else ""
    body_tokens = body_text.split() if body_text else []

    score = 0.0
    reasons = []

    # 1) Type-token ratio in tail
    ttr = _type_token_ratio(tail_tokens)
    if ttr < TYPE_TOKEN_RATIO_THRESHOLD:
        score += 1.0
        reasons.append(f"low_ttr={ttr:.2f}")

    # 2) Sentence end density: tail much lower than body
    tail_ratio = _sentence_ends_per_100_words(tail_tokens, tail_text)
    if body_tokens:
        body_ratio = _sentence_ends_per_100_words(body_tokens, body_text)
        if body_ratio > 0.5 and tail_ratio < body_ratio * TAIL_SENTENCE_END_RATIO_MIN:
            score += 1.0
            reasons.append("tail_few_sentences")
    elif tail_ratio < 1.0:  # less than 1 sentence end per 100 words in tail
        score += 0.5
        reasons.append("tail_almost_no_sentences")

    # 3) Marker words
    if _tail_has_markers(tail_text):
        score += 1.0
        reasons.append("gibberish_markers")

    # 4) Long run without sentence end
    if _long_run_without_sentence_end(tail_text):
        score += 1.0
        reasons.append("long_run_no_sentence_end")

    has_gibberish = score >= 1.5  # at least two strong signals

    if not has_gibberish:
        return False, content

    # Trim: keep content up to (and including) last sentence end before tail
    # We trim from the start of the tail region back to last . ! ?
    trim_at = _find_last_good_sentence_end(stripped[:tail_start_char]) if tail_start_char > 0 else 0
    if trim_at <= 0:
        # No sentence end found in body; keep up to tail start
        trim_at = tail_start_char if tail_start_char > 0 else len(stripped)

    trimmed = stripped[:trim_at].strip()
    if not trimmed:
        trimmed = content  # fallback: do not trim to empty

    logger.info(
        "Gibberish tail detected and trimmed: %s (score=%.1f). Trimmed %d -> %d chars",
        reasons, score, len(content), len(trimmed)
    )
    return True, trimmed
