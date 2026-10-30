import sys
from sim import *
# curvas candidatas (monstros normalizados pela média do bioma)
H0=34.0; D0=8.0; X0=6.0; G0=4.0
def G_hp(f): return 1+0.17*(f-1)
def G_dmg(f): return 1+0.11*(f-1)
def G_rw(f): return 1+0.16*(f-1)
FOCUS_XP=4.0; FOCUS_GOLD=2.0
def pool_full(f): return BIOME[((f-1)//5)%4]
def mean(f,i):
    es=pool_full(f); return sum(M[e][i] for e in es)/len(es)
def enemy(f,name=None):
    es=pool(f)
    # usa média dos inimigos liberados, relativa à média do bioma inteiro
    hp=sum(M[e][0] for e in es)/len(es)/mean(f,0)*H0*G_hp(f)
    dm=sum(M[e][1] for e in es)/len(es)/mean(f,1)*D0*G_dmg(f)
    xp=sum(M[e][2] for e in es)/len(es)/mean(f,2)*X0*G_rw(f)
    gd=sum(M[e][3] for e in es)/len(es)/mean(f,3)*G0*G_rw(f)
    return hp,dm,xp,gd
BHP=1.0; BDMG=1.0
def run(c,verbose=True,hit_rate=0.5,lvl_bonus_pomos=0):
    L=1;xp=0;gold=0;tier=0
    rows=[]
    for f in range(1,36):
        t_max=max(i for i in range(6) if L>=TIER_LV[i])
        while tier<t_max and gold>=SET_PRICE[tier+1]*0.8:
            gold-=SET_PRICE[tier+1]*0.8; tier+=1
        k=CLS[c]; atk,hp,df=player(c,L,tier)
        dps=atk*1.05/k['cd']*0.75; red=df/(df+40)
        ehp,edm,exp_,egd=enemy(f)
        n=20+f//2
        ttk=ehp/dps
        per=(ttk/1.3)*hit_rate*edm*(1-red)
        pct=n*per*1.25/hp*100
        b=''
        bh=None
        if f%5==0:
            bi=(f//5-1)%6; cyc=max(0,(f//5-1)//6); m=1+.35*cyc
            bhp=BOSS[bi][0]*BHP*m*(1+0.0*f); bdm=BOSS[bi][1]*BDMG*m
            t=bhp/(atk*1.05/k['cd']*0.6)
            dmg=t/3.0*bdm*1.3*(1-red)
            b=f"boss {t:4.0f}s {dmg/hp*100:4.0f}%"
        rows.append((f,L,tier,atk,hp,df,ttk,pct,n*exp_,n*egd,b))
        xp+=n*exp_+(BOSS[(f//5-1)%6][2] if f%5==0 else 0); gold+=n*egd+(BOSS[(f//5-1)%6][3] if f%5==0 else 0)
        while xp>=xpn(L): xp-=xpn(L); L+=1
    if verbose:
        print(f"== {c}")
        print("andar nv t |  atk   hp  def | ttk  dano% | xp   ouro | chefe")
        for r in rows:
            print(f"{r[0]:4d} {r[1]:3d} {r[2]} | {r[3]:5.1f} {r[4]:4.0f} {r[5]:4.1f} | {r[6]:4.2f} {r[7]:5.0f} | {r[8]:5.0f} {r[9]:5.0f} | {r[10]}")
    return rows
if __name__=='__main__':
    for c in sys.argv[1:] or ['cavaleiro']: run(c)
