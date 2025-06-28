# Domain Status Monitor

Una aplicación Flutter moderna para monitorear el estado de dominios y sitios web en tiempo real.

## Características

- 🌐 **Monitoreo de dominios:** Agrega y monitorea múltiples dominios o URLs
- ⚡ **Verificación automática:** Comprueba el estado cada 2 minutos automáticamente
- 📊 **Tiempo de respuesta:** Muestra el tiempo de respuesta de cada dominio
- 💾 **Persistencia:** Los dominios se guardan localmente usando SharedPreferences
- 🎨 **Interfaz moderna:** UI limpia y responsive con Material Design 3
- 🔄 **Verificación manual:** Opción para verificar dominios individualmente o todos a la vez

## Funcionalidades

### Agregar Dominios
- Agrega dominios con nombre personalizado y URL
- Soporta URLs con o sin protocolo (http/https)
- Validación de entrada de datos

### Monitoreo en Tiempo Real
- Indicadores visuales de estado (verde/rojo)
- Tiempo de respuesta con código de colores:
  - Verde: < 300ms (Excelente)
  - Naranja: 300-1000ms (Bueno)
  - Rojo: > 1000ms (Lento)
- Última verificación con timestamps relativos

### Gestión de Dominios
- Eliminar dominios con confirmación
- Verificación individual por dominio
- Verificación masiva de todos los dominios

## Instalación

1. Clona el repositorio:
```bash
git clone <repository-url>
cd domain_status
```

2. Instala las dependencias:
```bash
flutter pub get
```

3. Ejecuta la aplicación:
```bash
flutter run
```

## Dependencias

- `http`: Para realizar peticiones HTTP a los dominios
- `shared_preferences`: Para almacenar los dominios localmente
- `async`: Para manejo de tareas asíncronas

## Uso

1. **Agregar un dominio:**
   - Toca el botón flotante (+)
   - Ingresa el nombre del dominio
   - Ingresa la URL (con o sin http/https)
   - Toca "Agregar"

2. **Verificar estado:**
   - La aplicación verifica automáticamente cada 2 minutos
   - Usa el botón de refresh en la AppBar para verificar todos
   - Usa el menú de 3 puntos en cada dominio para verificar individualmente

3. **Eliminar dominios:**
   - Toca el menú de 3 puntos en el dominio
   - Selecciona "Eliminar"
   - Confirma la eliminación

## Arquitectura

La aplicación está construida con:
- **Estado local:** Usando StatefulWidget para manejar la UI
- **Persistencia:** SharedPreferences para guardar los datos
- **Networking:** HTTP client para verificar el estado de los dominios
- **Timers:** Para verificaciones periódicas automáticas

## Contribuir

1. Haz fork del proyecto
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Haz commit de tus cambios (`git commit -am 'Agrega nueva funcionalidad'`)
4. Haz push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.
