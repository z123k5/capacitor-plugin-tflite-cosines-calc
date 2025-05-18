package com.vod.plugin.tfcalctest;

import android.os.Build;
import android.widget.Toast;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import android.database.sqlite.SQLiteDatabase;
import com.vod.plugin.tfcalctest.TFLiteSimilarity;
import android.database.Cursor;
import org.tensorflow.lite.support.tensorbuffer.TensorBuffer;
import org.tensorflow.lite.DataType;

import java.io.File;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;

import android.content.Context;

import java.util.List;
import java.util.ArrayList;

import com.getcapacitor.JSArray;

import java.util.Arrays;
import java.io.IOException;

@CapacitorPlugin(name = "GalleryEngine")
public class GalleryEnginePlugin extends Plugin {
    private SQLiteDatabase db;
    private TFLiteSimilarity similarity;
    private TensorBuffer imageTensors;

    @Override
    protected void handleOnDestroy() {
//        db.close();
//        similarity.close();
//        similarity = null;
//        imageTensors = null;
        super.handleOnDestroy();
    }

    // 将字节数组转换为 float 数组（假设你的特征是 float 类型）
    private float[] convertBytesToFloatArray(byte[] bytes) {
        // 转换为 float 数组，具体可以根据你的数据格式调整
        float[] feature = new float[bytes.length / 4];
        for (int i = 0; i < feature.length; i++) {
            feature[i] = ByteBuffer.wrap(bytes, i * 4, 4).getFloat();
        }
        return feature;
    }

    // float[] 转 TensorBuffer
    private TensorBuffer convertToTensorBuffer(float[] floatArray) {
        TensorBuffer tensorBuffer = TensorBuffer.createFixedSize(new int[]{1, floatArray.length}, org.tensorflow.lite.DataType.FLOAT32);
        tensorBuffer.loadArray(floatArray);
        return tensorBuffer;
    }

    /// 从数据库中加载特征向量
    @PluginMethod()
    public void loadTensorFromDB(PluginCall call) {
        try {
            // 加载 TFLite 模型
            this.similarity = new TFLiteSimilarity(this.getContext(), "similarity_model.tflite");

            // 打开 SQLite 数据库并读取特征
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                File dbFile = new File(this.getContext().getDataDir(), "databases/mediaSQLite.db");
                this.db = SQLiteDatabase.openOrCreateDatabase(dbFile, null);
            } else {
                String errMsg = "Error: Database not supported until Android 7.0 (API 24)";
                Toast.makeText(this.getContext(), errMsg, Toast.LENGTH_LONG).show();
                call.reject(errMsg);
                return;
            }

            // 查询数据库
            Cursor cursor = db.rawQuery("SELECT identifier, processStep, feature FROM media", null);
            List<float[]> featureList = new ArrayList<>();

            int numCols = -1; // 记录特征向量维度
            while (cursor.moveToNext()) {
                float[] feature;
                if (cursor.getInt(1) == 2) {
                    // If ProcessStep == 2
                    byte[] blob = cursor.getBlob(2);
                    feature = byteArrayToFloatArray(blob);
                } else feature = new float[768];

                featureList.add(feature);
                if (numCols == -1) {
                    numCols = feature.length;
                }
            }
            cursor.close();

            int numRows = featureList.size();
            if (numRows == 0 || numCols == -1) {
                throw new IllegalStateException("No valid features found.");
            }

            // 构建 TensorBuffer
            TensorBuffer tensorBuffer = TensorBuffer.createFixedSize(new int[]{numRows, numCols}, DataType.FLOAT32);
            ByteBuffer buffer = ByteBuffer.allocateDirect(numRows * numCols * 4).order(ByteOrder.nativeOrder());

            for (float[] feature : featureList) {
                for (float value : feature) {
                    buffer.putFloat(value);
                }
            }

            tensorBuffer.loadBuffer(buffer);
            imageTensors = tensorBuffer;

            call.resolve();
        } catch (Exception e) {
            call.reject("Error loading tensor", e);
        }
    }

    @PluginMethod()
    public void calculateCosineSimilarity(PluginCall call) {
        // 获取 tensorArray
        JSArray tensorArray = call.getArray("tensorArray");
        if (tensorArray == null) {
            call.reject("No tensor data provided");
            return;
        }

        float[] probs = null;
        try {
            // Tensor类型
            // 2️⃣ byte[] 转 float[]
            float[] tensorData = new float[tensorArray.length()];

            for (int i = 0; i < tensorArray.length(); i++) {
                tensorData[i] = (float) tensorArray.getDouble(i);
            }

            // 3️⃣ 转换为 textTensor
            TensorBuffer textTensor = TensorBuffer.createFixedSize(new int[]{1, tensorData.length}, org.tensorflow.lite.DataType.FLOAT32);
            textTensor.loadArray(tensorData);
            // TODO: 利用TFLite矩阵相乘，计算余弦相似度

            try {
                // 计算相似度
                probs = this.similarity.computeSimilarity(textTensor, imageTensors);

                // 输出概率
                // TODO: 删除这行代码
                System.out.println("Similarity Probabilities: " + Arrays.toString(probs));

            } catch (Exception e) {
                e.printStackTrace();
            }

            // 返回计算结果
            JSObject result = new JSObject();
            JSArray jsonArray = new JSArray();

            // 将 float[] 转换为 JSArray
            for (float prob : probs) {
                jsonArray.put(prob);
            }

            result.put("prob", jsonArray);
            // ✅ 处理完毕，返回成功
            call.resolve(result);
        } catch (Exception e) {
            call.reject("Error calculating cosine similarity", e);
        }
    }

    @PluginMethod()
    public void offloadTensor(PluginCall call) {
        try {
            // 关闭数据库
            db.close();
            db = null;

            // 关闭 TFLite 模型
            this.similarity.close();

            call.resolve();
        } catch (Exception e) {
            call.reject("Error offloading tensor", e);
        }
    }

    // 将字节数组转换为 float 数组（假设你的特征是 float 类型）
    private static float[] byteArrayToFloatArray(byte[] bytes) {
        ByteBuffer byteBuffer = ByteBuffer.wrap(bytes).order(ByteOrder.nativeOrder());
        float[] floats = new float[bytes.length / 4];
        byteBuffer.asFloatBuffer().get(floats);
        return floats;
    }

    // 计算余弦相似度
    private float cosineSimilarity(float[] vector1, float[] vector2) {
        float dotProduct = 0f;
        float normA = 0f;
        float normB = 0f;
        for (int i = 0; i < vector1.length; i++) {
            dotProduct += vector1[i] * vector2[i];
            normA += Math.pow(vector1[i], 2);
            normB += Math.pow(vector2[i], 2);
        }
        return dotProduct / (float) (Math.sqrt(normA) * Math.sqrt(normB));
    }
}
