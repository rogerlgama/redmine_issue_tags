# Histórico de versões

## 0.5.2

- Inclui `issue_tags` nas respostas JSON padrão de `GET /issues/:id.json` e `GET /issues.json`.
- Retorna ID, nome, descrição e cor das tags em cada tarefa.
- Representa tarefas sem tags com uma lista vazia.
- Carrega os dados das tags em lote na listagem de tarefas.
- Mantém os endpoints específicos do plugin sem alterações.

## 0.5.1

- Substitui a seleção múltipla nativa de tags por checkboxes independentes.
- Evita que um clique desmarque as outras tags selecionadas.
- Mantém as seleções existentes e marca automaticamente tags criadas pela edição colaborativa.
- Atualiza a orientação exibida abaixo do campo de tags.

## 0.5.0

- Adiciona API administrativa de consulta sob `/api/issue_tags`.
- Permite listar tags, consultar uma tag, listar suas tarefas, consultar as tags de uma tarefa e verificar permissões por perfil.
- Aceita autenticação pelo cabeçalho `X-Redmine-API-Key`.
- Adiciona paginação com `limit` e `offset` à listagem de tarefas vinculadas.
- Exibe a descrição da tag como tooltip nos selos das tarefas e da administração.

## 0.4.14

- Corrige `PG::InvalidColumnReference` nas telas de visualização e edição de tarefas.
- Remove `DISTINCT` de consultas cuja unicidade já é garantida pelos índices do plugin.
- Substitui o `JOIN DISTINCT` usado para ler tags vinculadas por uma subconsulta portátil.
- Remove o `ORDER BY` herdado antes do `DISTINCT` utilizado no agrupamento de consultas.
- Mantém o mesmo comportamento em MySQL, PostgreSQL e SQLite.

## 0.4.13

- Corrige a ocultação das opções que não correspondem à pesquisa parcial de perfis.
- Aplica a correção aos seletores de criação/edição e de adição/remoção.
- Preserva a pesquisa sem diferenciação entre maiúsculas, minúsculas e acentos.
- Corrige também o mesmo conflito visual no seletor pesquisável de tipos de tarefa.

## 0.4.12

- Registra alterações de tags como detalhes estruturados do diário da tarefa.
- Exibe inclusões e remoções na aba `Histórico`, sem gerar registros na aba `Notas`.
- Garante o histórico em tarefas novas, tarefas existentes e operações exclusivas de tags pela API.
- Remove o segundo salvamento da tarefa e evita novos conflitos de bloqueio otimista.

## 0.4.11

- Remove automaticamente vínculos com tarefas de tipos retirados da configuração da tag.
- Adiciona migração para limpar associações incompatíveis criadas em versões anteriores.
- Corrige o cenário em que a tag permanecia na tarefa antiga, mas deixava de aparecer no campo de seleção.

## 0.4.10

- Corrige o conflito de bloqueio otimista (HTTP 409) ao criar uma tarefa com tags.
- Recarrega a tarefa antes de gerar o diário das alterações de tags.
- Centraliza a geração do diário e protege também as alterações realizadas pela API.

## 0.4.9

- Permite abrir, pela tag exibida na lista administrativa, a consulta das tarefas vinculadas à mesma tag.
- Reutiliza os mesmos parâmetros de filtro empregados nos selos exibidos dentro das tarefas.

## 0.4.8

- Remove orientações redundantes abaixo dos seletores.
- Move o aviso de sincronização para o rodapé da seção `Permissão ativa`.
- Centraliza o título da seção e ajusta o texto do seletor de adicionar/remover tags.

## 0.4.7

- Remove o rótulo lateral `Buscador`.
- Adiciona seleção independente para a permissão de adicionar/remover tags.
- Divide a área `Permissão ativa` em duas colunas e equilibra o layout do painel.

## 0.4.6

- Remove da listagem as colunas globais de permissões por perfil.
- Renomeia o seletor de perfis para `Buscador` e exibe os selecionados em `Permissão ativa`.
- Renomeia a coluna `Tarefas` para `Nº de Tarefas`.

## 0.4.5

- Divide a coluna de perfis em duas permissões independentes: criação/edição colaborativa e adição/remoção de tags das tarefas.
- Mantém a seleção global de `Perfis` vinculada exclusivamente à permissão de criação/edição colaborativa.

## 0.4.4

- Renomeia a coluna `Usado por` para `Tarefas vinculadas`.
- Adiciona a coluna `Perfis vinculados` à lista administrativa.
- Usa a permissão `Criar e editar tags diretamente nas tarefas` como fonte única de autorização.
- Sincroniza automaticamente a seleção de `Perfis` com `Papéis e permissões` nos dois sentidos.
- Migra as seleções globais existentes para as permissões nativas dos papéis.

## 0.4.3

- Define que nenhum perfil fique autorizado por padrão para criação e edição colaborativa.
- Limpa as seleções automáticas herdadas da migração anterior.
- Remove `Administrar tags de tarefas` da tela `Papéis e permissões`.
- Mantém a administração do catálogo restrita diretamente aos administradores.

## 0.4.2

- Corrige o erro HTTP 406 ao acessar a configuração global de perfis.
- Exibe a configuração diretamente na tela principal de tags, sem abrir uma rota separada.
- Mantém o link `Perfis` à direita de `Nova tag` e adiciona abertura e fechamento do painel.

## 0.4.1

- Transforma a autorização por perfis em uma configuração global do plugin.
- Remove `Perfis` das telas de criação e edição de cada tag.
- Adiciona o link `Perfis` à direita de `Nova tag` na tela principal.
- Mantém a pesquisa parcial e a seleção múltipla de perfis.
- Converte automaticamente as autorizações da versão anterior para a configuração global.

## 0.4.0

- Adiciona o campo administrativo `Perfis` logo abaixo de `Tipos de tarefa`.
- Permite pesquisar e selecionar vários perfis autorizados à edição colaborativa de cada tag.
- Mantém a permissão colaborativa do Redmine como requisito adicional de segurança.
- Vincula automaticamente aos perfis do criador as tags criadas diretamente em uma tarefa.
- Preserva o comportamento das tags existentes autorizando inicialmente todos os perfis normais.

## 0.3.10

- Restringe os grupos às tags escolhidas quando a consulta usa o filtro `Tags igual a`.
- Impede que outras tags da mesma tarefa sejam exibidas como grupos fora do filtro original.
- Mantém o agrupamento por todas as tags para consultas sem seleção específica de tags.

## 0.3.9

- Corrige o agrupamento para tratar cada tag como um grupo independente.
- Faz tarefas com várias tags aparecerem em cada grupo correspondente.
- Calcula a contagem e os totais separadamente para cada tag.

## 0.3.8

- Corrige o erro `ONLY_FULL_GROUP_BY` ao agrupar consultas por tags no MySQL 8.
- Calcula contagens e totais dos grupos de tags sem desativar o modo SQL seguro do banco.
- Mantém o filtro simples por tags funcionando independentemente do agrupamento.

## 0.3.7

- Altera a cor normal do texto das tags para `#0f172a`.
- No hover, permite que a tag assuma a cor padrão de links definida pelo tema do Redmine.
- Adiciona `Tags` à opção `Agrupar por` nas consultas de tarefas.

## 0.3.6

- Restaura o negrito do texto das tags, mantendo a cor `#333333` e as demais características.

## 0.3.5

- Renomeia o botão de criação colaborativa para `Criar tag`.
- Define o texto dos selos na cor `#333333` e remove o negrito.

## 0.3.4

- Corrige o enquadramento do formulário de criação colaborativa para impedir o corte dos nomes dos campos.
- Ajusta a capitalização da mensagem sobre os limites da edição colaborativa.

## 0.3.3

- Após salvar ou cancelar a edição colaborativa, retorna para a tarefa de origem.
- Ajusta a mensagem sobre os limites da edição colaborativa.

## 0.3.2

- Corrige erro 500 ao abrir ou criar tarefas no MySQL.
- Qualifica a coluna de ordenação das tags para evitar conflito com a coluna `name` dos tipos de tarefa.

## 0.3.1

- Usuários com permissão colaborativa podem definir a cor ao criar uma tag.
- A edição colaborativa passa a permitir alteração da cor.
- Tipos de tarefa e exclusão continuam restritos aos administradores.

## 0.3.0

- Criação e edição colaborativa de tags controlada por papel.
- Criação direta na tarefa com vínculo automático ao tipo.
- Restrição administrativa para cor, tipos de tarefa e exclusão.

## 0.2.0

- Interface e validações em português brasileiro.
- Vínculo de tags com tipos de tarefa.
- Seletor pesquisável e coluna `Usado por`.
- Remoção da opção `Ativa`.

## 0.1.2

- Correção do carregamento do patch do modelo `Issue` em produção.
- Remoção da dependência das views e da API em relação aos métodos dinâmicos da associação.
- Proteção adicional contra erro 500 nas telas de tarefas.

## 0.1.1

- Proteção das telas de tarefas quando o banco do plugin não está pronto.
- Carregamento explícito dos modelos.
- Correção do registro da coluna de consulta no Redmine 6.0.6.

## 0.1.0

- Versão inicial para testes.
