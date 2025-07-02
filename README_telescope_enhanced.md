# 🔭 Enhanced Telescope Interface

Uma interface aprimorada para telescópios no World of Space que permite seleção interativa de coordenadas, coordenadas predefinidas, scanner sequencial e histórico de navegação.

![Enhanced Telescope Interface](https://github.com/user-attachments/assets/06c91835-8152-4de3-ba96-6ae2d8cc55ed)

## 🌟 Recursos Implementados

### ✅ Todos os requisitos atendidos:

1. **📍 Interface para inserir coordenadas**: Campos de entrada para X1, X2, Y1, Y2 com validação
2. **⭐ Coordenadas predefinidas**: 8 botões para locais populares (Centro, Norte, Sul, etc.)
3. **🔄 Scanner sequencial**: Modo automático e manual para varrer áreas sistematicamente
4. **📜 Histórico de coordenadas**: Salva as últimas 10 coordenadas visitadas
5. **✅ Validação de entrada**: Verifica limites (-100 a 100) e formatos válidos

### 🎯 Recursos Adicionais:

6. **🔄 Coordenadas próximas**: Explora áreas adjacentes automaticamente
7. **⭐ Salvar favoritos**: Salva coordenadas interessantes como favoritos
8. **🌍 Informações em tempo real**: Mostra dados do planeta atual
9. **📊 Status detalhado**: Feedback visual de todas as operações
10. **🛡️ Verificação de componentes**: Valida se todos os componentes necessários estão conectados

## 📋 Requisitos de Hardware

- **Screen**: Conectado na porta 1 (obrigatório)
- **Keyboard**: Conectado na porta 1 (obrigatório para entrada manual)
- **Telescope**: Pelo menos um telescópio conectado (obrigatório)
- **Modem**: Opcional, para logs externos

## 🚀 Como Usar

### 1. Instalação
```lua
-- Execute o arquivo principal:
telescope_enhanced.txt
```

### 2. Entrada Manual de Coordenadas
- Clique nos campos X1, X2, Y1, Y2 para selecioná-los
- Digite valores entre -100 e 100
- Clique em "🎯 VISUALIZAR COORDENADAS"

### 3. Coordenadas Predefinidas
Use os botões para navegar rapidamente:
- **Centro**: (0,0,0,0)
- **Norte**: (0,0,50,50) 
- **Sul**: (0,0,-50,-50)
- **Leste**: (50,50,0,0)
- **Oeste**: (-50,-50,0,0)
- **Sector A**: (25,25,25,25)
- **Sector B**: (-25,-25,25,25)
- **Setor Rico**: (10,15,20,25)

### 4. Scanner Sequencial
- **"▶️ INICIAR SEQUENCIAL"**: Inicia varredura automática (3s entre coordenadas)
- **"⏭️ PRÓXIMA COORDENADA"**: Avança manualmente para próxima coordenada
- **"⏸️ PARAR SEQUENCIAL"**: Para o modo automático

### 5. Recursos Auxiliares
- **🔄 PRÓXIMAS**: Explora coordenadas próximas (±5 variação)
- **⭐ SALVAR**: Salva coordenadas atuais como favorito
- **📜 Histórico**: Clique em qualquer entrada para revisitar

## 🔧 Estrutura dos Arquivos

- `telescope_enhanced.txt` - Script principal da interface
- `telescope_enhanced_example.txt` - Documentação e exemplos de uso
- `README.md` - Esta documentação

## 💡 Exemplos de Uso

### Busca por Planetas Ricos
1. Use "Setor Rico" como ponto de partida
2. Use "🔄 PRÓXIMAS" para explorar área adjacente
3. Salve coordenadas interessantes com "⭐ SALVAR"

### Varredura Sistemática
1. Defina coordenadas iniciais manualmente
2. Use "▶️ INICIAR SEQUENCIAL" para varredura automática
3. Monitore o histórico para revisar descobertas

### Navegação Rápida
1. Use botões predefinidos para áreas conhecidas
2. Consulte histórico para revisitar locais interessantes
3. Use coordenadas próximas para exploração detalhada

## 🛠️ Melhorias Implementadas

Comparado ao comando original, esta versão adiciona:

- ✅ **Interface gráfica completa** vs comando de linha
- ✅ **Entrada interativa** vs coordenadas fixas
- ✅ **Múltiplas opções de navegação** vs apenas sequencial
- ✅ **Histórico persistente** vs sem memória
- ✅ **Validação robusta** vs verificação básica
- ✅ **Feedback visual** vs apenas texto no console
- ✅ **Coordenadas favoritas** (novo recurso)
- ✅ **Exploração de proximidade** (novo recurso)

## 🔍 Detalhes Técnicos

### Validação de Coordenadas
```lua
local function ValidateCoordinate(value)
    local num = tonumber(value)
    if not num then return false end
    return num >= MIN_COORD and num <= MAX_COORD
end
```

### Histórico Inteligente
- Remove duplicatas automaticamente
- Mantém apenas últimas 10 entradas
- Persiste durante sessão ativa

### Scanner Sequencial
- Baseado no algoritmo do s3.txt original
- Converte posição linear em coordenadas 4D
- Suporte para 201^4 combinações totais

## 🚨 Solução de Problemas

### "❌ Screen não encontrado na porta 1!"
- Verifique se o Screen está conectado na porta 1

### "❌ Nenhum telescópio encontrado!"
- Conecte pelo menos um telescópio em qualquer porta

### "⚠️ Keyboard não encontrado na porta 1"
- Entrada manual será limitada, mas botões predefinidos funcionam

### "❌ Erro ao configurar telescópio"
- Verifique se o telescópio está funcionando
- Tente coordenadas diferentes

## 📈 Status do Projeto

- [x] Interface para inserir coordenadas específicas
- [x] Coordenadas predefinidas com botões
- [x] Scanner sequencial automático e manual
- [x] Histórico de coordenadas visitadas
- [x] Validação completa de entrada
- [x] Coordenadas próximas para exploração
- [x] Sistema de favoritos
- [x] Informações de planetas em tempo real
- [x] Verificação de componentes
- [x] Interface gráfica completa

**Status**: ✅ **COMPLETO** - Todos os requisitos implementados com recursos adicionais

---

*Desenvolvido para World of Space - Uma interface moderna e intuitiva para exploração espacial! 🚀*