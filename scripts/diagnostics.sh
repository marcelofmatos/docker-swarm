#!/bin/bash
#
# curl https://raw.githubusercontent.com/marcelofmatos/docker-swarm/refs/heads/main/scripts/diagnostics.sh | bash
#
VERBOSE=0

if [[ "$1" == "--verbose" ]]; then
  VERBOSE=1
fi

echo "### Teste de Diagnóstico Docker Swarm ###"

# Função para exibir status
show_status() {
  local message=$1
  local status=$2
  if [[ "$status" -eq 0 ]]; then
    echo -e "[\033[32mOK\033[0m] $message"
  else
    echo -e "[\033[31mErro\033[0m] $message"
  fi
}

# Teste 1: Verificar conectividade com o gerenciador
echo "Teste 1: Conectividade com o Gerenciador"
MANAGER_IP="10.0.0.175"
ping -c 1 $MANAGER_IP > /dev/null 2>&1
show_status "Conectividade com o gerenciador ($MANAGER_IP)" $?

# Teste 2: Verificar porta 2377
echo "Teste 2: Porta 2377 no Gerenciador"
nc -zv $MANAGER_IP 2377 > /tmp/port_test.log 2>&1
if [[ $? -eq 0 ]]; then
  show_status "Porta 2377 está acessível no gerenciador" 0
else
  show_status "Porta 2377 inacessível no gerenciador" 1
  echo "Evidência: $(cat /tmp/port_test.log)"
fi

# Teste 3: Verificar versão do Docker
echo "Teste 3: Verificar versão do Docker"
DOCKER_VERSION=$(docker version --format '{{.Server.Version}}')
if [[ $? -eq 0 ]]; then
  show_status "Docker está instalado (versão: $DOCKER_VERSION)" 0
else
  show_status "Docker não está instalado ou configurado corretamente" 1
fi

# Teste 4: Verificar nó no Swarm
echo "Teste 4: Verificar nó no Swarm"
SWARM_STATUS=$(docker info --format '{{.Swarm.LocalNodeState}}')
if [[ "$SWARM_STATUS" == "active" ]]; then
  show_status "Nó está ativo no Swarm" 0
else
  show_status "Nó não está ativo no Swarm (Status: $SWARM_STATUS)" 1
fi

# Teste 5: Sincronização de tempo
echo "Teste 5: Sincronização de Tempo"
TIME_DIFF=$(timedatectl | grep "NTP synchronized" | grep -o "yes")
if [[ "$TIME_DIFF" == "yes" ]]; then
  show_status "Tempo está sincronizado com o NTP" 0
else
  show_status "Tempo não está sincronizado com o NTP" 1
fi

# Teste 6: Logs do Docker
echo "Teste 6: Verificar Logs do Docker"
docker logs $(docker ps -q) > /tmp/docker_logs.log 2>&1
if [[ $? -eq 0 ]]; then
  show_status "Logs do Docker estão acessíveis" 0
else
  show_status "Não foi possível acessar os logs do Docker" 1
  echo "Evidência: $(tail -n 5 /tmp/docker_logs.log)"
fi

# Informações detalhadas se --verbose for usado
if [[ "$VERBOSE" -eq 1 ]]; then
  echo "### Informações Detalhadas do Docker ###"
  docker info
fi
