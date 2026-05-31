# SARA — Sistema de Acompanhamento da Restauração Ambiental
### Aplicativo Flutter · Estado do Tocantins

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![AI Assisted](https://img.shields.io/badge/IA-Claude%20(Anthropic)-blueviolet?logo=anthropic)](https://anthropic.com)

> **Nota:** Este projeto foi desenvolvido com o auxílio de Inteligência Artificial (Claude, da Anthropic) para fins de aprendizado, experimentação e aceleração do desenvolvimento. Todo o código foi revisado, compreendido e validado pela equipe. O uso da IA foi intencional e transparente — parte do processo de estudo de novas tecnologias e metodologias de desenvolvimento assistido.

Plataforma mobile para monitoramento e acompanhamento da recuperação de áreas degradadas no Tocantins, integrando técnicos de campo, produtores rurais e gestores do NATURATINS em um único fluxo de trabalho offline-first.

---

## Funcionalidades principais

| Módulo | Descrição |
|--------|-----------|
| **Painel Público** | Indicadores agregados por município, mapa de áreas monitoradas, alertas de fogo e educação ambiental — sem login |
| **Módulo de Áreas** | Listagem, detalhe com mini-mapa, demarcação manual por polígono (toque no mapa) |
| **Captura de Evidências** | Foto + GPS com validação de localização dentro do polígono da propriedade |
| **Histórico de Satélite** | Linha do tempo de 5 anos com imagens Sentinel-2 reais (Microsoft Planetary Computer) |
| **Alertas de Fogo** | Focos INPE/CIGMA em mapa com severidade, notificações locais para alertas críticos |
| **Dashboard do Gestor** | Indicadores SQL agregados, mapa consolidado de todas as áreas e focos |
| **Sync Offline-first** | Outbox pattern — evidências capturadas em campo sincronizam automaticamente ao reconectar |

---

## Stack tecnológica

```
Flutter SDK  ^3.x          — UI multiplataforma (Android principal)
Dart         ^3.x
Riverpod     ^2.6          — Gerenciamento de estado reativo
go_router    ^14.8         — Navegação declarativa com guard de rotas
flutter_map  ^7.0          — Mapas OSM + tiles Sentinel-2
sqflite      ^2.3          — Banco local SQLite (offline-first)
Dio          ^5.7          — Cliente HTTP + interceptor JWT
fl_chart     ^0.70         — Gráficos de indicadores
flutter_local_notifications — Alertas críticos de fogo
```

---

## Arquitetura

```
lib/
├── core/
│   ├── config/          # AppConfig (--dart-define)
│   ├── database/        # AppDatabase sqflite — schema v2, migrações
│   ├── network/         # ApiClient Dio, interceptor JWT, Result<T>
│   ├── providers/       # Providers centrais Riverpod
│   ├── security/        # SecureStore (Keystore/Keychain)
│   ├── services/        # GPS, câmera, conectividade, notificações
│   ├── theme/           # AppColors, AppTheme Material 3, tipografia
│   ├── utils/           # GeoUtils: point-in-polygon, haversine, shoelace
│   └── widgets/         # SaraCard, SaraButton, SaraLoading…
│
├── data/
│   ├── datasources/     # Abstrações remote (real + mock)
│   ├── mock/            # Dados de desenvolvimento (áreas, alertas)
│   ├── models/          # AreaMonitorada, Alerta, SatelliteFrame…
│   └── repositories/    # Interfaces + implementações DB e mock
│
├── features/
│   ├── access_control/  # RBAC: UserRole, PermissionService, RouteGuard
│   ├── alerts/          # Focos de queimada: provider, telas, mapa
│   ├── areas/           # Listagem, detalhe, demarcação por polígono
│   ├── auth/            # Login, welcome, AuthNotifier
│   ├── evidence/        # Captura GPS + foto com validação geoespacial
│   ├── home/            # Telas home por perfil
│   ├── manager/         # Dashboard + mapa consolidado do gestor
│   ├── public/          # Painel público (sem autenticação)
│   ├── satellite/       # Timeline Sentinel-2 por área
│   └── sync/            # SyncEngine outbox, tela de fila
│
├── routes/              # GoRouter — rotas nomeadas + ShellRoute
└── main.dart            # Boot: sqflite + auth + NotificationService
```

### Papéis de usuário (RBAC)

| Papel | Acesso |
|-------|--------|
| **Público** | Painel público sem login |
| **Produtor** | Suas próprias áreas + captura de evidências |
| **Técnico** | Áreas atribuídas + validação + demarcação de polígono |
| **Gestor** | Todas as áreas + dashboard + gestão de alertas |

---

## Configuração e execução

### Pré-requisitos
- Flutter SDK ≥ 3.x
- Android SDK (mínimo API 21)
- Backend SARA rodando (ver [sara_backend](https://github.com/Sammytss/SARA-Sistema_de_Alerta_e_Restaura-o_Ambiental_Back))

### Instalação

```bash
git clone https://github.com/Sammytss/SARA-Sistema_de_Alerta_e_Restaura-o_Ambiental_Front.git
cd SARA-Sistema_de_Alerta_e_Restaura-o_Ambiental_Front
flutter pub get
```

### Executar em modo mock (sem backend)

```bash
flutter run --dart-define=USE_MOCK_DATA=true
```

### Executar com backend real

```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000 \
  --dart-define=USE_MOCK_DATA=false
```

> **Emulador Android:** use `10.0.2.2` para acessar `localhost` do host.
> **Dispositivo físico:** use o IP da máquina na rede local.

### Variáveis `--dart-define`

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `API_BASE_URL` | `http://10.0.2.2:8000` | URL base do backend |
| `USE_MOCK_DATA` | `true` | `false` para usar dados reais |

---

## Banco de dados local

O app usa **sqflite** com schema versionado:

| Versão | Mudança |
|--------|---------|
| v1 | `areas`, `evidencias`, `fotos`, `outbox_items` |
| v2 | `ALTER TABLE areas ADD COLUMN poligono_json TEXT` |

---

## Sincronização offline

O app implementa o **Outbox Pattern**:

1. Evidência capturada → salva local (sqflite) + insere em `outbox_items`
2. `AutoSyncService` monitora conectividade via `connectivity_plus`
3. Ao reconectar → `SyncEngine` processa fila com backoff exponencial
4. Sucesso → `status = 'enviado'`; falha → reagenda

---

## Imagens de satélite

A tela de histórico usa **Sentinel-2 via Microsoft Planetary Computer** (API pública, sem chave):

- Backend busca a cena com menor cobertura de nuvens por ano (período seco: jun–set)
- Retorna template XYZ para `TileLayer` do flutter_map
- Renderiza tiles reais com overlay do polígono da propriedade

---

## Testes

```bash
flutter test
```

25 testes unitários: 11 Haversine / point-in-polygon · 8 SyncEngine · 6 RBAC

---

## Licença

MIT © 2026 NATURATINS / Governo do Estado do Tocantins
