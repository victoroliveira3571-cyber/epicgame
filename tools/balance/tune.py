import sim2, sys
from sim2 import *
def setup(H0,D0,ah,ad,X0=5.5,bhp=6.0,bdm=1.0,pw=1.05):
    sim2.H0=H0; sim2.D0=D0; sim2.X0=X0
    sim2.G_hp=lambda f:1+ah*(f-1)
    sim2.G_dmg=lambda f:1+ad*(f-1)
    sim2.G_rw=lambda f:f**pw
    sim2.BHP=bhp; sim2.BDMG=bdm
def show(cls, hit):
    rows=sim2.run(cls,verbose=False,hit_rate=hit)
    out=[]
    for r in rows:
        if r[0] in (1,3,5,8,10,15,20,25,30):
            out.append(f"f{r[0]}:L{r[1]} ttk{r[6]:.1f} d{r[7]:.0f}% {r[10].replace('boss ','')}")
    print(cls, " | ".join(out))
if __name__=='__main__':
    H0,D0,ah,ad,bhp,bdm=map(float,sys.argv[1:7])
    setup(H0,D0,ah,ad,bhp=bhp,bdm=bdm)
    show('cavaleiro',0.5); show('assassino',0.5); show('mago',0.3); show('escudeiro',0.5)
