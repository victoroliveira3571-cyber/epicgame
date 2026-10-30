import math, sys
# --- dados (espelham Data.gd)
M = {  # hp, dmg, xp, gold_avg
 'slime':(22,6,5,4),'rato':(14,5,4,2.5),'morcego':(12,5,5,3),'cogumelo':(28,7,7,4.5),
 'esqueleto':(42,11,11,7.5),'cranio':(30,12,12,7.5),'espirito':(26,11,12,8.5),'aranha':(34,11,12,7.5),'lagarto':(52,14,15,10),
 'kappa':(58,15,19,13),'cobra':(40,16,18,11.5),'polvo':(66,16,20,13),'reptil':(70,18,22,14.5),'slime_verde':(30,8,7,5.5),
 'chama':(54,20,26,16),'ciclope':(110,24,34,20),'fera':(84,22,30,18),'polvo_vermelho':(90,24,32,19),'demonio':(70,24,33,19)}
BIOME = [['slime','rato','morcego','cogumelo'],['esqueleto','cranio','espirito','aranha','lagarto'],['kappa','cobra','polvo','reptil','slime_verde'],['chama','ciclope','fera','polvo_vermelho','demonio']]
BOSS = [(420,16,160,75),(760,24,300,135),(1150,30,480,195),(1700,38,720,290),(2300,46,1000,385),(2900,54,1300,480)]
CLS = {'cavaleiro':dict(hp=120,atk=12,df=3,hpl=10,atkl=1.6,cd=.36,mult=1.0),
       'assassino':dict(hp=80,atk=16,df=1,hpl=6,atkl=2.2,cd=.26,mult=0.9),
       'mago':dict(hp=70,atk=14,df=0,hpl=5,atkl=2.0,cd=.5,mult=1.0),
       'escudeiro':dict(hp=100,atk=8,df=6,hpl=9,atkl=1.1,cd=.36,mult=1.0)}
WATK=[5,10,17,27,40,58]; DEF=[1+2+2,2+4+3+1,4+7+5+2,6+11+8+3,9+16+12+5,13+23+17+7]; AHP=[4+8+6,8+16+10,14+28+18,22+44+28,34+66+42,50+95+60]
TIER_LV=[1,5,10,18,28,40]; TP=[30,90,260,700,1800,4500]
SET_PRICE=[TP[t]*(1.3+.7+1.2+.9+.6+1.0) for t in range(6)]
def xpn(l): return int(90*l**1.25)
def hs(f): return 1+.22*(f-1)
def ds(f): return 1+.16*(f-1)
def rs(f): return 1+.12*(f-1)
def pool(f):
    b=BIOME[((f-1)//5)%4]; n=min(len(b),2+(f-1)%5); return b[:n]
def player(c,L,tier,ups=0):
    k=CLS[c]; mult=1+.12*ups
    atk=(k['atk']+k['atkl']*(L-1)+WATK[tier]*mult)+2*0  # talentos ignorados no atk
    tal=(L-1)*2  # pontos de talento: dividir em forca/vigor/guarda
    atk+=tal*0.4*2; hp=k['hp']+k['hpl']*(L-1)+AHP[tier]*mult+tal*0.3*14; df=k['df']+DEF[tier]*mult+tal*0.3*1
    return atk,hp,df
def floor_report(c,f,L,tier,ups=0,hit_rate=0.5):
    k=CLS[c]; atk,hp,df=player(c,L,tier,ups)
    dps=atk*1.05/k['cd']*0.75  # taxa de acerto
    red=df/(df+40)
    es=pool(f); n=20+f//2
    avg=lambda i:sum(M[e][i] for e in es)/len(es)
    ehp=avg(0)*hs(f); edmg=avg(1)*ds(f)*(1-red)
    ttk=ehp/dps
    taken=(ttk/1.3)*hit_rate*edmg*1.0   # por inimigo
    # fração de inimigos que lutam sozinhos ~ 60%, o resto em grupo (x1.6)
    per_floor=n*taken*1.25
    xp=n*avg(2)*rs(f); gold=n*avg(3)*rs(f)
    return dict(atk=atk,hp=hp,df=df,dps=dps,ttk=ttk,taken_pct=per_floor/hp*100,per_enemy=taken,xp=xp,gold=gold,n=n)
def boss_report(c,f,L,tier,ups=0):
    k=CLS[c]; atk,hp,df=player(c,L,tier,ups)
    b=BOSS[(f//5-1)%6]; cyc=max(0,(f//5-1)//6); m=1+.35*cyc
    dps=atk*1.05/k['cd']*0.6  # chefe: janelas de abertura
    t=b[0]*m/dps; red=df/(df+40)
    dmg=b[1]*m*(1-red)
    hits=t/2.5*1.2  # um golpe a cada ~2.5s, padrões variados; 1.2 hits por padrão
    return dict(time=t,taken_pct=hits*dmg*1.4/hp*100,hp=hp)
if __name__=='__main__':
    c=sys.argv[1] if len(sys.argv)>1 else 'cavaleiro'
    L=1; xp=0; gold=0; tier=0; ups=0
    print(f"classe {c}")
    print("andar | nv  tier | atk   hp  def | ttk(s) dano/andar% | xp/andar ouro/andar | chefe: tempo s, dano%")
    for f in range(1,31):
        # tier da equipamento: compra o conjunto quando pode e o nível libera
        t_max=max(i for i in range(6) if L>=TIER_LV[i])
        while tier<t_max and gold>=SET_PRICE[tier+1]*0.8:
            gold-=SET_PRICE[tier+1]*0.8; tier+=1
        r=floor_report(c,f,L,tier,ups)
        b=''
        if f%5==0:
            br=boss_report(c,f,L,tier,ups); b=f"{br['time']:.0f}s {br['taken_pct']:.0f}%"
        print(f"{f:5d} | {L:3d}  {tier}  | {r['atk']:5.1f} {r['hp']:5.0f} {r['df']:4.1f} | {r['ttk']:5.2f} {r['taken_pct']:6.0f}%   | {r['xp']:7.0f} {r['gold']:7.0f}  | {b}")
        xp+=r['xp']+(BOSS[(f//5-1)%6][2] if f%5==0 else 0); gold+=r['gold']+(BOSS[(f//5-1)%6][3] if f%5==0 else 0)
        while xp>=xpn(L): xp-=xpn(L); L+=1
