
from pathlib import Path
import argparse
import numpy as np

NN = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description="Export one MNIST-derived tile without overwriting existing vectors.")
parser.add_argument("--output", required=True, type=Path, help="New vector directory")
SIM = parser.parse_args().output
SIM.mkdir(parents=True, exist_ok=False)

with np.load(NN / "data" / "mnist.npz") as data:
    images = data["x_test"][:4]
    labels = data["y_test"][:4]

with np.load(NN / "models" / "mnist_int8.npz") as model:
    W1 = model["W1q"].astype(np.int32)

# 与之前量化脚本保持一致
X = np.clip(
    np.rint(images.reshape(4, 784).astype(np.float64)
            * 127.0 / 255.0),
    0, 127
).astype(np.int32)

# 选择像素活动最明显的一个 4 特征分块
scores = np.abs(X.reshape(4, 196, 4)).sum(axis=(0, 2))
tile = int(np.argmax(scores))
k = tile * 4

A = X[:, k:k+4]
B = W1[k:k+4, :4]

# Python 整数标准结果
C = A @ B

# 打包方式与 TinyNPU row-major 接口一致
def pack_matrix(M):
    value = 0
    for r in range(4):
        for c in range(4):
            value |= (int(M[r, c]) & 0xff) << ((r*4+c)*8)
    return f"{value:032x}"

(SIM / "mnist_tile_a.hex").write_text(pack_matrix(A) + "\n")
(SIM / "mnist_tile_b.hex").write_text(pack_matrix(B) + "\n")

with open(SIM / "mnist_tile_expected.hex", "w") as f:
    for value in C.flatten():
        f.write(f"{int(value) & 0xffffffff:08x}\n")

print("MNIST labels:", labels.tolist())
print("Selected feature indices:", list(range(k, k+4)))
print("Input matrix A:\n", A)
print("Weight matrix B:\n", B)
print("Expected C:\n", C)
print("EXPORT COMPLETED")
