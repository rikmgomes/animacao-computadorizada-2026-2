# Exercício 3: Shape Keys

## Equipe
- Ricardo Moreira Gomes

---

## Descrição do Projeto

> Este projeto foi desenvolvido como parte da disciplina *Animação Computadorizada* com o objetivo de explorar o uso de *shape keys* (*blend shapes*) em animação de malhas 3D. A malha da Suzanne foi modelada no Blender com 3 shape keys (`Inflar`, `Esticar` e `Alargar`) e animada na timeline por keyframes. O modelo foi exportado em glTF e importado na Godot, onde um programa executa a animação criada no Blender e também permite alterar manualmente os pesos de cada shape key por teclado e mouse.

---

## Estrutura do Projeto

O projeto consiste em uma cena única (`main.tscn`) + 1 script que controla a animação e os pesos das shape keys, além do modelo exportado do Blender.

| Arquivo | Descrição |
|----------------------|------------------------------------------------------------|
| `main.tscn` | Cena principal com o modelo, câmera, luz e a label de interface. |
| `main.gd` | Lê os shape keys da malha, executa a animação importada do Blender (em loop) e permite alterar os pesos manualmente por teclado e mouse. |
| `suzanne.glb` | Modelo exportado do Blender (glTF Binary) contendo a malha, os 3 shape keys e a animação da timeline. |

---

## Informações Técnicas

- **Modelagem:** Blender (shape keys + keyframes na timeline)
- **Formato de exportação:** glTF 2.0 (`.glb`)
- **Engine:** Godot Engine 4.6.2
- **Linguagem:** GDScript
- **Plataforma-alvo:** Desktop (Windows / Linux / macOS)

---

## Shape Keys

| Shape Key | Deformação |
|-----------|------------|
| `Inflar` | Escala uniforme da malha (1.3x). |
| `Esticar` | Escala no eixo vertical (1.6x em Z no Blender). |
| `Alargar` | Escala no eixo horizontal (1.6x em X no Blender). |

A animação da timeline (120 frames) ativa uma shape key por vez: `Inflar` (frame 30), `Esticar` (frame 60) e `Alargar` (frame 90), voltando ao estado original no frame 120.

---

## Controles

| Entrada | Ação |
|---------------------------|-----------------------------------------------------|
| `Espaço` | Alterna entre modo **Animação** e modo **Manual**. |
| `1` / `2` / `3` | Seleciona a shape key ativa (`Inflar` / `Esticar` / `Alargar`). |
| `↑` / `↓` | Aumenta / diminui o peso da shape key ativa. |
| Roda do mouse | Aumenta / diminui o peso da shape key ativa. |
| Arrastar com botão esquerdo | Altera o peso da shape key ativa ao mover o mouse na horizontal. |
| `R` | Zera todos os pesos (modo manual). |

No modo Animação, a animação sobrescreve os pesos a cada frame; por isso a edição manual só tem efeito no modo Manual. Ao voltar para o modo Animação, ela retoma de onde parou.

---

## Checklist de Requisitos

- [x] Criação de 3 shape keys em um objeto (Suzanne);
- [x] Pequena animação na timeline (keyframes) testando as shape keys;
- [x] Exportação para glTF;
- [x] Importação no motor de jogo (Godot);
- [x] Programa que executa a animação feita na timeline do Blender;
- [x] Programa que permite alterar os pesos das shape keys por interação de mouse ou teclado;

---

## Link para a Build

🔗 https://rikmgomes.itch.io/ex-3-shape-keys?secret=1sXk1I0Osv154Ii0uBTmAjr3sA