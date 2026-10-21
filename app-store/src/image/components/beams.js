/** @param {{url: string, layout: {cards: Array<object>, wand: {x: number, y: number}}}} options @returns {Promise<string>} */
window.drawBeams = async function ({url, layout}) {
 const canvas = document.createElement('canvas');
 canvas.width = 2560;
 canvas.height = 1600;
 const drawingContext = canvas.getContext('2d');
 const params = {reach: 1, theme: 1};
 const source = new Image();
 source.src = url;
 await source.decode();
 const bases = [source];
 const image = (img, x, y, width, height) => drawingContext.drawImage(img, x, y, width, height);
 const cards = layout.cards;
function geometry(v){return{x:v.ix+v.sx*v.scale,y:v.iy+v.sy*v.scale,w:v.sw*v.scale,h:v.sh*v.scale};}
function restoreCard(v){const c=drawingContext;c.save();c.translate(v.ix,v.iy);c.scale(v.scale,v.scale);c.beginPath();c.roundRect(v.sx-1,v.sy-1,v.sw+2,v.sh+2,41);c.moveTo(v.px-24,v.sy+v.sh-2);c.lineTo(v.px-7,v.py-2);c.quadraticCurveTo(v.px,v.py+4,v.px+7,v.py-2);c.lineTo(v.px+24,v.sy+v.sh-2);c.closePath();c.clip();c.setTransform(1.6,0,0,1.6,0,0);image(bases[params.theme-1],0,0,1600,1000);c.restore();}
function ellipticalGlow(x,y,rx,ry,opacity){const c=drawingContext;c.save();c.translate(x,y);c.scale(rx,ry);const g=c.createRadialGradient(0,0,0,0,0,1);g.addColorStop(0,`rgba(255,232,176,${opacity})`);g.addColorStop(.25,`rgba(237,171,63,${opacity*.82})`);g.addColorStop(.6,`rgba(210,138,49,${opacity*.4})`);g.addColorStop(1,'rgba(208,129,44,0)');c.fillStyle=g;c.fillRect(-1,-1,2,2);c.restore();}
function drawFullBeam(r){
 const c=drawingContext;
 const target={x:r.x+4,y:r.y+r.h*.5};
 const wand=layout.wand;
 const angle=Math.atan2(target.y-wand.y,target.x-wand.x);
 const length=Math.hypot(target.x-wand.x,target.y-wand.y);
 const width=Math.min(14,r.h*.45)*params.reach;
 c.save();c.translate(wand.x,wand.y);c.rotate(angle);
 const g=c.createLinearGradient(0,0,length+8,0);
 g.addColorStop(0,'#ffecc37a');
 g.addColorStop(.12,'#e4ac4a42');
 g.addColorStop(.55,'#e8b2554a');
 g.addColorStop(.88,'#f4ce8580');
 g.addColorStop(1,'#ffebbbc9');
 c.fillStyle=g;c.filter='blur(.9px)';c.beginPath();
 c.moveTo(0,0);c.lineTo(length+10,-width);
 c.quadraticCurveTo(length+17,0,length+10,width);
 c.closePath();c.fill();c.restore();
 ellipticalGlow(target.x,target.y,23,22,.37);
}

 drawingContext.setTransform(1.6, 0, 0, 1.6, 0, 0);
 image(source, 0, 0, 1600, 1000);
 for (const card of cards) {
  drawFullBeam(geometry(card));
  restoreCard(card);
  const r = geometry(card); ellipticalGlow(r.x+4,r.y+r.h*.5,10,13,.32);
 }
 return canvas.toDataURL();
};
