# Construye las 3 versiones de la app a partir de src\
#  1) ActaReunionesExternas.html  -> un solo archivo autónomo (se abre sin internet)
#  2) web\                         -> app instalable (PWA): sin internet + subida automática en segundo plano
#  3) publicar\                    -> página para claude.ai (pdf-lib desde cdnjs, sin subida automática)
$root = $PSScriptRoot
$utf8 = New-Object Text.UTF8Encoding($false)
$read = { param($p) [IO.File]::ReadAllText("$root\$p", [Text.Encoding]::UTF8) }
$app   = & $read 'src\app.html'
$lib   = & $read 'recursos\pdf-lib.min.js'
$envio = & $read 'src\envio-core.js'
$b64   = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$root\recursos\plantilla_GAM-F-006.pdf"))
$ver   = Get-Date -Format 'yyyyMMddHHmmss'

# 1) Archivo único
$single = $app.Replace('<!--PDFLIB-->', "<script>`n$lib`n</script>").Replace('<!--PLANTILLA-->', "<script>window.PLANTILLA_B64='$b64';</script>").Replace('<!--ENVIO-->', "<script>`n$envio`n</script>").Replace('<!--MANIFEST-->', '')
[IO.File]::WriteAllText("$root\ActaReunionesExternas.html", $single, $utf8)

# 2) Web instalable
New-Item -ItemType Directory -Force "$root\web" | Out-Null
$web = $app.Replace('<!--PDFLIB-->', '<script src="pdf-lib.min.js"></script>').Replace('<!--PLANTILLA-->', "<script>window.APP_WEB=true;window.APP_VERSION='$ver';</script>").Replace('<!--ENVIO-->', '<script src="envio-core.js"></script>').Replace('<!--MANIFEST-->', @'
<link rel="manifest" href="manifest.webmanifest">
<link rel="icon" type="image/png" sizes="32x32" href="favicon-32.png">
<link rel="apple-touch-icon" sizes="180x180" href="apple-touch-icon.png">
<meta name="apple-mobile-web-app-title" content="Actas GS">
<meta name="application-name" content="Actas GS">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<meta name="format-detection" content="telephone=no">
'@)
[IO.File]::WriteAllText("$root\web\index.html", $web, $utf8)
[IO.File]::WriteAllText("$root\web\sw.js", (& $read 'src\sw.js').Replace('__VERSION__', $ver), $utf8)
Copy-Item "$root\src\envio-core.js", "$root\src\manifest.webmanifest", "$root\src\*.png", "$root\recursos\pdf-lib.min.js", "$root\recursos\pdf.min.js", "$root\recursos\pdf.worker.min.js" "$root\web\" -Force
Compress-Archive -Path "$root\web\*" -DestinationPath "$root\ActasGS-app-web.zip" -Force
Copy-Item "$root\recursos\plantilla_GAM-F-006.pdf" "$root\web\plantilla.pdf" -Force

# 3) Página claude.ai
New-Item -ItemType Directory -Force "$root\publicar" | Out-Null
$pub = $app.Replace('<!--PDFLIB-->', '<script src="https://cdnjs.cloudflare.com/ajax/libs/pdf-lib/1.17.1/pdf-lib.min.js"></script>').Replace('<!--PLANTILLA-->', '').Replace('<!--ENVIO-->', "<script>`n$envio`n</script>").Replace('<!--MANIFEST-->', '')
[IO.File]::WriteAllText("$root\publicar\index.html", $pub, $utf8)
Copy-Item "$root\recursos\plantilla_GAM-F-006.pdf" "$root\publicar\plantilla.pdf" -Force

"OK -> ActaReunionesExternas.html ($([math]::Round((Get-Item "$root\ActaReunionesExternas.html").Length/1KB)) KB), web\ y publicar\  (versión $ver)"

