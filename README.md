# 💙 Finity Mobile

Aplicativo mobile desenvolvido em **Flutter**, integrado à API do sistema Finity, com o objetivo de facilitar o gerenciamento e o acompanhamento financeiro de empresas.

O aplicativo permite consultar informações financeiras, acompanhar contas a pagar e a receber e registrar movimentações, utilizando uma interface intuitiva e comunicação com um backend desenvolvido em ASP.NET Core.

---

## 📱 Sobre o projeto

O Finity é uma solução de gestão financeira empresarial composta por uma aplicação mobile e uma API responsável pelo processamento e armazenamento das informações.

Este repositório contém o desenvolvimento da aplicação mobile, construída com Flutter e Dart.

## 🚀 Funcionalidades

O aplicativo contempla as seguintes funcionalidades:

- **Autenticação:** acesso ao sistema por meio de credenciais e token de autenticação.
- **Dashboard:** visualização geral das informações financeiras.
- **Movimentações:** consulta, pesquisa e organização das movimentações financeiras.
- **Detalhes da movimentação:** visualização dos dados de cada movimentação.
- **Estorno:** possibilidade de estornar movimentações, conforme as regras do sistema.
- **Contas a pagar:** consulta e cadastro de despesas e compromissos financeiros.
- **Contas a receber:** consulta e cadastro de receitas e valores a receber.
- **Criação:** acesso centralizado às opções de cadastro.
- **Departamentos e categorias:** recursos de organização administrativa.
- **Perfil:** área destinada às informações do usuário, empresa e configurações.

> Algumas funcionalidades podem estar em desenvolvimento ou depender da conclusão de suas respectivas integrações com a API.

## 🛠️ Tecnologias utilizadas

| Tecnologia | Finalidade |
|---|---|
| Flutter | Desenvolvimento da aplicação mobile |
| Dart | Linguagem de programação |
| ASP.NET Core | Backend e disponibilização dos serviços |
| C# | Desenvolvimento da API |
| HTTP | Comunicação entre aplicativo e API |
| JSON | Formato de troca de dados |
| SharedPreferences | Armazenamento local de informações da sessão |
| Microsoft Azure | Hospedagem da API |

## 📂 Estrutura do projeto

A aplicação está organizada por funcionalidades, separando telas, serviços e componentes compartilhados.

```text
lib/
├── core/
│   ├── services/
│   │   ├── movimentacao_api.dart
│   │   ├── contas_pagar_api.dart
│   │   ├── contas_receber_api.dart
│   │   └── categorias_api.dart
│   └── theme/
│       └── app_theme.dart
│
├── features/
│   ├── dashboard/
│   │   └── presentation/
│   ├── movements/
│   │   └── presentation/
│   ├── accounts_payable/
│   │   └── presentation/
│   ├── accounts_receivable/
│   │   └── presentation/
│   ├── options/
│   │   └── presentation/
│   └── profile/
│       └── presentation/
│
└── shared/
    └── widgets/
        └── bottom_navigation.dart
```

*Estrutura ilustrativa, podendo ser atualizada conforme a organização final do repositório.*

## ⚙️ Como executar o projeto

### Pré-requisitos

Antes de executar o aplicativo, é necessário ter instalado:

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-dart)
- [Android Studio](https://developer.android.com/studio) ou VS Code
- Emulador Android ou dispositivo físico para testes.
- Git.

### 1. Clonar o repositório

```bash
git clone URL_DO_REPOSITORIO
```

### 2. Acessar a pasta do projeto

```bash
cd NOME_DO_PROJETO
```

### 3. Instalar as dependências

```bash
flutter pub get
```

### 4. Verificar a configuração do Flutter

```bash
flutter doctor
```

### 5. Executar o aplicativo

```bash
flutter run
```

## 🔗 Integração com a API

O aplicativo mobile realiza a comunicação com o backend do Finity por meio de requisições HTTP.

**Tecnologia do backend:** ASP.NET Core / C#

**Endereço base da API:**

```text
https://finity-api-eueqhvcgbpa2cgeq.brazilsouth-01.azurewebsites.net
```

Entre os recursos utilizados estão:

| Método | Endpoint | Descrição |
|---|---|---|
| GET | `/api/movimentacoes` | Listagem de movimentações |
| GET | `/api/movimentacoes/{id}` | Consulta de movimentação |
| POST | `/api/movimentacoes` | Cadastro de movimentação |
| POST | `/api/movimentacoes/{id}/estornar` | Estorno de movimentação |

As requisições protegidas utilizam autenticação por token Bearer, enviado no cabeçalho HTTP `Authorization`.

Os dados são transmitidos no formato JSON.

## 🔐 Autenticação e armazenamento

O aplicativo utiliza o pacote `SharedPreferences` para armazenar informações necessárias à manutenção da sessão do usuário.

Entre as informações armazenadas estão:

- `token`: token de autenticação.
- `idUsuario`: identificador do usuário autenticado.
- `idEmpresa`: identificador da empresa associada à sessão.

O token é utilizado nas requisições aos endpoints protegidos da API.

**Importante:** não armazene senhas, tokens reais ou outras credenciais diretamente no repositório Git.

## 📦 Principais dependências

As principais bibliotecas utilizadas incluem:

- `http`: realização de requisições HTTP.
- `shared_preferences`: armazenamento local de informações da sessão.

As versões das dependências podem ser consultadas no arquivo `pubspec.yaml`.

## 🎨 Interface do aplicativo

O Finity utiliza uma identidade visual própria, com tema centralizado e componentes reutilizáveis.

A navegação principal é composta por:

- Início;
- Movimentações;
- Criar (+);
- Relatórios;
- Perfil.

## 📌 Status do projeto

**Em desenvolvimento.**

O aplicativo está sendo desenvolvido de forma incremental, com implementação das telas, integração com os serviços da API e validação dos fluxos de navegação e autenticação.

## 👨‍💻 Desenvolvimento

Projeto desenvolvido como parte da disciplina de **Desenvolvimento Mobile**.

**Projeto:** Finity – Gestão Financeira Empresarial.

**Aplicação:** Finity Mobile.

**Tecnologia principal:** Flutter.

---

💙 **Finity – Simplificando a gestão financeira.**
