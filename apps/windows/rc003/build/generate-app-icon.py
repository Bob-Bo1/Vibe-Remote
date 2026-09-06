"""Render the original Remote Mic vector mark into PNG and Windows ICO assets."""
from pathlib import Path
import struct
from PySide6.QtCore import QByteArray, QBuffer, QIODevice, Qt
from PySide6.QtGui import QImage, QPainter
from PySide6.QtSvg import QSvgRenderer

assets=Path(__file__).resolve().parents[1]/'src/ovb_rc003/qml/assets'
assets.mkdir(parents=True,exist_ok=True)
svg='''<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
<defs>
<linearGradient id="blue" x1="0" y1="0" x2=".8" y2="1"><stop stop-color="#67C7FF"/><stop offset=".5" stop-color="#1689F9"/><stop offset="1" stop-color="#0759CF"/></linearGradient>
<linearGradient id="silver" x1="0" y1="0" x2="1" y2=".7"><stop stop-color="#FFFFFF"/><stop offset=".52" stop-color="#F8FBFF"/><stop offset="1" stop-color="#CDDFF2"/></linearGradient>
<linearGradient id="ring" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#4A627C"/><stop offset="1" stop-color="#142A49"/></linearGradient>
</defs>
<rect x="12" y="16" width="488" height="488" rx="114" fill="#0B367B" opacity=".16"/>
<rect x="12" y="8" width="488" height="488" rx="114" fill="url(#blue)"/>
<rect x="14" y="10" width="484" height="484" rx="112" fill="none" stroke="#FFFFFF" stroke-opacity=".3" stroke-width="3"/>
<g transform="rotate(-17 246 263)">
<rect x="171" y="87" width="153" height="352" rx="66" fill="#073D99" opacity=".25"/>
<rect x="158" y="69" width="153" height="352" rx="66" fill="url(#silver)" stroke="#FFFFFF" stroke-width="3"/>
<rect x="216" y="95" width="37" height="7" rx="3.5" fill="#AFBED0"/>
<circle cx="234.5" cy="187" r="52" fill="url(#ring)"/>
<circle cx="234.5" cy="187" r="29" fill="#2E88E4" stroke="#8DD3FF" stroke-width="2"/>
<rect x="194" y="269" width="27" height="46" rx="13.5" fill="#D2DFEB"/>
<rect x="249" y="264" width="27" height="60" rx="13.5" fill="#D2DFEB"/>
<path d="M257 282h11m-5.5-5.5v11m-5.5 22h11" stroke="#486681" stroke-width="3" stroke-linecap="round"/>
<rect x="226" y="343" width="17" height="26" rx="8.5" fill="#1689F9"/>
<path d="M221 361v3a13.5 13.5 0 0 0 27 0v-3m-13.5 17v7m-8 0h16" fill="none" stroke="#1689F9" stroke-width="3.5" stroke-linecap="round"/>
</g>
<g stroke="#FFFFFF" fill="none" stroke-linecap="round"><path d="M360 132q24 24 0 48" stroke-width="13"/><path d="M386 107q49 49 0 98" stroke-width="13" opacity=".75"/></g>
</svg>'''
(assets/'app-icon.svg').write_text(svg,encoding='utf-8')
renderer=QSvgRenderer(QByteArray(svg.encode()))
images=[]
for size in [16,20,24,32,40,48,64,128,256,512]:
    img=QImage(size,size,QImage.Format_ARGB32);img.fill(Qt.transparent)
    painter=QPainter(img);renderer.render(painter);painter.end()
    if size==512: img.save(str(assets/'app-icon.png'))
    if size<=256:
        data=QByteArray();buffer=QBuffer(data);buffer.open(QIODevice.WriteOnly);img.save(buffer,'PNG');buffer.close()
        images.append((size,bytes(data)))
offset=6+16*len(images);header=struct.pack('<HHH',0,1,len(images));body=b''
for size,png in images:
    header+=struct.pack('<BBBBHHII',size%256,size%256,0,0,1,32,len(png),offset)
    body+=png;offset+=len(png)
(assets/'app-icon.ico').write_bytes(header+body)
paths=[
    '<path d="M8 4v7m8-7v7M6 11h12v2a6 6 0 0 1-12 0zm6 8v3"/>',
    '<rect x="6" y="2" width="12" height="20" rx="4"/><circle cx="12" cy="9" r="3"/><path d="M10 16h4m-2 2v-4"/>',
    '<rect x="5" y="10" width="14" height="11" rx="3"/><path d="M8 10V7a4 4 0 0 1 8 0v3m-4 5v2"/>',
    '<circle cx="10" cy="10" r="7"/><path d="m15 15 6 6M7 10l2 2 4-4"/>'
]
for i,path in enumerate(paths):
    for suffix,color in [('', '#55555D'),('-white','#FFFFFF'),('-light','#D8D8DE')]:
        (assets/f'nav-{i}{suffix}.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="{color}" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">{path}</svg>',encoding='utf-8')
print('Generated PNG, SVG, 9-size ICO and navigation icons.')
