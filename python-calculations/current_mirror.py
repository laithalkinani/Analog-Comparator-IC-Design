import numpy as np 
from model_parameters import model, nmos, pmos


# current mirror in relation to V_DD
# these use NMOS transistors
# the assumption is that W and L of all M in current mirror are the same 
def CM_minWLForSaturation(model: model, VGS, ID, VSB: float = 0) -> float: 
    
    Vov = VGS - model.cal_vth(VSB)

    if Vov <= 0: 
        return float('inf') # impossible for current to conduct in saturation
    
    return (2 * ID) / (model.get_k() * (Vov ** 2) * (1 + model.LAMBDA * VGS)) # this is the min ratio needed

def cal_ISS(model: model, VGS, ID, VSB: float = 0) -> float: 
    
    return 
