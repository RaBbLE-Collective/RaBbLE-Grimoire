import re,sys
txt=re.sub(r'\x1b\[[0-9;]*m','',open(sys.argv[1],errors='replace').read())
for ln in txt.splitlines():
    m=re.search(r'\((\d+)\) rabble_entity: ([\d.]+) fps, render ([\d.]+) \+ ([\d.]+) ms, (\d+) prims \| per frame ms: (.*?) \| (.*)',ln)
    if m:
        st=dict(re.findall(r'(\w+) ([\d.]+)',m.group(6)))
        print("t=%6.1fs fps=%5s render=%5s+%5s prims=%3s ell=%s line=%s ring=%s spr=%s swap=%s sim=%s ui=%s | %s"%(int(m.group(1))/1000,m.group(2),m.group(3),m.group(4),m.group(5),st.get('ellipse'),st.get('line'),st.get('ring'),st.get('sprite'),st.get('swap'),st.get('sim'),st.get('ui'),m.group(7)[:90]))
    elif ln.strip() and 'rabble_entity' not in ln:
        print('    '+ln[:140])
