
# Calm Copa

Aplicativo Flutter para simulação e acompanhamento de partidas de uma copa (protótipo educacional / acadêmico).

Este repositório contém a implementação de uma aplicação móvel construída com Flutter. O app provê funcionalidades como visualização de partidas, simulação de resultados, histórico local e telas de estatísticas.

## Principais funcionalidades

- Listagem de partidas e detalhes de cada partida
- Simulação de resultados e registro local das partidas
- Histórico de partidas armazenado localmente (serviço de armazenamento local)
- Telas de estatísticas e placares
- Componentes reutilizáveis (widgets de bandeira, cartão de partida, bracket)

## Estrutura do projeto (resumo)

- `lib/` - Código fonte do app
	- `models/` - Modelos de domínio (Team, Match, Score, etc.)
	- `providers/` - Providers/State management (ex.: simulador, histórico)
	- `screens/` - Telas do aplicativo
	- `services/` - Serviços (API externa, armazenamento local)
	- `widgets/` - Widgets reutilizáveis
- `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/` - Plataformas geradas pelo Flutter
- `test/` - Testes automatizados (unit/widget tests)

## Requisitos

- Flutter SDK (estável) — verifique a versão recomendada em `pubspec.yaml`
- Git
- Emulador Android / iOS ou dispositivo físico configurado

## Instalação e execução (local)

1. Clone o repositório (se ainda não tiver feito):

```powershell
git clone https://github.com/lucas-s-santos/calm-copa.git
cd calm-copa
```

2. Instale dependências do Flutter:

```powershell
flutter pub get
```

3. Execute em modo debug num emulador ou dispositivo conectado:

```powershell
flutter run
```

4. Para gerar um build (Android APK):

```powershell
flutter build apk --release
```

Observação: em Windows/PowerShell, se usar caminho com espaços, coloque entre aspas.

## Configuração de variáveis/API

Se o projeto utilizar alguma API externa (por exemplo, `WorldCupApiService` em `lib/services`), verifique se há chaves ou endpoints necessários. No momento este projeto usa um serviço local/estático — confira `lib/services/world_cup_api_service.dart` para mais detalhes.

## Testes

Rode os testes unitários e de widget com:

```powershell
flutter test
```

Adicione testes ao diretório `test/` seguindo os padrões do Flutter.

## Boas práticas e dicas

- Evite commitar arquivos gerados/artifacts: confira `.gitignore` já presente no projeto.
- Mantenha o `pubspec.yaml` atualizado e rode `flutter pub get` após alterações.
- Use `flutter analyze` para checar problemas estáticos e `flutter format .` para formatar o código.

## Como contribuir

1. Faça um fork do repositório
2. Crie uma branch para sua feature/bugfix (`git checkout -b feat/minha-feature`)
3. Faça commits claros e pequenos
4. Abra um Pull Request descrevendo as mudanças

Para alterações maiores, abra uma issue antes para discutirmos o design.

## Contato

Para dúvidas, problemas ou sugestões, abra uma issue no GitHub: https://github.com/lucas-s-santos/calm-copa/issues

## Licença

Adicione a licença desejada (ex: MIT) no arquivo `LICENSE` ou atualize esta seção conforme necessário.

```
