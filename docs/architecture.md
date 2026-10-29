# Architecture and timing contract

TinyNPU computes one fixed 4 x 4 signed INT8 matrix product per request. Six RTL modules implement a controller, input buffer, combinational feeder and 16-PE array, integrated by `tiny_npu_top`.

## Storage and arithmetic

`input_buffer` captures A and B into 128-bit registers on a rising edge with `load=1`. Reset synchronously clears both; otherwise they hold. This adds 256 register bits and decouples RUN from later external input changes. It is not SRAM and cannot overlap loading a second pair with computation.

Each PE stores forwarded A/B (8 bits each) and an output accumulator (32 bits). Its signed 16-bit product is explicitly sign-extended before addition. A moves right, B moves down, C stays local. Sixteen PEs contain 768 state bits.

## Request timeline

| Edge / interval | Behavior |
|---|---|
| Before E0 | Controller is IDLE; assert `start` and present A/B. |
| E0 | Accept `start`; enter CLEAR. |
| E0-E1 | `clear=1`, `load=1`, `en=0`. Keep A/B stable. |
| E1 | Capture matrices, clear PEs, enter RUN with `cycle=0`. |
| E2-E11 | Ten MAC/forward edges sample RUN cycles 0..9. |
| After E11 | DONE asserts `done=1`; all results valid. |
| E12 | Return to IDLE. |

Pulse `start` for one cycle. There is no request queue, busy/ready signal or capture acknowledgement. Consumers must obey the fixed timing. Results stay stored until the next CLEAR/reset; `c_flat` is not a serial stream.

## Skew schedule

At cycle `t`, lane `r` selects `A[r,t-r]`, lane `c` selects `B[t-c,c]`, with zero padding outside indices 0..3. Term `k` reaches PE `[r,c]` on `t=r+c+k`; PE `[3,3]` finishes at `t=9`.

Ports use row-major packing: element `[0,0]` occupies the least-significant slice. Input slice: `(r*4+c)*8 +: 8`. Output slice: `(r*4+c)*32 +: 32`, interpreted with `$signed`.

## Change from the previous release

The 25 October release already integrated array, feeder and four-state controller. This update adds `input_buffer`, asserts controller `load` in CLEAR, and switches the feeder to captured matrices. Original PE, array, feeder and previous testbench logic remain unchanged. New extended and buffer benches are included without rewriting checks.

See [verification](verification.md) and [README](../README.md).
