
from pathlib import Path
from urllib.request import urlretrieve

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# 项目目录
NN_DIR = Path(__file__).resolve().parents[1]
DATA_DIR = NN_DIR / "data"
RESULT_DIR = NN_DIR / "results"

DATA_DIR.mkdir(parents=True, exist_ok=True)
RESULT_DIR.mkdir(parents=True, exist_ok=True)

# 下载真实 MNIST 数据
url = "https://storage.googleapis.com/tensorflow/tf-keras-datasets/mnist.npz"
data_path = DATA_DIR / "mnist.npz"

if not data_path.exists():
    print("Downloading MNIST dataset...")
    temp_path = DATA_DIR / "mnist.npz.part"
    urlretrieve(url, temp_path)
    temp_path.replace(data_path)

# 读取训练集与测试集
with np.load(data_path, allow_pickle=False) as data:
    x_train = data["x_train"]
    y_train = data["y_train"]
    x_test = data["x_test"]
    y_test = data["y_test"]

print("Training images:", x_train.shape)
print("Training labels:", y_train.shape)
print("Testing images:", x_test.shape)
print("Testing labels:", y_test.shape)

print("Pixel range:", x_train.min(), "to", x_train.max())

# 展示前16张真实手写数字
fig, axes = plt.subplots(4, 4, figsize=(7, 7))

for i, ax in enumerate(axes.flat):
    ax.imshow(x_train[i], cmap="gray", vmin=0, vmax=255)
    ax.set_title(f"Label: {y_train[i]}")
    ax.axis("off")

plt.tight_layout()

output_path = RESULT_DIR / "mnist_samples.png"
plt.savefig(output_path, dpi=160)
plt.close()

print("Saved image:", output_path)
print("MNIST DATA CHECK PASSED")
