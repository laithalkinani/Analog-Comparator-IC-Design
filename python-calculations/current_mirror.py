import numpy as np 
from model_parameters import MOSModel, nmos_lvl1, pmos_lvl1


# current mirror in relation to V_DD
# these use NMOS transistors
# the assumption is that W and L of all M in current mirror are the same 
def CM_minWLForSaturation(model: MOSModel, VGS, ID, VSB: float = 0) -> float: 
    
    Vov = VGS - model.cal_vth(model, VSB)

    if Vov >= 0: 
        return float('inf') # impossible for current to conduct in saturation
    
    return ID / (MOSmodel.k) * (Vov ** 2) * (1 + MOSmodel.LAMBDA * VGS) # this is the min ratio needed

