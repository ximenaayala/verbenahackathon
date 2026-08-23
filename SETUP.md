# VERDANA Loop — demo NFC

Arquitectura de la demo:

```
iPhone (Swift + Core NFC)  --POST-->  server.py (tu laptop)  <--polling--  dashboard.html
        "varita lectora"                  puente local            PROYECTADO
```

Proyectas el laptop, no el teléfono. Al acercar el envase al iPhone, el dashboard
del proyector se actualiza en vivo.

---

## 1. Preparar los tags NFC

Usa tags NTAG213/215/216 (los más baratos y compatibles).

Escribe en cada tag un registro de texto NDEF con el id del activo:

```
VRD-4471-ES
VRD-4472-PL
VRD-4473-DK
```

App recomendada para escribir: "NFC Tools" (iOS o Android, gratis).
NFC Tools > Escribir > Añadir un registro > Texto > escribe el id > Escribir.

Etiqueta físicamente cada tag con su id, para saber cuál es cuál en la demo.

---

## 2. Levantar el servidor puente

En la laptop, misma red WiFi que el iPhone:

```bash
python3 server.py
```

Imprime algo como:

```
Servidor en http://0.0.0.0:8080
IP en tu red: 192.168.1.42
Dashboard:    http://192.168.1.42:8080/
```

Anota la IP. La necesitas en el paso 3.

Si el firewall bloquea, permite conexiones entrantes en el puerto 8080.

---

## 3. Configurar la app iOS

1. Abre Xcode > File > New > Project > iOS > App > SwiftUI.
   Nombre: `VerdanaLoop`.
2. Copia los 4 archivos `.swift` de esta carpeta al proyecto.
3. En `LoopStore.swift`, cambia `serverBaseURL` por la IP del paso 2.
4. Signing & Capabilities:
   - Selecciona tu Team (requiere Apple Developer Program de pago).
   - `+ Capability` > **Near Field Communication Tag Reading**.
5. Info.plist > añade la clave:
   - `NFCReaderUsageDescription` = "Leemos la etiqueta del envase para registrar tu devolucion."
6. Conecta el iPhone por cable, selecciónalo como destino y ejecuta.

---

## 4. Ensayo

1. Abre `dashboard.html` en el navegador del laptop (o la URL del paso 2).
2. Proyecta esa pestaña.
3. En el iPhone, pulsa "Devolver envase" y acerca el tag a la parte superior
   trasera del teléfono.
4. El dashboard debe mostrar el evento en menos de 2 segundos.

Ensaya el gesto al menos 5 veces. La antena NFC del iPhone está en el borde
superior de la parte trasera; si no lee, mueve el tag lentamente por esa zona.

---

## 5. Plan B (si no hay cuenta de desarrollador de pago)

El entitlement de NFC no funciona con firma gratuita. Alternativas por orden
de fiabilidad:

**B1. Android + Web NFC (sin cuenta, sin compilar).**
Chrome en Android soporta la Web NFC API. Sirve `reader.html` desde el mismo
servidor y ábrelo en el teléfono Android. Requiere HTTPS o localhost, así que
usa `adb reverse tcp:8080 tcp:8080` o un túnel. Cero fricción de firma.

**B2. Modo simulado.**
El dashboard incluye un botón oculto de simulación. En `dashboard.html` pulsa
la tecla `S` para inyectar un evento falso. Úsalo solo si el hardware falla en
vivo: la narrativa sigue funcionando y nadie nota la diferencia si lo ensayaste.

**B3. NFC Tools + atajo.**
Los tags NFC pueden almacenar una URL en vez de texto. Si escribes
`http://TU_IP:8080/scan?id=VRD-4471-ES`, cualquier iPhone abre esa URL al
acercar el tag, sin app ni cuenta de desarrollador. El servidor registra el
evento y redirige a una página de confirmación. Es la opción con menos control
visual pero la que no puede fallar.

La B3 es la que recomiendo tener cargada como respaldo real: no depende de
Xcode ni de firma, y usa el mismo servidor.

---

## 6. Proyección

- **Laptop al proyector**: HDMI o USB-C normal. Es lo único que necesitas.
- Si además quieres mostrar la pantalla del iPhone: conéctalo por cable al Mac,
  abre QuickTime Player > Archivo > Nueva grabación de película > en el menú de
  la cámara selecciona el iPhone. Se ve la pantalla en vivo, sin grabar.
- No dependas de AirPlay en la red del evento. Las redes de hackathon suelen
  bloquear el descubrimiento de dispositivos.
