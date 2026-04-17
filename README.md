<p align="center">
  <a href="https://flutter.dev" target="blank">
    <img src="https://www.vectorlogo.zone/logos/flutterio/flutterio-ar21.svg" width="250" alt="Flutter Logo" />
  </a>
</p>

<p align="center"><b>Sercom Frontend:</b> Interfaz móvil multiplataforma para la gestión de servicios técnicos.</p>

<p align="center">
<a href="https://flutter.dev" target="_blank"><img src="https://img.shields.io/badge/Platform-Flutter-02569B?style=flat-square&logo=flutter" alt="Flutter" /></a>
<a href="https://dart.dev" target="_blank"><img src="https://img.shields.io/badge/Language-Dart-0175C2?style=flat-square&logo=dart" alt="Dart" /></a>
</p>
# Sercom - Mobile App

Aplicación construida con **Flutter** que permite a los técnicos gestionar misiones y a los clientes solicitar servicios de forma intuitiva.

## Estructura del Proyecto
Basado en el análisis del repositorio actual:
- **`lib/core`**: Contiene el cliente de API (`api_client.dart`) para la comunicación con el Backend de NestJS.
- **`lib/screens`**: Interfaces de usuario (Login, Registro, etc.).
- **`lib/services`**: Lógica de consumo de servicios externos (Auth, Categorías).

## Configuración Inicial
1. Asegúrate de tener instalado el SDK de Flutter.
2. Obtener dependencias:
   ```bash
   flutter pub get
   ```

3. Ejecutar la aplicación:
   ```bash
   flutter run
   ```

## Conexión con el Backend
La aplicación se conecta al API de Sercom a través de la capa core. Asegúrate de que la URL base en api_client.dart apunte a tu servidor local o de despliegue.

## Equipo de Ingeniería

* **Luis Cadena:** Lider de proyecto
* **Santiago Grajales:** Scrum Master
* **Isabella:** UX/UI
* **Samuel:** Desarrollador Backend
* **Melissa:** Desarrolladora Backend
* **Valentina:** QA tester

### Recursos:

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.