# iVend Wallet Backend

Modular Django backend for the iVend consumer mobile application.

## Database Strategy

This project automatically toggles its database based on the `DEBUG` flag in `settings.py`:

- **Development (`DEBUG = True`):** Uses **SQLite** (`db.sqlite3`). No setup required.
- **Production (`DEBUG = False`):** Uses **PostgreSQL** (`ivend_wallet_db`).

### Production PostgreSQL Setup

If you are deploying or testing with `DEBUG = False`, follow these steps:

1.  **Open PostgreSQL Shell (psql) or your database management tool.**
2.  **Run the following commands:**
    ```sql
    CREATE USER ivend WITH PASSWORD 'Iv@123456';
    CREATE DATABASE ivend_wallet_db OWNER ivend;
    GRANT ALL PRIVILEGES ON DATABASE ivend_wallet_db TO ivend;
    ```

## Local Development

1.  **Clone the repository.**
2.  **Create a virtual environment:**
    ```bash
    python -m venv venv
    source venv/bin/activate  # On Windows: venv\Scripts\activate
    ```
3.  **Install dependencies:**
    ```bash
    pip install -r requirements.txt
    ```
4.  **Run migrations:**
    ```bash
    python manage.py migrate
    ```
5.  **Create a superuser:**
    ```bash
    python manage.py createsuperuser
    ```
6.  **Run the development server:**
    ```bash
    python manage.py runserver
    ```

## Dashboard Access

Once the server is running, you can access the Admin Command Center at:
`http://127.0.0.1:8000/dashboard/`

## API Documentation

Interactive Swagger documentation is available at:
`http://127.0.0.1:8000/api/schema/swagger-ui/`
