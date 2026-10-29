"""Run existing benches and generic synthesis without overwriting saved evidence.

Requires Python 3 and Icarus Verilog / Yosys on PATH. No Python dependencies.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[1]
RTL = ['rtl/' + name + '.sv' for name in
       ['pe', 'systolic', 'input_buffer', 'controller', 'matrix_feeder', 'tiny_npu_top']]
BENCHES = [
    ('tb_pe', 'tb/tb_pe.sv', 'ALL PE TESTS PASSED'),
    ('tb_systolic_array', 'tb/tb_systolic.sv', 'ALL ARRAY TESTS PASSED'),
    ('tb_controller', 'tb/tb_controller.sv', 'Return to IDLE passed!'),
    ('tb_matrix_feeder', 'tb/tb_matrix_feeder.sv', 'FEEDER TEST FINISHED'),
    ('tb_input_buffer', 'tb/tb_input_buffer.sv', 'ALL INPUT BUFFER TESTS PASSED'),
    ('tb_tiny_npu_top', 'tb/tb_tiny_npu_top.sv', 'ALL TINYNPU TOP TESTS PASSED'),
    ('tb_tiny_npu_extended', 'tb/tb_tiny_npu_extended.sv', 'ALL EXTENDED TESTS PASSED'),
]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, help='New output directory; must not exist')
    parser.add_argument('--mode', choices=['all', 'sim', 'synth'], default='all')
    args = parser.parse_args()
    out = Path(args.output).resolve()
    out.mkdir(parents=True, exist_ok=False)
    (out / 'sim').mkdir()
    sources = RTL + [b[1] for b in BENCHES] + ['scripts/synth.ys', 'scripts/run_checks.py']
    manifest = {
        'started_utc': datetime.now(timezone.utc).isoformat(),
        'mode': args.mode,
        'sources_sha256': {p: hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources},
        'commands': [], 'tests': [],
    }

    def run(command, log_name, cwd):
        manifest['commands'].append({'argv': command, 'working_directory': 'project root' if cwd == ROOT else 'output directory', 'log': log_name})
        # Executable paths in console output are redacted for portable evidence.
        proc = subprocess.run(command, cwd=cwd, stdout=subprocess.PIPE,
                              stderr=subprocess.STDOUT, timeout=180)
        output = proc.stdout.decode('utf-8', errors='replace')
        for tool in ['iverilog', 'vvp', 'yosys']:
            executable = shutil.which(tool)
            if executable:
                for prefix in [str(Path(executable).parent.parent), str(Path(executable).parent.parent).replace('\\', '/')]:
                    output = output.replace(prefix, '<toolchain>')
        output = output.replace(str(ROOT), '<project>').replace(str(out), '<output>')
        (out/log_name).write_text(output, encoding='utf-8')
        if proc.returncode:
            raise RuntimeError(f'{command[0]} failed ({proc.returncode}); see {log_name}')
        return output

    try:
        if args.mode in ['all', 'sim']:
            run(['iverilog', '-V'], 'iverilog_version.log', ROOT)
            run(['vvp', '-V'], 'vvp_version.log', ROOT)
            for top, source, marker in BENCHES:
                binary = out / (top + '.vvp')
                # Run in the evidence directory: benches use relative dump paths.
                run(['iverilog', '-g2012', '-s', top, '-o', str(binary)] + RTL + [source], top + '_compile.log', ROOT)
                output = run(['vvp', binary.name], top + '.log', out)
                if marker not in output or re.search(r'(?im)^.*\b(?:FAIL|FAILED|FATAL|TIMEOUT)\b', output):
                    raise RuntimeError('Missing success marker or reported failure: ' + top)
                if top == 'tb_tiny_npu_extended':
                    ids = re.findall(r'^PASS TEST (\d+)\s*$', output, re.MULTILINE)
                    if ids != [str(i) for i in range(1, 25)] or 'Tests passed: 24 / 24' not in output or 'Total errors: 0' not in output:
                        raise RuntimeError('Extended test count/error check failed')
                manifest['tests'].append({'top': top, 'status': 'PASS', 'success_marker': marker})
                print(top + ': PASS', flush=True)
        if args.mode in ['all', 'synth']:
            version = run(['yosys', '-V'], 'yosys_version.log', ROOT).strip()
            output = run(['yosys', '-s', 'scripts/synth.ys'], 'yosys_synth.log', ROOT)
            if 'Found and reported 0 problems.' not in output:
                raise RuntimeError('Yosys structural check result missing')
            manifest['synthesis'] = {'status': 'PASS', 'tool': version, 'flow': 'scripts/synth.ys', 'mapping': 'generic internal cells; no target library'}
            print('Yosys generic synthesis: PASS', flush=True)
        manifest['status'] = 'PASS'
    except Exception as error:
        manifest['status'] = 'FAIL'
        manifest['failure'] = str(error)
        raise
    finally:
        # Store portable commands, never local machine paths.
        for command in manifest['commands']:
            command['argv'] = [arg.replace(str(out), '<output>').replace(str(ROOT), '<project>') for arg in command['argv']]
        manifest['finished_utc'] = datetime.now(timezone.utc).isoformat()
        manifest['artifacts_sha256'] = {str(p.relative_to(out)).replace('\\', '/'): hashlib.sha256(p.read_bytes()).hexdigest()
                                       for p in sorted(out.rglob('*')) if p.is_file() and p.suffix in ['.log', '.vcd']}
        (out/'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
