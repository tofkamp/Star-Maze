#!/usr/bin/env python3
"""Independent check of maze2.asm: a small interpreter for the BeebAsm subset used by the source
(ORG, EQUB, EQUW, labels, equates, COPYBLOCK, SAVE, 6502 instructions). It is NOT BeebAsm; it mimics its
addressing mode choice (zero page when the value is < 256) and reports forward references that would
change size between passes. Usage: verify_maze2.py maze2.asm [original_MAZE2_file]"""
import re,sys
# ---- 6502 opcode table (shared with the disassembler) ----
OPS={}
def a(op,m,mode):OPS[op]=(m,mode)
tbl="""00 BRK imp|01 ORA izx|05 ORA zp|06 ASL zp|08 PHP imp|09 ORA imm|0A ASL acc|0D ORA abs|0E ASL abs|10 BPL rel|11 ORA izy|15 ORA zpx|16 ASL zpx|18 CLC imp|19 ORA aby|1D ORA abx|1E ASL abx|20 JSR abs|21 AND izx|24 BIT zp|25 AND zp|26 ROL zp|28 PLP imp|29 AND imm|2A ROL acc|2C BIT abs|2D AND abs|2E ROL abs|30 BMI rel|31 AND izy|35 AND zpx|36 ROL zpx|38 SEC imp|39 AND aby|3D AND abx|3E ROL abx|40 RTI imp|41 EOR izx|45 EOR zp|46 LSR zp|48 PHA imp|49 EOR imm|4A LSR acc|4C JMP abs|4D EOR abs|4E LSR abs|50 BVC rel|51 EOR izy|55 EOR zpx|56 LSR zpx|58 CLI imp|59 EOR aby|5D EOR abx|5E LSR abx|60 RTS imp|61 ADC izx|65 ADC zp|66 ROR zp|68 PLA imp|69 ADC imm|6A ROR acc|6C JMP ind|6D ADC abs|6E ROR abs|70 BVS rel|71 ADC izy|75 ADC zpx|76 ROR zpx|78 SEI imp|79 ADC aby|7D ADC abx|7E ROR abx|81 STA izx|84 STY zp|85 STA zp|86 STX zp|88 DEY imp|8A TXA imp|8C STY abs|8D STA abs|8E STX abs|90 BCC rel|91 STA izy|94 STY zpx|95 STA zpx|96 STX zpy|98 TYA imp|99 STA aby|9A TXS imp|9D STA abx|A0 LDY imm|A1 LDA izx|A2 LDX imm|A4 LDY zp|A5 LDA zp|A6 LDX zp|A8 TAY imp|A9 LDA imm|AA TAX imp|AC LDY abs|AD LDA abs|AE LDX abs|B0 BCS rel|B1 LDA izy|B4 LDY zpx|B5 LDA zpx|B6 LDX zpy|B8 CLV imp|B9 LDA aby|BA TSX imp|BC LDY abx|BD LDA abx|BE LDX aby|C0 CPY imm|C1 CMP izx|C4 CPY zp|C5 CMP zp|C6 DEC zp|C8 INY imp|C9 CMP imm|CA DEX imp|CC CPY abs|CD CMP abs|CE DEC abs|D0 BNE rel|D1 CMP izy|D5 CMP zpx|D6 DEC zpx|D8 CLD imp|D9 CMP aby|DD CMP abx|DE DEC abx|E0 CPX imm|E1 SBC izx|E4 CPX zp|E5 SBC zp|E6 INC zp|E8 INX imp|E9 SBC imm|EA NOP imp|EC CPX abs|ED SBC abs|EE INC abs|F0 BEQ rel|F1 SBC izy|F5 SBC zpx|F6 INC zpx|F8 SED imp|F9 SBC aby|FD SBC abx|FE INC abx"""
for t in tbl.split('|'):
    o,m,md=t.split(); OPS[int(o,16)]=(m,md)
LEN={'imp':1,'acc':1,'imm':2,'zp':2,'zpx':2,'zpy':2,'izx':2,'izy':2,'rel':2,'abs':3,'abx':3,'aby':3,'ind':3}
def dis(mem,pc,end,base=None):
    out=[]
    while pc<end:
        op=mem[pc]
        if op not in OPS: out.append((pc,[op],'.byte $%02X'%op)); pc+=1; continue
        m,md=OPS[op]; n=LEN[md]; b=list(mem[pc:pc+n])
        v=b[1] if n==2 else (b[1]|b[2]<<8 if n==3 else 0)
        s={'imp':'','acc':' A','imm':' #$%02X'%v,'zp':' $%02X'%v,'zpx':' $%02X,X'%v,'zpy':' $%02X,Y'%v,'izx':' ($%02X,X)'%v,'izy':' ($%02X),Y'%v,'abs':' $%04X'%v,'abx':' $%04X,X'%v,'aby':' $%04X,Y'%v,'ind':' ($%04X)'%v}.get(md)
        if md=='rel':
            t=(pc+2+(v-256 if v>127 else v))&0xFFFF; s=' $%04X'%t
        out.append((pc,b,m+s)); pc+=n
    return out

INV={}
for op,(m,md) in OPS.items(): INV[(m,md)]=op
BRANCH={'BPL','BMI','BVC','BVS','BCC','BCS','BNE','BEQ'}
def strip_comment(s):
    for i,ch in enumerate(s):
        if ch in ';\\': return s[:i]
    return s
def evaluate(e,sym):
    e=e.strip()
    e=re.sub(r'&([0-9A-Fa-f]+)',lambda m:str(int(m.group(1),16)),e)
    def rep(m):
        n=m.group(0)
        if n in sym: return str(sym[n])
        raise KeyError(n)
    e=re.sub(r'[A-Za-z_]\w*',rep,e)
    return eval(e,{'__builtins__':{}})
def run(path,passn,sym,mem,files,warn):
    pc=0; newsym={}
    for lineno,raw in enumerate(open(path),1):
        s=strip_comment(raw).strip()
        if not s: continue
        for stmt in [x.strip() for x in s.split(':') if x.strip()]:
            m=re.match(r'^\.(\w+)$',stmt)
            if m: newsym[m.group(1)]=pc; sym[m.group(1)]=pc; continue
            m=re.match(r'^(\w+)\s*=\s*(.+)$',stmt)
            if m and m.group(1).upper() not in ('ORG',) :
                newsym[m.group(1)]=evaluate(m.group(2),sym); sym[m.group(1)]=newsym[m.group(1)]; continue
            parts=stmt.split(None,1); mn=parts[0].upper(); arg=parts[1] if len(parts)>1 else ''
            def ev(x):
                try: return evaluate(x,sym)
                except KeyError:
                    if passn==2: raise
                    return 0x1000
            if mn=='ORG': pc=ev(arg); continue
            if mn=='EQUB':
                for x in arg.split(','): mem[pc]=ev(x)&255; pc+=1
                continue
            if mn=='EQUW':
                for x in arg.split(','): v=ev(x); mem[pc]=v&255; mem[pc+1]=v>>8; pc+=2
                continue
            if mn=='COPYBLOCK':
                a,b,c=[ev(x) for x in arg.split(',')]
                if passn==2: mem[c:c+(b-a)]=mem[a:b]
                continue
            if mn=='SAVE':
                m2=re.match(r'^"([^"]+)"\s*,(.*)$',arg); a,b,ex,rl=[ev(x) for x in m2.group(2).split(',')]
                if passn==2: files[m2.group(1)]=(bytes(mem[a:b]),rl,ex)
                continue
            if mn in ('GUARD','CLEAR'): continue
            # instruction
            op=arg.strip(); known=True
            if mn in BRANCH:
                t=ev(op); off=t-(pc+2)
                if passn==2 and not -128<=off<=127: raise SystemExit('branch out of range line %d'%lineno)
                mem[pc]=INV[(mn,'rel')]; mem[pc+1]=off&255; pc+=2; continue
            if op=='' : mode='imp'; v=0
            elif op.upper()=='A': mode='acc'; v=0
            elif op.startswith('#'): mode='imm'; v=ev(op[1:])
            elif re.match(r'^\((.+),\s*X\)$',op,re.I): mode='izx'; v=ev(re.match(r'^\((.+),\s*X\)$',op,re.I).group(1))
            elif re.match(r'^\((.+)\),\s*Y$',op,re.I): mode='izy'; v=ev(re.match(r'^\((.+)\),\s*Y$',op,re.I).group(1))
            elif re.match(r'^\((.+)\)$',op): mode='ind'; v=ev(op[1:-1])
            else:
                idx=''
                mm=re.match(r'^(.+),\s*([XY])$',op,re.I)
                if mm: op,idx=mm.group(1),mm.group(2).upper()
                v=ev(op)
                zp={'':'zp','X':'zpx','Y':'zpy'}[idx]; ab={'':'abs','X':'abx','Y':'aby'}[idx]
                undefined_fwd = False
                mode = zp if (v<256 and (mn,zp) in INV) else ab
            if (mn,mode) not in INV: raise SystemExit('bad instruction line %d: %s'%(lineno,stmt))
            mem[pc]=INV[(mn,mode)]; n=LEN[mode]
            if n==2: mem[pc+1]=v&255
            elif n==3: mem[pc+1]=v&255; mem[pc+2]=(v>>8)&255
            if passn==1: warn[(lineno)]=n
            elif warn.get(lineno,n)!=n: raise SystemExit('size changed between passes at line %d: %s (forward reference below 256?)'%(lineno,stmt))
            pc+=n
    return newsym
def build(path):
    sym={}; warn={}; files={}
    mem=bytearray(65536)
    run(path,1,sym,mem,files,warn)
    mem=bytearray(65536)
    run(path,2,sym,mem,files,warn)
    return files,sym
if __name__=='__main__':
    files,sym=build(sys.argv[1])
    for n,(data,load,ex) in files.items():
        print('%s: %d bytes (&%04X), load &%04X exec &%04X'%(n,len(data),len(data),load,ex))
        if len(sys.argv)>2:
            orig=open(sys.argv[2],'rb').read()
            if orig==data: print('IDENTICAL to',sys.argv[2])
            else:
                diff=[i for i in range(min(len(orig),len(data))) if orig[i]!=data[i]]
                print('DIFFERENT: lengths',len(orig),len(data),'first diffs at',[hex(0x2500+i) for i in diff[:10]],'count',len(diff))
