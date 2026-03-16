import numpy as np 
import matplotlib.pyplot as plt
from model_parameters import model, nmos, pmos


# current mirror in relation to V_DD
# these use NMOS transistors
# the assumption is that W and L of all M in current mirror are the same 
def CM_minWLForSaturation(model: model, VGS, ID, L: float = 5e-6, VSB: float = 0) -> float: 
    
    Vov = VGS - model.get_vth(VSB)

    if Vov <= 0: 
        return float('inf') # impossible for current to conduct in saturation
    
    return (ID * L) / (model.get_k() * (Vov ** 2) * (1 + model.LAMBDA * VGS)) # this is the min ratio needed

def W_for_vov(model: model, Vov, Iref: float = 10e-6, L: float = 5e-6) -> float: 

    W = (Iref * L) / ((Vov ** 2) * model.k * (1 + model.LAMBDA * (Vov + model.get_vth())))
    return W 

def tail_current_ro(model: model, ID) -> float:
    # assumption: body of transistor is tied to ground
    return 1 / (model.LAMBDA * ID)

def V_D1_min(model: model, tail_current, WL_ratio: float = 1) -> float:

    return np.sqrt(tail_current / model.get_k() * WL_ratio)

def Gm_gain(model: model, tail_current, WL_ratio) -> float: 
    beta = 2 * model.get_k() * WL_ratio
    # gm = sqrt(beta * I_tail)
    return np.sqrt(beta * tail_current)

def GM_gain_sweep(n_model: model, p_model: model, tail_current, WL_ratio, points, step): 
    results_gm = []
    results_gain = []
    results_WL = []
    current_WL = WL_ratio

    for i in range(points): 
        results_WL.append(current_WL)
        gm = Gm_gain(n_model, tail_current, current_WL)
        gain = cal_gain(n_model, p_model, gm, tail_current)
        results_gm.append(gm)
        results_gain.append(gain)
        
        current_WL += step
        
    return results_gm, results_gain, results_WL

def graph_results(results_gm, results_gain, results_wl):
    # Top subplot for Transconductance
    plt.figure()
    plt.plot(results_wl, results_gm)
    plt.grid(True)
    plt.ylabel('$g_m$ (S)')
    plt.xlabel(r'$\left ( \frac{W}{L} \right )$ Ratio')
    plt.savefig('ro_sweep.png')

    # Bottom subplot for Voltage Gain in dB
    plt.figure()
    plt.subplot(2,1,1)
    plt.plot(results_wl, results_gain)
    plt.grid(True)
    plt.xlabel('$A_v$')
    plt.xlabel(r'$\left ( \frac{W}{L} \right )$ Ratio')

    gain_arr = np.array(results_gain)
    gain_db = 20 * np.log10(np.abs(gain_arr))

    plt.subplot(2, 1, 2)
    plt.plot(results_wl, gain_db)
    plt.grid(True)
    plt.ylabel('Gain (dB)')
    plt.xlabel(r'$\left ( \frac{W}{L} \right )$ Ratio')

    plt.tight_layout()
    plt.savefig('sweep_results.png')

def cal_gain(n_model: model, p_model: model, gm_n, tail_current): 

    ID = tail_current / 2
    ro_n = 1 / (n_model.LAMBDA * ID)
    ro_p = 1 / (p_model.LAMBDA * ID)
    
    # rout is (r_o,n || r_o,p)
    rout = (ro_n * ro_p) / (ro_n + ro_p)
    return gm_n * rout

