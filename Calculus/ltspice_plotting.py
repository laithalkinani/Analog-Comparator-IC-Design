import matplotlib.pyplot as plt
from PyLTSpice import RawRead

filepath = 'comparator_design.raw'
LTR = RawRead(filepath)

time = LTR.get_trace('time').get_wave()
v_out = LTR.get_trace('V(vout)').get_wave()
v_in1 = LTR.get_trace('V(vin_1)').get_wave()
v_diff = LTR.get_trace('V(diff_out)').get_wave()
v_cs_out = LTR.get_trace('V(cs_out)').get_wave()

plt.figure(figsize=(12, 6))

plt.plot(time * 1e3, v_out, label='V(vout)', linewidth=1.5)
plt.plot(time * 1e3, v_in1, label='V(vin_1)', linewidth=1.5)
plt.plot(time * 1e3, v_diff, label='V(diff_out)', linewidth=1.5)
plt.plot(time * 1e3, v_cs_out, label='V(cs_out)', linewidth=1.5)

plt.xlim(0, 2)
plt.ylim(-0.3, 3.3)
plt.gca().set_yticks([n/10 for n in range(0, 34, 3)])
plt.xlabel('Time (ms)', fontname='CMU Serif', fontsize=14)
plt.ylabel('Voltage (V)', fontname='CMU Serif', fontsize=14)
plt.title('Comparator Analysis: Transient Response', fontname='CMU Serif', fontsize=18)
plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left', prop={'family': 'serif', 'size': 12})

plt.grid(True, which='both', linestyle=':', alpha=0.6)

plt.tight_layout()
plt.show()