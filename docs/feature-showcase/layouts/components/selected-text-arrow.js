/** @param {SVGElement} guide @returns {void} */
function drawSelectedTextArrow(guide) {
  const scale = Math.hypot(25.6, 28.16) / 100;
  const angle = .833 * 180 / Math.PI;
  guide.innerHTML = `
    <defs>
      <linearGradient id="arrow-gold" x1="0" y1="0" x2="100" y2="0" gradientUnits="userSpaceOnUse">
        <stop stop-color="#e8b255" stop-opacity=".0314"/>
        <stop offset=".25" stop-color="#ba842f" stop-opacity=".6667"/>
        <stop offset=".7" stop-color="#e8b255"/>
        <stop offset="1" stop-color="#bc8224"/>
      </linearGradient>
      <filter id="arrow-glow" x="-60%" y="-300%" width="220%" height="700%">
        <feDropShadow dx="0" dy="0" stdDeviation="10.51" flood-color="#efc26c"/>
      </filter>
    </defs>
    <g transform="translate(${guide.dataset.x} ${guide.dataset.y}) rotate(${angle}) scale(${scale})">
      <path d="M0 -.3 L71 -3.4 L65 -11 L100 0 L65 11 L71 3.4 Z"
        fill="url(#arrow-gold)" filter="url(#arrow-glow)"/>
      <path d="M23 0 L91 0" fill="none" stroke="#ffeac0" stroke-width="1.35"/>
      <path d="M65 -11 L100 0 L65 11" fill="none" stroke="#ce9943" stroke-width="1.1"/>
    </g>`;
}

document.querySelectorAll('svg.guide').forEach(drawSelectedTextArrow);
