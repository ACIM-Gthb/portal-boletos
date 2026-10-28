#!/bin/sh
# Verifica se a página só aponta para destinos autorizados.
# Usado pelo GitHub Actions e pode ser rodado localmente: sh scripts/verificar-links.sh
set -eu

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
PERMITIDOS="$RAIZ/config/links-permitidos.txt"
PASTA="$RAIZ/public"
ERROS=0

# Prefixos permitidos (ignora comentários e linhas vazias)
PREFIXOS=$(grep -vE '^[[:space:]]*(#|$)' "$PERMITIDOS" | tr -d '\r' | sed 's/[[:space:]]*$//')
PORTAL=$(printf '%s\n' "$PREFIXOS" | head -n 1)

if [ -z "$PORTAL" ]; then
  echo "ERRO: nenhum link permitido definido em config/links-permitidos.txt"
  exit 1
fi

echo "Portal oficial esperado: $PORTAL"

for ARQ in $(find "$PASTA" -type f \( -name '*.html' -o -name '*.svg' -o -name '*.css' \)); do
  NOME="${ARQ#$RAIZ/}"

  # 1) Nada de JavaScript, formulários, iframes, redirecionamentos automáticos ou <base>
  if grep -inE '<script|javascript:|<form|<iframe|<object|<embed|<base[[:space:]>]|http-equiv=["'"'"']?refresh|[[:space:]]on[a-z]+[[:space:]]*=' "$ARQ"; then
    echo "ERRO em $NOME: conteúdo proibido encontrado (script, formulário, iframe, refresh ou evento)."
    ERROS=1
  fi

  # 2) Todo link http(s) precisa começar por um prefixo permitido
  for LINK in $(grep -oiE '(href|src|action|url)[[:space:]]*[=(][[:space:]]*["'"'"']?https?://[^"'"'"' )>]+' "$ARQ" \
                | sed -E 's#^.*(https?://)#\1#'); do
    OK=0
    for P in $PREFIXOS; do
      case "$LINK" in "$P"*) OK=1 ;; esac
    done
    if [ "$OK" -eq 1 ]; then
      echo "ok      $NOME -> $LINK"
    else
      echo "BLOQUEADO $NOME -> $LINK"
      ERROS=1
    fi
  done
done

# 3) A página principal precisa conter o link oficial do portal
if ! grep -qF "href=\"$PORTAL" "$PASTA/index.html"; then
  echo "ERRO: o botão do portal oficial ($PORTAL) não foi encontrado em public/index.html"
  ERROS=1
fi

if [ "$ERROS" -ne 0 ]; then
  echo ""
  echo "Verificação FALHOU. A alteração não pode ser publicada."
  exit 1
fi

echo ""
echo "Verificação OK: todos os links são autorizados."
