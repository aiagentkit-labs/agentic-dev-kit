import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@12.2.0/dist/mermaid.esm.min.mjs';

const STEP_MS = 1100;
const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

// Jekyll (kramdown) wraps a mermaid fence in div.language-mermaid; other renderers emit pre > code.language-mermaid.
const sources = document.querySelectorAll('div.language-mermaid, pre > code.language-mermaid');
const diagrams = [];
for (const source of sources) {
  const host = source.matches('code') ? source.parentElement : source;
  const figure = document.createElement('figure');
  figure.className = 'diagram';
  const graph = document.createElement('div');
  graph.className = 'mermaid';
  graph.textContent = source.textContent;
  figure.append(graph);
  host.replaceWith(figure);
  diagrams.push(figure);
}

mermaid.initialize({ startOnLoad: false, securityLevel: 'strict' });
await mermaid.run({ nodes: diagrams.map((figure) => figure.querySelector('.mermaid')) });

if (!reduceMotion) diagrams.forEach(animate);

// Walk the arrows in the order the diagram defines them, so the reader can follow the flow.
function animate(figure) {
  const svg = figure.querySelector('svg');
  if (!svg) return;
  const edges = [...new Set(svg.querySelectorAll('path.flowchart-link, .edgePaths path'))];
  if (edges.length === 0) return;

  let index = 0;
  let timer = null;
  const step = () => {
    edges.forEach((edge) => edge.classList.remove('adk-active'));
    edges[index].classList.add('adk-active');
    index = (index + 1) % edges.length;
  };
  const play = () => {
    step();
    timer = setInterval(step, STEP_MS);
    button.textContent = 'Pause animation';
    button.setAttribute('aria-pressed', 'false');
  };
  const pause = () => {
    clearInterval(timer);
    timer = null;
    button.textContent = 'Play animation';
    button.setAttribute('aria-pressed', 'true');
  };

  const button = document.createElement('button');
  button.type = 'button';
  button.className = 'diagram-toggle';
  button.addEventListener('click', () => (timer ? pause() : play()));
  figure.append(button);
  play();
}
