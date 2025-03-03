import Foundation
import TensorFlowLite

class TFLiteSimilarity {
    private var interpreter: Interpreter

    init(modelName: String) throws {
        guard let modelPath = Bundle.main.path(forResource: modelName, ofType: "tflite") else {
            throw NSError(domain: "TFLite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model not found"])
        }
        interpreter = try Interpreter(modelPath: modelPath)
    }

    func computeSimilarity(textFeatures: [Float], imageFeatures: [Float]) throws -> [Float] {
        let batchSize = imageFeatures.count / 768

        // 重新调整输入大小
        try interpreter.resizeInput(at: 1, to: [batchSize, 768])
        try interpreter.allocateTensors()

        // 创建 TensorBuffer
        let textTensor = try TensorBuffer(shape: [1, 768], data: textFeatures)
        let imageTensor = try TensorBuffer(shape: [batchSize, 768], data: imageFeatures)

        var outputProbs = [Float](repeating: 0.0, count: batchSize)
        let outputs = [UnsafeMutableRawPointer(&outputProbs)]

        // 运行推理
        try interpreter.invoke()
        try interpreter.copy(outputProbs, toInputAt: 0)

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
