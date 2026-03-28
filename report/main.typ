#import "template.typ": *
#import "@preview/codly:1.3.0": *
#show: codly-init
#import "@preview/codly-languages:0.1.10": *
#codly(languages: codly-languages)
#import "@preview/lovelace:0.3.1": *

// Check for the private compile flag
#let use-private = sys.inputs.at("private", default: "false") == "true"

// Conditionally load the array of authors
#let document-authors = if use-private {
  import "authors.typ": private-authors
  private-authors
} else {
  (
    (
      names: ("[REDACTED AUTHOR 1]",),
      affiliation: "[REDACTED AFFILIATION]",
      email: "[REDACTED EMAIL]",
      student-id: "[REDACTED SID]"
    ),
    (
      names: ("[REDACTED AUTHOR 2]",),
      affiliation: "[REDACTED AFFILIATION]",
      email: "[REDACTED EMAIL]",
      student-id: "[REDACTED SID]"
    ),
  )
}

#show: project.with(
  header_text: [ELEC4440 - Analog Integrated Circuit Design],
  title: [Final Project - Comparator Design],
  authors: document-authors,
  date: auto,
  abstract:[
     This paper presents the design and layout of a high-gain CMOS comparator intended for precision analog-to-digital conversion applications. The comparator architecture consists of a five-transistor operational transconductance amplifier (OTA) with active current-mirror load, followed by a common-source gain stage and a CMOS inverter for rail-to-rail output drive. A systematic design methodology is employed, beginning with hand calculations that establish transistor aspect ratios based on small-signal gain requirements, overdrive voltage constraints, and current mirror relationships. The design targets a differential gain of approximately 67 V/V from the OTA stage while maintaining all devices in saturation with a 3 V supply. Post-layout considerations are addressed in detail, including common-centroid layout techniques to cancel first-order process gradients, multifinger transistor structures to minimize gate resistance and thermal noise, and dummy devices to mitigate shallow trench isolation (STI) stress and well proximity effects. Design rule check (DRC) compliance is verified using MAGIC EDA with a $0.25 mu m$ SCMOS technology file. Simulation results confirm the theoretical gain predictions, but reveal practical limitations: the common-source output stage exhibits clipping to ground during dynamic operation due to the inherently ill-defined bias point of current-source-loaded amplifiers, leading to duty cycle distortion at the final output. This instability is traced to the mismatch between the switching threshold of the CMOS inverter and the DC operating point of the preceding stage. The analysis highlights the gap between idealized hand calculations and real circuit behavior, emphasizing the necessity of feedback stabilization techniques—such as source degeneration—to establish a well-defined output operating point in multistage comparators. The layout strategies discussed provide a foundation for robust comparator implementation in scaled CMOS technologies.
  ],
)


= Theory

The operational transconductance amplifier (OTA) is the beating heart of the comparator, and is a quintessential component of many analog and mixed-signal designs. We break up this design in three large steps: creating the requirements for the OTA (first stage), then the common source amplifier (second stage), then finally the CMOS inverter at the last stage. We focus on tuning the size of the transistors to fit our system requirements.
#figure(
  image("assets/COMPARATOR_CIRCUIT_ORCAD.png", width: 80%),
  caption: [Comparator schematic]
)

== Large-Signal Analysis

We rely heavily on Razavi for this analysis.

$M_1$ and $M_2$ are the NMOS diff pair. $M_3$ and $M_4$ are the PMOS current mirror pair sitting above $M_1$ and $M_2$ - their purpose is to keep the current saturated through $M_1$ and $M_2$, essentially keeping the pair in saturation. How does this work though?

When $V_"in1"$ is more negative than $V_"in2"$, $M_1$ is off, so are $M_3$ and $M_4$ (the diff pair and the PMOS current mirror). Thus, $V_"out"$, sitting at the drain of $M_2$, is zero.

When $V_"in1"$ approaches $V_"in2"$, $M_1$ turns on, drawing a fraction of $I_"ss"$ (the tail current) from $M_3$, which turns $M_4$ on. Here, both $M_4$ and $M_2$ are saturated, providing a high gain.

Finally, when $V_"in1" = V_"in2"$ (DC values), $V_"out" = V_"DD" - |V_"gs3"|$. This is where we want the $V_"out"$ DC operating to sit at, which should roughly be equal to $V_"out" = V_"DD" \/ 2$.

This, of course, assumes perfect symmetry between $M_3$/$M_4$, and between $M_1$/$M_2$. This is an assumption we will have to contend with later on.

The OTA demonstrates "push-pull" action between $M_1$ and $M_2$, each hogging $I_"ss"$, turning off the other side and leading to a single-ended output. At equilibrium, the current through each "half" (since it's not truly symmetrical) of the OTA is equal to $I_"ss" \/ 2$.

The OTA is followed by a common-source (CS) stage amplifier to boost the initial gain, then a CMOS inverter to rail the output up to $V_"DD"$ and down to GND.

On the input side:

We define $V_p$ as the "virtual" voltage at the source of $M_1$ and $M_2$, and the drain of $M_6$ the tail NMOS.

For proper operation:
$ V_"in,cm" >= V_"gs1" + (V_"gs6" - V_"th6") $

The drain voltages of $M_1$ and $M_2$ must be, at minimum:
$ (V_"gs1" - V_"th1") + V_"ds6(min)" $

Essentially, this means the drain voltage of the differential pair must be two overdrive voltages above GND. Intuitively, this makes sense: $V_p$ must be at $V_"ds6(min)"$, and thus that is the "relative ground" to $M_1$ and $M_2$, so their $V_"ds"$ must sit at one overdrive voltage above that!

When designing this amplifier, we have to make sure that all the transistors are in saturation. We make use of current mirrors at $M_5$ and $M_6$ to do so. We have to size the transistors appropriately.

First, we can focus on the OTA and make sure that the $I_"ss"$ tail current is high enough to keep the transistors in operation. We constrain the design, by nature of the OTA, such that $M_1$ and $M_2$ are symmetrical and $M_3$ and $M_4$ are symmetrical. $M_6$ boosts the current of $M_5$. $I_"ref"$ is given as $1 mu A$, $V_"dd"$ is given as 3V. Later on, we will use a diode-connected FET to generate $I_"ref"$ in layout.

== Small-Signal Analysis

Using the lemma $A_v = -G_m R_"out"$:

$ G_m = I_"out" / V_"in" $

$ |I_"d1"| = |I_"d3"| = |I_"d4"| = g_"m1,2" v_"in" $

Where $v_"in"$ is the common mode input to the differential pair.

Thus, $G_m = g_"m1,2"$ since $M_1$ and $M_2$ are symmetrical.

Looking at the small signal model of the OTA, and noting that $r_"o1" = r_"o2"$, we see that:

$ R_"out" = 1/g_"m1" || 2r_"o2" || r_"o4" approx r_"o2" || r_"o4" $

Thus, the approximate gain we will use is:
$ A_v approx g_"m1,2" (r_"o1" || r_"o4") $

The exact gain is:
$ A_v = g_"m1" (r_"o2" || r_"o4") dot (2g_"m4" r_"o4" + 1) / (2(g_"m4" r_"o4" + 1)) $

Where, of course:
$ g_"m1" = sqrt(4K (W\/L)_1 I_d) quad "where" quad I_d = I_"ss"\/2 $

And where:
$ r_"o1" approx 1 / (lambda_n dot I_d) $

== Solving for the Variables

We have some questions that we must progressively answer to design this comparator.

- What is an adequate $I_"ss"$?
- What is an adequate $V_"in,CM"$ to keep $M_1$ and $M_2$ in saturation?
- How high do we want our gain?
- What is our maximum output swing?

We have to do multi-parameter sweeps using software to see what our "options" are, since we have so many variables. Let's define the equations we will use.

$ r_"o1" || r_"o4" = r_"o1" r_"o4" / (r_"o1" + r_"o4") = 1 / (I_d (lambda_n + lambda_p)) = 10 / (3 I_d) $

We define:
$ K_n = 1/2 mu_n C_"ox" = 67.2 times 10^(-6) $
$ K_p = 1/2 mu_p C_"ox" = 19.2 times 10^(-6) $

Then:
$ A_v = sqrt(4 K_n (W\/L)_1 I_d) dot 10 / (3 I_d) $

Where, ignoring channel length modulation (for now!!!):
$ I_d = K_n (W\/L)_1 V_"ov"^2 $

Next, let's make a healthy assumption and fix the overdrive voltage $V_"ov" = V_"gs1" - V_"th1"$ of $M_1$ to 0.1V. This knocks off one of our variables. We can substitute $I_d$ into the gain equation to get:

$ A_v = 2 / (V_"ov" (lambda_n + lambda_p)) $

We get $A_v = 66.67$.

Then, let's use MATLAB to do the multi-parameter sweep and, for that gain, we find $I_d$ and $(W\/L)_1$. So we can see our options of sizing $W\/L$ and the associated drain current.

```matlab
%hand calcs for the comparator

clear; clc;
kn       = 67.2e-6;
lambda_n = 0.1;
lambda_p = 0.2;
Vov      = 0.1;        % fixed overdrive
L        = 180e-9;


Av = 2 / (Vov * (lambda_n + lambda_p));
fprintf('Av = %.4f\n', Av)


wl1 = linspace(1, 1000, 1000);

% Id = kn * (W/L) * Vov^2
Id = kn * wl1 * Vov^2;

% gm = 2*Id/Vov = sqrt(2*kn*(W/L)*Id)
gm = 2 * Id / Vov;


W_nm   = wl1 * L * 1e9;
mask   = mod(W_nm, 180) == 0;
WL_int = wl1(mask);
Id_int = Id(mask);
gm_int = gm(mask);


fprintf('\nW (nm) | W/L  | Id (uA)  | gm (uA/V)\n')
fprintf('------------------------------------------\n')
for i = 1:10   % print first 10 cause that's all we need rly
    fprintf('%6.0f nm | %4.0f | %8.4f uA | %8.4f uA/V\n', ...
        WL_int(i)*180, WL_int(i), Id_int(i)*1e6, gm_int(i)*1e6)
end


figure;
subplot(2,1,1)
plot(wl1, Id*1e6, 'b-', 'LineWidth', 1.5)
xlabel('W/L'); ylabel('I_D (\muA)')
title(sprintf('I_D vs W/L | V_{ov}=0.2V, A_v=%.1f', Av))
grid on; box on;

subplot(2,1,2)
plot(wl1, gm*1e6, 'r-', 'LineWidth', 1.5)
xlabel('W/L'); ylabel('g_m (\muA/V)')
title(sprintf('g_m vs W/L | V_{ov}=0.2V, A_v=%.1f', Av))
grid on; box on;

sgtitle('5T OTA: V_{ov}=0.2V Fixed Design', 'FontSize', 13)
```

Running the script, we see:

```
W (um) | W/L  | Id (uA)  | gm (uA/V)
------------------------------------------
  1620 um |    9 |   6.0480 uA | 120.9600 uA/V
  3240 um |   18 |  12.0960 uA | 241.9200 uA/V
  4860 um |   27 |  18.1440 uA | 362.8800 uA/V
  6480 um |   36 |  24.1920 uA | 483.8400 uA/V
  9720 um |   54 |  36.2880 uA | 725.7600 uA/V
 11340 um |   63 |  42.3360 uA | 846.7200 uA/V
 12960 um |   72 |  48.3840 uA | 967.6800 uA/V
 17820 um |   99 |  66.5280 uA | 1330.5600 uA/V
 19440 um |  108 |  72.5760 uA | 1451.5200 uA/V
 21060 um |  117 |  78.6240 uA | 1572.4800 uA/V
```

Let's select $(W\/L)_1 = (W\/L)_2 = 9$, to get $6.0480 mu A$ as our $I_d$ through $M_1$ and $M_2$, and $I_"ss" = 12.06 mu A$.

Now, since $I_"ss" = ((W\/L)_6 \/ (W\/L)_5) dot I_"ref" approx 12$, so $(W\/L)_6 approx 12 (W\/L)_5$.

Let's fix $(W\/L)_5 = 1$ so $(W\/L)_6 = 12$.

Now, let's find $V_x$ - the input voltage to $M_6$, the voltage at the gate of our tail current mirror - which also biases the NMOS of the CS stage.

$ I_"ss" = K_n (W\/L)_6 (V_x - V_"th")^2 arrow.r V_x = sqrt(I_"ss" \/ (K_n (W\/L)_6)) + 0.7 $

Thus, $V_x = V_"gs6" = 0.8225 "V"$.

$ V_p = V_"ds6" >= V_x - V_"th" arrow.r V_p >= 0.8225 - 0.7 = 0.1225 "V" $
$ V_"gs1" = V_"g1" - V_p arrow.r V_"g1" = 0.9225 "V" $

Or, in other words:
$ V_"in,cm" >= 0.8 + (0.8225 - 0.7) arrow.r V_"in,cm" = V_"g1" >= 0.9225 "V" $

So, let's be safe and pick $V_"in,cm" = 1.2 "V"$.

So far, we have found the aspect ratios for $M_1$, $M_2$, $M_5$, and $M_6$. Now let's find the ratios for the top PMOS current mirrors, $M_3$ and $M_4$.

Remember: we want $V_"out,DC"$ to sit around $V_"DD"\/2$, but it's defined by $V_"out,DC" = V_"DD" - |V_"DS3"|$.

Where $|V_"DS3"| = |V_"SG3"|$ since $M_3$ is diode connected.

Since we know that $I_"d1" = I_"d3"$ is constant, and since we want to force $M_3$ to be in saturation, let's use the formula of $I_"d3"$ and solve for $(W\/L)_3$:

$ (W\/L)_3 = I_D / (K_p dot V_"ov3"^2) $

Let's sweep $V_"ov3"$ from 0.5 to 1.5 ($V_"DD"\/2$) using another MATLAB script.

Again, for simplicity, let's fix $(W\/L)_3 = 1$.

Note: here, I had an idea to sweep $V_"ov"$ and $(W\/L)_3$ to force $V_"out,dc" = 1.5 "V"$. But that returned a $(W\/L)_3$ at $< 1$, at a pretty low $V_"ov"$ as well. $W\/L < 1$ is not physically practical (see: why?). So I chose to just fix $(W\/L)_3$ at the lowest realizable value, which is 1.

Thus:
$ V_"ov"^2 = (V_"SG3" - V_"TH,P")^2 = I_d / (K_p (W\/L)_3) $

Solving for $V_"SG3"$, we get $V_"SG3" = 1.361 "V"$.

Plugging into $V_"out" = V_"DD" - V_"SG3"$, we get:
$ V_"out,DC" = 1.639 "V" $

Which is pretty damn close to $V_"DD"\/2$.

Now, we have finally sized all the transistors in the OTA and bias current mirror. Next, we have to size transistors in the CS stage and the inverter.

== CS Stage

The CS stage is here to increase the output swing of the differential amplifier. We consider $V_y$ to be the output voltage of the CS stage. The input to $M_7$, the PMOS, is $V_"out,DC"$ from the diff pair - we'll hereby call $V_"out,DC"$ as diff_out, and $V_y$ = cs_out.

The questions we have to answer here are:

- What do we want the output bias voltage to sit at?
- How do we then size $M_7$ and $M_8$, the PMOS and NMOS, respectively?

This topology is essentially a CS stage with current source load.

Here, $A_v = -g_"m8" (r_"o8" || r_"o7")$. However, the CS stage is pretty susceptible to channel length modulation. According to Razavi, the output bias voltage of the CS stage with current load is not well-defined without feedback @razavi2016design. the gain is proportional to the drain current, since $r_o prop L\/I_d$. Thus, a longer transistor yields a higher voltage gain. The purpose of the CS stage is to increase swing, so that the inverter in the next stage is appropriately driven.

From Razavi, the intrinsic gain of the CS stage with current source load is given as:

$ g_"m1" r_"o1" = sqrt(K_n (W\/L)_8 I_d) dot 1 / (lambda_n I_d) $ 

Let's consider the maximum output swing levels of the CS stage.

At the very top, $M_7$ is at the edge of saturation at $"CS\_OUT" = V_"DD" - |V_"GS7" - V_"TH,P"|$ and at the bottom swing, $"CS\_OUT" = V_"IN,COUT" - V_"TH,n"$. So CS_OUT is bound by these two levels. We know that $V_"IN,COUT"$ is the $V_x$ level we computed earlier, which is equal to $V_x = 0.8225 "V"$.

Thus, the low level of $"CS\_OUT" = 0.8225 - 0.7 = 0.1225 "V"$.

We want to avoid clipping, so we have to keep both $M_7$ and $M_8$ in saturation, but the CS_OUT level is also unstable without feedback. We also want to keep $L$ fixed for simplicity of layout.

We need to find $V_"GS7"$ to see what CS_OUT might be, despite it being ill-defined.

So, if we know that $0.1225 < "CS\_OUT" < V_"DD" - |V_"SG7" - V_"TH,P"|$, let's just find the average value of those two peaks and that should tell us where CS_OUT should sit at.

Adding up those two values, where $V_"SG7" = 3 - 1.639 "V"$, we get $"CS\_OUT" = 1.28075 "V"$.

We also see that $M_8$ is driven by $V_x$, which is the current mirror output voltage from $M_5$. Which means we can size $M_8$ to provide enough current to put $M_7$ and $M_8$ in saturation, while keeping the output voltage swing level in check.

We see that, since $(W\/L)_5 = 1$, $I_"d8" = (W\/L)_8 dot I_"ref"$.

Knowing that $I_"d7" = I_"d8"$, then:
$ (W\/L)_8 dot I_"ref" = K_p (W\/L)_7 (V_"sg7" - |V_"th,p"|)^2 (1 + lambda_p V_"sd7") $

Where $V_"sg7" = 3 - 1.639 "V"$ and $V_"sd7" = 3 - 1.28 "V"$.

Solving for the ratio, we get:
$ (W\/L)_8 \/ (W\/L)_7 = 8.12 $

So, we have some control here over the aspect ratios.

Now, from the current through $M_8$, we have:
$ I_"d8" = K_n (W\/L)_8 (0.8225 - 0.7)^2 (1 + 0.1(1.28075 - 0.7)) $
$ (W\/L)_8 \/ (W\/L)_7 dot I_"ref" = K_n (W\/L)_8 (0.8225 - 0.7)^2 (1 + 0.1(1.28075 - 0.7)) $

We get $(W\/L)_7 approx 0.93$, so we will push it to 1.

Thus, to keep CS_OUT at 1.28075 V, we get $(W\/L)_8 = 8.12$.

However - in practice - we see significant duty cycle distortion with this aspect ratio of $M_8$. So, by inspection, we reduce it to 6. We will discuss these adjustments to second-order effects in a later section.

== The CMOS Inverter

Here, the idea is that the PMOS at the top ($M_9$) pulls the level up to $V_"DD"$, and the NMOS ($M_10$) pulls it to GND. Therefore, we need the bias of $V_"out"$ as close as possible to 0. $M_10$ acts as a current source pull-up. So, the question here, is how do we size the transistors? We ideally want a high $|A_v|$ around the logic threshold for good noise margins (MIT).

Let's define $V_m$ as the input bias point to the CMOS inverter. We ideally want it at $V_"DD"\/2$, but we actually have $V_m = "cs\_out" = 1.29 "V"$. We define a "drive strength" ratio of $r = sqrt(k_p\/k_n) = 0.53$. Equating the currents of $M_10$ and $M_9$, we get:

$ V_m = (V_"tn" + r(V_"DD" - V_"tp")) / (1 + r) approx 1.233 "V" $

Which matches closely to CS_OUT (the error difference is due to rounding when I calculated $r$).

From this, we further find that:
$ (W\/L)_P = mu_n / mu_p dot (W\/L)_N $

Where $mu_n = 350$ and $mu_p = 100$ (Table 2.1 Razavi) @razavi2016design.

Thus:
$ (W\/L)_P = 3.5 (W\/L)_N $

To keep it as an integer multiple, $(W\/L)_P = (W\/L)_9 = 4$ and $(W\/L)_N = (W\/L)_10 = 1$.

We have now fully sized the transistors.

= Simulation

The simulation results were highly consistent with our hand-calculations.
Of course, this is all dependent on the channel-length being relatively large - we found that decreasing the channel-length to, say, 180 nm caused channel-length modulation effects to kick in drastically.

We built the circuit in both OrCAD and LTSpice to compare results and found that they both matched each other.  

We used a "custom" library for the MOS devices, taken from Table 2.1 @razavi2016design: 

```md
* NMOS model from table 2.1
.MODEL NMOS_LVL1 NMOS(LEVEL=1 VTO=0.7 GAMMA=0.45 PHI=0.9 NSUB=9e+14 LD=0.08e-6 UO=350 LAMBDA=0.1 TOX=9e-9 PB=0.9 CJ=0.56e-3 CJSW=0.35e-11 MJ=0.45 MJSW=0.2 CGDO=0.4e-9 JS=1.0e-8)

* PMOS model from table 2.1 
.MODEL PMOS_LVL1 PMOS(LEVEL=1 VTO=-0.8 GAMMA=0.4 PHI=0.8 NSUB=5e+14 LD=0.09e-6 UO=100 LAMBDA=0.2 TOX=9e-9 PB=0.9 CJ=0.94e-3 CJSW=0.32e-11 MJ=0.5 MJSW=0.3 CGDO=0.3e-9 JS=0.5e-8)

```

We ran a transient simulation and obtained these operating points:

#figure(
  image("assets/COMPARATOR_OPERATING_POINTS.png", width: 80%),
  caption: [DC Operating Points]
)

Note: we left $V_"in2"$ as a DC source in OrCAD for validation. In our LTSpice model we changed $V_"in2"$ to be a sinusoid and we found the same simulation results. I will say that, for the next iteration of this design, we should "push" the limits of our circuit by testing the comparison logic at varying frequencies and amplitudes. We didn't have time to do this, but it would have given some more data to discuss later on when we investigate duty cycle distortion, noise margin, and other higher-order effects. 

== Results

We can see that the comparator logic works as intended. When we zoom in, we can see where the theory faces its limitations: there are significant nonlinearities that produce distortions in our output, that we didn't quite account for in our design. 

#figure(
  image("figures/transient_response_10ms.png", width: 80%),
  caption: [Transient simulation]
)
#figure(
  image("figures/Transient_Response.png", width: 80%),
  caption: [Transient simulation zoomed in to observe the output wave distortion, likely caused by MOSFET nonlinearities]
)


== Next Steps

If we had more time, we would have ran AC signal sweeps to determine noise bandwidth of the signal. Noise analysis is an essential part of any analog circuit design that we completely omitted from this study for brevity. These results would have helped us quantify the noise margin issue that we will later discuss with regards to the common source stage. 

= Layout

We need to decouple layout from the schematic when we consider CMOS design. A lot of the issues that inform layout decisions are straight up ignored in simulation. Here, the schematic is, at best, a suggestion for the physical layout designer to follow. It gives us a floorplan. Beyond that, we're largely on our own. 

#figure(
  image("assets/COMP_LAYOUT_ANNOTATED.jpeg", width: 80%),
  caption: [Transistor layout, annotated]
)

== Substrate Gradient

For the differential pair ($M_1$/$M_2$) and the current mirror pair ($M_3$/$M_4$), maintaining symmetry is critical to minimize input-referred offset and common-mode errors. As discussed in the theory section, we assume perfect matching, but in layout, this must be enforced. Both transistors in each pair are laid out with identical orientation to avoid process-dependent asymmetries. The gate-aligned configuration is preferred over parallel-gate structures to mitigate the effects of gate shadowing during source/drain implantation.

To suppress the effect of linear process gradients across the chip, a common-centroid layout is employed for the critical pairs. $M_1$ and $M_2$ are each split into two halves and placed diagonally opposite each other. Similarly, $M_3$ and $M_4$ are interdigitated. This first-order cancellation of gradients in oxide thickness, doping concentration, and other parameters ensures that the symmetry assumed in hand calculations is preserved in silicon @hastings2018art.

The surrounding environment is also matched. Dummy transistors are placed at the boundaries of the active arrays to ensure that each finger sees identical STI stress and well proximity effects. NMOS dummy fingers are tied to GND and PMOS dummy fingers are tied to VDD to mitigate the phenomenon of charge building up on the poly layer, which may arc to an adjacent finger and damage the silicon. Tying dummy fingers to GND/VDD, respectively, also mitigates the antenna effect (Hastings). Metal lines carrying bias currents or clocks are routed symmetrically with respect to the differential pairs, and where asymmetry is unavoidable, dummy lines are added to balance parasitic coupling.

== Multifinger Folding

The wide transistors in the design, particularly the differential pair and the current mirror devices, are implemented using multifinger structures to reduce both the source/drain junction area and the gate resistance. The gate resistance must be kept sufficiently low to minimize thermal noise, especially given the comparator's role in low-noise applications.

For the differential pair $M_1$/$M_2$, each transistor is folded into multiple fingers. The width of each finger is chosen such that the finger's distributed resistance is less than the inverse transconductance of the finger. With a sheet resistance of the gate polysilicon approximately 30 Ω/□, the number of fingers is selected to ensure the gate thermal noise voltage remains well below the channel thermal noise. Dummy fingers are added at both ends of the array to buffer the active fingers from STI-induced stress, which would otherwise modulate the threshold voltage and carrier mobility @hastings2018art.

The current mirror transistors $M_5$ and $M_6$ are also implemented with multiple fingers to improve matching and reduce noise. The layout follows a unit-cell approach: a minimum-sized finger serves as the unit transistor, and larger devices are constructed by placing multiple unit cells in parallel. This approach allows precise current ratios to be maintained despite process variations.

It's most important that we implement our multi-finger method to the differential pair transistors, $M_1$ and $M_2$. We desperately need these two transistors to have symmetry, lest we incur mismatch issues that we will discuss in more detail later. $M_3$ and $M_4$ also have to be symmetric and are also arranged as multi-fingers, but we will see that the design approach for $M_1$ and $M_2$ is more nuanced.
We arrange the differential pair as two rows of six column fingers in accordance with the common centroid design philosophy. When we look at our differential pair in the layout, we have it arranged in a $A B B A A B$ format, where $A$ and $B$ are transistors $M_1$ and $M_2$ specifically. $M_1$ and $M_2$ are the very wide transistors on the bottom, $M_3$ and $M_4$ are the smaller transistors on the top, in accordance with their size ratios. 

#figure(
  image("figures/DIFF_AMP_LAYOUT.jpeg", width: 50%),
  caption: [Layout zoomed in on the differential pair. Notice the wide gates separated into fingers (the red color) where $M_1$ and $M_2$ are separated into two rows, six columns of multi-fingers. $M_3$ and $M_4$, the PMOS current mirror pair, are connected by drain and shown at the top of the image, also drawn as multi-fingers.]
)



== Design Rule Check

Using MAGIC EDA's default SCMOS DRC file and with $lambda = 0.25 mu m$,we have the following design rule in Table 1 to check parameters that we followed. We also fixed the channel length $L = 5 mu m$ to avoid having to contend with deeper second-order effects. These DRC's were enforced by the MAGIC EDA in our layout process. 

== Input and Output Ports

VDD, GND, $I_"ref"$, $V_1$, and $V_2$ are "ports" to the device. In a production circuit, these ports would be routed to the peripheral of the layout and connected to a wire-bonded package. Moreover, there would be a better method of generating the internal current $I_"ref"$. At the most basic level, we leave current generation to an external circuit and have it as an input to ours. If we want a very stable current reference, we need a circuit in the neighborhood of a bandgap reference generator. More simply, we could use a diode-connected NMOS with the gate to VDD, which would give us an (ideally) constant current. We went with the former option for simplicity's sake. 




#figure(
  caption: [Design rule check parameters for SCMOS technology with $lambda = 0.25 mu m$.],
  table(
    columns: (1fr, 1fr, 1fr),
    align: (left, center, right),
    table.header(
      [Parameter],
      [Rule Value ($lambda$)],
      [Actual (nm)],
    ),
    [*Transistor (Active)*], [],
    [Minimum drain/source width], [3 $lambda$], [375],
    [Minimum drain/source length], [3 $lambda$], [375],
    [*Polysilicon Gate*], [], [],
    [Minimum poly width], [2 $lambda$], [250],
    [Minimum poly spacing], [2 $lambda$], [250],
    [Poly overhang beyond active (gate edge clearance)], [2 $lambda$], [250],
    [Active overhang beyond poly], [3 $lambda$], [375],
    [*Contacts*], [], [],
    [Poly contact width], [4 $lambda$], [500],
    [Diffusion contact width (ndc/pdc)], [4 $lambda$], [500],
    [Substrate contact width (nsc/psc)], [4 $lambda$], [500],
    [*Contact Clearances*], [], [],
    [Contact to diffusion edge (poly contact to diffusion)], [1 $lambda$], [125],
    [Contact to gate (diffusion contact to poly)], [1 $lambda$], [125],
    [Poly contact to diffusion contact spacing], [2 $lambda$], [250],
    [*Metal 1*], [], [],
    [Metal 1 width], [3 $lambda$], [375],
    [Metal 1 spacing], [3 $lambda$], [375],
    [*Metal 2*], [], [],
    [Metal 2 width], [3 $lambda$], [375],
    [Metal 2 spacing], [4 $lambda$], [500],
    [*Via (m2c)*], [], [],
    [Via width], [4 $lambda$], [500],
    [*Well*], [], [],
    [N-well/P-well width], [10 $lambda$], [1250],
    [Well spacing], [9 $lambda$], [1125],
  ),
)


= Discussion

Although addressing second-order effects is mostly beyond the scope of this project, we still investigated several of them. 



== Duty Cycle Distortion and Switching Transients



The ideal duty cycle is always exactly 50%, in accordance with the duty cycle of the input signal (which in our case is a sinusoid).

At its core, duty cycle distortion originates in variations from ON/OFF times in the switching period. 

Essentially, there is rise/fall time asymmetry that, when adding up, causes duty cycle distortion. In noisy systems, duty cycle distortion is amplified when a noisy signal is injected into a lossy channel @cadence2023duty.

In our case, rise/fall time asymmetry is the main culprit of duty cycle distortion. 

There is a threshold mismatch between the switching threshold of the CMOS inverter and the DC operating point of the cs_out stage driving it (which sits around $~$1.2 V). 

The switching threshold of the CMOS inverter should be close to or equal to VDD/2 (1.5 V). So, from our hand calcs, we see that $(W\/L)_8$ is a current mirror to $M_5$, and tries to sink more current than what $M_7$ can provide. When we tried to input $(W\/L)_8 = 8$ as the dimensions of $M_8$, we saw that this caused $M_8$ to sink $9.9 mu A$ peak-peak. This demand exceeds the supply of $M_7$, which causes $M_8$ to enter the triode region and $M_7$ to turn off - which means the operating point cs_out is essentially just pulled low to ground.

But how could we not see this from our hand calculations? 

Well, we know from Chapter 3.3 @razavi2016design that cs_out is not a stable or well-defined operating point. A small change to the current will cause a huge change to the operating point. The range of current that $M_8$ can sink without turning $M_7$ off is very small, and that's why we had to "guess" the width of $M_8$ until we got the sunk current to be around 75% of the peak-peak current from our hand calculations. At this width, $M_8$ sinks just enough current to keep $M_7$ on. However - finding an analytically satisfying solution to the problem of this operating point still evades us. Most likely, the SPICE solver finds an equilibrium point at cs_out = GND that we don't consider in our hand calculations. 

Either way, a bias point within 0.2-0.3 V from $V_(D D)\/2$ biases the CMOS inverter well enough that we see the proper 50% duty cycle. The key point of this discussion, ultimately, is to say that this operating point is not robust and highly susceptible to noise, which will cause the duty cycle to become distorted. 

== Clipping of CS Output and Noise Margin

Clipping of the CS output is a problem related to the previously discussed one on duty cycle distortion. 

In our Theory section we already discussed the "ideal" operating point of cs_out to be in the middle of the two swing extrema,  $V_"x" - V_"th" < "CS_OUT" < V_"DD" - |V_"SG7" - V_"TH,P"|$. 

In our simulation, however, we see that on the low end, cs_out clips to zero (GND). Shouldn't the "lowest" point of its swing be Vin1 - Vth? What is causing it to swing to ground, giving us the clipping that we see in simulation? 

The answer is: when $M_8$ is pulling a high current (on the low end of the swing), $M_7$ turns off. This means that $M_8$ now drops into triode, and the voltage cs_out increasingly starts to "see" ground. Now, there is no "floor" to the cs_out signal.
Remember, cs_out is an amplified and inverted signal of diff_out (since it is a common-source amplifier). When diff_out is high, $V_"SG7"$ shrinks until $V_"SG7" < |V_"THP"|$, thereby turning off entirely. At this point $M_8$ has no load, and thus pulls cs_out to ground.

So, our calculations provided us with a theoretical lower bound to cs_out, but the dynamic condition actually tells us that $M_7$ isn't always active like we assumed it was. How do we fix this? Well, the first solution that comes to mind is to add a source degeneration resistor to $M_8$ - this gives us the "feedback" we need to stabilize cs_out, and helps to improve the linearity of the operating point. With this, we can soften how aggressively $M_8$ pulls its output voltage to ground. In CMOS technology, a degeneration resistor can be implemented by means of a diode-connected NMOS at the source of $M_8$. We could, of course, reduce the OTA gain, but we should never do that. The whole point of the OTA is to amplify a small-signal gain, so we should keep it as reasonably high as possible.

Consequently, having clipping at cs_out causes an asymmetric input into the inverter - leading to our aforementioned duty cycle distortion problem. This will give us the unequal rise/fall times that we see at the inverter output. 

Furthermore, while the cs_out level is saturated, the comparator logic is effectively "blind". If there are any signal contents to resolve during the recovery phase (the transient time when cs_out is climbing back up from gnd or falling down to gnd), the inverter would not know and continue to hold its last known position. This means, effectively, that the resolution of the comparator has been compromised. This means that, for some fraction of the duty cycle, there is 0 noise margin in our circuit. This is not good, and that's why we need to fix the clipping issue in future iterations of this design. 


== Size Mismatch

This is more of a layout problem, but it did define our layout decisions so we will discuss it. 

We have already seen the effects of nonlinearity in our CS stage, causing cs_out to be inherently unstable and requiring some feedback to make it a well-defined operating point. 

Mismatch is another key issue that can really only be resolved in layout. In the Theory section, we assumed perfect symmetry between the OTA pairs: $M_1$=$M_2$, and $M_3$=$M_4$. This allows us to complete our analysis of OTA behavior while ignoring an important factor that does show up in real circuits: threshold voltage variation, $Delta V_"th"$. 

Mismatch is caused by microscopic variations in device dimensions @razavi2016design. Having mismatch between two devices in the OTA can cause, among other things, a DC offset where $V_"out" != 0$ when $V_"in" = 0$.  This reduces the precision of which signals can be measured. It introduces harmonics into the OTA equations related to the dimension mismatches. It also, notably, increases the channel capacitance. 

= Conclusion

This project successfully demonstrated the complete design flow for a CMOS comparator, from hand calculations and schematic capture to layout implementation and simulation verification. The three-stage architecture—consisting of a five-transistor OTA, a common-source gain stage, and a CMOS inverter—achieved the targeted differential gain of approximately 67 V/V while maintaining proper biasing with a 3 V supply. The hand calculations provided a solid foundation for sizing the transistors, with the differential pair $M_1$/$M_2$ sized at $(W/L) = 9$, the tail current mirror at $(W/L)_6 = 12$, and the inverter stage sized with $(W/L)_9 = 4$ and $(W/L)_10 = 1$.

The layout phase revealed critical considerations that schematic simulation alone cannot capture. Common-centroid placement of the differential pair and current mirror effectively cancels first-order process gradients, while multifinger folding of wide transistors reduces gate resistance and mitigates STI-induced stress. Dummy fingers tied to GND and VDD address both STI stress and the antenna effect, ensuring reliability. The DRC verification using MAGIC EDA confirmed compliance with SCMOS rules at $lambda = 0.25 mu m$, with all dimensions scaled to integer multiples of the minimum feature size.

Simulation results validated the comparator's functionality but also exposed practical limitations that hand calculations underestimated. The most significant issue identified is the instability of the common-source output stage's bias point. With $(W/L)_8 = 8$, the stage exhibited severe clipping to ground during dynamic operation, forcing an empirical reduction to $(W/L)_8 = 6$ to maintain reasonable operation. This instability stems from the inherently ill-defined DC operating point of current-source-loaded amplifiers—a phenomenon Razavi notes but one that becomes acutely problematic when driving a subsequent inverter stage. The resulting duty cycle distortion and reduced noise margin during saturation periods represent genuine reliability concerns for high-precision applications.

== Future Work

Several avenues for improvement emerged from this analysis. First and foremost, adding source degeneration to $M_8$—implemented via a diode-connected NMOS at the source—would provide the negative feedback necessary to stabilize cs_out and linearize the stage's transfer characteristic. This modification would directly address the clipping issue while preserving the OTA's high gain.

Second, a more rigorous noise analysis is essential. AC noise simulations would quantify the input-referred noise contributions from each stage and establish the comparator's minimum detectable signal. This analysis would also clarify the noise margin limitations observed during cs_out saturation.

Third, frequency characterization across a range of input amplitudes would reveal the comparator's maximum operating frequency and establish its propagation delay characteristics. Our current transient simulations at a single frequency provide functional verification but insufficient data for performance benchmarking.

Fourth, post-layout parasitic extraction and back-annotation would quantify the impact of layout-induced parasitics on high-frequency performance. The multifinger structures, while beneficial for matching and noise, introduce additional junction capacitance that may limit bandwidth.

Finally, a more robust current reference—perhaps derived from a bandgap core—would eliminate the external $I_"ref"$ dependency and improve the circuit's practicality as a standalone comparator.

The fundamental trade-off between gain and stability remains central to comparator design. Future iterations should explore alternative architectures, such as a folded-cascode OTA or a regenerative latch following the preamplifier, to achieve both high gain and well-defined output swing without the instability observed in this implementation.

#pagebreak()
#bibliography("citations.bib")
