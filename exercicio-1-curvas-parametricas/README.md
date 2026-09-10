# Exercício 1: Curvas Paramétricas

## Equipe
- Ricardo Moreira Gomes

---

## Descrição do Projeto

> Este projeto foi desenvolvido como parte da disciplina *Animação Computadorizada* com o objetivo de explorar a construção matemática e visualização de curvas paramétricas. A aplicação permite alternar dinamicamente entre diferentes tipos de curvas (Interpolação Linear, Catmull-Rom e Bézier Cúbica), calculando os pontos com base em nós de controle editáveis somente na modo de edição da Godot e movimentando um objeto ao longo do trajeto com velocidade constante e rotação orientada pela direção do movimento.

---

## Estrutura do Projeto

O projeto consiste em uma cena única (main.tscn) + 4 scripts gerenciando as curvas e trajetórias.

| Arquivo | Descrição |
|----------------------|------------------------------------------------------------|
| `main.gd` | Gerencia o estado atual da curva, escuta os inputs de troca de modo e desenha os pontos de controle e tangências. |
| `pathfollower.gd` | Controla a movimentação suave do objeto ao longo da curva utilizando parametrização por comprimento de arco e cálculo de rotação. |
| `arrow.gd` | Configura o desenho vetorial e visualização da flecha 2D orientada na direção do vetor tangente. |
| `CurveUtils.gd` | Contém a implementação matemática pura para a geração dos pontos das curvas Linear, Catmull-Rom e Bézier. |

---
## Informações Técnicas

- **Engine:** Godot Engine 4.6.2  
- **Linguagem:** GDScript  
- **Plataforma-alvo:** Desktop (Windows / Linux / macOS)  

---

## Checklist de Requisitos

- [x] Implementação de um sistema de trajetórias baseado em curvas paramétricas;
- [x] Estrutura de pontos de controle com adição via editor da Godot;
- [x] Implementação: Interpolação Linear + Bézier;
- [x] Visualização individual dos tipos de curvas e trajetórias;
- [x] Utilização de um motor de jogo (Godot);
- [x] Cena única com trocas de modo (pressionando as teclas 1/2/3);

---

## Link para a Build

🔗 *Disponível no repositório do projeto.*

---

## Referências

1. Parent, R. (2012). *Interpolating values* (pp. 61–109). In *Computer animation: Algorithms and techniques* (3rd
ed.). San Francisco, CA: Morgan Kaufmann Publishers Inc.
2. Parent, R. (2012). *Interpolation-based animation* (pp. 111–160). In *Computer animation: Algorithms and
techniques* (3rd ed.). San Francisco, CA: Morgan Kaufmann Publishers Inc.
3. Lengyel, E. (2011). *Curves* (pp. 317–359). In *Mathematics for 3D game programming and computer graphics*
(3rd ed.). Boston, MA: Course Technology Press.
