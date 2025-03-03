package com.vod.plugin.tfcalctest;

import android.content.Context;
import android.content.res.AssetFileDescriptor;
import org.jetbrains.annotations.TestOnly;
import org.tensorflow.lite.Interpreter;
import org.tensorflow.lite.Tensor;
import org.tensorflow.lite.DataType;
import org.tensorflow.lite.support.tensorbuffer.TensorBuffer;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

public class TFLiteSimilarity {

    private Interpreter interpreter;

    public TFLiteSimilarity(Context context, String modelPath) throws IOException {
        interpreter = new Interpreter(loadModelFile(context, modelPath));
    }

    // 加载 TFLite 模型
    private MappedByteBuffer loadModelFile(Context context, String modelPath) throws IOException {
        // ✅ 使用 AssetFileDescriptor 读取 assets 下的文件
        AssetFileDescriptor fileDescriptor = context.getAssets().openFd(modelPath);
        FileInputStream inputStream = new FileInputStream(fileDescriptor.getFileDescriptor());
        FileChannel fileChannel = inputStream.getChannel();

        // ✅ 使用 `map()` 加载模型
        long startOffset = fileDescriptor.getStartOffset();
        long declaredLength = fileDescriptor.getDeclaredLength();
        return fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength);
    }

    public static String formatTensorBuffer(TensorBuffer tensorBuffer, int rows, int cols) {
        float[] array = tensorBuffer.getFloatArray();
        StringBuilder sb = new StringBuilder();

        if (array.length != rows * cols) {
            return "Error: Shape mismatch!";
        }

        for (int i = 0; i < rows; i++) {
            sb.append("[");
            for (int j = 0; j < cols; j++) {
                sb.append(array[i * cols + j]);
                if (j < cols - 1) {
                    sb.append(", ");
                }
            }
            sb.append("],\n");
        }
        return sb.toString();
    }


    // 计算相似度
    public float[] computeSimilarity(TensorBuffer textFeatures, TensorBuffer imageFeatures) {
        // 获取 batch size（即 imageFeatures 的行数）
        int batchSize = imageFeatures.getShape()[0];

        // **动态调整 batch size**
        interpreter.resizeInput(1, new int[]{batchSize, 768});
        interpreter.allocateTensors();  // 重新分配张量

        // 创建输出张量（一维 float 数组）
        float[][] outputProbs = new float[1][batchSize];

        // 创建输出缓冲区
//        TensorBuffer outputBuffer = TensorBuffer.createFixedSize(new int[]{batchSize}, DataType.FLOAT32);

        // 运行 TFLite 计算
        Object[] inputs = {textFeatures.getBuffer(), imageFeatures.getBuffer()};
        Map<Integer, Object> outputs = new HashMap<>();
        outputs.put(0, outputProbs);



        interpreter.runForMultipleInputsOutputs(inputs, outputs);

        // 将输出缓冲区的数据复制到 outputProbs
//        outputBuffer.loadArray(outputProbs);

        return outputProbs[0];
    }

    // 归一化 L2
    private float[] normalizeL2(float[] vector) {
        float sum = 0;
        for (float v : vector) {
            sum += v * v;
        }
        float norm = (float) Math.sqrt(sum);
        float[] normalized = new float[vector.length];
        for (int i = 0; i < vector.length; i++) {
            normalized[i] = vector[i] / norm;
        }
        return normalized;
    }

    // 展平 2D 数组
    private float[] flatten(float[][] array) {
        int rows = array.length;
        int cols = array[0].length;
        float[] flattened = new float[rows * cols];
        int index = 0;
        for (float[] row : array) {
            for (float value : row) {
                flattened[index++] = value;
            }
        }
        return flattened;
    }

    // 释放 Interpreter
    public void close() {
        if (interpreter != null) {
            interpreter.close();
        }
    }
}
