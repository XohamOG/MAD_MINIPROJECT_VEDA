# Veda Django Backend

Django backend configured for API development with DRF and CORS.

## Setup

1. Install dependencies:
   - `pip install -r requirements.txt`
2. Add environment file:
   - copy `.env.example` to `.env`
3. Run migrations:
   - `python manage.py migrate`
4. Start server:
   - `python manage.py runserver`

## API

- Health check: `GET /api/health/`
