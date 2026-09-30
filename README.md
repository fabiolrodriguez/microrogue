# A Última Vigília / The Last Vigil

Um micro roguelike de ação em uma única cripta, feito em **Godot 4.6+** sobre o Indie Game Starter Kit 2.0. Quatro selos, quatro escolhas de relíquias e um Guardião entre você e a aurora. Partidas planejadas para 5–10 minutos, sem progressão permanente.

## Jogar

Importe `project.godot` no Godot e pressione **F6** em `game/entry.tscn`, ou **F5** para executar o projeto. Não precisa instalar dependências, plugins ou gerar assets.

```sh
godot --path .
```

| Ação | Teclado / mouse | Controle |
| --- | --- | --- |
| Mover | WASD ou setas | Analógico esquerdo / direcional |
| Espada — segure para repetir | J ou Espaço; clique esquerdo mira no cursor | A / Cross |
| Esquiva | K, Shift ou clique direito | B / Circle |
| Pausar | Esc | Start / Options |
| Menus / relíquias | Setas, Enter, mouse | Direcional, A / Cross |

Sem mouse, a espada mira automaticamente em inimigos próximos. Os pilares bloqueiam movimento e projéteis. A esquiva tem um breve período de invulnerabilidade. Círculos no chão anunciam perigos; linhas indicam a direção travada dos ataques.

## A partida

- Cada selo dura pelo menos 65 segundos. Novos grupos chegam até os 55 segundos; depois, elimine os sobreviventes.
- Após cada selo, vá ao baú central: cure 1 de vida e escolha uma entre três relíquias. Cada relíquia só aparece uma vez na sua build.
- Ratos perseguem; goblins anunciam investidas; esqueletos mantêm distância e atiram; slimes deixam poças temporárias quando morrem.
- A partir do segundo selo, espinhos alternam entre corredores. O Guardião usa leques, anéis com abertura, maldições no chão e reforços. Abaixo de metade da vida, fica mais agressivo.
- Morrer ou vencer abre a opção de outra partida imediatamente. Configurações de áudio, vídeo e idioma são persistidas pela base; partidas e relíquias não são salvas.

Oito relíquias: alcance/dano, cadência, onda perfurante, reflexão de projéteis, esquiva/movimento, vida máxima/cura, cura por eliminações e dano extra com bônus em baixa vida.

## Implementação

Todo o jogo está em `game/`. `core/` e as cenas reutilizáveis permanecem iguais ao template. A cripta é desenhada num viewport de 384×192 pixels, com amostragem nearest; a interface usa o tema compartilhado e uma paleta semântica própria. Textos completos em português brasileiro e inglês, com troca de idioma em tempo real.

Consulte [resultados de validação](docs/VALIDATION.md), [integração e arquitetura do jogo](game/README.md), [decisões de design](game/DESIGN.md), [arquitetura da base](ARCHITECTURE.md) e [documentação original](docs/STARTER_KIT.md).

## Testar

```sh
python3 tests/run_tests.py --godot /caminho/para/Godot
python3 tests/run_tests.py --godot /caminho/para/Godot --screenshots /tmp/vigil-shots
python3 tests/run_tests.py --godot /caminho/para/Godot --only game
```

O runner importa uma cópia descartável e isola os arquivos de configuração e save. A suíte do jogo cobre combate, colisão, recompensas, navegação, pausa, vitória, morte, reinício e simulações de partidas sem encurtar as ondas. Capturas exigem um ambiente gráfico. Eventos sintéticos de controle não substituem teste em hardware real.

## Créditos e distribuição

Pixel art: **Bitcrawl Free Roguelike v1**, fornecido em `assets/Bitcrawl_Free_Roguelike_v1`. A licença original está preservada em `Licence.txt`. A licença inclui uma restrição a “AI creations”; o responsável pelo projeto deve esclarecer a autorização com o autor antes de uma publicação deste jogo desenvolvido com assistência de IA. Os assets não devem ser redistribuídos como pacote independente.

Fonte Public Pixel e sons de UI vieram do Starter Kit. O áudio de gameplay é síntese original, reproduzível com `python3 game/audio/generate.py`, sem samples externos. O template não trouxe licença própria; confirme também os direitos de distribuição da base e dos seus assets antes de publicar.

O preset Windows usa `builds/the-last-vigil.exe`. Instale os export templates correspondentes à versão do Godot para gerar o executável. Nenhum upload ou publicação é realizado pelo projeto.
