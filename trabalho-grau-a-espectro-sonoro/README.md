# Exercício 3: Espectro Sonoro

## Equipe
- Ricardo Moreira Gomes

---

## Descrição do Projeto

> Este projeto foi desenvolvido como parte da disciplina *Animação Computadorizada* com o objetivo de explorar a transformação de dados do espectro sonoro em animações. A aplicação implementa um jogo simples similar a *Dinosaur Game* e *Geometry Dash* em que as músicas influenciam diretamente no comportamento e no visual do personagem jogador, dos obstáculos e do cenário. Valores normalizados de graves, médios, agudos, energia total e barras de frequência são utilizados para influenciar diferentes comportamentos e animações por código.

---

## Estrutura do Projeto

O projeto consiste em uma cena única (`main.tscn`) + 2 scripts gerenciando o sistema de áudio e a lógica do jogo.

| Arquivo | Descrição |
|----------------------|------------------------------------------------------------|
| `main.gd` | Controla a lógica do jogo, incluindo movimentação, obstáculos, pontuação e efeitos visuais reativos à musica. |
| `spectrum.gd` | Analisa o áudio em frequências graves, médias e agudas, calcula a energia sonoroa e detecta as batidas para sincronizar os efeitos do jogo. |

---

## Informações Técnicas

- **Engine:** Godot Engine 4.6.2
- **Linguagem:** GDScript
- **Plataforma-alvo:** Desktop (Windows / Linux / macOS)

---

## Checklist de Requisitos

- [x] Implementação de uma das opções do trabalho (A);
- [x] Motor de jogo de livre escolha (Godot);
- [x] Mapeamento do espectro sonoro para os parâmetros de animação devidamente explicados;
- [x] Desenvolvimento de ambiente experimental com comportamento de objetos;
- [x] Alteração de velocidade, direções, trajetória, aparência, rastros, partículas etc;
- [x] Ambiente pode ser 2D ou 3D (2D);

---

## Link para a Build

🔗 https://rikmgomes.itch.io/trabalho-espectro-sonoro?secret=nqfRAoUG3b6OGlfzIbiphXnQ

---

## Referências

1. Thomas Lewiner, Thales Vieira, Alex Bordignon, Allyson Cabral, Clarissa Marques, Joao Paixao, Lis Custodio, Marcos Lage, Maria Andrade, Renata Nascimento, Scarlett de Botton, Sinesio Pesco, Helio Lopes, Vinicius Mello, Adelailson Peixoto, Dimas Martinez, *Tuning Manifold Harmonics Filters*, Graphics, Patterns and Images, SIBGRAPI Conference on, pp. 110-117, 2010 23rd SIBGRAPI Conference on Graphics, Patterns and Images, 2010.
2. Steve DiPaola and Ali Arya. 2006. *Emotional remapping of music to facial animation*. In Proceedings of the 2006 ACM SIGGRAPH symposium on Videogames (Sandbox '06). ACM, New York, NY, USA, 143-149. DOI=http://dx.doi.org/10.1145/1183316.1183337
3. Wikipédia, artigo sobre Som digital. http://pt.wikipedia.org/wiki/Som_digital. Acessado em 05/09/2018.
4. Wikipédia, artigo sobre Espectro Sonoro. http://pt.wikipedia.org/wiki/Espectro_sonoro. Acessado em 18/09/2025.
5. Alice R. Abreu, João R. Bittencourt, Rossana B. Queiroz and Vinícius J. Cassol. *Geração procedural de coreografias para jogos de dança*. Anais do SBGames 2017: Games na Graduação, Curitiba, 2017.
6. Music: Legends - Retro Loops by Josh Lim. Fonte: https://joshjameslim.itch.io/legend-retro-loops. Licence: CC BY 4.0. Três faixas desse pacote forem utilizadas neste projeto.