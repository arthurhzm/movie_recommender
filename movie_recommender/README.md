# Movie Recommender App

Um aplicativo mobile desenvolvido em Flutter que utiliza inteligência artificial para recomendar filmes personalizados com base nas preferências do usuário.

## Sobre o Projeto

O Movie Recommender é um aplicativo que oferece recomendações de filmes personalizadas através da integração com a API Gemini da Google. O sistema aprende com as preferências e avaliações do usuário para sugerir filmes cada vez mais alinhados ao seu gosto pessoal.

## Funcionalidades

### Autenticação
- Login com e-mail e senha
- Cadastro de novos usuários
- Gerenciamento de perfil (atualização de dados, alteração de senha)

### Preferências do Usuário
- Definição de gêneros favoritos
- Seleção de diretores e atores preferidos
- Configuração de período de filmes (ano mínimo de lançamento)
- Definição de duração máxima de filmes
- Configurações de conteúdo (aceitação de conteúdo adulto)

### Recomendações
- Geração de recomendações personalizadas via IA (Google Gemini)
- Integração com TMDB para informações e pôsteres de filmes
- Interface de "swipe" para avaliar as recomendações (curtir/não curtir/super curtir)
- Detalhamento completo dos filmes recomendados

### Gerenciamento de Histórico
- Armazenamento das avaliações e interações do usuário
- Melhoria contínua das recomendações com base no histórico

## Tecnologias Utilizadas

- **Flutter/Dart**: Framework para desenvolvimento multiplataforma
- **Firebase Authentication**: Autenticação de usuários
- **Cloud Firestore**: Banco de dados para armazenamento de preferências e interações
- **Google Gemini API**: Geração de recomendações personalizadas via IA
- **TMDB API**: Informações detalhadas e pôsteres de filmes

## Requisitos do Sistema

- Flutter SDK ^3.7.2
- Dart SDK ^3.7.2
- Dispositivo ou emulador Android/iOS

## Como Executar o Projeto

### Pré-requisitos
1. Certifique-se de ter o Flutter SDK versão 3.7.2 ou superior instalado:
   ```
   flutter --version
   ```
   Se necessário, atualize o Flutter:
   ```
   flutter upgrade
   ```

2. Configure um projeto no Firebase e obtenha o arquivo de configuração:
   - Crie um projeto no [Firebase Console](https://console.firebase.google.com/)
   - Configure o Firebase Authentication (e-mail/senha)
   - Configure o Cloud Firestore
   - Adicione os arquivos de configuração ao projeto (`google-services.json` para Android, `GoogleService-Info.plist` para iOS)

3. Obtenha uma API key do Gemini:
   - Acesse [Google AI Studio](https://ai.google.dev/)
   - Crie uma API key para o Gemini
   - Adicione a chave ao arquivo `.env` na raiz do projeto:
     ```
     GEMINI_API_KEY=sua_chave_gemini_aqui
     ```

4. Obtenha uma API key do TMDB:
   - Crie uma conta no [TMDB](https://www.themoviedb.org/)
   - Gere uma API key
   - Adicione a chave ao arquivo `.env`:
     ```
     TMDB_API_KEY=sua_chave_tmdb_aqui
     ```

### Instalando Dependências
1. Clone o repositório:
   ```
   git clone https://github.com/seu-usuario/movie_recommender.git
   cd movie_recommender
   ```

2. Instale as dependências:
   ```
   flutter pub get
   ```

### Executando o Aplicativo
1. Conecte um dispositivo ou inicie um emulador
2. Execute o aplicativo:
   ```
   flutter run
   ```

## Estrutura do Projeto

- `lib/`
  - `components/` - Widgets reutilizáveis
  - `pages/` - Telas do aplicativo
  - `providers/` - Classes para comunicação com APIs externas
  - `services/` - Serviços internos da aplicação
  - `main.dart` - Ponto de entrada da aplicação

## Contribuição

Para contribuir com o projeto, siga estas etapas:

1. Faça um fork do repositório
2. Crie uma branch para sua feature (`git checkout -b feature/nova-feature`)
3. Faça commit das alterações (`git commit -m 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

## Próximos Passos

- Implementar recuperação de senha
- Adicionar modo "mood do dia" para recomendações contextuais
- Implementar função "vou assistir" para filmes recomendados
- Desenvolver modo "batalha" de filmes para refinar preferências

## Licença

Este projeto está sob a licença [MIT](LICENSE).