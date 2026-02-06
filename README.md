<div align="center">

# carlos-statusline

![Bash](https://img.shields.io/badge/Bash-4EAA25?logo=gnubash&logoColor=white)
![Claude Code](https://img.shields.io/badge/Claude_Code-Plugin-blueviolet)
![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Dependencies](https://img.shields.io/badge/dependencies-0-brightgreen)
![License](https://img.shields.io/badge/license-MIT-green)

**Statusline avanzado para Claude Code con metricas en tiempo real, barra de progreso ANSI y cero dependencias.**

[Instalacion](#instalacion) •
[Como Funciona](#como-funciona) •
[Arquitectura](#arquitectura) •
[Extensibilidad](#extensibilidad)

</div>

---

## Features

| Feature | Descripcion |
|---------|-------------|
| Modelo activo | Identificacion color-coded (Cyan=Opus, Green=Sonnet, Yellow=Haiku) |
| Directorio de trabajo | Muestra el directorio actual con icono de carpeta |
| Branch de Git | Detecta y muestra la rama activa del repositorio |
| Barra de progreso | 6 bloques ANSI con colores dinamicos segun uso del contexto |
| Costo acumulado | Muestra el costo en USD con 2 decimales |
| Lineas +/- | Conteo de lineas agregadas (verde) y eliminadas (rojo) |

### Vista previa

```
[Opus 4.6] │ 📁 mi-proyecto │ 🌿 main │ [███░░░] 48% │ $1.25 │ +142/-38
```

## Instalacion

### Prerequisitos

- Claude Code CLI instalado
- Bash 4.0+
- Git (opcional, para deteccion de branches)

### Setup

```bash
# 1. Clonar o copiar el plugin al directorio de plugins
mkdir -p ~/.claude/plugins/carlos-statusline
cp -r . ~/.claude/plugins/carlos-statusline/

# 2. Dar permisos de ejecucion
chmod +x ~/.claude/plugins/carlos-statusline/scripts/statusline.sh

# 3. Configurar en settings.json
# Agregar la siguiente configuracion a ~/.claude/settings.json:
```

```json
{
  "statusLine": {
    "type": "command",
    "command": "/home/USER/.claude/plugins/carlos-statusline/scripts/statusline.sh",
    "padding": 0
  }
}
```

```bash
# 4. Reiniciar Claude Code para activar el statusline
```

## Como Funciona

El plugin opera como un **script de procesamiento de stdin**. Claude Code invoca el comando configurado y le pasa un JSON por stdin con el estado actual de la sesion.

### Flujo de datos

```
Claude Code (JSON stdin) ──▶ statusline.sh ──▶ ANSI output (stdout)
```

### JSON de entrada (ejemplo)

```json
{
  "model": { "display_name": "Opus 4.6" },
  "workspace": { "current_dir": "/home/carlos/mi-proyecto" },
  "cost": {
    "total_cost_usd": 1.25,
    "total_lines_added": 142,
    "total_lines_removed": 38
  },
  "context_window": { "used_percentage": 48.3 }
}
```

### Procesamiento interno

1. **Lectura**: El script lee el JSON completo desde stdin
2. **Parsing**: Un parser custom con `grep -oP` extrae valores (soporta claves anidadas)
3. **Git**: Detecta la rama activa via `git branch --show-current`
4. **Rendering**: Construye la linea con codigos ANSI y la emite por stdout

## Arquitectura

```
carlos-statusline/
├── .claude-plugin/
│   └── plugin.json          # Metadata del plugin (nombre, version, autor)
├── commands/
│   └── statusline-setup.md  # Instrucciones de setup para Claude
├── scripts/
│   └── statusline.sh        # Script principal (143 lineas)
└── README.md
```

| Archivo | Responsabilidad |
|---------|-----------------|
| `plugin.json` | Declara el plugin ante el ecosistema de Claude Code |
| `statusline-setup.md` | Skill que automatiza la configuracion del plugin |
| `statusline.sh` | Core: parsing JSON, logica de rendering, output ANSI |

### Decisiones de diseno

| Decision | Razon |
|----------|-------|
| Bash puro | Cero dependencias, disponible en cualquier sistema Unix |
| Sin jq | Elimina la necesidad de instalar herramientas externas |
| `grep -oP` | Parser liviano con soporte para claves anidadas |
| ANSI codes directos | Maxima compatibilidad con terminales modernas |
| `echo -en` sin newline | Permite a Claude Code controlar el layout final |

## Configuracion

| Variable (en script) | Descripcion | Valor |
|----------------------|-------------|-------|
| `RESET` | Reset de colores ANSI | `\033[0m` |
| `BOLD` | Texto en negrita | `\033[1m` |
| `FG_CYAN` | Color para modelos Opus | `\033[36m` |
| `FG_GREEN` | Color para modelos Sonnet | `\033[32m` |
| `FG_YELLOW` | Color para modelos Haiku | `\033[33m` |

### Umbrales de la barra de progreso

| Uso del contexto | Color | Significado |
|------------------|-------|-------------|
| < 50% | Verde | Uso saludable |
| 50% - 74% | Amarillo | Uso moderado |
| >= 75% | Rojo | Contexto casi lleno |

## Extensibilidad

El plugin fue disenado como un script modular que se puede extender de varias maneras:

### 1. Agregar nuevos segmentos

Cada segmento del statusline es independiente. Para agregar uno nuevo, solo se necesita:

```bash
# Extraer el valor del JSON
mi_valor=$(extract_json "nueva_clave" "default")

# Agregar al output
output+=" ${SEP} 🏷️ ${mi_valor}"
```

### 2. Crear variantes del script

Se puede tener multiples scripts y cambiar entre ellos en `settings.json`:

```
scripts/
├── statusline.sh          # Default: completo
├── statusline-minimal.sh  # Solo modelo + contexto
└── statusline-git.sh      # Enfocado en metricas git
```

### 3. Sistema de plugins modulares

Se podria evolucionar a un sistema donde cada segmento sea un script independiente:

```
segments/
├── model.sh       # Renderiza el modelo
├── git.sh         # Renderiza info de git
├── context.sh     # Renderiza barra de progreso
├── cost.sh        # Renderiza costo
└── lines.sh       # Renderiza lineas +/-
```

Y un orquestador que los ejecute en orden:

```bash
for segment in segments/*.sh; do
    output+=$(source "$segment")
    output+=" ${SEP} "
done
```

### 4. Configuracion externa

Se podria agregar un archivo de configuracion para personalizar sin editar el script:

```bash
# ~/.config/carlos-statusline/config
SHOW_GIT=true
SHOW_COST=true
SHOW_LINES=true
BAR_WIDTH=6
THEME="default"  # default, minimal, nerd-fonts
```

### 5. Temas

Soporte para diferentes conjuntos de iconos:

| Tema | Carpeta | Git | Separador |
|------|---------|-----|-----------|
| `default` | 📁 | 🌿 | `│` |
| `nerd-fonts` |  |  | `│` |
| `ascii` | `DIR:` | `BR:` | `\|` |
| `minimal` | *(oculto)* | *(oculto)* | ` ` |

## Como se creo

Este plugin fue creado siguiendo la API de statusline de Claude Code:

1. **Se creo la estructura** de plugin en `~/.claude/plugins/`
2. **Se definio el metadata** en `plugin.json` con nombre, descripcion y version
3. **Se escribio el script** en Bash puro que:
   - Lee JSON de stdin (formato que envia Claude Code)
   - Parsea las claves necesarias sin dependencias externas
   - Genera output ANSI formateado
4. **Se registro el comando** en `~/.claude/settings.json` bajo la clave `statusLine`
5. **Se creo un skill** (`statusline-setup.md`) para automatizar la configuracion

La clave del funcionamiento es que Claude Code ejecuta el comando configurado, le pasa el estado de la sesion como JSON por stdin, y usa el stdout como contenido del statusline.

## License

MIT
