# Biblionet

Sistema de gestión de la biblioteca del Instituto Superior Universitario Japón.

La aplicación usa una sola base de código Flutter para Windows, web y Android, una API REST en Node.js y PostgreSQL.

**Estudiante:** Siomey Elizabeth Romero Tituaña  
**Docente:** MSc. Luis Calo

## Estructura

```
Biblioteca/
├── database/sert_biblioteca.sql    Base sert_Biblionet
├── backend/                        API Express (MVC)
│   └── src/
│       ├── server.js
│       ├── db.js
│       ├── controllers y services vía server.js
│       ├── repositories/
│       └── middleware/auth.js
└── app/                            Flutter: models, views, controllers, services
```

## Cuentas de prueba

| Rol | Usuario | Contraseña |
| --- | --- | --- |
| Administrador | admin | admin123 |
| Bibliotecario | biblio | biblio123 |
| Lector | lector | lector123 |

## Cómo ejecutarlo

1. Cree la base y ejecute `database/sert_biblioteca.sql`.
2. Copie `backend/.env.example` a `backend/.env` (o use el `.env` de la raíz con `DATABASE_URL`).
3. En una terminal:

```bash
cd backend
npm install
npm start
```

4. En otra terminal, elija la plataforma:

```bash
cd app
flutter pub get
flutter run -d windows
flutter run -d chrome
flutter build apk
```

En Windows también puede usar `INICIAR_SISTEMA.bat` o `INICIAR_WEB.bat`.

La API queda en `http://localhost:3000`. En el emulador Android la aplicación usa `http://10.0.2.2:3000`.
