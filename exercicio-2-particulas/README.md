# Exercício 2: Sistemas de Partículas

## Equipe
- Ricardo Moreira Gomes

---

## Descrição do Projeto

> Este projeto foi desenvolvido como parte da disciplina *Animação Computadorizada* com o objetivo de explorar a técnica de sistemas de partículas. A aplicação implementa um sistema de partículas customizado com múltiplos emissores, comportamentos de evolução e critérios de morte, todos alternáveis dinamicamente em tempo de execução através de teclas, permitindo a demonstração individual de cada variação exigida no exercício.

---

## Estrutura do Projeto

O projeto consiste em uma cena única (`main.tscn`) + 2 scripts gerenciando o sistema de partículas e a interface.

| Arquivo | Descrição |
|----------------------|------------------------------------------------------------|
| `main.gd` | Gerencia o estado atual de cada categoria (atributo/emissor/comportamento/morte), escuta os inputs de troca de modo (teclas 0-3) e atualiza as labels de status e estatísticas na tela. |
| `particle_system.gd` | Implementa a lógica completa do sistema de partículas: nascimento (3 emissores), evolução (5 comportamentos + 3 variações de atributos) e morte (2 critérios), além da renderização via `_draw()`. |

---

## Informações Técnicas

- **Engine:** Godot Engine 4.6.2
- **Linguagem:** GDScript
- **Plataforma-alvo:** Desktop (Windows / Linux / macOS)

---

## Checklist de Requisitos

- [x] Implementação de pelo menos um sistema de partículas;
- [x] No mínimo 3 variações de atributos ao longo do tempo (cor em gradiente HSV, tamanho pulsante, forma morfando);
- [x] No mínimo 3 formas de nascimento/emissores diferentes (ponto, área, anel);
- [x] No mínimo 5 comportamentos de evolução diferentes (gravidade/queda, explosão, órbita, onda, atrator);
- [x] Pelo menos 2 critérios de morte (tempo de vida, saída da tela);
- [x] Cada comportamento demonstrável individualmente via troca de modo (teclas 0/1/2/3);
- [x] Utilização de um motor de jogo (Godot);
- [x] Interface com contadores de partículas vivas/nascidas/mortas em tempo real;

---

## Link para a Build

🔗 https://rikmgomes.itch.io/ex-2-sistema-de-particulas?secret=kOZDRPX3la5vPtq86RAVO48t0

---

## Referências

1. W. T. Reeves. 1983. *Particle Systems — a Technique for Modeling a Class of Fuzzy Objects*. ACM Trans. Graph. 2, 2 (April 1983), 91-108.
