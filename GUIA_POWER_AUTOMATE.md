# Subida automática de actas a SharePoint / OneDrive con Power Automate

La app guarda cada acta en una **bandeja de envío** dentro del celular. Apenas hay conexión, envía el PDF a un **flujo de Power Automate**, y el flujo lo guarda en la carpeta que eligió quien llenó el acta.

```
Celular (app)  ──►  Flujo de Power Automate  ──►  Carpeta de SharePoint / OneDrive / Teams
 (sin señal: queda en cola y se reintenta sola)
```

> **Requisitos**
> - Licencia **Power Automate Premium**: el disparador “Cuando se recibe una solicitud HTTP” es Premium. Si no la tienes, pide a TI que cree el flujo con una cuenta que sí la tenga.
> - La cuenta dueña del flujo debe tener permiso de **edición** en las carpetas donde se guardarán las actas.

---

## 1. Crear el flujo

1. Entra a <https://make.powerautomate.com> con tu cuenta de Celsia.
2. **Crear** → **Flujo de nube instantáneo** → nombre: `Actas GAM-F-006 - Recibir PDF` → elige el disparador **Cuando se recibe una solicitud HTTP** → **Crear**.
3. En el disparador:
   - **Quién puede desencadenar el flujo:** `Cualquiera` (la app no inicia sesión; la dirección del flujo funciona como clave).
   - **Esquema JSON del cuerpo de la solicitud:** pega esto:

```json
{
  "type": "object",
  "properties": {
    "nombreArchivo":   { "type": "string" },
    "sitio":           { "type": "string" },
    "carpeta":         { "type": "string" },
    "contenidoBase64": { "type": "string" },
    "acta": {
      "type": "object",
      "properties": {
        "numero":       { "type": "string" },
        "fecha":        { "type": "string" },
        "asunto":       { "type": "string" },
        "proyecto":     { "type": "string" },
        "responsable":  { "type": "string" },
        "lugar":        { "type": "string" },
        "elaboradaPor": { "type": "string" }
      }
    },
    "generado": { "type": "string" },
    "origen":   { "type": "string" }
  },
  "required": ["nombreArchivo", "sitio", "carpeta", "contenidoBase64"]
}
```

## 2. (Recomendado) Permitir solo sitios de Celsia

Así nadie puede usar el flujo para escribir fuera de Celsia.

1. **Nuevo paso** → **Condición**.
2. Valor: `sitio` (contenido dinámico) · **empieza por** · `https://celsia.sharepoint.com`
   - Para aceptar también OneDrive personal, agrega con **O** una segunda fila: `sitio` **empieza por** `https://celsia-my.sharepoint.com`.
3. En **Si no** agrega la acción **Respuesta**: código `403`, cuerpo `{"error":"Sitio no permitido"}`.
4. Pon los pasos 3 y 4 de abajo dentro de **Si es sí**.

## 3. Guardar el PDF en la carpeta

Acción **SharePoint → Crear archivo**:

| Campo | Valor |
|---|---|
| Dirección del sitio | **Escribir un valor personalizado** → contenido dinámico `sitio` |
| Ruta de acceso de la carpeta | contenido dinámico `carpeta` |
| Nombre de archivo | contenido dinámico `nombreArchivo` |
| Contenido del archivo | **Expresión:** `base64ToBinary(triggerBody()?['contenidoBase64'])` |

> La app agrega la hora al nombre del archivo (por ejemplo `GAM-F-006_Acta_021_04-11-2026_143015.pdf`), así que dos envíos nunca se pisan.

## 4. Responder a la app

Acción **Respuesta** (Solicitud):

- **Código de estado:** `200`
- **Encabezados:** `Access-Control-Allow-Origin` = `*`  ·  `Content-Type` = `application/json`
- **Cuerpo:** `{"ok": true}`

En **Configuración** de la acción *Crear archivo*, no hace falta nada más: si falla, el flujo devuelve error y la app lo muestra en la bandeja para reintentarlo.

## 5. Copiar la dirección del flujo

1. **Guardar** el flujo.
2. Abre de nuevo el disparador y copia la **URL de HTTP POST**. Es larga y empieza por `https://...`.
3. Compártela solo con quienes van a usar la app (por Teams o correo interno). **Cualquier persona con esa dirección puede enviar archivos al flujo.**

---

## 6. Configurar la app en el celular (una sola vez)

En la sección **7 · Carpeta donde se guardan las actas**:

1. **🔗 Elegir carpeta:** abre la carpeta de destino en SharePoint u OneDrive desde el navegador, copia la dirección de la barra y pégala. La app detecta el **sitio** y la **carpeta**; revisa que estén bien.
   - Los enlaces “para compartir” (los que contienen `/:f:/`) no traen la ruta. En ese caso escribe a mano el sitio (por ejemplo `https://celsia.sharepoint.com/sites/GestionSocial`) y la carpeta (por ejemplo `/Documentos compartidos/Actas 2026`).
2. **⚙️ Configurar flujo:** pega la URL del paso 5.

Todo queda guardado en el celular. Se puede cambiar sin internet y no se borra con «Nueva acta».

## 7. Uso diario

1. Llenar el acta → **Generar PDF** → **☁️ Enviar a «carpeta»**.
2. Con señal, se sube en segundos. Sin señal, queda **Pendiente** en la *Bandeja de envío* y se sube sola:
   - al recuperar la conexión,
   - al volver a abrir la app,
   - y cada 30 segundos mientras la app está abierta.
   - En **Android con Chrome** y la app instalada, también se sube aunque la app esté cerrada (sincronización en segundo plano). En **iPhone** hay que abrir la app para que suba lo pendiente.
3. Arriba a la derecha el indicador muestra `● En línea · N por subir` o `○ Sin conexión`.

---

## Dónde debe alojarse la app

La subida automática **no funciona en la página publicada en claude.ai**, porque esa página tiene bloqueadas las conexiones a otros sitios. Usa una de estas opciones:

| Versión | Sin internet | Subida automática | Cómo se usa |
|---|---|---|---|
| Carpeta `web/` en un sitio propio (https) | ✅ (se instala como app) | ✅ incluso en segundo plano (Android) | Subir la carpeta `web/` a un hosting estático: GitHub Pages, Azure Static Web Apps (TI) o Netlify. Luego, en el celular, abrir el enlace → menú → **Agregar a la pantalla de inicio**. |
| Archivo `ActaReunionesExternas.html` | ✅ | ✅ mientras la app esté abierta | Enviar el archivo al celular y abrirlo con Chrome. |
| Página de claude.ai | ❌ | ❌ (abre la carpeta para subirla a mano) | Enlace privado de Claude. |

> SharePoint no sirve para alojar la app: descarga los archivos `.html` en vez de abrirlos como página.

### Publicar la app (una sola vez)

El archivo **`ActasGS-app-web.zip`** contiene la carpeta `web/` lista. Debe quedar en una dirección **https**. Opciones:

- **Netlify Drop** (la más rápida): entra a <https://app.netlify.com/drop>, crea una cuenta y arrastra la carpeta `web/` descomprimida. Te da un enlace `https://….netlify.app`.
- **GitHub Pages**: crea un repositorio, sube el contenido de `web/` y activa *Settings → Pages*.
- **Azure Static Web Apps**: pídelo a TI si se requiere un dominio de Celsia.

Para publicar una versión nueva, sube otra vez el contenido de `web/`. Los celulares con la app instalada se actualizan solos la próxima vez que la abran con señal.

### Instalar en el celular

| | Android (Chrome, Edge, Samsung Internet) | iPhone / iPad (Safari; Chrome o Edge desde iOS 16.4) |
|---|---|---|
| 1 | Abrir el enlace de la app. | Abrir el enlace de la app. |
| 2 | Tocar **📲 Instalar app** en la tarjeta naranja, o el menú **⋮ → Instalar app**. | Tocar **Compartir** ⬆️ → **Agregar a pantalla de inicio** → **Agregar**. |
| 3 | Abrir **Actas GS** desde la pantalla de inicio. | Abrir **Actas GS** desde la pantalla de inicio. |

La app instalada abre a pantalla completa, funciona sin internet y guarda los borradores y la bandeja de envío en el teléfono. **Úsala siempre desde el ícono de la pantalla de inicio**: en iPhone, Safari y la app instalada guardan sus datos por separado.

## Problemas frecuentes

| Mensaje en la bandeja | Causa / solución |
|---|---|
| *No se pudo contactar el flujo* (con señal) | La URL del flujo está mal copiada, o falta el encabezado `Access-Control-Allow-Origin: *` en la respuesta (paso 4). Revisa también que «Quién puede desencadenar» esté en *Cualquiera*. |
| *El flujo respondió 400/404* | Sitio o carpeta mal escritos, o la carpeta no existe. Corrige en la sección 7 y toca ↻. |
| *El flujo respondió 401/403* | El flujo no permite ese sitio (paso 2) o la cuenta del flujo no tiene permiso en la carpeta. |
| *El flujo respondió 502* | Error interno del flujo. En Power Automate abre **Historial de ejecuciones** para ver el detalle; la app lo reintenta sola. |
