
from pathlib import Path
import json
import time

import numpy as np
from sklearn.neural_network import MLPClassifier
from sklearn.metrics import accuracy_score

# 项目路径
NN_DIR = Path(__file__).resolve().parents[1]
DATA_DIR = NN_DIR / "data"
MODEL_DIR = NN_DIR / "models"
RESULT_DIR = NN_DIR / "results"

MODEL_DIR.mkdir(parents=True, exist_ok=True)
RESULT_DIR.mkdir(parents=True, exist_ok=True)

# 1. 读取 MNIST
with np.load(DATA_DIR / "mnist.npz", allow_pickle=False) as data:
    x_train = data["x_train"]
    y_train = data["y_train"]
    x_test = data["x_test"]
    y_test = data["y_test"]

# 2. 展平并归一化到 0~1
X_train = x_train.reshape(-1, 784).astype(np.float32) / 255.0
X_test = x_test.reshape(-1, 784).astype(np.float32) / 255.0

print("Training samples:", len(X_train))
print("Testing samples:", len(X_test))

# 3. 创建 784 → 16 → 10 网络
model = MLPClassifier(
    hidden_layer_sizes=(16,),
    activation="relu",
    solver="adam",
    batch_size=256,
    learning_rate_init=0.001,
    max_iter=30,
    random_state=42,
    verbose=True
)

# 4. 训练网络
start = time.time()
model.fit(X_train, y_train)
elapsed = time.time() - start

# 5. 在独立测试集上评估
predictions = model.predict(X_test)
accuracy = accuracy_score(y_test, predictions)

print("\n===== TRAINING RESULT =====")
print(f"Training time: {elapsed:.2f} seconds")
print(f"Test accuracy: {accuracy * 100:.2f}%")

# 6. 保存两层网络的权重和偏置
W1, W2 = model.coefs_
b1, b2 = model.intercepts_

assert W1.shape == (784, 16)
assert W2.shape == (16, 10)
assert b1.shape == (16,)
assert b2.shape == (10,)

np.savez(
    MODEL_DIR / "mnist_fp32.npz",
    W1=W1.astype(np.float32),
    W2=W2.astype(np.float32),
    b1=b1.astype(np.float32),
    b2=b2.astype(np.float32)
)

# 7. 保存训练结果
report = {
    "architecture": "784-16-10",
    "test_accuracy": float(accuracy),
    "training_seconds": elapsed,
    "epochs": int(model.n_iter_),
    "random_state": 42
}

with open(RESULT_DIR / "training_report.json", "w", encoding="utf-8") as f:
    json.dump(report, f, indent=2)

print("W1 shape:", W1.shape)
print("W2 shape:", W2.shape)
print("b1 shape:", b1.shape)
print("b2 shape:", b2.shape)
print("Saved model: nn/models/mnist_fp32.npz")
print("TRAINING COMPLETED")
