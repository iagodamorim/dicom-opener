# DICOM Opener

Automação para abrir exames DICOM (ZIPs) no OsiriX Lite ao baixar da plataforma de telemedicina.

Ao baixar um exame, o OsiriX abre automaticamente em ~2-5 segundos — sem clicar em nada.

## Requisitos

- macOS (testado em Monterey 12.x)
- [OsiriX Lite](https://www.osirix-viewer.com/osirix/osirix-md/download-osirix-lite/) instalado em `/Applications/`
- Plataforma de telemedicina que baixa ZIPs no padrão `NOME_PACIENTE-NUMERO.zip`

## Instalação

```bash
git clone https://github.com/SEU_USUARIO/dicom-opener.git
cd dicom-opener
./install.sh
```

O instalador copia os scripts para `~/.dicom-opener/`, cria o serviço macOS e ativa o daemon automaticamente.

## Desinstalação

```bash
cd dicom-opener
./uninstall.sh
```

## Como funciona

### Modo automático (padrão)

```
Clica download no site → download termina → ~2-5s → OsiriX abre o exame
```

Um daemon roda em background checando `~/Downloads` a cada 2 segundos. Quando detecta um ZIP novo no padrão de exame, abre no OsiriX automaticamente.

### Modo manual

```
Clica download no site → download termina → pressiona atalho de teclado → OsiriX abre
```

Para criar o atalho de teclado:
1. Abra o **Automator** → Novo Documento → **Ação Rápida**
2. Configure: "O fluxo de trabalho recebe **nenhuma entrada** em **qualquer aplicativo**"
3. Adicione **"Executar Script de Shell"** com: `~/.dicom-opener/open-dicom.sh`
4. Salve como **"Abrir DICOM"**
5. Vá em **Preferências do Sistema → Teclado → Atalhos → Serviços** e atribua um atalho

### Toggle (ligar/desligar daemon)

```bash
~/.dicom-opener/toggle-watcher.sh
```

Ou crie um app no Dock:
1. **Automator** → Novo Documento → **Aplicativo**
2. Adicione **"Executar Script de Shell"** com: `~/.dicom-opener/toggle-watcher.sh`
3. Salve como **"Toggle Watcher"** em `/Applications/`
4. Arraste para o Dock

## Arquitetura

```
~/.dicom-opener/                    ← Pasta principal (oculta na home)
├── open-dicom.sh                   ← Script manual (atalho/Dock)
├── toggle-watcher.sh               ← Liga/desliga o daemon
├── watcher-daemon.sh               ← Daemon automático (loop a cada 2s)
└── .opened_zips                    ← Histórico de ZIPs já abertos (gerado na instalação)

~/Library/LaunchAgents/
└── com.dicomopener.watcher.plist   ← Serviço macOS (gerado pelo install.sh)
```

## Scripts

### `open-dicom.sh` — Abertura manual

- Procura o ZIP mais recente em `~/Downloads` no padrão da telemedicina
- Ignora ZIPs já abertos (consulta `.opened_zips`)
- Abre OsiriX Lite automaticamente se estiver fechado
- Exibe notificação macOS confirmando

### `watcher-daemon.sh` — Detecção automática

- Loop que checa `~/Downloads` a cada 2 segundos
- Usa AppleScript (System Events) para listar arquivos — contorna a restrição de privacidade (TCC) do macOS sobre ~/Downloads em processos background
- Mesma lógica de filtragem do `open-dicom.sh`

### `toggle-watcher.sh` — Liga/desliga

- Daemon rodando → para + notificação "DESATIVADO"
- Daemon parado → inicia + notificação "ATIVADO"

## Padrão de nome reconhecido

Regex: `^[A-Z][A-Z_]+-[0-9]+\.zip$`

| Exemplo | Reconhecido? |
|---|---|
| `JOSIMAR_CEREJO_CORREIA_JUNIOR-1276437.zip` | Sim |
| `ANA_SILVA-123.zip` | Sim |
| `logioptionsplus_installer.zip` | Não |
| `voxel_canva_kit.zip` | Não |

Para alterar o padrão, edite a variável `PATTERN` em `open-dicom.sh` e o `grep -qE` em `watcher-daemon.sh`.

## Manutenção

| Tarefa | Comando |
|---|---|
| Limpar histórico de ZIPs | `> ~/.dicom-opener/.opened_zips` |
| Ver ZIPs já abertos | `cat ~/.dicom-opener/.opened_zips` |
| Verificar se daemon está rodando | `launchctl list \| grep dicomopener` |
| Ligar/desligar daemon | `~/.dicom-opener/toggle-watcher.sh` |
| Testar script manual | `~/.dicom-opener/open-dicom.sh` |

## Limitações

- **Delay de ~2-5s no modo automático** — overhead do AppleScript necessário para contornar TCC
- **Padrão de nome fixo** — só reconhece `MAIUSCULAS_UNDERSCORE-NUMEROS.zip` (editável nos scripts)
- **macOS only** — usa launchd, osascript e notificações nativas
- **Consumo mínimo de CPU** (~0.1%) pelo loop de 2s com osascript
