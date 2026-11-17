/* ---------------- the live body ---------------- */
var EL=8,ER=4,PL=2,PR=1,HOME=ER|PL;
var FORMS=[['Rest (home)',ER|PL],['Mirror',ER|PR]]; /* draft 5: colour is position-defined, so only the portal arrangement varies */
var WORKING={0:'cold, very sad',3:'odd state',12:'odd state?',15:'angry, alarmed'};
var LABEL={calm:'calm',joy:'joy',sad:'sad',angry:'angry',speaking:'speaking',listening_spread_pocket:'listening (Pocket spread)'};
var HEAD={calm:0,joy:2,sad:-4,angry:0,speaking:0,listening_spread_pocket:0}; /* tilt, alive-backend.js EXPR */
var ORDER=['calm']; /* draft 6: emotional states pruned, to be figured out */
/* proportions in eye widths (section 3.3); off per side [left, right] in eye half-heights */
var PROP={reference:{name:'Rig baseline',eh:3.13,sp:2.11,pw:2.69,fl:0.30,off:null},
          pocket:{name:'Pocket today',eh:2.64,sp:1.95,pw:2.0,fl:0.25,off:[0.86,0.79]},
          baseline:{name:'Rig baseline today',eh:3.13,sp:2.11,pw:2.69,fl:0.30,off:[0.93,0.93]}};
var ENV={eh:[2.5,3.2],sp:[1.9,2.2],pw:[1.9,2.8],fl:[0.22,0.33]};
var W=87,POLE=['#00f5ff','#ff2d78'],GAP=6;
var ZARC=75,DUR_P=1.45,DUR_S=0.8,DUR_B=1.4,portalK=1.0,MINO=0.26; /* portalK: portal distance from the eye centre, in eye half-heights */
var word=HOME,prop='reference',sel='calm',rotMode='spin',elev=17,ortho=false,w={};
ORDER.forEach(function(k){w[k]=k==='calm'?1:0;});
var side=[{pa:null,ea:null},{pa:null,ea:null}],body=null;

function mixHex(a,b,t){var x=parseInt(a.slice(1),16),y=parseInt(b.slice(1),16),c=function(sh){return Math.round(((x>>sh)&255)*(1-t)+((y>>sh)&255)*t);};return '#'+((1<<24)|(c(16)<<16)|(c(8)<<8)|c(0)).toString(16).slice(1);}
/* the YZ plane (x = 0) is a colour volume: cyan to its left, magenta to its right, crossed smoothly, so a part's colour is a function of where it is */
function hslOf(h){var n=parseInt(h.slice(1),16),r=(n>>16)/255,g=((n>>8)&255)/255,b=(n&255)/255,mx=Math.max(r,g,b),mn=Math.min(r,g,b),l=(mx+mn)/2,d=mx-mn,H=0,S=0;
  if(d){S=d/(1-Math.abs(2*l-1));H=mx===r?((g-b)/d)%6:mx===g?(b-r)/d+2:(r-g)/d+4;H*=60;if(H<0)H+=360;}return [H,S,l];}
function hex2(H,S,l){var c=(1-Math.abs(2*l-1))*S,x=c*(1-Math.abs((H/60)%2-1)),m=l-c/2,r,g,b;
  if(H<60){r=c;g=x;b=0;}else if(H<120){r=x;g=c;b=0;}else if(H<180){r=0;g=c;b=x;}else if(H<240){r=0;g=x;b=c;}else if(H<300){r=x;g=0;b=c;}else{r=c;g=0;b=x;}
  var f=function(v){return Math.round((v+m)*255);};return '#'+((1<<24)|(f(r)<<16)|(f(g)<<8)|f(b)).toString(16).slice(1);}
var HC=hslOf('#00f5ff'),HM=hslOf('#ff2d78');
/* hue runs the short way round, cyan through violet to magenta, so the crossing stays saturated instead of going grey */
function volCol(x){var B=96,t=smooth((x+B)/(2*B)),dh=((HM[0]-HC[0]+540)%360)-180;return hex2((HC[0]+dh*t+360)%360,lerp(HC[1],HM[1],t),lerp(HC[2],HM[2],t));}
function bitsOf(sd){return sd===0?{e:EL,p:PL}:{e:ER,p:PR};}
function cl(x){return Math.max(0,Math.min(1,x));}
function smooth(x){x=cl(x);return x*x*(3-2*x);}
function sstep(a,b,x){return smooth((x-a)/(b-a));}
function lerp(a,b,t){return a+(b-a)*t;}
function lerpX(a,b,t){var o={};for(var c in a)o[c]=a[c]+(b[c]-a[c])*t;return o;}
function blendRole(role,part){
  var tot=0,k,acc={dx_in:0,dy:0,rot_m:0,sx:0,sy:0};for(k in w)tot+=w[k];if(tot<1e-3)tot=1;
  for(k in w){var v=POSES[k][role][part];for(var c in acc)acc[c]+=v[c]*w[k]/tot;}
  return acc;
}
function tiltNow(){var t=0,tot=0,k;for(k in w){t+=HEAD[k]*w[k];tot+=w[k];}return tot>1e-3?t/tot:0;}
function blinkAmt(t){var p=t%4.2,b=p<.16?Math.sin(Math.PI*p/.16):0;if(Math.floor(t/4.2)%3===2&&p>=.24&&p<.4)b=Math.sin(Math.PI*(p-.24)/.16);return b;}

/* one side in the body frame (front view). still=true: rest pose only (no float, blink or transitions), for the no-touch check */
function sideGeom(sd,wd,now,t,still){
  var P=PROP[prop],s=sd?1:-1,b=bitsOf(sd),S=still?{}:side[sd];
  var hh=P.eh*W/2,O=portalK*hh,x0=s*P.sp*W/2;
  var up=!!(wd&b.p),fromUp=up,toUp=up,m=1,rec=0;
  var pk=0,zArc=0;
  /* Pocket's withdraw-swap (scene.c:689-714): the portal slides through the eye while the eye pulls into the portal it is leaving, down to 3%, and grows out of the other side. In 3D the two portals also arc past each other in depth, so they never overlap. */
  if(S.pa){fromUp=S.pa.fromUp;toUp=!fromUp;m=smooth(cl((now-S.pa.t0)/DUR_P));var pq=cl(Math.sin(Math.PI*m)*1.6);pk=pq*pq*pq*(pq*(6*pq-15)+10); /* hold the eye fully gone for a moment around the middle */zArc=ZARC*pk*(fromUp?-1:1)*-1;}
  var rF=fromUp?'upper':'lower',rT=toUp?'upper':'lower';
  var ev=lerpX(blendRole(rF,'eye'),blendRole(rT,'eye'),m),pv=lerpX(blendRole(rF,'portal'),blendRole(rT,'portal'),m);
  var uF=fromUp?-1:1,uT=toUp?-1:1,uCur=m<.5?uF:uT;
  var fy=still?0:12*Math.sin(1.05*t);
  var bl=still?0:blinkAmt(t),bs=(1-.95*bl)*(1-pk),ery0=hh*ev.sy,py=lerp(uF*O,uT*O,m)+pv.dy+fy,ey0=ev.dy+fy+lerp(uF,uT,m)*ery0*(1-bs),ery=ery0*bs;
  var hid=0,dnn=2,eyN=ev.dy+fy; /* the cut uses the nominal eye (not the blink or swap squash), and is off while a swap runs */
  if(pk<.001){hid=uCur<0?cl((py-(eyN-ery0))/(2*ery0)):cl(((eyN+ery0)-py)/(2*ery0));dnn=uCur<0?(eyN-py)/ery0:(py-eyN)/ery0;}
  var ey=ey0; /* blink is Pocket's squash toward the portal (scene.c:737), never a screen-space cut, so no view can tear it */
  var bit=!!(wd&b.e),erx=W/2*ev.sx*(1+.18*pk);
  var colF=null;if(S.ea){var fe=cl((now-S.ea.t0)/DUR_S);bit=fe<.5?S.ea.fromBit:!S.ea.fromBit;colF=mixHex(POLE[S.ea.fromBit?1:0],POLE[S.ea.fromBit?0:1],smooth(fe));}
  return {bsq:bs,dn:dnn,hid:hid,uv:lerp(uF,uT,m),s:s,u:uCur,col:colF||POLE[bit?1:0],rec:rec,
    eye:{x:x0-s*ev.dx_in,y:ey,rx:erx,ry:ery,rot:s*ev.rot_m*Math.PI/180},
    por:{x:x0-s*pv.dx_in,y:py,z:zArc,rx:P.pw*W/2*pv.sx,ry:P.pw*W/2*P.fl*pv.sy,rot:s*pv.rot_m*Math.PI/180,sy:pv.sy}};
}

var cv=document.getElementById('cv'),ctx=cv.getContext('2d'),dpr=Math.max(1,window.devicePixelRatio||1);
function size(){var r=cv.getBoundingClientRect();cv.width=Math.round(r.width*dpr);cv.height=Math.round(r.height*dpr);}
window.addEventListener('resize',size);size();

function glowStroke(col,wd){ctx.lineWidth=wd;ctx.strokeStyle=col;ctx.shadowColor=col;ctx.shadowBlur=14;ctx.stroke();ctx.shadowBlur=0;}

/* ---- true 3D: body space (x right, y down, z toward the camera) through yaw, elevation and perspective ---- */
var persp=0; /* 0 at the canonical front view (the 2D reference), full by about 23 degrees */
var CAMD=800; /* stronger perspective: near and far rims differ visibly even at 0 degrees */
function yawRot(x,y,z,yaw){var cy=Math.cos(yaw),sy=Math.sin(yaw);return [x*cy+z*sy,y,-x*sy+z*cy];}
function view(x1,y,z1,e){var ce=Math.cos(e),se=Math.sin(e),Y=y*ce+z1*se,Z=z1*ce-y*se,f=ortho?1:1/(1-persp*Z/CAMD);return {x:x1*f,y:Y*f,z:Z,f:f};}
function cam(x,y,z,yaw,e){var q=yawRot(x,y,z,yaw);return view(q[0],q[1],q[2],e);}
/* an eye is an ellipsoid (tall spherical pill): its silhouette is the ellipse of the projected principal axes */
function covEllipse(a,b,d){ /* principal axes of the screen covariance [[a,b],[b,d]] */
  var m=(a+d)/2,q=Math.sqrt(Math.max(0,((a-d)/2)*((a-d)/2)+b*b));
  return {A:Math.sqrt(Math.max(.25,m+q)),B:Math.sqrt(Math.max(.25,m-q)),ang:0.5*Math.atan2(2*b,a-d)};
}
function eyeEllipse(E,yaw,e){
  var c=cam(E.x,E.y,0,yaw,e),r=E.rot,cr=Math.cos(r),sr=Math.sin(r),rz=E.rx;
  var axes=[[E.rx*cr,E.rx*sr,0],[-E.ry*sr,E.ry*cr,0],[0,0,rz]],a=0,b=0,d=0;
  axes.forEach(function(v){var q=cam(E.x+v[0],E.y+v[1],v[2],yaw,e),r=cam(E.x-v[0],E.y-v[1],-v[2],yaw,e),dx=(q.x-r.x)/2,dy=(q.y-r.y)/2; /* central difference: perspective must not skew the silhouette differently above and below the horizon */
    a+=dx*dx;b+=dx*dy;d+=dy*dy;});
  return {x:c.x,y:c.y,z:c.z,f:c.f,cov:[a,b,d]};
}
/* a portal is a disc (a void) in its own plane; every rim point gets its own perspective, so the near rim is bigger */
function sigAt(P,R,yaw,e,tau){var a=cam(P.x,P.y+R*Math.sin(tau),(P.z||0)+R*Math.cos(tau),yaw,e),b=cam(P.x,P.y-R*Math.sin(tau),(P.z||0)-R*Math.cos(tau),yaw,e);return (a.y-b.y)/(2*R);}
/* Ball (index.html:675-684): each portal tips toward the viewer so it never collapses to an edge-on line. (Seen-from-below for the upper portal needs a sign flip through edge-on, so both are kept seen from above.) */
/* Portal tilt, one rule for both discs: the opening is sin(e + tau), so tau = eps(e) - e makes the opening sin(eps) where eps is an even, smooth floor of the elevation. Never edge-on, no sign flip, and +e and -e show the same portal picture (from below the disc is simply turned over: it is symmetric). Orthographic mode keeps the flat bars. */
var EPS0=.283,EPSK=.16; /* opening at 0 degrees = 0.30, the 2D reference's portal flatten */
function portalTilt(P,uv,yaw,e){if(ortho)return 0;var a=Math.abs(e),eps=(a+EPS0+Math.sqrt((a-EPS0)*(a-EPS0)+EPSK*EPSK))/2;return eps-e;}
function portalRim(P,yaw,e,uv){
  /* the disc is built flat, turned with the face (yaw), and only then tipped toward the viewer about the VIEW's horizontal axis, so the tilt stays put on screen while the face turns */
  var n=72,pts=[],r=P.rot,cr=Math.cos(r),sr=Math.sin(r),R=P.rx,pz=P.z||0,tau=portalTilt(P,uv,yaw,e),st=Math.sin(tau),ct=Math.cos(tau);
  var cw=yawRot(P.x,P.y,pz,yaw),c=view(cw[0],cw[1],cw[2],e);
  /* the sight line to a portal above or below the camera axis already tips its disc toward or away from the viewer; take that out so both portals show the same opening */
  if(!ortho){var dl=Math.atan2(c.y/c.f,CAMD-c.z);tau-=dl*persp;st=Math.sin(tau);ct=Math.cos(tau);}
  for(var i=0;i<n;i++){var a=2*Math.PI*i/n,u=R*Math.cos(a),zz=R*Math.sin(a),l=yawRot(u*cr,u*sr,zz,yaw),y3=l[1]*ct+l[2]*st,z3=-l[1]*st+l[2]*ct,q=view(cw[0]+l[0],cw[1]+y3,cw[2]+z3,e);q.far=q.z<c.z;q.x=c.x+(q.x-c.x)/c.f;q.y=c.y+(q.y-c.y)/c.f;pts.push(q);} /* the disc keeps its own near/far perspective, but is not scaled by its centre's depth: both portals are the same size at every angle */
  return {pts:pts,c:c,R:R,e:e,tau:tau};
}
function liftSide(g,yaw,yawE,e,gp){
  var E=g.eye,ell=eyeEllipse(E,yawE,e),rim=portalRim(g.por,yaw,e,g.uv);
  var cv0=ell.cov,hw=Math.sqrt(cv0[0]),hh=Math.sqrt(cv0[2]); /* screen half-width and half-height of the silhouette */
  var top=sstep(.6,1.2,Math.abs(e)),sx=1,sy=1; /* the Ball: looking down, each eye settles into its ring and shrinks to fit (index.html:693-706); scaled along the screen axes, not the principal axes, so it cannot flip when the silhouette goes round */
  if(top>0||Math.abs(e)>.5){var lo=1e9,hi=-1e9;rim.pts.forEach(function(q){lo=Math.min(lo,q.y);hi=Math.max(hi,q.y);});
    var fit=Math.min(1,.74*(hi-lo)/(2*hh));
    var tf=sstep(.5,1.05,Math.abs(e)); /* shrink a little before the eye has settled, so it never spills over the ring on the way */
    ell.x=lerp(ell.x,rim.c.x,top);ell.y=lerp(ell.y,rim.c.y,top);sy=lerp(1,fit,tf);sx=lerp(1,Math.min(1,fit*1.25),tf);}
  var cutY=cam(E.x,g.por.y,0,yawE,e).y,chord=Math.sqrt(Math.max(0,1-g.dn*g.dn)),cutRx=0,cutRy=0;
  if(g.hid>0&&top>.5)sy*=1-g.hid*top; /* looking down the swallowed part simply shortens the dot */
  if(gp){var v=(g.eye.y-gp.eye.y)/0.03,st=1+Math.min(.22,Math.abs(v)/3500);sy*=Math.sqrt(st);sx/=Math.sqrt(st);} /* stretch along the motion */
  var tv=sstep(.25,1.0,Math.abs(e)),qs=lerp(1,Math.max(.02,g.bsq),tv);sx*=qs;sy*=qs; /* from above the squash is invisible in height, so the whole eye shrinks away instead of popping out */
  var ce=covEllipse(cv0[0]*sx*sx,cv0[1]*sx*sy,cv0[2]*sy*sy);ell.A=ce.A;ell.B=ce.B;ell.ang=ce.ang;
  var dyc=Math.max(-1,Math.min(1,(cutY-ell.y)/Math.max(1,Math.sqrt(cv0[2])*sy)));
  cutRx=Math.sqrt(cv0[0])*sx*Math.sqrt(Math.max(0,1-dyc*dyc))+.6;cutRy=cutRx*Math.max(.2,Math.abs(Math.sin(e)));
  return {hid:g.hid,cut:cutY,cutRx:cutRx,cutRy:cutRy,hide:g.eye.ry<1.2||g.hid>.985||ce.A*ce.B<2,top:top,s:g.s,u:g.u,col:volCol(E.x*Math.cos(yawE)),rec:g.rec,ell:ell,rim:rim,z:rim.c.z};
}
function rgba(col,a){var n=parseInt(col.slice(1),16);return 'rgba('+(n>>16)+','+((n>>8)&255)+','+(n&255)+','+a+')';}
function drawRimHalf(L,far,alpha,wd){
  var P=L.rim.pts,n=P.length,i,idx=[];
  for(i=0;i<n;i++)if(P[i].far===far)idx.push(i);
  if(!idx.length)return;
  /* rotate so the run is contiguous */
  var start=idx[0];if(idx[0]===0&&idx[idx.length-1]===n-1){for(i=1;i<idx.length;i++)if(idx[i]!==idx[i-1]+1){start=idx[i];break;}}
  ctx.beginPath();var k=0,c=idx.length;
  for(k=0;k<c;k++){var q=P[(start+k)%n];if(k)ctx.lineTo(q.x,q.y);else ctx.moveTo(q.x,q.y);}
  var q2=P[(start+c)%n];ctx.lineTo(q2.x,q2.y);
  var mf=L.rim.c.f;ctx.lineWidth=wd*mf;ctx.lineCap='round';ctx.globalAlpha=alpha;ctx.strokeStyle=L.col;ctx.shadowColor=L.col;ctx.shadowBlur=far?6:16;ctx.stroke();
  ctx.shadowBlur=0;ctx.globalAlpha=1;
}
/* the void: black, deepening toward its middle, a faint event-horizon glow inside the rim, and slow dark flow */
function drawVoidBack(L,t,ghost){
  var P=L.rim.pts,c=L.rim.c;
  if(!ghost){
    ctx.beginPath();P.forEach(function(q,i){if(i)ctx.lineTo(q.x,q.y);else ctx.moveTo(q.x,q.y);});ctx.closePath();
    ctx.fillStyle='rgba(0,0,0,.9)';ctx.fill();
  }
  drawRimHalf(L,true,ghost?ghost*.5:lerp(1,.6,persp),lerp(3.2,1.9,persp)); /* far rim dim and fine, near rim bright and thick: the depth cue */
}
var oc=document.createElement('canvas'),octx=oc.getContext('2d');
function drawEnergyEye(L,t,ghost){
  if(L.hide)return;
  if(L.hid>.003&&L.top<.5){
    /* draw the eye alone on a scratch layer, keep only its own side of the portal plane, and let it dissolve into the void along the cross-section dome, so the portal behind shows through (no grey smear) */
    var main=ctx,T=main.getTransform(),E=L.ell,up=L.u<0,RM=Math.max(E.A,E.B)+30,span=Math.max(14,Math.min(60,(RM-30)*.22)),crx=Math.max(1,L.cutRx),cry=Math.max(1,L.cutRy);
    if(oc.width!==cv.width||oc.height!==cv.height){oc.width=cv.width;oc.height=cv.height;}
    octx.setTransform(1,0,0,1,0,0);octx.clearRect(0,0,oc.width,oc.height);octx.setTransform(T);
    ctx=octx;
    drawEyeBody(L,t,ghost);
    if(!ghost){ /* the cut as a smooth field: sd = distance inside the visible shape (the visible half-plane plus the cross-section dome); alpha = smoothstep(sd / span). No clip edges, so no square patches. */
      var Ti=T.inverse(),cs=[[E.x-RM,E.y-RM],[E.x+RM,E.y-RM],[E.x-RM,E.y+RM],[E.x+RM,E.y+RM]].map(function(p){var q=T.transformPoint(new DOMPoint(p[0],p[1]));return [q.x,q.y];});
      var bx=Math.max(0,Math.floor(Math.min(cs[0][0],cs[1][0],cs[2][0],cs[3][0]))),by=Math.max(0,Math.floor(Math.min(cs[0][1],cs[1][1],cs[2][1],cs[3][1])));
      var bx2=Math.min(oc.width,Math.ceil(Math.max(cs[0][0],cs[1][0],cs[2][0],cs[3][0]))),by2=Math.min(oc.height,Math.ceil(Math.max(cs[0][1],cs[1][1],cs[2][1],cs[3][1])));
      if(bx2>bx&&by2>by){var im=octx.getImageData(bx,by,bx2-bx,by2-by),d=im.data,W2=bx2-bx,sg=up?1:-1,Fd=span;
        for(var yy=0;yy<by2-by;yy++)for(var xx=0;xx<W2;xx++){var i=(yy*W2+xx)*4+3;if(!d[i])continue;
          var p=Ti.transformPoint(new DOMPoint(bx+xx+.5,by+yy+.5)),dd=sg*(p.y-L.cut),uu=(p.x-E.x)/crx,h=Math.abs(uu)<1?cry*Math.sqrt(1-uu*uu):0,sd=dd+h,tt=sd/Fd;
          tt=tt<=0?0:tt>=1?1:tt*tt*(3-2*tt);d[i]=d[i]*tt;}
        octx.putImageData(im,bx,by);}}
    ctx=main;
    main.save();main.setTransform(1,0,0,1,0,0);main.drawImage(oc,0,0);main.restore();return;}
  drawEyeBody(L,t,ghost);
}
function drawEyeBody(L,t,ghost){
  var E=L.ell;ctx.save();
  ctx.translate(E.x,E.y);ctx.rotate(E.ang);
  if(ghost){ctx.beginPath();ctx.ellipse(0,0,E.A,E.B,0,0,Math.PI*2);ctx.globalAlpha=ghost;ctx.fillStyle=L.col;ctx.shadowColor=L.col;ctx.shadowBlur=18;ctx.fill();ctx.restore();return;}
  var pulse=.92+.08*Math.sin(t*2.6+L.s*1.7);
  ctx.beginPath();ctx.ellipse(0,0,E.A,E.B,0,0,Math.PI*2);
  ctx.shadowColor=L.col;ctx.shadowBlur=30*pulse*E.f;ctx.fillStyle='#f8faff';ctx.fill();ctx.shadowBlur=0;
  ctx.restore();
  ctx.save();ctx.translate(E.x,E.y);ctx.rotate(E.ang); /* Disney catchlights */
  ctx.beginPath();ctx.ellipse(-E.A*.32,-E.B*.46,E.A*.2,E.B*.12,-.25,0,Math.PI*2);ctx.fillStyle='rgba(255,255,255,.95)';ctx.fill();
  ctx.beginPath();ctx.ellipse(E.A*.26,E.B*.52,E.A*.1,E.B*.05,.3,0,Math.PI*2);ctx.fillStyle='rgba(255,255,255,.55)';ctx.fill();
  ctx.beginPath();ctx.ellipse(0,0,E.A,E.B,0,0,Math.PI*2);ctx.lineWidth=2*E.f;ctx.strokeStyle=L.col;ctx.stroke();
  ctx.restore();
}
/* Two passes: every portal (far to near), then every orb. An orb is never occluded by any portal, its own or the other's: an impossible layering, like the Ball's, that gives the bent-physics look. */
/* One draw order at every angle. Portals first, far to near (well, then its near rim), so a nearer portal hides a farther one; then every orb, so no portal ever covers an orb; then the rig's one exception, clipped to the orb it belongs to: a lower-role eye is drawn *through* its portal, so that portal's near rim is laid back over that eye only. */
function drawScene(Ls,order,t,M,ghost,mid){
  var ra=ghost?ghost*.7:1;
  order.forEach(function(i,k){ctx.setTransform(M);drawVoidBack(Ls[i],t,ghost);ctx.setTransform(M);drawRimHalf(Ls[i],false,ra,lerp(3.2,4.4,persp));if(k===0&&mid){ctx.setTransform(M);mid();}});
  order.forEach(function(i){ctx.setTransform(M);drawEnergyEye(Ls[i],t,ghost);});
  order.forEach(function(i){var L=Ls[i];if(L.u>0&&!L.hide&&!ghost){var E=L.ell;ctx.setTransform(M);ctx.save();ctx.beginPath();ctx.ellipse(E.x,E.y,E.A+1,E.B+1,E.ang,0,Math.PI*2);ctx.clip();drawRimHalf(L,false,ra,lerp(3.2,4.4,persp));ctx.restore();}});
}

/* the infinity flow (Ball index.html:720-806): loops just outside each rim, opening toward the other portal, slung across */
var STREAMS=[{rho:1.06,reach:1.1,wd:3,a:1},{rho:1.25,reach:1.7,wd:2,a:.8},{rho:1.48,reach:2.4,wd:1.4,a:.6}],GAPA=0.75;
function drawInfinity(gs,alpha,t){
  if(alpha<.01)return;
  var L=[gs[0],gs[1]],DIR=[1,-1];
  /* each loop's gap faces the other portal (in the ring's own parameter space), so the figure-eight holds when the rings stack or overlap */
  var phi=L.map(function(g,i){var N=L[1-i];return Math.atan2((N.por.y-g.por.y)/Math.max(1,g.por.ry),(N.por.x-g.por.x)/Math.max(1,g.por.rx));});
  STREAMS.forEach(function(st,si){
    var pts=[];
    var pt=function(i,a){var g=L[i];return [g.por.x+Math.cos(a)*g.por.rx*st.rho,g.por.y+Math.sin(a)*g.por.ry*st.rho];};
    var tn=function(i,a){var g=L[i],x=-Math.sin(a)*g.por.rx*DIR[i],y=Math.cos(a)*g.por.ry*DIR[i],n=Math.hypot(x,y)||1;return [x/n,y/n];};
    var aS=function(i){return phi[i]+DIR[i]*GAPA;},aE=function(i){return phi[i]-DIR[i]*GAPA;};
    [0,1].forEach(function(li){var N=1-li;
      for(var j=0;j<=40;j++){var u=GAPA+(2*Math.PI-2*GAPA)*j/40;pts.push(pt(li,phi[li]+DIR[li]*u));}
      var p0=pt(li,aE(li)),p3=pt(N,aS(N)),t0=tn(li,aE(li)),t3=tn(N,aS(N)),r=Math.min(st.reach*L[li].por.rx*.5,Math.hypot(p3[0]-p0[0],p3[1]-p0[1])*.7);
      var p1=[p0[0]+t0[0]*r,p0[1]+t0[1]*r],p2=[p3[0]-t3[0]*r,p3[1]-t3[1]*r];
      for(var k=1;k<18;k++){var uu=k/18,v=1-uu;pts.push([v*v*v*p0[0]+3*v*v*uu*p1[0]+3*v*uu*uu*p2[0]+uu*uu*uu*p3[0],v*v*v*p0[1]+3*v*v*uu*p1[1]+3*v*uu*uu*p2[1]+uu*uu*uu*p3[1]]);}
    });
    var gr=ctx.createLinearGradient(L[0].por.x,0,L[1].por.x+(L[0].por.x===L[1].por.x?1:0),0);gr.addColorStop(.3,L[0].col);gr.addColorStop(.7,L[1].col);
    ctx.beginPath();pts.forEach(function(p,i){if(i)ctx.lineTo(p[0],p[1]);else ctx.moveTo(p[0],p[1]);});ctx.closePath();
    ctx.globalAlpha=alpha*st.a;ctx.strokeStyle=gr;ctx.lineWidth=st.wd;ctx.setLineDash([16,10]);ctx.lineDashOffset=-t*40*(1+si*.3);ctx.stroke();
    if(si===0){ctx.setLineDash([]);ctx.globalAlpha=alpha*.16;ctx.lineWidth=12;ctx.stroke();}
    ctx.setLineDash([]);ctx.globalAlpha=1;
  });
}

/* no-touch: smallest gap between projected outlines (face units), sampled */
function ellPts(e,n){var o=[],c=Math.cos(e.rot),s=Math.sin(e.rot);for(var i=0;i<n;i++){var a=2*Math.PI*i/n,u=e.rx*Math.cos(a),v=e.ry*Math.sin(a);o.push([e.x+u*c-v*s,e.y+u*s+v*c]);}return o;}
function inEll(p,e){var dx=p[0]-e.x,dy=p[1]-e.y,c=Math.cos(-e.rot),s=Math.sin(-e.rot),u=dx*c-dy*s,v=dx*s+dy*c;return (u/e.rx)*(u/e.rx)+(v/e.ry)*(v/e.ry)<1;}
function gapOf(a,b){var pa=ellPts(a,48),pb=ellPts(b,48),i,j,m=1e9;
  for(i=0;i<48;i++)if(inEll(pa[i],b)||inEll(pb[i],a))return -1;
  for(i=0;i<48;i++)for(j=0;j<48;j++)m=Math.min(m,Math.hypot(pa[i][0]-pb[j][0],pa[i][1]-pb[j][1]));return m;}
var lastKey='',lastTouch='';
/* body space: a portal is a disc in its (tilted) plane, an eye an upright pill */
function spanGap(a0,a1,b0,b1){return Math.max(0,Math.max(a0,b0)-Math.min(a1,b1));}
function ownGap(g){var e=g.eye,p=g.por,yp=p.y+Math.tan(p.rot)*(e.x-p.x),tip=e.y+g.u*e.ry;return g.u*(yp-tip)-Math.abs(Math.sin(p.rot-e.rot))*e.rx;}
function eyePor(g,h){var e=g.eye,p=h.por,dv=spanGap(e.y-e.ry,e.y+e.ry,p.y,p.y),dh=Math.abs(e.x-p.x)-p.rx-e.rx;return dv===0&&dh<0?-1:Math.hypot(Math.max(dh,0),dv);}
function eyeEye(a,b){var dv=spanGap(a.y-a.ry,a.y+a.ry,b.y-b.ry,b.y+b.ry),dh=Math.abs(a.x-b.x)-a.rx-b.rx;return dv===0&&dh<0?-1:Math.hypot(Math.max(dh,0),dv);}
function porPor(a,b){var dh=Math.abs(a.x-b.x)-a.rx-b.rx,dv=Math.abs(a.y-b.y);return dh<0?(dv>3?dv:-1):Math.hypot(dh,dv);}
function noTouch(){
  var key=JSON.stringify([word,prop,sel,portalK,Math.round(w[sel]*20)]);if(key===lastKey)return lastTouch;lastKey=key;
  var g=[sideGeom(0,word,0,0,true),sideGeom(1,word,0,0,true)];
  var rows=[['eye-own portal',Math.min(ownGap(g[0]),ownGap(g[1]))],
    ['eye-other portal',Math.min(eyePor(g[0],g[1]),eyePor(g[1],g[0]))],
    ['eye-eye',eyeEye(g[0].eye,g[1].eye)],['portal-portal',porPor(g[0].por,g[1].por)]];
  lastTouch=rows.map(function(r){var ok=r[1]>=0;return '  '+r[0]+' '+(r[1]<0?'contact':r[1].toFixed(0))+'  '+(ok?'<span class="ok">clear</span>':'<span class="bad">touch</span>');}).join('\n');
  return lastTouch;
}

var last=null,t0=performance.now()/1000;
function bodyState(now){var wd=word,ang=0;
  if(body){var f=(now-body.t0)/DUR_B;
    if(f<1){var th=Math.PI*smooth(Math.max(0,f));if(f<.5){wd=body.from;ang=th;}else{wd=body.to;ang=th-Math.PI;}}else{wd=body.to;}}
  return {wd:wd,ang:ang};
}
function frame(ms){
  var now=ms/1000,t=now-t0,dt=last==null?1/60:Math.min(.1,Math.max(.001,now-last));last=now;
  var k=1-Math.exp(-dt/0.25);for(var x in w)w[x]+=((x===sel?1:0)-w[x])*k;
  side.forEach(function(S){if(S.pa&&now-S.pa.t0>=DUR_P)S.pa=null;if(S.ea&&now-S.ea.t0>=DUR_S)S.ea=null;});
  if(body&&(now-body.t0)/DUR_B>=1){word=body.to;body=null;}
  var st=bodyState(now),wd=st.wd,ang=st.ang;
  var roll=body&&body.kind==='roll'?ang:0,yaw=body&&body.kind==='yaw'?ang:0,yawE=body&&(body.kind==='yaw'||body.kind==='eyes')?ang:0;
  var e=(ortho?0:elev)*Math.PI/180;persp=ortho?0:smooth(Math.min(1,Math.abs(e)/.4));
  var Wd=cv.width,Hd=cv.height,sc=Math.min(Wd/700,Hd/620);
  ctx.setTransform(1,0,0,1,0,0);ctx.clearRect(0,0,Wd,Hd);
  ctx.translate(Wd/2,Hd/2);ctx.scale(sc,sc);ctx.rotate(tiltNow()*Math.PI/180+roll);
  var M=ctx.getTransform();
  var Ls=[0,1].map(function(sd){return liftSide(sideGeom(sd,wd,now,t,false),yaw,yawE,e,sideGeom(sd,wd,now-.03,t-.03,false));});
  var moving=body||side.some(function(S){return S.pa||S.ea;});
  /* far to near; the portal's centre depth decides (the upper portal is nearer from above) */
  var order=Ls[0].z<=Ls[1].z?[0,1]:[1,0];
  if(moving){[3,2,1].forEach(function(gi){var dtp=.05*gi,sd2=bodyState(now-dtp),yg=(body&&body.kind==='yaw')?sd2.ang:0;
    var Lg=[0,1].map(function(i){return liftSide(sideGeom(i,sd2.wd,now-dtp,t-dtp,false),yg,yg,e,null);});
    drawScene(Lg,order,t,M,.13*(4-gi)/3);});}
  var infl=Ls.map(function(L){return {col:L.col,por:{x:L.rim.c.x,y:L.rim.c.y,rx:L.rim.R,ry:L.rim.R*Math.max(.02,Math.abs(Math.sin(e)))}};});
  drawScene(Ls,order,t,M,0,function(){drawInfinity(infl,sstep(.25,.8,Math.abs(e)),t);});
  readout();
  requestAnimationFrame(frame);
}

function bits(v){return [EL,ER,PL,PR].map(function(m){return v&m?'1':'0';}).join('');}
var roEl=document.getElementById('ro');
function readout(){
  var fm=FORMS.filter(function(f){return f[1]===word;})[0],name=fm?fm[0]:'turning';
  var P=PROP[prop];
  var lines=['form <b>'+name+'</b>','no touch at rest (body space, face units):',noTouch(),'proportions: '+P.name];
  [['eh','eye h:w'],['sp','spacing'],['pw','portal width'],['fl','flatten']].forEach(function(r){var v=P[r[0]],en=ENV[r[0]],ok=v>=en[0]&&v<=en[1];
    lines.push('  '+r[1]+' '+v+'  ['+en[0]+'..'+en[1]+'] '+(ok?'<span class="ok">in</span>':'<span class="bad">out</span>'));});
  var hhh=P.eh*W/2;lines.push('  portal Y '+portalK.toFixed(3)+' eye half-heights (gap '+((portalK-1)*hhh).toFixed(0)+' units)');
  document.getElementById('hvv').textContent=portalK.toFixed(2);
  var html=lines.join('\n');if(roEl.innerHTML!==html)roEl.innerHTML=html;
  document.getElementById('elv').textContent=ortho?'orthographic front (0°, no perspective)':(elev<0?'from below ':'')+elev+'° with perspective';
}

/* controls */
function pressed(box,val){[].forEach.call(document.getElementById(box).children,function(b){b.setAttribute('aria-pressed',b.dataset.k===String(val)?'true':'false');});}
function busy(){return !!body||side.some(function(S){return S.pa||S.ea;});}
function nowS(){return performance.now()/1000;}
function flipPortal(sd){var S=side[sd],b=bitsOf(sd);if(body||S.pa||S.ea)return;S.pa={t0:nowS(),fromUp:!!(word&b.p)};word^=b.p;}
function spinEye(sd){var S=side[sd],b=bitsOf(sd);if(body||S.pa||S.ea)return;S.ea={t0:nowS(),fromBit:!!(word&b.e)};word^=b.e;}
function bodyTurn(kind,mask){if(busy())return;body={kind:kind,t0:nowS(),from:word,to:word^mask};}

function goForm(target){if(busy()||word===target)return;bodyTurn('yaw',PL|PR);}
function mk(box,items,on){var el=document.getElementById(box);items.forEach(function(it){var b=document.createElement('button');b.textContent=it[1];b.dataset.k=it[0];b.onclick=function(){on(it[0]);};el.appendChild(b);});}
mk('forms',FORMS.map(function(f){return [String(f[1]),f[0]];}),function(v){goForm(+v);});
document.getElementById('mvP').onclick=function(){if(!busy()){flipPortal(0);flipPortal(1);}};
document.getElementById('mvY').onclick=function(){bodyTurn('yaw',PL|PR);};
document.getElementById('ortho').onclick=function(){ortho=!ortho;this.classList.toggle('on',ortho);};
document.getElementById('elev').oninput=function(ev){elev=+ev.target.value;};
document.getElementById('hover').oninput=function(ev){portalK=+ev.target.value;lastKey='';};
requestAnimationFrame(frame);
})();
