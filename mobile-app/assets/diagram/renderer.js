'use strict';

const send = payload => DiagramBridge.postMessage(JSON.stringify(payload));

const SANITIZE_OPTIONS = {
  USE_PROFILES: { svg: true, svgFilters: true },
  FORBID_TAGS: ['script', 'foreignObject', 'iframe', 'object', 'embed'],
  FORBID_ATTR: ['srcdoc'],
};

/** Raster scale for the inline preview; the lightbox uses the vector SVG. */
const RASTER_SCALE = 3;
const RASTER_MAX_EDGE = 4096;

let vizInstance = null;

async function renderMermaid(request) {
  mermaid.initialize({
    startOnLoad: false,
    securityLevel: 'strict',
    htmlLabels: false,
    flowchart: { htmlLabels: false },
    suppressErrorRendering: true,
    theme: request.dark ? 'dark' : 'neutral',
    themeVariables: {
      pie1: '#93c5fd',
      pie2: '#fdba74',
      pie3: '#86efac',
      pie4: '#d8b4fe',
      pie5: '#fda4af',
      pie6: '#67e8f9',
      pie7: '#fde047',
      pie8: '#a5b4fc',
      pie9: '#bef264',
      pie10: '#f9a8d4',
      pie11: '#5eead4',
      pie12: '#cbd5e1',
      pieSectionTextColor: '#111827',
      pieOpacity: '1',
      xyChart: {
        plotColorPalette: request.dark
          ? '#60a5fa,#fbbf24,#34d399,#c084fc,#fb7185,#22d3ee'
          : '#1d4ed8,#b45309,#047857,#7e22ce,#be123c,#0e7490',
      },
    },
  });
  const result = await mermaid.render(`diagram-${request.id}`, request.source);
  return result.svg;
}

async function renderGraphviz(request) {
  if (!window.ParchmentViz) throw new Error('Graphviz engine is unavailable');
  vizInstance ||= await window.ParchmentViz.instance();
  const ink = request.dark ? '#d8d4ce' : '#2b2622';
  const svg = vizInstance.renderSVGElement(request.source, {
    graphAttributes: { bgcolor: 'transparent', fontcolor: ink },
    nodeAttributes: { color: ink, fontcolor: ink },
    edgeAttributes: { color: ink, fontcolor: ink },
  });
  return svg.outerHTML;
}

async function renderDiagram(requestJson) {
  const request = JSON.parse(requestJson);
  try {
    const raw = request.kind === 'graphviz'
      ? await renderGraphviz(request)
      : await renderMermaid(request);
    const svg = DOMPurify.sanitize(raw, SANITIZE_OPTIONS);
    const { png, width, height } = await rasterizeSvg(svg);
    send({ id: request.id, type: 'rendered', svg, png, width, height });
  } catch (error) {
    send({
      id: request.id,
      type: 'error',
      message: String(error && error.message ? error.message : error),
    });
  }
}

/**
 * Gives the SVG explicit pixel dimensions from its viewBox. Mermaid emits
 * `width="100%"`, which an <img> resolves to the 300px default inside the
 * 1×1 renderer WebView and produces a blurry raster.
 */
function withIntrinsicSize(svg) {
  const doc = new DOMParser().parseFromString(svg, 'image/svg+xml');
  const root = doc.documentElement;
  const viewBox = (root.getAttribute('viewBox') || '').trim().split(/[\s,]+/).map(Number);
  if (viewBox.length !== 4 || !(viewBox[2] > 0) || !(viewBox[3] > 0)) return svg;
  root.setAttribute('width', String(viewBox[2]));
  root.setAttribute('height', String(viewBox[3]));
  root.style.removeProperty('max-width');
  return new XMLSerializer().serializeToString(root);
}

/** High-resolution raster of an already sanitized SVG, used for PNG export. */
async function rasterizeDiagram(requestJson) {
  const request = JSON.parse(requestJson);
  try {
    const svg = DOMPurify.sanitize(request.svg, SANITIZE_OPTIONS);
    const { png, width, height } = await rasterizeSvg(svg, request.scale, request.maxEdge);
    send({ id: request.id, type: 'rendered', svg, png, width, height });
  } catch (error) {
    send({
      id: request.id,
      type: 'error',
      message: String(error && error.message ? error.message : error),
    });
  }
}

function rasterizeSvg(svg, rasterScale = RASTER_SCALE, maxEdge = RASTER_MAX_EDGE) {
  return new Promise((resolve, reject) => {
    const blob = new Blob([withIntrinsicSize(svg)], { type: 'image/svg+xml;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const image = new Image();
    image.onload = () => {
      try {
        const width = Math.max(1, image.naturalWidth || image.width || 800);
        const height = Math.max(1, image.naturalHeight || image.height || 450);
        const scale = Math.min(rasterScale, maxEdge / width, maxEdge / height);
        const canvas = document.createElement('canvas');
        canvas.width = Math.max(1, Math.round(width * scale));
        canvas.height = Math.max(1, Math.round(height * scale));
        const context = canvas.getContext('2d');
        context.drawImage(image, 0, 0, canvas.width, canvas.height);
        resolve({ png: canvas.toDataURL('image/png').split(',')[1], width, height });
      } catch (error) {
        reject(error);
      } finally {
        URL.revokeObjectURL(url);
      }
    };
    image.onerror = () => {
      URL.revokeObjectURL(url);
      reject(new Error('Sanitized SVG could not be converted to an image'));
    };
    image.src = url;
  });
}

send({ type: 'ready' });
