# Portal de Boletos — página de acesso do app

Página estática que recebe o associado vindo do banner do app e leva ao Portal do Associado (Supera Entidades).

**Endereço oficial:** `https://boletos.suaentidade.com.br`

**Principal risco protegido:** alguém trocar o link do botão e desviar os associados para um portal falso.

---

## Estrutura

| Arquivo | Função |
|---|---|
| `public/index.html` | A página. Contém o link do botão "Acessar meus boletos". |
| `public/logo.svg` | Logo (substitua pelo da entidade, mantendo o nome ou ajustando o `index.html`). |
| `config/links-permitidos.txt` | Lista de destinos autorizados. A 1ª linha é o portal oficial. |
| `scripts/verificar-links.sh` | Bloqueia links não autorizados, JavaScript, formulários e redirecionamentos. |
| `.github/workflows/verificar-links.yml` | Roda a verificação em todo pull request. |
| `.github/CODEOWNERS` | Exige aprovação do time responsável em qualquer alteração. |
| `nginx.conf` / `Dockerfile` | Servidor com cabeçalhos de segurança, usado pelo Easypanel. |

---

## 1. Preencher antes do primeiro deploy

1. Em `public/index.html`, troque `[NOME DA ENTIDADE]`, CNPJ, telefone, WhatsApp e as cores em `:root`.
2. Troque `https://portal.exemplo-supera.com.br/` pelo **endereço oficial confirmado com a Supera**, em dois lugares:
   - no botão em `public/index.html`;
   - na 1ª linha de `config/links-permitidos.txt`.
3. Substitua `public/logo.svg` pelo logo da entidade.
4. Rode a verificação localmente: `sh scripts/verificar-links.sh`

---

## 2. GitHub (conta da entidade)

1. Crie uma **Organização** com o e-mail institucional (ex.: `ti@suaentidade.com.br`), nunca uma conta pessoal.
2. Em *Settings → Authentication security*, ative **2FA obrigatório** para todos os membros.
3. Crie o time **aprovadores** (ex.: responsável do financeiro) e ajuste o nome da organização em `.github/CODEOWNERS`.
4. Crie o repositório `portal-boletos` e envie estes arquivos.

> **Visibilidade:** as regras de proteção de branch em repositório **privado** exigem plano pago do GitHub (Team). Como o repositório não contém senhas nem dados (só a página pública), ele pode ser **público** no plano gratuito. Nunca coloque senhas, tokens ou dados de associados aqui.

### Proteção da branch `main`
*Settings → Branches (ou Rules → Rulesets) → regra para `main`:*

- [x] Exigir pull request antes de mesclar, com **1 aprovação**
- [x] Exigir revisão de **Code Owners**
- [x] Descartar aprovações quando houver novos commits
- [x] Exigir o status check **`verificar-links`** passando
- [x] Bloquear force push e exclusão da branch
- [x] Aplicar as regras também a **administradores**

Resultado: ninguém altera o link sozinho, e um link fora da lista é barrado automaticamente.

---

## 3. Easypanel

1. Crie um **App** → origem **GitHub**, repositório `portal-boletos`, branch `main`.
2. Build: **Dockerfile**.
3. Ative o **Auto Deploy** (deploy a cada merge na `main`).
4. Em **Domains**: `boletos.suaentidade.com.br` → porta interna **80**, HTTPS ativado (Let's Encrypt via Traefik).
5. Em **Ports**: **não adicione nada**. O container fica só na rede interna; o Traefik é a única entrada.
6. **Não** use variáveis de ambiente para o link: ele precisa ficar no Git para ter histórico e revisão.

### Servidor
- Firewall: abertas apenas **80**, **443** e **SSH** (com chave, de preferência restrita por IP).
- Painel do Easypanel (porta 3000): atrás de domínio com HTTPS, senha forte, 2FA, acesso restrito por IP/VPN e com no máximo 2 administradores.

---

## 4. DNS

- Crie um **registro A**: `boletos` → IP da VPS.
- A conta do registrador (ex.: registro.br) deve estar em nome da entidade, com **2FA** e poucos usuários.

---

## 5. Monitoramento (Uptime Kuma no Easypanel)

Instale o **Uptime Kuma** pelo template do Easypanel e crie:

| Monitor | Tipo | Configuração |
|---|---|---|
| Link oficial | **HTTP(s) - Keyword** | URL `https://boletos.suaentidade.com.br`, palavra-chave = endereço oficial do portal, intervalo 5 min |
| Certificado | HTTP(s) | Avisar quando o certificado estiver perto de expirar |

Alertas para o **responsável** e o **aprovador** (e-mail, Telegram ou WhatsApp).

**Conferência manual mensal (financeiro):** abrir o app, tocar no banner e confirmar que abre `boletos.suaentidade.com.br`.

---

## 6. Como trocar o link do portal

1. Registrar a solicitação (quem pediu e por quê).
2. Responsável cria uma branch e altera o link em `public/index.html` **e** em `config/links-permitidos.txt`.
3. Abre o pull request → verificação automática roda.
4. Aprovador confere o novo endereço com a Supera e aprova.
5. Merge → Easypanel publica automaticamente.
6. Atualizar a palavra-chave do monitor no Uptime Kuma.

---

## 7. Se o alerta disparar

1. **Reverter** o último commit na `main` (via pull request de revert); o Easypanel republica.
2. **Trocar senhas** da conta envolvida (GitHub, Easypanel, DNS ou painel do app).
3. Conferir **DNS** e o **link do banner** no app.
4. Se algum associado pode ter sido afetado, **avisar** pelos canais oficiais.
5. Registrar o ocorrido.

---

## Checklist antes do lançamento

- [ ] HTTPS abre sem aviso no celular (Android e iPhone, pelo app)
- [ ] `http://IP-DA-VPS` não mostra a página nem o painel
- [ ] Botão leva exatamente ao portal oficial
- [ ] securityheaders.com mostra os cabeçalhos ativos
- [ ] Pull request com link não autorizado é bloqueado (teste proposital)
- [ ] Monitor do Uptime Kuma ativo e alerta testado
- [ ] 2FA ativo em GitHub, Easypanel, DNS e painel do app
