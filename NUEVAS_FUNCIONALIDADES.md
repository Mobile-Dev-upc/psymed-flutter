# Nuevas Funcionalidades Agregadas - Tasks y Analytics

Este documento describe las nuevas funcionalidades agregadas a la aplicación móvil de PsyMed Flutter, basadas en el frontend web Angular.

## 📋 Resumen de Cambios

Se han agregado dos nuevas secciones principales a la aplicación:

1. **Tasks (Tareas)** - Para que los pacientes vean y gestionen las tareas asignadas por sus terapeutas
2. **Analytics (Estadísticas)** - Para visualizar el estado emocional y físico del paciente con gráficos interactivos

## 🆕 Nuevos Archivos Creados

### Modelos
- `lib/models/task_model.dart` - Modelo para las tareas
- `lib/models/mood_state_model.dart` - Modelo para estados de ánimo y analytics
- `lib/models/biological_functions_model.dart` - Modelo para funciones biológicas y analytics

### Servicios
- `lib/services/task_service.dart` - Servicios HTTP para tareas
- `lib/services/analytics_service.dart` - Servicios HTTP para estadísticas

### Providers (Gestión de Estado)
- `lib/providers/task_provider.dart` - Provider para gestionar el estado de las tareas
- `lib/providers/analytics_provider.dart` - Provider para gestionar el estado de analytics

### Pantallas
- `lib/screens/tasks_screen.dart` - Pantalla principal de tareas
- `lib/screens/analytics_screen.dart` - Pantalla principal de estadísticas

## 📱 Funcionalidades Implementadas

### Tasks Screen (Pantalla de Tareas)

**Características:**
- ✅ Vista de todas las tareas asignadas al paciente
- ✅ Tarjeta de progreso con estadísticas:
  - Tareas completadas
  - Tareas pendientes
  - Tasa de finalización
  - Barra de progreso visual
- ✅ Lista de tareas con:
  - Checkbox para marcar como completa/incompleta
  - Estado visual (Done/Pending)
  - Título y descripción
  - Tachado de texto para tareas completadas
- ✅ Modal de detalles de tarea al hacer tap
- ✅ Pull to refresh para actualizar datos
- ✅ Estados de carga y error con reintentos
- ✅ Diseño moderno con gradientes y sombras

**Endpoints utilizados:**
- `GET /api/v1/patients/{patientId}/tasks` - Obtener todas las tareas del paciente
- `POST /api/v1/sessions/{sessionId}/tasks/{taskId}/complete` - Marcar como completa
- `POST /api/v1/sessions/{sessionId}/tasks/{taskId}/incomplete` - Marcar como incompleta

### Analytics Screen (Pantalla de Estadísticas)

**Características:**

#### Tab 1: Estado Emocional
- ✅ Gráfico de pastel (Pie Chart) mostrando la distribución de estados de ánimo:
  - So Sad 😢
  - Sad 😕
  - Neutral 😐
  - Happy 😊
  - So Happy 😄
- ✅ Leyenda con contadores de cada estado
- ✅ Lista de entradas recientes de estado de ánimo
- ✅ Formulario para agregar nuevo estado de ánimo

#### Tab 2: Salud Física
- ✅ Tarjeta de promedios mensuales mostrando:
  - 🍽️ Hambre (Hunger)
  - 💧 Hidratación (Hydration)
  - 😴 Sueño (Sleep)
  - ⚡ Energía (Energy)
- ✅ Gráfico de barras con promedios mensuales
- ✅ Gráfico de líneas mostrando tendencia semanal de los últimos 7 días
- ✅ Lista de entradas recientes
- ✅ Formulario con sliders para agregar nueva entrada

**Características comunes:**
- ✅ Navegación por tabs entre Estado Emocional y Salud Física
- ✅ Pull to refresh
- ✅ Floating Action Button para agregar nuevas entradas
- ✅ Modal con tabs para elegir tipo de entrada (Mood/Physical)
- ✅ Estados de carga y error
- ✅ Diseño responsive y moderno

**Endpoints utilizados:**
- `GET /api/v1/mood-state-analytics?patientId={id}&year={year}&month={month}` - Analytics de estado de ánimo
- `GET /api/v1/biological-functions-analytics?patientId={id}&year={year}&month={month}` - Analytics biológicos
- `GET /api/v1/mood-states?patientId={id}` - Lista de estados de ánimo
- `GET /api/v1/biological-functions?patientId={id}` - Lista de funciones biológicas
- `POST /api/v1/mood-states` - Crear nuevo estado de ánimo
- `POST /api/v1/biological-functions` - Crear nueva entrada biológica

## 🎨 Diseño y UX

### Características de Diseño:
- **Colores**: Paleta moderna con negro, blanco y colores de acento
- **Tipografía**: Sistema de fuentes con jerarquía clara
- **Espaciado**: Uso consistente de padding y margins
- **Shadows**: Sombras sutiles para profundidad
- **Gradientes**: Gradientes modernos en tarjetas destacadas
- **Iconos**: Icons de Material Design
- **Animaciones**: Transiciones suaves y feedback visual

### Componentes Reutilizables:
- Cards con diseño consistente
- Badges de estado
- Progress bars
- Modal bottom sheets
- Empty states
- Loading indicators
- Error screens con retry

## 🔧 Cambios en Archivos Existentes

### `lib/main.dart`
- Agregados `TaskProvider` y `AnalyticsProvider` a MultiProvider

### `lib/screens/home_screen.dart`
- Agregadas nuevas pantallas: `TasksScreen` y `AnalyticsScreen`
- Actualizado BottomNavigationBar con 6 items (agregados Tasks y Analytics)
- Cambiado tipo a `BottomNavigationBarType.fixed` para soportar 6+ items

### `pubspec.yaml`
- Agregada dependencia: `fl_chart: ^0.66.0` para gráficos

## 🚀 Cómo Usar

### Para Pacientes:

#### Tasks (Tareas):
1. Navega a la pestaña "Tasks" en el bottom navigation
2. Verás tus tareas asignadas por tu terapeuta
3. Toca el checkbox para marcar una tarea como completa o incompleta
4. Toca una tarea para ver más detalles
5. Desliza hacia abajo para actualizar la lista

#### Analytics (Estadísticas):
1. Navega a la pestaña "Analytics" en el bottom navigation
2. Usa los tabs para cambiar entre "Emotional State" y "Physical Health"
3. Revisa tus gráficos y estadísticas
4. Toca el botón "Add Entry" para agregar una nueva entrada:
   - Para estado de ánimo: selecciona un emoji que represente cómo te sientes
   - Para salud física: ajusta los sliders para cada métrica
5. Desliza hacia abajo para actualizar los datos

## 📊 Gráficos Implementados

1. **Pie Chart** - Para distribución de estados de ánimo
2. **Bar Chart** - Para promedios mensuales de métricas biológicas
3. **Line Chart** - Para tendencias semanales de salud física

## 🔗 Integración con Backend

Todas las funcionalidades están conectadas al backend existente usando los mismos endpoints que el frontend web Angular. La aplicación mobile es completamente funcional y se sincroniza con el backend en tiempo real.

## ⚠️ Consideraciones Importantes

1. **Token de Autenticación**: Todas las llamadas API requieren el token Bearer del usuario autenticado
2. **Patient ID**: Las funcionalidades requieren que el usuario tenga un perfil de paciente activo
3. **Conexión al Backend**: Asegúrate de que `ApiService.baseUrl` esté configurado correctamente en `lib/services/api_services.dart`

## 🎯 Próximos Pasos (Opcional)

Posibles mejoras futuras:
- [ ] Filtros por fecha en Analytics
- [ ] Notificaciones push para nuevas tareas
- [ ] Exportar estadísticas a PDF
- [ ] Comparación entre meses en Analytics
- [ ] Edición de tareas (solo para profesionales)
- [ ] Comentarios en tareas
- [ ] Calendario de estado de ánimo (Mood Calendar)

## 📝 Notas Técnicas

- **State Management**: Provider
- **HTTP Client**: http package
- **Charts Library**: fl_chart
- **UI Framework**: Material Design 3
- **Arquitectura**: Clean Architecture con separación de modelos, servicios, providers y vistas

---

**Fecha de Implementación**: 11 de Noviembre, 2025
**Basado en**: Frontend Web Angular de PsyMed

