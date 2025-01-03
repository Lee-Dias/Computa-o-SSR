# Computação SSR

## Autoria

Lee Dias, a22405765;

## [>Repositório Git<](https://github.com/Lee-Dias/Computa-o-SSR.git)

### Descrição

Neste projeto comecei por ver o video (1), (2), (3) e (4) para entender o que era screen space reflection, para ter screen space reflection Primeiro,
procura se a posição e a direção do reflexo do “raio da câmera” que passa pelo pixel.
Isto é simples porque o depth buffer da nos as coordenadas 3D do ponto de reflexão, e o normal buffer fornece a direção do raio refletido, tudo no espaço da câmera.
Usa-se técnicas de ray marching para encontrar a interseção do raio com um "heightmap" fornecido pelo buffer de profundidade, em vez de calcular a interseção desse raio com a geometria real da cena.
Se existir uma interseção, as coordenadas 3D do ponto serão mapeadas de volta às coordenadas 2D do pixel correspondente.
A cor refletida é então obtida consultando o valor desse pixel no color buffer (ou seja, a imagem original ou a versão de um quadro anterior). Durante este processo, as geometrias fora do campo de visão são ignoradas, pois os cálculos são feitos apenas ao que esta na camera.
Por fim para conseguir realmente fazer o código vi o tutorial (5) para entender como fazer tudo para eu mesmo saber que entendi as coisas tentei comentar o máximo de coisas para demonstrar que entendi,
e de forma também a caso eu me esquece-se estava la escrito e depois adicionei coisas ao código para o tentar melhorar,
tal como dynamic step para o step do raymarching ser diferente consoante o tamanho do objeto e também alterei outras coisas olhando para o código (6),
não entendi tudo so de olhar mas do que olhei dele tentei em algumas coisas que vi que era possível implementar no meu código.

Técnicas usadas:

Ray Marching: Técnica para simular a interação do raio com a superfície da cena, e usa depth buffer para buscar interseções.

Depth Buffer: Usa-se para obter a profundidade dos pontos de reflexão e mapear as posições 3D para 2D.

Normal Buffer: Da nos a direção do raio refletido a partir do ponto de reflexão.

Color Buffer: Usa-se para obter as cores refletidas da cena ao consultar o valor de pixels específicos.



As Tecnica usadas mas em codigo  código:

metodo- vert: Calcula os raios de perspetiva da câmara para cada vértice,para depois ser usado no ray marching.

metodo- ComputeViewSpacePosition: Obtém a posição no espaço da câmara a partir das coordenadas UV e do depth buffer.

metodo- ScreenToWorldPos: Converte uma posição no espaço da câmara para o espaço do mundo.

metodo- WorldToScreenPos: Converte uma posição do espaço do mundo para coordenadas UV na tela.

metodo- Vignette: Aplica um efeito de vinheta para escurecer os cantos da imagem.

metodo- hash33: Faz um ruido semi aleatorio para a variação dos reflexos, para simular imperfeições.

metodo- Frag: Implementa o SSR, incluindo ray marching, cálculo de reflexos e mistura da cor final.




(1) - https://www.youtube.com/watch?v=thsWwbFriY8&ab_channel=GlassHandStudios

(2) - https://www.youtube.com/watch?v=a0OQvWAPeuo&ab_channel=Brackeys

(3) - https://www.youtube.com/watch?v=lhELeLnynI8&t=617s&ab_channel=Brackeys

(4) - https://www.reddit.com/r/gamedev/comments/52lawa/what_exactly_are_screenspace_reflections/

(5) - https://www.youtube.com/watch?v=eUYAj0TmHvM&ab_channel=TechnicallyHarry

(6) - https://github.com/JoshuaLim007/Unity-ScreenSpaceReflections-URP/blob/main/Shaders/ssr_shader.shader
