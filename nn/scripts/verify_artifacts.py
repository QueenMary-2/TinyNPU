"""Read-only evaluation of saved MNIST models and published tile fixtures.

Requires NumPy and the local dataset. Never retrains or overwrites models/reports.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import platform
import numpy as np

NN = Path(__file__).resolve().parents[1]
ROOT = NN.parent


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path, help='New report directory')
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    with np.load(NN/'data/mnist.npz', allow_pickle=False) as data:
        images, labels = data['x_test'], data['y_test']
    with np.load(NN/'models/mnist_fp32.npz', allow_pickle=False) as saved:
        fp = {k: saved[k] for k in ['W1', 'W2', 'b1', 'b2']}
    with np.load(NN/'models/mnist_int8.npz', allow_pickle=False) as saved:
        q = {k: saved[k] for k in saved.files}
    assert fp['W1'].shape == q['W1q'].shape == (784, 16)
    assert fp['W2'].shape == q['W2q'].shape == (16, 10)
    assert len(labels) == 10000
    correct_fp, correct_q = 0, 0
    multiplier, shift = int(q['requant_multiplier']), int(q['requant_shift'])
    for offset in range(0, len(labels), 256):
        batch = images[offset:offset+256].reshape(-1, 784)
        x = batch.astype(np.float32)/255.0
        logits_fp = np.maximum(x@fp['W1'] + fp['b1'], 0)@fp['W2'] + fp['b2']
        xq = np.clip(np.rint(batch.astype(np.float64)*127.0/255.0), 0, 127).astype(np.int32)
        acc = xq@q['W1q'].astype(np.int32) + q['b1q']
        hidden = np.clip((np.maximum(acc, 0).astype(np.int64)*multiplier + (1 << (shift-1))) >> shift, 0, 127).astype(np.int32)
        logits_q = hidden@q['W2q'].astype(np.int32) + q['b2q']
        target = labels[offset:offset+256]
        correct_fp += int(np.sum(np.argmax(logits_fp, axis=1) == target))
        correct_q += int(np.sum(np.argmax(logits_q, axis=1) == target))
        if offset == 0:
            with np.load(NN/'results/int8_sample.npz', allow_pickle=False) as sample:
                for name, value in [('input_q', xq[:1]), ('hidden_q', hidden[:1]), ('logits_q', logits_q[:1]), ('prediction', np.argmax(logits_q[:1], axis=1)), ('label', labels[:1])]:
                    assert np.array_equal(sample[name], value), name
    train_report = json.loads((NN/'results/training_report.json').read_text())
    quant_report = json.loads((NN/'results/quantization_report.json').read_text())
    assert correct_fp/len(labels) == train_report['test_accuracy']
    assert correct_q == quant_report['correct'] and len(labels) == quant_report['total']
    assert correct_q/len(labels) == quant_report['accuracy']
    x = np.clip(np.rint(images[:4].reshape(4, 784).astype(np.float64)*127.0/255.0), 0, 127).astype(np.int32)
    tile = int(np.argmax(np.abs(x.reshape(4,196,4)).sum(axis=(0,2))))
    a, b = x[:,4*tile:4*tile+4], q['W1q'][4*tile:4*tile+4,:4].astype(np.int32)
    def packed(matrix):
        return format(sum((int(matrix[r,c]) & 255) << (8*(4*r+c)) for r in range(4) for c in range(4)), '032x')
    assert (NN/'vectors/mnist_tile_a.hex').read_text().strip() == packed(a)
    assert (NN/'vectors/mnist_tile_b.hex').read_text().strip() == packed(b)
    c = a@b
    expected = [format(int(v) & 0xffffffff, '08x') for v in c.flatten()]
    assert (NN/'vectors/mnist_tile_expected.hex').read_text().split() == expected
    files = [NN/'data/mnist.npz', *sorted((NN/'models').glob('*.npz')),
             *sorted((NN/'vectors').glob('*.hex')), *sorted((NN/'scripts').glob('*.py')),
             NN/'results/training_report.json', NN/'results/quantization_report.json', NN/'results/int8_sample.npz']
    report = {'status':'PASS', 'verified_utc':datetime.now(timezone.utc).isoformat(),
              'python':platform.python_version(), 'numpy':np.__version__,
              'test_images':len(labels), 'fp32_correct':correct_fp, 'fp32_accuracy':correct_fp/len(labels),
              'int8_correct':correct_q, 'int8_accuracy':correct_q/len(labels),
              'sample_artifact_matches':True, 'tile_labels':labels[:4].tolist(),
              'feature_indices':list(range(4*tile,4*tile+4)), 'A':a.tolist(), 'B':b.tolist(), 'C':c.tolist(),
              'scope':'Software full-network evaluation; RTL validates only one partial first-layer tile, without bias, ReLU or requantization.',
              'sources_sha256':{str(p.relative_to(ROOT)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}}
    (args.output/'model_verification.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
    print(f'FP32: {correct_fp}/{len(labels)}; INT8: {correct_q}/{len(labels)}; sample and tile fixtures: PASS')
    print('Tile features:', report['feature_indices'], 'labels:', report['tile_labels'])


if __name__ == '__main__':
    main()
