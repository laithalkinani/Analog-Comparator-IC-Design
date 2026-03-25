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
    placeholder text
  ],
)

= Theory

The operational transconductance amplifier (OTA hereinafter) is the beating heart of the comparator, and is a quintessential component of many analog and mixed-signal designs.

== Large-Signal Analysis

Taken from 5.3.1-Razavi.

M1 and M2 are the NMOS diff pair. M3 and M4 are the PMOS current mirror pair sitting above M1 and M2 - their purpose is to keep the current saturated through M1 and M2, essentially keeping the pair in saturation. How does this work though?

When $V_"in1"$ is more negative than $V_"in2"$, M1 is off, so are M3 and M4 (the diff pair and the PMOS current mirror). Thus, $V_"out"$, sitting at the drain of M2, is zero.

When $V_"in1"$ approaches $V_"in2"$, M1 turns on, drawing a fraction of $I_"ss"$ (the tail current) from M3, which turns M4 on. Here, both M4 and M2 are saturated, providing a high gain.

Finally, when $V_"in1" = V_"in2"$ (DC values), $V_"out" = V_"DD" - |V_"gs3"|$. This is where we want the $V_"out"$ DC operating to sit at, which should roughly be equal to $V_"out" = V_"DD" \/ 2$.

This, of course, assumes perfect symmetry between M3/M4, and between M1/M2. This is an assumption we will have to contend with later on.

The OTA demonstrates "push-pull" action between M1 and M2, each hogging $I_"ss"$, turning off the other side and leading to a single-ended output. At equilibrium, the current through each "half" (since it's not truly symmetrical) of the OTA is equal to $I_"ss" \/ 2$.

The OTA is followed by a common-source (CS) stage amplifier to boost the initial gain, then a CMOS inverter to rail the output up to $V_"DD"$ and down to GND.

On the input side:

We define $V_p$ as the "virtual" voltage at the source of M1 and M2, and the drain of M6 the tail NMOS.

For proper operation:
$ V_"in,cm" >= V_"gs1" + (V_"gs6" - V_"th6") $

The drain voltages of M1 and M2 must be, at minimum:
$ (V_"gs1" - V_"th1") + V_"ds6(min)" $

Essentially, this means the drain voltage of the differential pair must be two overdrive voltages above GND. Intuitively, this makes sense: $V_p$ must be at $V_"ds6(min)"$, and thus that is the "relative ground" to M1 and M2, so their $V_"ds"$ must sit at one overdrive voltage above that!

When designing this amplifier, we have to make sure that all the transistors are in saturation. We make use of current mirrors at M5 and M6 to do so. We have to size the transistors appropriately.

First, we can focus on the OTA and make sure that the $I_"ss"$ tail current is high enough to keep the transistors in operation. We constrain the design, by nature of the OTA, such that M1 and M2 are symmetrical and M3 and M4 are symmetrical. M6 boosts the current of M5. $I_"ref"$ is given as $1 mu A$, $V_"dd"$ is given as 3V. Later on, we will use a diode-connected FET to generate $I_"ref"$ in layout.

== Small-Signal Analysis

Using the lemma $A_v = -G_m R_"out"$:

$ G_m = I_"out" / V_"in" $

$ |I_"d1"| = |I_"d3"| = |I_"d4"| = g_"m1,2" v_"in" $

Where $v_"in"$ is the common mode input to the differential pair.

Thus, $G_m = g_"m1,2"$ since M1 and M2 are symmetrical.

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
- What is an adequate $V_"in,CM"$ to keep M1 and M2 in saturation?
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

Next, let's make a healthy assumption and fix the overdrive voltage $V_"ov" = V_"gs1" - V_"th1"$ of M1 to 0.1V. This knocks off one of our variables. We can substitute $I_d$ into the gain equation to get:

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

Let's select $(W\/L)_1 = (W\/L)_2 = 9$, to get $6.0480 mu A$ as our $I_d$ through M1 and M2, and $I_"ss" = 12.06 mu A$.

Now, since $I_"ss" = ((W\/L)_6 \/ (W\/L)_5) dot I_"ref" approx 12$, so $(W\/L)_6 approx 12 (W\/L)_5$.

Let's fix $(W\/L)_5 = 1$ so $(W\/L)_6 = 12$.

Now, let's find $V_x$ - the input voltage to M6, the voltage at the gate of our tail current mirror - which also biases the NMOS of the CS stage.

$ I_"ss" = K_n (W\/L)_6 (V_x - V_"th")^2 arrow.r V_x = sqrt(I_"ss" \/ (K_n (W\/L)_6)) + 0.7 $

Thus, $V_x = V_"gs6" = 0.8225 "V"$.

$ V_p = V_"ds6" >= V_x - V_"th" arrow.r V_p >= 0.8225 - 0.7 = 0.1225 "V" $
$ V_"gs1" = V_"g1" - V_p arrow.r V_"g1" = 0.9225 "V" $

Or, in other words:
$ V_"in,cm" >= 0.8 + (0.8225 - 0.7) arrow.r V_"in,cm" = V_"g1" >= 0.9225 "V" $

So, let's be safe and pick $V_"in,cm" = 1.2 "V"$.

So far, we have found the aspect ratios for M1, M2, M5, and M6. Now let's find the ratios for the top PMOS current mirrors, M3 and M4.

Remember: we want $V_"out,DC"$ to sit around $V_"DD"\/2$, but it's defined by $V_"out,DC" = V_"DD" - |V_"DS3"|$.

Where $|V_"DS3"| = |V_"SG3"|$ since M3 is diode connected.

Since we know that $I_"d1" = I_"d3"$ is constant, and since we want to force M3 to be in saturation, let's use the formula of $I_"d3"$ and solve for $(W\/L)_3$:

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

The CS stage is here to increase the output swing of the differential amplifier. We consider $V_y$ to be the output voltage of the CS stage. The input to M7, the PMOS, is $V_"out,DC"$ from the diff pair - we'll hereby call $V_"out,DC"$ as diff_out, and $V_y$ = cs_out.

The questions we have to answer here are:

- What do we want the output bias voltage to sit at?
- How do we then size M7 and M8, the PMOS and NMOS, respectively?

This topology is essentially a CS stage with current source load.

Here, $A_v = -g_"m8" (r_"o8" || r_"o7")$. However, the CS stage is pretty susceptible to channel length modulation. According to Razavi, the output bias voltage of the CS stage with current load is not well-defined without feedback (Razavi, 3.3.3). Since the gain is proportional to the drain current, since $r_o prop L\/I_d$. Thus, a longer transistor yields a higher voltage gain. The purpose of the CS stage is to increase swing, so that the inverter in the next stage is appropriately driven.

From Razavi, the intrinsic gain of the CS stage with current source load is given as:

$ g_"m1" r_"o1" = sqrt(K_n (W\/L)_8 I_d) dot 1 / (lambda_n I_d) $

Let's consider the maximum output swing levels of the CS stage.

At the very top, M7 is at the edge of saturation at $"CS\_OUT" = V_"DD" - |V_"GS7" - V_"TH,P"|$ and at the bottom swing, $"CS\_OUT" = V_"IN,COUT" - V_"TH,n"$. So CS_OUT is bound by these two levels. We know that $V_"IN,COUT"$ is the $V_x$ level we computed earlier, which is equal to $V_x = 0.8225 "V"$.

Thus, the low level of $"CS\_OUT" = 0.8225 - 0.7 = 0.1225 "V"$.

We want to avoid clipping, so we have to keep both M7 and M8 in saturation, but the CS_OUT level is also unstable without feedback. We also want to keep $L$ fixed for simplicity of layout.

We need to find $V_"GS7"$ to see what CS_OUT might be, despite it being ill-defined.

So, if we know that $0.1225 < "CS\_OUT" < V_"DD" - |V_"SG7" - V_"TH,P"|$, let's just find the average value of those two peaks and that should tell us where CS_OUT should sit at.

Adding up those two values, where $V_"SG7" = 3 - 1.639 "V"$, we get $"CS\_OUT" = 1.28075 "V"$.

We also see that M8 is driven by $V_x$, which is the current mirror output voltage from M5. Which means we can size M8 to provide enough current to put M7 and M8 in saturation, while keeping the output voltage swing level in check.

We see that, since $(W\/L)_5 = 1$, $I_"d8" = (W\/L)_8 dot I_"ref"$.

Knowing that $I_"d7" = I_"d8"$, then:
$ (W\/L)_8 dot I_"ref" = K_p (W\/L)_7 (V_"sg7" - |V_"th,p"|)^2 (1 + lambda_p V_"sd7") $

Where $V_"sg7" = 3 - 1.639 "V"$ and $V_"sd7" = 3 - 1.28 "V"$.

Solving for the ratio, we get:
$ (W\/L)_8 \/ (W\/L)_7 = 8.12 $

So, we have some control here over the aspect ratios.

Now, from the current through M8, we have:
$ I_"d8" = K_n (W\/L)_8 (0.8225 - 0.7)^2 (1 + 0.1(1.28075 - 0.7)) $
$ (W\/L)_8 \/ (W\/L)_7 dot I_"ref" = K_n (W\/L)_8 (0.8225 - 0.7)^2 (1 + 0.1(1.28075 - 0.7)) $

We get $(W\/L)_7 approx 0.93$, so we will push it to 1.

Thus, to keep CS_OUT at 1.28075 V, we get $(W\/L)_8 = 8.12$.

However - in practice - we see significant duty cycle distortion with this aspect ratio of M8. So, by inspection, we reduce it to 6. We will discuss these adjustments to second-order effects in a later section.

== The CMOS Inverter

Here, the idea is that the PMOS at the top (M9) pulls the level up to $V_"DD"$, and the NMOS (M10) pulls it to GND. Therefore, we need the bias of $V_"out"$ as close as possible to 0. M10 acts as a current source pull-up. So, the question here, is how do we size the transistors? We ideally want a high $|A_v|$ around the logic threshold for good noise margins (MIT).

Let's define $V_m$ as the input bias point to the CMOS inverter. We ideally want it at $V_"DD"\/2$, but we actually have $V_m = "cs\_out" = 1.29 "V"$. We define a "drive strength" ratio of $r = sqrt(k_p\/k_n) = 0.53$. Equating the currents of M10 and M9, we get:

$ V_m = (V_"tn" + r(V_"DD" - V_"tp")) / (1 + r) approx 1.233 "V" $

Which matches closely to CS_OUT (the error difference is due to rounding when I calculated $r$).

From this, we further find that:
$ (W\/L)_P = mu_n / mu_p dot (W\/L)_N $

Where $mu_n = 350$ and $mu_p = 100$ (Table 2.1 Razavi).

Thus:
$ (W\/L)_P = 3.5 (W\/L)_N $

To keep it as an integer multiple, $(W\/L)_P = (W\/L)_9 = 4$ and $(W\/L)_N = (W\/L)_10 = 1$.

We have now fully sized.

= Results

= Discussion

= Conclusion

#pagebreak()
#include("citations.bib")
