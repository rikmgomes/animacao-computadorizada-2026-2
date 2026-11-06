# Exercício 4: Pipeline de Personagem Animado por Esqueleto

## Equipe
- Ricardo Moreira Gomes

---

## Descrição do Projeto

> Este projeto foi desenvolvido como parte da disciplina *Animação Computadorizada* com o objetivo de percorrer o pipeline completo de um personagem animado por esqueleto: modelagem, rigging, skinning, animação, exportação e implementação em um motor de jogo. O personagem é um humanoide low-poly feito apenas com cubos, modelado, rigado e animado no Blender com 3 animações (`Idle`, `Acenar` e `Dancar`). O modelo foi exportado em glTF e importado na Godot, onde um programa permite alternar entre as animações por teclado, com transições suaves entre elas.

---

## Estrutura do Projeto

O projeto consiste em uma cena única (`main.tscn`) + 1 script que controla a troca de animações, além do modelo exportado do Blender.

| Arquivo | Descrição |
|----------------------|------------------------------------------------------------|
| `main.tscn` | Cena principal com o personagem, câmera, luz, chão e ambiente. |
| `main.gd` | Monta uma máquina de estados (`AnimationTree`) com as 3 animações importadas, define o loop e troca de animação por teclado com transição suave. Também cria a label de interface. |
| `personagem.glb` | Modelo exportado do Blender (glTF Binary) contendo a malha, o esqueleto e as 3 animações. |

---

## Informações Técnicas

- **Modelagem, rig e animação:** Blender 5.2
- **Formato de exportação:** glTF 2.0 (`.glb`)
- **Engine:** Godot Engine 4.7.2
- **Linguagem:** GDScript
- **Plataforma-alvo:** Desktop (Windows / Linux / macOS)

---

## Pipeline

| Etapa | O que foi feito |
|-------|-----------------|
| Modelagem | Humanoide low-poly montado com cubos (quadril, torso, cabeça, nariz, braços, antebraços, mãos, coxas, canelas e pés), em T-pose. |
| Rigging | Esqueleto criado manualmente no Blender, sem rig pronto: `Hips`, `Spine`, `Head` e, de cada lado (`.L` e `.R`), `Thigh`, `Shin`, `Foot`, `UpperArm`, `ForeArm` e `Hand`. O lado direito foi gerado por espelhamento (*Symmetrize*). |
| Skinning | Pesos automáticos (*With Automatic Weights*), com ajustes manuais por grupos de vértices onde foi necessário. |
| Animação | 3 animações criadas por keyframes no Blender, cada uma como uma *action* separada. |
| Exportação | glTF 2.0 (`.glb`), com cada *action* exportada como uma animação. |
| Implementação | Importação na Godot, `AnimationTree` com máquina de estados e controle por teclado. |

---

## Animações

| Animação | Descrição |
|----------|-----------|
| `Idle` | Personagem parado, com os braços ao lado do corpo e leve movimento de respiração no tronco. |
| `Acenar` | Braço esquerdo levantado, com o antebraço balançando de um lado para o outro. |
| `Dancar` | Tronco girando de um lado para o outro, com os braços se alternando para cima e para baixo. |

---

## Controles

| Entrada | Ação |
|---------------------------|-----------------------------------------------------|
| `1` | Toca a animação `Idle`. |
| `2` | Toca a animação `Acenar`. |
| `3` | Toca a animação `Dancar`. |

A troca entre animações usa *cross-fade* (mistura suave) de 0,35 segundos, definido nas transições da máquina de estados do `AnimationTree`.
---

## Checklist de Requisitos

- [x] Personagem humanoide modelado do zero (low-poly, com primitivas);
- [x] Rigging e skinning feitos manualmente (sem rig pronto);
- [x] Pelo menos 3 animações atribuídas ao personagem;
- [x] Exportação para glTF;
- [x] Importação no motor de jogo (Godot);
- [x] Controle simples que permite alternar entre as animações;
- [x] Transições suaves entre as animações (máquina de estados com cross-fade);

---

## Link para a Build

🔗 https://rikmgomes.itch.io/ex-4-pipeline-humanoide?secret=waJNDwN0NYDjhcRE5v3ZOmDw8
