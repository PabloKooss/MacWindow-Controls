# MacWindow Controls

Widget nativo para KDE Plasma 6 que muestra los botones de la ventana (cerrar, minimizar,
maximizar/restaurar) con el estilo de los "semáforos" de macOS directamente en el panel
superior cuando hay una ventana maximizada.

- Rojo: cerrar. Amarillo: minimizar. Verde: restaurar (o maximizar, ver Configuración).
- Los botones se ponen grises cuando la ventana objetivo no tiene el foco; al pasar el ratón
  aparecen los símbolos.
- Funciona sobre la ventana correcta aunque el foco esté en un diálogo u otra ventana.

## Requisitos

- KDE Plasma 6 (`X-Plasma-API-Minimum-Version: 6.0`). Desarrollado y probado en Plasma 6.3.6 sobre Wayland.
- `kpackagetool6` (incluido con Plasma 6) y `zip` (solo para generar el `.plasmoid`).
- Sin C++, sin compilar, sin scripts de KWin: es QML puro.

No probado: sesión X11, varios monitores y paneles verticales (ver Limitaciones).

## Instalación

### A) Con el script (recomendado)

    unzip macwindow-controls-0.7.0.zip -d ~/mwc && cd ~/mwc/macwindow-controls
    ./install.sh
    systemctl --user restart plasma-plasmashell.service

`install.sh` muestra la carpeta de origen y la versión, y comprueba al final que la versión
instalada coincide con la del paquete. Se niega a instalar desde la papelera.
Instala solo en tu usuario (`~/.local/share/plasma/plasmoids/`); no toca archivos de KDE.

### B) Con el archivo .plasmoid

    kpackagetool6 --type Plasma/Applet --install macwindow-controls-0.7.0.plasmoid

o desde la interfaz: Añadir widgets > Obtener nuevos widgets > Instalar widget desde un archivo
local (el nombre exacto del menú puede variar según la versión de Plasma).
Para actualizar, usa `--upgrade` en lugar de `--install`.

### Comprobar la instalación

    journalctl --user -f | grep -i -E "MacWindow|macwindowcontrols"

Al cargar el widget debe aparecer `[MacWindow] loaded: build 0.7.0 ...`.

## Colocarlo en el panel

1. Clic derecho en el panel > Entrar en modo de edición.
2. Añadir widgets > "MacWindow Controls".
3. Arrástralo al extremo izquierdo del panel (como en macOS).

En modo de edición el widget muestra un recuadro resaltado aunque no haya ventana maximizada,
para poder moverlo o quitarlo. Fuera de ese modo se contrae a ancho cero y no deja hueco.
Con varios monitores, añade el widget al panel de cada pantalla: cada instancia solo sigue
las ventanas de su propia pantalla.

## Configuración

Clic derecho en el widget > Configurar MacWindow Controls...

| Ajuste | Valores | Por defecto |
|---|---|---|
| Activado | sí / no | sí |
| Tamaño de los botones | 8 a 32 px | 12 |
| Separación | 0 a 24 px | 8 |
| Animación | sí / no, 0 a 600 ms | sí, 150 ms |
| Solo con ventana maximizada | sí / no | sí |
| Ventanas de todas las actividades | sí / no | no (solo la actividad actual) |

Los tamaños son píxeles lógicos: siguen la escala de pantalla de KDE. Con "solo con ventana
maximizada" desactivado, los botones se muestran para cualquier ventana activa y el verde
maximiza en lugar de restaurar.

## Ocultar la barra de título nativa (opcional)

Para que las ventanas maximizadas no dupliquen los botones, KWin tiene un ajuste oculto que
quita la barra de título y los bordes de las ventanas maximizadas. Solo escribe en tu
`~/.config/kwinrc`:

    kwriteconfig6 --file ~/.config/kwinrc --group Windows --key BorderlessMaximizedWindows true
    qdbus6 org.kde.KWin /KWin reconfigure

Revertir:

    kwriteconfig6 --file ~/.config/kwinrc --group Windows --key BorderlessMaximizedWindows false
    qdbus6 org.kde.KWin /KWin reconfigure

Sin barra de título no hay botones de control: úsalo solo con este widget en el panel. Las
aplicaciones que dibujan su propia barra pueden no verse afectadas.

## Cómo funciona (arquitectura)

    package/
    ├── metadata.json
    └── contents/
        ├── config/       main.xml (claves), config.qml (pestañas)
        └── ui/
            ├── main.qml                 raíz (PlasmoidItem): ensambla todo, tamaño en el panel
            ├── configGeneral.qml        página de configuración
            ├── logic/
            │   ├── WindowTracker.qml    detección: decide la ventana objetivo
            │   └── WindowActions.qml    acciones: cerrar / minimizar / maximizar-restaurar
            └── components/
                ├── TrafficLights.qml    grupo de tres botones, animación
                └── TrafficLightButton.qml  botón circular (hover, pressed, símbolos)

**Dependencias (módulos QML):** `org.kde.taskmanager` (de plasma-workspace: `TasksModel`,
`VirtualDesktopInfo`, `ActivityInfo`), `org.kde.plasma.plasmoid`, `org.kde.plasma.core`,
`org.kde.kirigami`, `org.kde.kcmutils` (página de configuración) y `QtQuick.Shapes`.

**Comunicación con KWin:** no hay script de KWin, DBus propio ni código C++. El widget lee el
estado de las ventanas del modelo de tareas de Plasma (el mismo que usa el Administrador de
tareas), que obtiene los datos del sistema de ventanas, y ejecuta las acciones con los métodos
del propio modelo (`requestClose`, `requestToggleMinimized`, `requestToggleMaximized`).
Se eligió QML puro porque el ABI de `libtaskmanager` puede cambiar entre versiones menores de
Plasma, mientras que el módulo QML siempre coincide con el Plasma instalado.

**Ventana objetivo:**
1. La ventana activa, si está maximizada.
2. Si no, la maximizada más alta en el orden de apilamiento de la pantalla (`StackingOrder`;
   `LastActivated` desempata).
3. Si no hay ninguna, la ventana activa (solo se muestra si "solo maximizadas" está desactivado).

**Seguridad de las acciones:** al hacer clic, la ventana se vuelve a localizar por su identificador
(`winId`) y se verifica. Si ya no existe, o su estado maximizado cambió respecto a lo que se
mostraba, no se ejecuta nada (queda una línea `ABORTED` en el log). Así nunca se actúa sobre
otra ventana por un cambio de foco.

## Solución de problemas

- **El widget no aparece o no se actualiza:** `systemctl --user restart plasma-plasmashell.service`.
- **Comprueba qué versión corre:** busca `loaded: build ...` en el log (ver arriba). Si no
  coincide con la que instalaste, probablemente ejecutaste `install.sh` desde una carpeta antigua.
  Extrae el zip en una carpeta nueva y vuelve a instalar.
- **Líneas `ABORTED` en el log:** la comprobación de seguridad rechazó actuar; no es un error.
- **Errores de otros widgets** (por ejemplo `KPackageStructure ... does not match requested format`)
  vienen de widgets de Plasma 5 instalados, no de este.
  
## Limitaciones conocidas

- Sesión X11, varios monitores y paneles verticales sin probar (en vertical el widget se oculta).
- El rol `HasNoBorder` de `TasksModel` requiere Plasma 6.4 o superior; no se usa.
- El estado del modelo de tareas es asíncrono: puede haber un instante breve entre un cambio de
  ventana y la actualización de los botones.
- El tamaño de los botones es fijo (configurable) y no se adapta automáticamente a la altura del panel.

## Desinstalar

    ./uninstall.sh
    systemctl --user restart plasma-plasmashell.service

(o `kpackagetool6 --type Plasma/Applet --remove io.github.macwindowcontrols`). Quita antes el
widget del panel si sigue ahí.


## Licencia

GPL-2.0-or-later
