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
- Register: `POST /api/auth/register/`
- Login: `POST /api/auth/login/`

## Mobile connectivity (Android device)

1. Start backend on all interfaces:
   - `python manage.py runserver 0.0.0.0:8000`
2. Find your PC LAN IP (example `192.168.1.10`)
3. Run Flutter with API URL:
   - `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api`
