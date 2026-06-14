# 4-bit Carry Look-Ahead Adder — 180 nm CMOS

A full-custom 4-bit Carry Look-Ahead (CLA) adder I designed end-to-end in **180 nm CMOS**, from logic and transistor sizing all the way to layout, parasitic-extracted simulation, and an FPGA demo. The combinational adder is built in **static CMOS** and the input/output registers use a **TSPC (True Single-Phase Clock) D flip-flop**.

This was my VLSI Design course project at IIIT Hyderabad. I'm putting it up as a single, organised repository so the whole flow — schematic → layout → post-layout → RTL → hardware — can be followed in one place.

## Final Performance

| Metric | Value |
|---|---|
| Technology | 180 nm (TSMC model), VDD = 1.8 V |
| Max reliable clock | **1.25 GHz** (800 ps period) |
| Average power | **5.393 mW** |
| Power–delay product (CLA core) | **3.97 × 10⁻¹² Ws** |
| Critical path | `a0 → s3` |
| Final layout area | 64.08 µm × 86.31 µm |

## What is a CLA adder?

A ripple-carry adder is slow because each bit waits for the carry from the bit below it. A CLA adder breaks that dependency: it computes, for every bit, a **generate** term `Gᵢ = Aᵢ·Bᵢ` (this bit makes a carry on its own) and a **propagate** term `Pᵢ = Aᵢ ⊕ Bᵢ` (this bit passes an incoming carry along). With these, every carry can be written directly in terms of the inputs:

```
C1 = G0
C2 = G1 + P1·G0
C3 = G2 + P2·G1 + P2·P1·G0
C4 = G3 + P3·G2 + P3·P2·G1 + P3·P2·P1·G0     (carry out)

s0 = A0 ⊕ B0
sᵢ = Aᵢ ⊕ Bᵢ ⊕ Cᵢ
```

So all carries are produced in parallel instead of rippling, which is where the speed comes from.

<p align="center"><img src="docs/images/architecture_gate_level.jpg" width="460"></p>

The inputs and outputs are registered by TSPC D flip-flops so the whole block behaves as one synchronous stage: inputs are latched on a clock edge, and the result is available at the next edge.

---

## Design flow (what I did, step by step)

### 1–2. Logic design and topology

I implemented each `Gᵢ` as an AND gate and each `Pᵢ` as an XOR gate, then built the carry equations above as static CMOS complex gates. Each sum bit drives an output inverter (Wp/Wn = 20λ/10λ).

| | |
|---|---|
| ![P/G gates](docs/images/schematic_pg_gates.jpg) | ![C4 carry gate](docs/images/schematic_c4_carry.jpg) |
| Generate (AND) and Propagate (XOR) gates | Static CMOS complex gate for the C4 carry |

The registers use a TSPC D flip-flop. I chose TSPC because it needs only a single clock (no complementary clock distribution), which keeps the clock network simple and the load light.

<p align="center"><img src="docs/images/schematic_tspc_dff.jpg" width="460"></p>

### 3. Sizing and layout-design strategy

I used a **modified Euler-path approach** for the layouts, and sized the transistors conservatively against the propagation delay each option gave:

- **Most modules were best with a constant 2W/W ratio**, so I kept that as the default. This deliberately keeps the cells equi-sized and symmetric, which is what makes a clean Euler-path layout possible.
- The **AND gate** was the one exception — its theoretical 2W/2W sizing performed best, so AND uses 2W/2W.
- The **XOR gate** was marginally faster at 4W/W, but the delay improvement was very small, so I kept it at 2W/W to preserve the symmetric layout.
- The **TSPC flip-flop showed no improvement** from increasing size or ratio, so I used a small 2W/W to add as little load as possible on the clock signal.

An Euler path is a walk through the transistor graph that uses every edge exactly once (an Euler *circuit* starts and ends at the same vertex). I built Euler paths for all modules, but in doing so only one transistor of the pull-up/pull-down network ends up touching VDD/GND. That raises the rise/fall time, which is critical to delay. To fix it I **split the larger gates into smaller diffusion regions** with more supply contacts, lowering the supply resistance and improving the edges.

### 4. Block-level functional simulation (NGSPICE)

I wrote a SPICE netlist for each module and verified its truth table under a realistic load. Delay and RMS power were measured for every block.

<p align="center"><img src="docs/images/sim_xor_block.png" width="520"></p>

| Module | Delay (s) | RMS Power (W) |
|---|---|---|
| Inverter | 5.31 × 10⁻¹¹ | 2.08 × 10⁻⁴ |
| XOR | 1.39 × 10⁻¹⁰ | 3.34 × 10⁻⁴ |
| AND | 1.60 × 10⁻¹⁰ | 4.98 × 10⁻⁴ |
| C2 logic | 2.87 × 10⁻¹⁰ | 2.44 × 10⁻⁴ |
| C3 logic | 3.90 × 10⁻¹⁰ | 1.91 × 10⁻⁴ |
| C4 logic | 4.97 × 10⁻¹⁰ | 1.48 × 10⁻⁴ |

→ Netlists: [`spice/blocks/`](spice/blocks/), [`spice/delay_power/`](spice/delay_power/)

### 5. Flip-flop timing (setup, hold, clock-to-Q)

I characterised the TSPC flip-flop by sweeping the data edge against the clock edge and finding the point just before the output corrupts. This gave me the setup time, hold time and clock-to-Q delay. The final characterised values:

| t_setup | t_hold | t_pcq |
|---|---|---|
| 50 ps | 30 ps | 118 ps |

<p align="center"><img src="docs/images/dff_clk_to_q.png" width="520"></p>

→ Netlist: [`spice/dff_timing/dff_fused.cir`](spice/dff_timing/dff_fused.cir)

### 6. Stick diagrams

Before drawing the layout I made Euler-path-based stick diagrams for every unique gate so that the diffusion strips were continuous and the cells stayed compact and regular.

<p align="center"><img src="docs/images/stick_xor.jpg" width="460"></p>

*(All stick diagrams — AND, XOR, C2, C3/C4, DFF, inverter — are in the [report](docs/report.pdf).)*

### 7. Block-level layout + post-layout verification (MAGIC)

I laid out each block in MAGIC using the `SCN6M_DEEP.09` tech file, then extracted parasitics and re-simulated. As noted in the sizing strategy, gates that would have sat in a single diffusion area were split into smaller regions with more VDD/GND contacts to lower resistance and keep the edges fast.

<p align="center"><img src="docs/images/layout_c4_block.png" width="520"></p>

The post-layout delays tracked the schematic closely for most blocks — the comparison tables are in the [report](docs/report.pdf).

→ Layouts: [`layout/blocks/`](layout/blocks/) · Extracted sims: [`post_layout_sim/block_wise/`](post_layout_sim/block_wise/)

### 8. Full-circuit integration

I stitched all the blocks together — input flip-flops → P/G → carry logic → sum → output flip-flops — into one netlist and verified the complete synchronous adder in NGSPICE.

<p align="center"><img src="docs/images/full_schematic.png" width="560"></p>

<p align="center"><img src="docs/images/sim_full_circuit_outputs.png" width="560"></p>

In the waveforms, `a0_unsync…` are the raw test inputs, `a0…` are the registered CLA inputs, `c4,s3…s0` are the CLA outputs, and `…_sync` are the final registered outputs.

→ Netlists: [`spice/integrated/`](spice/integrated/)

### 9. Floor plan

I planned the placement of all 16 flip-flops and the combinational blocks so the regular structures lined up, and identified the horizontal/vertical pitches.

<p align="center"><img src="docs/images/floor_plan.png" width="480"></p>

### 10. Full-chip layout, extraction and timing

I assembled the complete layout, extracted the parasitic netlist, and repeated every simulation on it.

**Finding the worst-case delay:** the worst-case delay is obtained on the critical path. I keep the inputs to all other paths constant, and choose the inputs so that toggling only the critical-path input changes the critical-path output. The rise and fall propagation delays are then noted. For this design the critical path is `a0 → s3`. From the extracted netlist:

```
t_CLK ≥ t_p + t_setup + t_pcq = 532 + 30 + 174 = 736 ps
```

I saw glitches right at 736 ps, so I picked **800 ps (1.25 GHz)** as the reliable operating period.

| | |
|---|---|
| ![Final layout](docs/images/final_layout.png) | ![Critical path delay](docs/images/critical_path_delay.png) |
| Complete extracted layout | Critical path (`a0 → s3`) delay |

→ Layout: [`layout/full_chip/`](layout/full_chip/) · Extracted sims: [`post_layout_sim/full_chip/`](post_layout_sim/full_chip/)

### 11. Verilog (structural) + simulation

I also described the same circuit structurally in Verilog — gate primitives for the CLA, a parameterised D flip-flop for the registers, and an on-chip clock divider (built from T flip-flops) that walks through all 256 input combinations so the adder can be exercised exhaustively. Verified in GTKWave.

![GTKWave verification of the structural Verilog](docs/images/verilog_gtkwave.png)

→ RTL: [`verilog/rtl/`](verilog/rtl/) · Testbench: [`verilog/tb/`](verilog/tb/)

### 12. FPGA implementation

Finally I put the design on a Boolean Board FPGA. The internal clock divider drives the inputs, and I captured the outputs (C4, S3, S2, S1, S0) on a logic analyzer to confirm the hardware matches simulation.

| | |
|---|---|
| ![Logic analyzer capture](docs/images/fpga_logic_analyzer.png) | ![Test setup](docs/images/fpga_test_setup.jpg) |
| Logic-analyzer capture of outputs | Hardware test setup |

→ Capture file: [`fpga/capture/Final_Capture.sal`](fpga/capture/) (open with Saleae Logic 2)

---

## Repository layout

```
4bit-cla-adder-180nm/
├── docs/
│   ├── report.pdf                 # full project report
│   ├── problem_statement.pdf      # original assignment
│   ├── report_source/             # LaTeX source + all figures
│   └── images/                    # figures used in this README
├── spice/
│   ├── models/                    # TSMC 180 nm model card
│   ├── blocks/                    # per-block functional netlists  (Sec 4)
│   ├── dff_timing/                # setup/hold/clk-to-Q            (Sec 5)
│   ├── integrated/                # full adder netlist             (Sec 8)
│   └── delay_power/               # per-output delay + power       (Sec 4,10)
├── layout/
│   ├── tech/                      # SCN6M_DEEP.09 tech file
│   ├── devices/                   # sized NMOS/PMOS device cells
│   ├── blocks/                    # per-block MAGIC layouts (.mag) + extracted (.spice)
│   └── full_chip/                 # complete layout + extracted netlist
├── post_layout_sim/
│   ├── block_wise/                # extracted block simulations    (Sec 7)
│   └── full_chip/                 # extracted full-chip simulation (Sec 10)
├── verilog/
│   ├── rtl/                       # structural Verilog
│   ├── tb/                        # testbench
│   └── sim/                       # VCD + GTKWave session
└── fpga/
    └── capture/                   # logic-analyzer capture
```

## Tools

- **NGSPICE** — circuit simulation (180 nm TSMC model)
- **MAGIC** — full-custom layout and parasitic extraction (`SCN6M_DEEP.09` tech)
- **Icarus Verilog + GTKWave** — RTL simulation
- **Saleae Logic 2** — FPGA output capture

To re-run a SPICE deck, MAGIC layout, or the RTL, see the notes at the top of each netlist / source file. SPICE decks expect the model card `TSMC_180nm.txt` to be on the include path.

## References

1. Md. Ashik Zafar Dipto, Elias Ahammad Sojib, Afran Sorwar, Md. Mostak Tahmid Rangon, *"Performance Improvement in Conventional 4-bit Static CMOS Carry Look-Ahead Adder by Modifying Carry-Generate and Propagate Terms,"* 11th ICCCNT, IIT Kharagpur, July 2020.
2. Behzad Razavi, *"A Circuit for All Seasons — The TSPC Logic,"* IEEE Solid-State Circuits Magazine, Fall 2016.
3. N. Weste and D. Harris, *CMOS VLSI Design*, 4th ed., Addison-Wesley.

---

*Hrishikesh Gawas — VLSI Design course project, IIIT Hyderabad.*
