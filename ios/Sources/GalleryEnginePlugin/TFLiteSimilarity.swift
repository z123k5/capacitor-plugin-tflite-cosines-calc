import Foundation
import TensorFlowLite

class TFLiteSimilarity {
    private var interpreter: Interpreter

    init(modelName: String) throws {
//        guard let modelPath = Bundle.main.path(forResource: modelName, ofType: "tflite") else {
//            throw NSError(domain: "TFLite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model not found"])
//        }
        guard let bundleURL = Bundle(for: GalleryEnginePlugin.self).url(forResource: "podRes", withExtension: "bundle"),
              let resourceBundle = Bundle(url: bundleURL),
              let modelPath = resourceBundle.path(forResource: modelName, ofType: "tflite")
        else {
            throw NSError(domain: "TFLite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model not found in bundle"])
        }
        interpreter = try Interpreter(modelPath: modelPath)
    }

    func computeSimilarity(textFeatures: [Float], imageFeatures: [Float]) throws -> [Float] {
        let batchSize = imageFeatures.count / 768
        
        // 调整输入大小
        try interpreter.resizeInput(at: 0, to: [1, 768]) // 假设 textFeatures 对应索引 0
        try interpreter.resizeInput(at: 1, to: [batchSize, 768]) // 假设 imageFeatures 对应索引 1
        try interpreter.allocateTensors()

        // 转换输入数据
        let textData = Data(buffer: UnsafeBufferPointer(start: textFeatures, count: textFeatures.count))
        let imageData = Data(buffer: UnsafeBufferPointer(start: imageFeatures, count: imageFeatures.count))

        // 复制数据到 TFLite 解释器
        try interpreter.copy(textData, toInputAt: 0)
        try interpreter.copy(imageData, toInputAt: 1)

        // 运行推理
        try interpreter.invoke()

        // 获取输出
        let outputTensor = try interpreter.output(at: 0) // 假设输出索引是 0
        let outputProbs = outputTensor.data.toArray(type: Float.self)

        return outputProbs
    }

}

// TensorBuffer 辅助类
struct TensorBuffer {
    let shape: [Int]
    let data: [Float]

    func toByteBuffer() -> Data {
        var buffer = Data()
        for value in data {
            var value = value
            buffer.append(Data(bytes: &value, count: MemoryLayout<Float>.size))
        }
        return buffer
    }
}
