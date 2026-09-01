from app.core.config import settings


def test_ai_credentials_are_disabled_in_tests():
    assert not settings.OPENAI_API_KEY
    assert not settings.DEEPSEEK_API_KEY
    assert not settings.XIAOMI_API_KEY
