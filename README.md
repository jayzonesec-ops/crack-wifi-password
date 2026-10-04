<<<<<<< HEAD
# 📡 Brute Force WiFi – Handshake Capture & Password Cracking

   Versão: 1.0

   Autor: JayZoneSec

   Plataforma: Kali Linux / Debian-based

📡 Crack WiFi Password

   Ferramenta automatizada para captura de handshake WPA/WPA2 e quebra de senha WiFi com wordlists, crunch e suporte a GPU (hashcat).

   [!CAUTION]
 
   AVISO LEGAL — LEIA ANTES DE USAR**
 
   Esta ferramenta é destinada **exclusivamente** a testes de segurança em **redes próprias** ou com **autorização expressa por escrito** do proprietário. O uso não autorizado para acessar redes de terceiros é **CRIME** no Brasil, previsto no **Art. 154-A do Código Penal** (Lei 12.737/2012), com pena de detenção de **3 meses a 2 anos** e multa.
 
   O autor **não se responsabiliza** pelo uso indevido desta ferramenta. **Ao executá-la, você assume total responsabilidade por suas ações.**

------------------------------------------------------------------------------------------------------------------------

## 🔍 Visão Geral

   Esta ferramenta automatiza o processo completo de:

✅ Ativação do modo monitor em interfaces wireless.

✅ Varredura de redes Wi-Fi disponíveis (SSID, BSSID, canal, potência, beacons e criptografia).

✅ Seleção de rede alvo e captura do handshake WPA/WPA2.

✅ Ataque de desautenticação (deauth) direcionado a toda a rede ou a um cliente específico.

✅ Quebra de senha com wordlists (rockyou, personalizada, crunch) e ataque via pipe com crunch.

✅ Suporte opcional a GPU via hashcat para aceleração massiva.

✅ Armazenamento automático de senhas descobertas.

-------------------------------------------------------------------------------------------------------------------

## ✨ Funcionalidades

   Recurso	Descrição:

 1- Interface interativa
 
 2- Menus intuitivos com status atualizado a cada etapa.
 
 3- Modo monitor automático, ativa e gerencia interfaces wireless sem complicação.
 
 4- Varredura de redes, lista todas as redes com SSID, BSSID, canal, potência, beacons e criptografia.
 
 5- Captura de handshake,	usa airodump-ng e aireplay-ng com opção de repetição em caso de falha.
 
 6- Deauth contínuo, envia 2 pacotes a cada 3 segundos para forçar reconexão.
 
 7- Seleção de cliente,	permite escolher um cliente específico para ataques direcionados.
 
 8- Múltiplos métodos de wordlist:	rockyou, wordlist do usuário, geração com crunch, ataque via pipe com crunch.
 
 9- Suporte a GPU,	detecta automaticamente disponibilidade de GPU e oferece quebra com hashcat.

10- Salvamento de senhas,	todas as senhas descobertas são salvas em senhas_capturadas.txt.

11- Saída limpa, ao sair (Ctrl+C ou opção 4), restaura a interface, mata processos e limpa a tela.

12- Cabeçalho dinâmico,	cor aleatória a cada atualização e relógio em tempo real.

-----------------------------------------------------------------------------------------------------------------
=======
# 📡 Brute Force WiFi — Handshake Capture & Password Cracking

> Ferramenta automatizada para captura de handshake WPA/WPA2 e quebra de senha WiFi com wordlists, **crunch** e suporte a **GPU (hashcat)**.

![Versão](https://img.shields.io/badge/versão-1.0-blue?style=for-the-badge)
![Plataforma](https://img.shields.io/badge/plataforma-Kali%20Linux-557C94?style=for-the-badge&logo=kalilinux&logoColor=white)
![Bash](https://img.shields.io/badge/bash-5.0+-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)
![Licença](https://img.shields.io/badge/licença-MIT-green?style=for-the-badge)

---

> [!CAUTION]
> **AVISO LEGAL — LEIA ANTES DE USAR**
> Esta ferramenta é destinada **exclusivamente** a testes de segurança em **redes próprias** ou com **autorização expressa por escrito** do proprietário. O uso não autorizado para acessar redes de terceiros é **CRIME** no Brasil, previsto no **Art. 154-A do Código Penal** (Lei 12.737/2012), com pena de detenção de **3 meses a 2 anos** e multa.
>
> O autor **não se responsabiliza** pelo uso indevido desta ferramenta. **Ao executá-la, você assume total responsabilidade por suas ações.**

---

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Funcionalidades](#-funcionalidades)
- [Dependências](#-dependências)
- [Instalação](#-instalação)
- [Como Usar](#-como-usar)
- [Fluxo de Ataque](#-fluxo-de-ataque)
- [Métodos de Wordlist](#-métodos-de-wordlist)
- [Exemplo de Uso](#️-exemplo-de-uso)
- [Avisos Legais](#️-avisos-legais)
- [Licença](#-licença)
- [Autor](#-autor)

---

## 🔍 Visão Geral

Esta ferramenta automatiza o processo completo de auditoria de redes Wi-Fi:

- ✅ Ativação do **modo monitor** em interfaces wireless
- ✅ Varredura de redes Wi-Fi disponíveis (SSID, BSSID, canal, potência, beacons e criptografia)
- ✅ Seleção de rede alvo e **captura do handshake WPA/WPA2**
- ✅ Ataque de **desautenticação (deauth)** direcionado a toda a rede ou a um cliente específico
- ✅ Quebra de senha com **wordlists** (rockyou, personalizada, crunch) e ataque via **pipe** com crunch
- ✅ Suporte opcional a **GPU via hashcat** para aceleração massiva
- ✅ Armazenamento automático de senhas descobertas

---

## ✨ Funcionalidades

| # | Recurso | Descrição |
|---|---------|-----------|
| 1 | **Interface interativa** | Menus intuitivos com status atualizado a cada etapa |
| 2 | **Modo monitor automático** | Ativa e gerencia interfaces wireless sem complicação |
| 3 | **Varredura de redes** | Lista todas as redes com SSID, BSSID, canal, potência, beacons e criptografia |
| 4 | **Captura de handshake** | Usa `airodump-ng` e `aireplay-ng` com opção de repetição em caso de falha |
| 5 | **Deauth contínuo** | Envia 2 pacotes a cada 3 segundos para forçar reconexão |
| 6 | **Seleção de cliente** | Permite escolher um cliente específico para ataques direcionados |
| 7 | **Múltiplos métodos de wordlist** | rockyou, wordlist do usuário, geração com crunch, ataque via pipe |
| 8 | **Suporte a GPU** | Detecta automaticamente disponibilidade de GPU e oferece quebra com hashcat |
| 9 | **Salvamento de senhas** | Todas as senhas descobertas são salvas em `senhas_capturadas.txt` |
| 10 | **Saída limpa** | Ao sair (`Ctrl+C` ou opção 4), restaura a interface, mata processos e limpa a tela |
| 11 | **Cabeçalho dinâmico** | Cor aleatória a cada atualização e relógio em tempo real |

---
>>>>>>> 3454e83 (Initial commit)

## 📦 Dependências

### Pacotes obrigatórios

<<<<<<< HEAD
`aircrack-ng` – Captura e quebra de handshake.

`xterm` – Janelas de monitoramento em tempo real.

`crunch` – Geração de wordlists e ataques via pipe.

### Pacotes Opcionais

`hashcat` - Quebra com GPU (aceleração massiva).
`hashcat-utils` - Utilitários (inclui `cap2ccapx`)

### Instalação no Kali Linux / Debian

   sudo apt update
 
   sudo apt install aircrack-ng xterm crunch hashcat hashcat-utils

-----------------------------------------------------------------------------------------------------------------

## 🚀 Como Usar

### 1. Clone ou baixe o script

   git clone https://github.com/jayzonesec-ops/crack-wifi-password

   cd crack-wifi-password

   chmod +x crack_wifi.sh


### 2. Execute com privilégios de root

   sudo ./crack_wifi.sh


### 3. Menu principal
=======
| Pacote | Função |
|--------|--------|
| `aircrack-ng` | Captura e quebra de handshake |
| `xterm` | Janelas de monitoramento em tempo real |
| `crunch` | Geração de wordlists e ataques via pipe |

### Pacotes opcionais

| Pacote | Função |
|--------|--------|
| `hashcat` | Quebra com GPU (aceleração massiva) |
| `hashcat-utils` | Utilitários (inclui `cap2hccapx`) |

### Instalação (Kali Linux / Debian)

```bash
sudo apt update
sudo apt install aircrack-ng xterm crunch hashcat hashcat-utils
```

---

## 🚀 Como Usar

### 1️⃣ Clone ou baixe o script

```bash
git clone https://github.com/jayzonesec-ops/crack-wifi-password
cd crack-wifi-password
chmod +x crack_wifi.sh
```

### 2️⃣ Execute com privilégios de root

```bash
sudo ./crack_wifi.sh
```

### 3️⃣ Menu principal
>>>>>>> 3454e83 (Initial commit)

<p align="center">
  <img src="https://github.com/user-attachments/assets/e0750495-084b-4373-a8e6-60496a7c3e10" width="800"/>
  <br>
  <em>Menu principal da ferramenta</em>
</p>

<<<<<<< HEAD
---------------------------------------------------------------------------------------------------------------

## 📋 Fluxo de Ataque:

1- Configurar Interface – selecione a interface wireless (ex: wlan0) e ative o modo monitor.

2- Varredura de Redes – escaneie as redes disponíveis e selecione o alvo.

3- Tipo de Ataque – escolha entre ataque à rede inteira ou a um cliente específico.

4- Captura de Handshake – aguarde a captura do handshake (até 60 segundos).

5- Selecionar Wordlist – escolha entre vários métodos de quebra.

6- Quebra de Senha – inicie a quebra e aguarde o resultado.

----------------------------------------------------------------------------------------------------------------

## 🧠 Métodos de Wordlist:

1 – rockyou	Wordlist padrão do Kali Linux.

2 – Wordlist do usuário	Lista wordlists em /usr/share/wordlists/wordlist_usuario/. Permite adicionar novas.

3 – Gerar com crunch	Define tamanho e caracteres; gera arquivo e pergunta se deseja salvar.

4 – Ataque via pipe	Usa crunch em pipe com aircrack-ng – não cria arquivo em disco.

5 – GPU (hashcat)	(se disponível) Quebra acelerada com GPU.

---------------------------------------------------------------------------------------------------------------

## ⚙️ Exemplo de Uso

   sudo ./crack_wifi.sh

Selecione a interface wlan0.

Escaneie as redes.

Escolha o alvo (ex: número 3).

Selecione o tipo de ataque (ex: 1 – rede inteira).

Aguarde a captura do handshake.

Escolha a wordlist (ex: 4 – ataque via pipe).

Configure o crunch (ex: min 8, max 10, charset numérico).

Inicie a quebra.

Se encontrada, a senha será exibida e salva.

--------------------------------------------------------------------------------------------------------------------------------

## ⚠️ Avisos Legais

   Esta ferramenta destina-se exclusivamente a testes de segurança em redes próprias ou com autorização explícita do proprietário.

   O uso não autorizado para acessar redes de terceiros é ilegal.

   O autor não se responsabiliza por mau uso da ferramenta.

   Ao executar, você assume total responsabilidade por suas ações.

----------------------------------------------------------------------------------------------------------------------------------

## 📄 Licença

   MIT License – Copyright (c) 2026 JayZoneSec

### 👨‍💻 Autor

   JayZoneSec

GitHub: @jayzonesec-ops

Projeto: crack-wifi-password
=======
---

## 📋 Fluxo de Ataque

> [!IMPORTANT]
> Siga as etapas na ordem apresentada para garantir o funcionamento correto da ferramenta.

### Etapa 1 — Configurar Interface

Selecione a interface wireless (ex: wlan0) e ative o modo monitor.

### Etapa 2 — Varredura de Redes

Escaneie as redes disponíveis e selecione o alvo.

### Etapa 3 — Tipo de Ataque

Escolha entre:

| Opção | Descrição |
|-------|-----------|
| 1 | Ataque à rede inteira (todos os clientes) |
| 2 | Ataque a cliente específico (mais discreto) |

### Etapa 4 — Captura de Handshake

Aguarde a captura do handshake (até 60 segundos).

### Etapa 5 — Selecionar Wordlist

Escolha entre os vários métodos de quebra disponíveis.

### Etapa 6 — Quebra de Senha

Inicie a quebra e aguarde o resultado. Senhas encontradas são salvas em `senhas_capturadas.txt`.

---

## 🧠 Métodos de Wordlist

| Opção | Método | Descrição |
|-------|--------|-----------|
| 1 | rockyou | Wordlist padrão do Kali Linux |
| 2 | Wordlist do usuário | Lista wordlists em `/usr/share/wordlists/wordlist_usuario/`. Permite adicionar novas |
| 3 | Gerar com crunch | Define tamanho e caracteres; gera arquivo e pergunta se deseja salvar |
| 4 | Ataque via pipe | Usa crunch em pipe com aircrack-ng — não cria arquivo em disco |
| 5 | GPU (hashcat) | (se disponível) Quebra acelerada com GPU |

---

## ⚙️ Exemplo de Uso

```bash
sudo ./crack_wifi.sh
```

1. Selecione a interface `wlan0`
2. Escaneie as redes
3. Escolha o alvo (ex: número 3)
4. Selecione o tipo de ataque (ex: 1 — rede inteira)
5. Aguarde a captura do handshake
6. Escolha a wordlist (ex: 4 — ataque via pipe)
7. Configure o crunch (ex: min 8, max 10, charset numérico)
8. Inicie a quebra
9. Se encontrada, a senha será exibida e salva

---

## ⚠️ Avisos Legais

> [!CAUTION]
> Esta ferramenta destina-se exclusivamente a testes de segurança em redes próprias ou com autorização explícita do proprietário.
>
> O uso não autorizado para acessar redes de terceiros é **ILEGAL**.
>
> O autor não se responsabiliza por mau uso da ferramenta.
>
> Ao executar, você assume total responsabilidade por suas ações.

---

## 📄 Licença

Este projeto está sob a licença **MIT License** — Copyright (c) 2026 JayZoneSec.

Veja o arquivo `LICENSE` para mais detalhes.

---

## 👨‍💻 Autor

**JayZoneSec**

- 🐙 GitHub: [@jayzonesec-ops](https://github.com/jayzonesec-ops)
- 📦 Projeto: [crack-wifi-password](https://github.com/jayzonesec-ops/crack-wifi-password)

<p align="center">
  <sub>Feito com ❤️ por <a href="https://github.com/jayzonesec-ops">JayZoneSec</a></sub>
</p>
>>>>>>> 3454e83 (Initial commit)
