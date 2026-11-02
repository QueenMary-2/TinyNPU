
from pathlib import Path
import json

import numpy as np

NN_DIR = Path(__file__).resolve().parents[1]
DATA_DIR = NN_DIR / "data"
MODEL_DIR = NN_DIR / "models"
RESULT_DIR = NN_DIR / "results"

# 读取已经训练好的 FP32 模型
with np.load(MODEL_DIR / "mnist_fp32.npz") as model:
    W1 = model["W1"].astype(np.float32)
    W2 = model["W2"].astype(np.float32)
    b1 = model["b1"].astype(np.float32)
    b2 = model["b2"].astype(np.float32)

# 读取 MNIST
with np.load(DATA_DIR / "mnist.npz") as data:
    x_train = data["x_train"]
    x_test = data["x_test"]
    y_test = data["y_test"]

assert W1.shape == (784, 16)
assert W2.shape == (16, 10)

# 1. 输入量化：归一化像素 0~1 → 0~127
INPUT_SCALE = 1.0 / 127.0

def quantize_input(images):
    flat = images.reshape(-1, 784).astype(np.float64)
    return np.clip(
        np.rint(flat * 127.0 / 255.0),
        0, 127
    ).astype(np.int32)

# 2. 对每层权重进行对称 INT8 量化
def quantize_weight(W):
    scale = float(np.max(np.abs(W))) / 127.0
    assert scale > 0
    Wq = np.clip(
        np.rint(W / scale), -127, 127
    ).astype(np.int32)
    return Wq, scale

W1q, s_w1 = quantize_weight(W1)
W2q, s_w2 = quantize_weight(W2)

# 3. 使用训练集前 4096 张图片校准隐藏层范围
calib = x_train[:4096].reshape(-1, 784).astype(np.float32) / 255.0
hidden_fp = np.maximum(calib @ W1 + b1, 0)

hidden_max = float(np.max(hidden_fp))
assert hidden_max > 0
s_hidden = hidden_max / 127.0

# 4. 将 Bias 转换成 INT32
s_acc1 = INPUT_SCALE * s_w1
s_acc2 = s_hidden * s_w2

b1q = np.rint(b1 / s_acc1).astype(np.int32)
b2q = np.rint(b2 / s_acc2).astype(np.int32)

# 5. 第一层输出需要重新缩放到 INT8
#    使用 Q24 定点乘数，推理时不需要浮点乘法
SHIFT = 24
multiplier = int(np.rint((s_acc1 / s_hidden) * (1 << SHIFT)))

assert multiplier > 0

def integer_inference(images):
    Xq = quantize_input(images)

    # 第一层：INT8 × INT8 → INT32
    acc1 = Xq @ W1q
    acc1 = acc1 + b1q

    # ReLU
    relu1 = np.maximum(acc1, 0)

    # 定点重新量化到 INT8
    hidden_q = (
        relu1.astype(np.int64) * multiplier
        + (1 << (SHIFT - 1))
    ) >> SHIFT

    hidden_q = np.clip(hidden_q, 0, 127).astype(np.int32)

    # 第二层：INT8 × INT8 → INT32
    acc2 = hidden_q @ W2q
    logits_q = acc2 + b2q

    # 不需要 Softmax，最大得分对应预测类别
    predictions = np.argmax(logits_q, axis=1)

    return predictions, hidden_q, logits_q

# 6. 测试 10,000 张图片
correct = 0
total = len(x_test)

for start in range(0, total, 256):
    end = min(start + 256, total)

    predictions, _, _ = integer_inference(x_test[start:end])
    correct += int(np.sum(predictions == y_test[start:end]))

accuracy = correct / total

# 7. 保存硬件需要的整数参数
MODEL_DIR.mkdir(parents=True, exist_ok=True)
RESULT_DIR.mkdir(parents=True, exist_ok=True)

np.savez_compressed(
    MODEL_DIR / "mnist_int8.npz",
    W1q=W1q.astype(np.int8),
    W2q=W2q.astype(np.int8),
    b1q=b1q,
    b2q=b2q,
    input_scale=INPUT_SCALE,
    weight1_scale=s_w1,
    weight2_scale=s_w2,
    hidden_scale=s_hidden,
    requant_multiplier=multiplier,
    requant_shift=SHIFT
)

# 8. 保存第一张图片的推理中间结果
sample_pred, sample_hidden, sample_logits = integer_inference(x_test[:1])

np.savez_compressed(
    RESULT_DIR / "int8_sample.npz",
    input_q=quantize_input(x_test[:1]),
    hidden_q=sample_hidden,
    logits_q=sample_logits,
    prediction=sample_pred,
    label=y_test[:1]
)

report = {
    "architecture": "784-16-10",
    "quantization": "symmetric INT8, INT32 accumulator",
    "correct": correct,
    "total": total,
    "accuracy": accuracy,
    "weight1_scale": s_w1,
    "weight2_scale": s_w2,
    "hidden_scale": s_hidden,
    "requant_multiplier": multiplier,
    "requant_shift": SHIFT
}

with open(RESULT_DIR / "quantization_report.json", "w") as f:
    json.dump(report, f, indent=2)

print("\n===== INT8 QUANTIZATION RESULT =====")
print("W1 INT8 shape:", W1q.shape)
print("W2 INT8 shape:", W2q.shape)
print("W1 range:", W1q.min(), W1q.max())
print("W2 range:", W2q.min(), W2q.max())
print("Hidden activation scale:", s_hidden)

print("\n===== MNIST TEST =====")
print("Correct:", correct)
print("Total:", total)
print(f"INT8 accuracy: {accuracy * 100:.2f}%")
print("FP32 baseline: 95.50%")
print(f"Accuracy difference: {(accuracy - 0.955) * 100:+.2f} percentage points")

print("\n===== SAMPLE INFERENCE =====")
print("Actual label:", int(y_test[0]))
print("Predicted label:", int(sample_pred[0]))
print("Integer logits:", sample_logits[0].tolist())

print("\nSaved: nn/models/mnist_int8.npz")
print("Saved: nn/results/int8_sample.npz")
print("INT8 QUANTIZATION COMPLETED")
