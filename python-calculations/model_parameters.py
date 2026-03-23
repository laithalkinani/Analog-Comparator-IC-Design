import numpy as np

# create a class of MOS with their respective attributes 
# lowk overkill but i don't know how to do this, i was taught only C/C++
class model:
    def __init__(self, LEVEL, VTO, GAMMA, PHI, NSUB, LD, UO, LAMBDA, 
                 TOX, PB, CJ, CJSW, MJ, MJSW, CGDO, JS):
        self.LEVEL = LEVEL
        self.VTO = VTO
        self.GAMMA = GAMMA
        self.PHI = PHI
        self.NSUB = NSUB * 10e-6
        self.LD = LD
        self.UO = UO * 1e-4
        self.LAMBDA = LAMBDA
        self.TOX = TOX
        self.PB = PB
        self.CJ = CJ
        self.CJSW = CJSW
        self.MJ = MJ
        self.MJSW = MJSW
        self.CGDO = CGDO
        self.JS = JS
        self.COX = 3.9 * 8.854187817e-12 / TOX
        self.k = 0.5 * self.UO * self.COX

    def get_k(self) -> float: 
        return self.k
    
    def get_COX(self) -> float: 
        return self.COX
    
    def get_vth(self, VSB: float = 0.0) -> float:
        return self.VTO + self.GAMMA * (np.sqrt(np.abs(VSB + self.PHI)) - np.sqrt(np.abs(self.PHI)))
    

# initialize objects

# NMOS model
nmos= model(
    LEVEL=1, VTO=0.7, GAMMA=0.45, PHI=0.9, NSUB=9e+14, LD=0.08e-6, 
    UO=350, LAMBDA=0.1, TOX=9e-9, PB=0.9, CJ=0.56e-3, 
    CJSW=0.35e-11, MJ=0.45, MJSW=0.2, CGDO=0.4e-9, JS=1.0e-8
)

# PMOS model
pmos= model(
    LEVEL=1, VTO=-0.8, GAMMA=0.4, PHI=0.8, NSUB=5e+14, LD=0.09e-6, 
    UO=100, LAMBDA=0.2, TOX=9e-9, PB=0.9, CJ=0.94e-3, 
    CJSW=0.32e-11, MJ=0.5, MJSW=0.3, CGDO=0.3e-9, JS=0.5e-8
)