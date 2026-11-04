# App Acta Reuniones Externas · GAM-F-006

App para celular (Android e iPhone) que permite diligenciar el acta de reuniones externas **GAM-F-006**, firmarla en pantalla, escanear los listados de asistencia y exportar el PDF con la misma estética del formato original. Funciona sin internet y puede enviar las actas a una carpeta de SharePoint/OneDrive.

## Estructura

| Carpeta / archivo | Contenido |
|---|---|
| `src/` | Código fuente: `app.html` (app), `envio-core.js` (bandeja de envío), `sw.js` (modo sin conexión y actualización), `manifest.webmanifest`, íconos e `iconos.ps1` |
| `recursos/` | `pdf-lib.min.js` y la plantilla original `plantilla_GAM-F-006.pdf` |
| `web/` | **Versión publicable** (la genera `build.ps1`). Es la carpeta que se sirve en el sitio web |
| `publicar/` | Versión para la página de claude.ai |
| `ActaReunionesExternas.html` | App en un solo archivo (se abre sin internet) |
| `GUIA_POWER_AUTOMATE.md` | Cómo configurar la subida automática y cómo publicar/instalar la app |

## Construir y publicar

```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1          # solo construir
powershell -ExecutionPolicy Bypass -File .\publicar-web.ps1   # construir y subir a GitHub
```

El sitio web (por ejemplo Netlify) debe publicar la carpeta **`web`** de la rama `main`, sin comando de construcción. Cada subida a GitHub actualiza el sitio, y la app instalada en los celulares se actualiza sola al abrirla.
