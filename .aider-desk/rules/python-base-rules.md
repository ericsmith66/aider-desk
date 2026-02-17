# Python Development Standards

## 1. Environment & Versioning
- TARGET VERSION: Python 3.12+
- PACKAGE MANAGER: Prefer `uv` or `poetry`.
- VIRTUAL ENV: Always use a local `.venv`.

## 2. Code Style & Linting
- FORMATTER: Black or Ruff.
- LINTER: Ruff (preferred for speed and comprehensive rules).
- NAMING: PEP 8 (snake_case for functions/vars, PascalCase for classes).
- TYPING: Mandatory type hints for all function signatures. Use `Pydantic` for models.

## 3. Architecture
- FASTAPI/FLASK: Use Dependency Injection for services/repositories.
- ASYNCIO: Use `async/await` for I/O bound tasks. Avoid blocking calls in async loops.
- SCHEMAS: Separate API schemas from Database models (SQLAlchemy/Tortoise).

## 4. Testing
- FRAMEWORK: Pytest.
- FIXTURES: Use scoped fixtures in `conftest.py`.
- MOCKING: Use `pytest-mock` or `unittest.mock`.
- ASYNC TESTS: Use `pytest-asyncio`.

## 5. Documentation
- STYLE: Google or NumPy docstring format.
- TYPE HINTS: Do not repeat types in docstrings; let the type hints handle it.
