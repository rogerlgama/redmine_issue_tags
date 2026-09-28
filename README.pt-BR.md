# Redmine Issue Tags 0.5.2

Plugin de tags pesquisáveis para tarefas, desenvolvido para testes no Redmine 6.0.6.

## Melhoria da versão 0.5.2

- inclui `issue_tags` automaticamente na resposta JSON padrão de uma tarefa;
- aplica a integração tanto em `GET /issues/:id.json` quanto em `GET /issues.json`;
- retorna ID, nome, descrição e cor de cada tag;
- retorna uma lista vazia para tarefas sem tags;
- carrega as tags da listagem em uma única consulta, evitando consultas individuais por tarefa;
- mantém os endpoints específicos do plugin disponíveis.

Esta versão não possui nova migração.

## Melhoria da versão 0.5.1

- substitui o campo de seleção múltipla nativo por uma lista rolável de checkboxes;
- permite marcar ou desmarcar cada tag sem pressionar `Ctrl` e sem apagar as demais seleções;
- preserva as tags já vinculadas ao abrir a edição da tarefa;
- inclui e marca automaticamente na lista uma tag criada pela edição colaborativa;
- substitui a orientação antiga sobre a tecla `Ctrl` por uma instrução compatível com os checkboxes.

Esta versão não possui nova migração.

## Novidades da versão 0.5.0

- adiciona API administrativa para consultar tags, tarefas vinculadas e permissões globais;
- segue o padrão `/api/issue_tags/...` e aceita autenticação pelo cabeçalho `X-Redmine-API-Key`;
- adiciona paginação à consulta das tarefas vinculadas a uma tag;
- exibe a descrição da tag como tooltip ao posicionar o cursor sobre o selo;
- aplica o tooltip tanto nas tarefas quanto na listagem administrativa.

Esta versão não possui nova migração.

## Correção da versão 0.4.14

- corrige o erro `PG::InvalidColumnReference` ao abrir ou editar tarefas em instalações com PostgreSQL;
- remove combinações desnecessárias de `DISTINCT` com ordenação por `LOWER(...)`;
- consulta as tags vinculadas por subconsulta, sem gerar duplicidade e sem depender do comportamento específico do banco;
- remove a ordenação herdada antes da coleta distinta de IDs usada no agrupamento;
- preserva a compatibilidade com MySQL, PostgreSQL e SQLite.

Esta versão não possui nova migração.

## Correção da versão 0.4.13

- corrige a pesquisa parcial nos seletores de perfis autorizados a criar/editar tags;
- corrige a pesquisa parcial nos seletores de perfis autorizados a adicionar/remover tags;
- mantém a pesquisa sem diferenciação entre maiúsculas, minúsculas e acentos;
- aplica a mesma correção ao seletor pesquisável de tipos de tarefa.

Esta versão não possui nova migração.

## Correção da versão 0.4.12

- registra a inclusão e a remoção de tags como alterações estruturadas do campo `Tags`;
- exibe as mudanças somente na aba `Histórico`, sem criar uma nota;
- registra corretamente as mudanças tanto na criação quanto na edição de tarefas existentes;
- cria um diário próprio quando a operação altera somente tags, inclusive pela API;
- elimina o segundo salvamento da tarefa usado anteriormente para gerar o histórico.

Esta versão não possui nova migração. A migração incluída na versão 0.4.11 continua necessária para instalações vindas de versões anteriores.

## Correção da versão 0.4.11

- remove automaticamente a tag das tarefas cujos tipos deixaram de estar vinculados a ela;
- inclui migração para limpar vínculos incompatíveis já existentes;
- impede que uma tag permaneça visível em uma tarefa sem estar disponível para remoção.

Esta versão possui nova migração. Execute `bundle exec rake redmine:plugins:migrate RAILS_ENV=production` antes de reiniciar o Redmine.

## Correção da versão 0.4.10

- corrige o HTTP 409 ao criar uma tarefa com uma tag selecionada;
- recarrega a tarefa antes de registrar no histórico a alteração das tags, evitando conflito de versão;
- aplica a mesma proteção às alterações realizadas pela API do plugin.

## Melhorias da versão 0.4.9

- transforma as tags da tela administrativa em links para a consulta de tarefas filtrada pela tag selecionada.

## Melhorias da versão 0.4.8

- remove os textos redundantes abaixo dos seletores de perfis;
- move a orientação de sincronização para o rodapé de `Permissão ativa`;
- centraliza e reforça visualmente o título `Permissão ativa`;
- esclarece que o segundo seletor autoriza adicionar/remover tags.

## Melhorias da versão 0.4.7

- remove o rótulo lateral `Buscador` e aproveita melhor a largura do painel;
- adiciona um seletor independente para a permissão de adicionar/remover tags;
- divide `Permissão ativa` entre `Criar/Editar` e `Adicionar/Remover`;
- reorganiza os elementos para equilibrar os seletores, orientações e permissões ativas.

## Melhorias da versão 0.4.6

- remove da tabela as colunas globais de perfis;
- renomeia o campo de seleção de perfis para `Buscador`;
- adiciona a área somente leitura `Permissão ativa`, atualizada conforme a seleção;
- renomeia a coluna `Tarefas` para `Nº de Tarefas`.

## Melhorias da versão 0.4.5

- separa, na administração de tags, os perfis autorizados a criar/editar tags dos perfis autorizados a adicionar/remover tags das tarefas.

## Melhorias da versão 0.4.4

- sincroniza a seleção global de perfis com a permissão `Criar e editar tags diretamente nas tarefas`;
- altera `Usado por` para `Tarefas vinculadas` e adiciona `Perfis vinculados` na lista administrativa;
- elimina o armazenamento paralelo de perfis e passa a usar diretamente as permissões dos papéis do Redmine.

## Melhorias da versão 0.4.3

- nenhum perfil é autorizado por padrão para a colaboração, evitando liberação excessiva acidental;
- a permissão `Administrar tags de tarefas` foi removida de `Papéis e permissões`, pois o catálogo é exclusivo dos administradores.

## Correção da versão 0.4.2

- corrige o erro HTTP 406 do link `Perfis`;
- a configuração global passa a abrir em um painel na própria tela principal de tags.

## Ajuste da versão 0.4.1

- a seleção de perfis passa a ser global, acessível pelo link `Perfis` ao lado de `Nova tag`;
- o campo deixa de ser exibido na criação e edição individual das tags;
- a configuração continua exigindo também a permissão colaborativa do Redmine.

## Novidades da versão 0.4.0

- adiciona `Perfis` ao cadastro administrativo da tag, logo abaixo de `Tipos de tarefa`;
- utiliza pesquisa parcial, seleção múltipla e lista compacta, seguindo a mesma mecânica dos tipos de tarefa;
- somente administradores definem os perfis autorizados em cada tag;
- a edição colaborativa exige simultaneamente a permissão do Redmine e um perfil autorizado na tag;
- tags criadas colaborativamente são vinculadas aos perfis do criador no projeto.

## Correção da versão 0.3.8

- corrige o erro `Expression of SELECT list is not in GROUP BY clause` ao agrupar consultas por tags no MySQL 8 com `ONLY_FULL_GROUP_BY`;
- contagens e totais passam a ser calculados por conjunto de tags sem alterar a configuração segura do banco;
- o filtro simples por tags continua funcionando sem depender do agrupamento.

## Melhorias da versão 0.3.7

- altera a cor normal do texto das tags para `#0f172a`, mantendo o negrito;
- ao posicionar o cursor, o texto passa a usar a cor de hover dos links definida pelo tema do Redmine;
- adiciona `Tags` ao campo `Agrupar por` das consultas de tarefas;
- tarefas com o mesmo conjunto de tags são exibidas no mesmo grupo, sem duplicar registros com várias tags.

## Melhoria da versão 0.3.6

- restaura o negrito do texto das tags, mantendo a cor `#333333`, a cor configurada na borda e no fundo e todas as demais melhorias.

## Melhorias da versão 0.3.5

- o botão `Criar nova tag` foi renomeado para `Criar tag`;
- o texto dos selos passa a usar a cor `#333333`, sem negrito, mantendo a cor escolhida na borda e no fundo.

## Melhorias da versão 0.3.4

- corrige o enquadramento do formulário colaborativo e evita o corte dos rótulos Nome, Descrição e Cor;
- revisa a capitalização da mensagem exibida na edição colaborativa.

## Melhorias da versão 0.3.3

- após salvar ou cancelar uma edição colaborativa, o usuário retorna para a tarefa onde acionou a edição;
- o retorno é validado pelo ID da tarefa e limitado ao projeto corrente;
- mensagem dos limites da edição colaborativa revisada.

## Correção da versão 0.3.2

- corrige o erro MySQL `Column 'name' in order clause is ambiguous` ao abrir ou criar tarefas;
- a ordenação passa a usar explicitamente `redmine_issue_tags.name` nas consultas com tipos de tarefa.

## Novidades da versão 0.3.1

- usuários com permissão colaborativa podem escolher a cor ao criar uma tag;
- a cor também pode ser alterada na edição colaborativa;
- tipos de tarefa e exclusão continuam exclusivos da administração.

## Novidades da versão 0.3.0

- criação colaborativa diretamente no formulário da tarefa;
- permissão por papel `Criar e editar tags diretamente nas tarefas`;
- usuários autorizados informam nome, descrição e cor;
- a nova tag é vinculada automaticamente ao tipo da tarefa corrente;
- a tag criada é automaticamente selecionada para ser vinculada ao salvar a tarefa;
- edição colaborativa limitada a nome e descrição;
- tipos de tarefa e exclusão permanecem exclusivos da administração;
- exclusão continua disponível somente para administradores.

## Novidades da versão 0.2.0

- interface administrativa em português brasileiro;
- menu renomeado para `Tags`, com ícone administrativo;
- vínculo obrigatório entre tags e tipos de tarefa;
- busca por parte do nome na seleção compacta de tipos de tarefa;
- exibição somente das tags permitidas para o tipo da tarefa;
- coluna `Usado por` na lista administrativa;
- remoção do parâmetro e da coluna `Ativa`;
- mensagem de duplicidade alterada para `Nome não está disponível`.

## Correções da versão 0.1.2

- corrige `undefined method issue_tags/issue_tag_ids for Issue` no ambiente de produção;
- aplica os patches do modelo imediatamente no carregamento e também pelo ciclo de reload do Rails;
- views, API e gravação passam a funcionar diretamente pelas tabelas do plugin, sem depender das associações adicionadas ao modelo `Issue`;
- a coluna de consulta passa a usar `issue_tags_as_string`, evitando a renderização de objetos de associação;
- ao agrupar por tags, cada tag forma um grupo independente e tarefas com várias tags aparecem em todos os grupos correspondentes;
- quando a consulta filtra `Tags igual a`, somente as tags selecionadas aparecem como grupos.

## Correções da versão 0.1.1

- impede que as telas de criação e visualização de tarefas apresentem erro 500 quando as tabelas do plugin ainda não estão disponíveis;
- carrega explicitamente os modelos do plugin antes de aplicar os patches;
- registra a coluna `Tags` diretamente em `IssueQuery.available_columns`, conforme a API do Redmine 6;
- mantém filtros, telas e API inativos de forma segura até a conclusão da migração.

## Recursos desta versão

- catálogo administrativo de tags, com nome, cor, descrição e tipos de tarefa;
- associação de várias tags a uma tarefa;
- exibição das tags como selos clicáveis;
- filtro `Tags` nas consultas de tarefas;
- operadores: contém qualquer tag selecionada, não contém, possui alguma e não possui;
- coluna opcional `Tags` nas consultas;
- consultas salvas, CSV e filtros por URL;
- histórico de inclusão e remoção de tags como alteração do campo `Tags`;
- endpoint JSON para catálogo e associação de tags;
- permissões por papel.

## Instalação

1. Extraia a pasta `redmine_issue_tags` em `plugins/`.
2. Na raiz do Redmine, execute:

```bash
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```

3. Reinicie o Redmine.
4. Em **Administração > Papéis e permissões**, habilite **Criar e editar tags diretamente nas tarefas** para os papéis autorizados à criação colaborativa.
5. Se necessário, habilite separadamente **Adicionar e remover tags das tarefas** para os demais papéis que apenas associarão tags existentes.
6. Administradores podem gerenciar o catálogo completo em **Administração > Tags**.

## Desinstalação

Antes de remover a pasta do plugin:

```bash
bundle exec rake redmine:plugins:migrate NAME=redmine_issue_tags VERSION=0 RAILS_ENV=production
```

## API

As requisições aceitam os mecanismos normais de autenticação do Redmine, incluindo o cabeçalho:

```http
X-Redmine-API-Key: SUA_CHAVE
```

A API padrão do Redmine inclui automaticamente as tags no atributo `issue_tags`, sem necessidade de usar `include`:

```http
GET /issues/123.json
GET /issues.json
```

Exemplo do trecho acrescentado a cada tarefa:

```json
"issue_tags": [
  {
    "id": 5,
    "name": "Segurança",
    "description": "Demandas relacionadas à segurança",
    "color": "#3b82f6"
  }
]
```

Os endpoints administrativos específicos do plugin permanecem disponíveis e exigem que a chave pertença a um administrador:

```http
GET /api/issue_tags/tags.json
GET /api/issue_tags/tags/:id.json
GET /api/issue_tags/tags/:id/issues.json
GET /api/issue_tags/issues/:issue_id/tags.json
GET /api/issue_tags/roles.json
```

A consulta das tarefas vinculadas aceita `limit` e `offset`:

```http
GET /api/issue_tags/tags/5/issues.json?limit=100&offset=0
```

O endpoint legado de listagem continua disponível:

```http
GET /issue_tags.json
```

Consultar tags de uma tarefa:

```http
GET /issues/123/tags.json
```

Substituir as tags de uma tarefa:

```http
PUT /issues/123/tags.json
Content-Type: application/json

{"tags":{"ids":[1,2,5]}}
```

## Limitações conhecidas da versão inicial

- o filtro `=` corresponde a qualquer uma das tags selecionadas;
- a edição em massa específica para adicionar/remover tags será incluída em uma versão posterior;
- tags são globais nesta versão;
- a API de listagem do catálogo está, por segurança, restrita a administradores.

## Licença

Este projeto é distribuído sob a GNU General Public License versão 2 ou, opcionalmente, qualquer versão posterior (`GPL-2.0-or-later`). Consulte [LICENSE](LICENSE).

## Autor

[Roger Gama](https://github.com/rogerlgama)
