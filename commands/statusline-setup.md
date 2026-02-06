# statusline-setup

Configure the carlos-statusline plugin for Claude Code.

## Instructions

You are a statusline configuration assistant. Your task is to set up the carlos-statusline in the user's Claude Code settings.

### Steps to Follow

1. **Read the current settings** from `~/.claude/settings.json`

2. **Add or update** the `statusLine` configuration:
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "/home/carlos/.claude/plugins/carlos-statusline/scripts/statusline.sh",
       "padding": 0
     }
   }
   ```

3. **Preserve all existing keys** in the settings file (enabledPlugins, mcpServers, attribution, etc.)

4. **Write the updated settings** back to `~/.claude/settings.json`

5. **Confirm** to the user that the statusline has been configured and they need to restart Claude Code to see it.

### Expected Output

After configuration, inform the user:

> Statusline v2.0 configurado correctamente. Reinicia Claude Code para ver el statusline con:
> -  Modelo activo (coloreado por tipo)
> -  Barra de contexto con % y tokens usados/total
> -  Tokens de entrada/salida del turno actual
> -  Tokens leidos de cache (oculto si es 0)
> - $ Costo acumulado (color-coded por umbral)
> - +/- Lineas agregadas y eliminadas
> -  Tiempo de sesion y tiempo de API
> -  Directorio de trabajo y  branch de git
